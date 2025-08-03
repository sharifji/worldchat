import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:photo_view/photo_view.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'package:permission_handler/permission_handler.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

enum MessageStatus { sending, sent, delivered, read }

class ChatMessage {
  final String id;
  final String text;
  final String sender;
  final DateTime timestamp;
  final MessageStatus status;
  final ChatMessage? replyTo;
  final Map<String, List<String>>? reactions;

  const ChatMessage({
    required this.id,
    required this.text,
    required this.sender,
    required this.timestamp,
    this.status = MessageStatus.sent,
    this.replyTo,
    this.reactions,
  });
}

// ==================== Emoji Picker & Data ====================
class Emoji {
  final String emoji;
  final String name;
  final String category;

  const Emoji({required this.emoji, required this.name, required this.category});
}

class EmojiCategory {
  final String name;
  final List<Emoji> emojis;

  const EmojiCategory({required this.name, required this.emojis});
}

class EmojiData {
  static const List<EmojiCategory> categories = [
    EmojiCategory(
      name: 'Smileys',
      emojis: [
        Emoji(emoji: '😀', name: 'Grinning Face', category: 'Smileys'),
        Emoji(emoji: '😂', name: 'Face with Tears of Joy', category: 'Smileys'),
        Emoji(emoji: '😍', name: 'Smiling Face with Heart-Eyes', category: 'Smileys'),
      ],
    ),
    EmojiCategory(
      name: 'Animals',
      emojis: [
        Emoji(emoji: '🐶', name: 'Dog Face', category: 'Animals'),
        Emoji(emoji: '🐱', name: 'Cat Face', category: 'Animals'),
      ],
    ),
  ];
}

class EmojiPicker extends StatefulWidget {
  final Function(String) onEmojiSelected;

  const EmojiPicker({Key? key, required this.onEmojiSelected}) : super(key: key);

  @override
  _EmojiPickerState createState() => _EmojiPickerState();
}

class _EmojiPickerState extends State<EmojiPicker> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<String> _categories = ['😀', '🐻', '🎉', '🍔', '⚡', '🏳️'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: EmojiData.categories.length, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 300,
      color: Theme.of(context).cardColor,
      child: Column(
        children: [
          TabBar(
            controller: _tabController,
            isScrollable: true,
            tabs: _categories.map((e) => Tab(text: e)).toList(),
            indicatorColor: Theme.of(context).primaryColor,
            labelColor: Theme.of(context).primaryColor,
            unselectedLabelColor: Colors.grey,
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: EmojiData.categories.map((category) {
                return GridView.builder(
                  padding: const EdgeInsets.all(10),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 7,
                    childAspectRatio: 1,
                  ),
                  itemCount: category.emojis.length,
                  itemBuilder: (context, index) {
                    return IconButton(
                      icon: Text(category.emojis[index].emoji, style: const TextStyle(fontSize: 24)),
                      onPressed: () => widget.onEmojiSelected(category.emojis[index].emoji),
                    );
                  },
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}

// ==================== Message Info Screen (Updated) ====================
class MessageInfoScreen extends StatelessWidget {
  final ChatMessage message;
  final List<String> readBy;

  const MessageInfoScreen({
    Key? key,
    required this.message,
    required this.readBy,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Message Info')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (message.replyTo != null) ...[
              const Text('Replying to:', style: TextStyle(fontWeight: FontWeight.bold)),
              _buildMessagePreview(message.replyTo!),
              const SizedBox(height: 20),
            ],
            Text(
              'Sent: ${DateFormat('MMM d, y h:mm a').format(message.timestamp)}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 20),
            _buildStatusRow('Sent', message.status.index >= MessageStatus.sent.index, Icons.send),
            _buildStatusRow('Delivered', message.status.index >= MessageStatus.delivered.index, Icons.done_all),
            _buildStatusRow('Read', message.status == MessageStatus.read, Icons.remove_red_eye),
            if (readBy.isNotEmpty) ...[
              const SizedBox(height: 20),
              Text('Read by:', style: Theme.of(context).textTheme.titleMedium),
              ...readBy.map((user) => ListTile(
                leading: const CircleAvatar(child: Icon(Icons.person)),
                title: Text(user),
              )).toList(),
            ],
            if (message.reactions != null && message.reactions!.isNotEmpty) ...[
              const SizedBox(height: 20),
              Text('Reactions:', style: Theme.of(context).textTheme.titleMedium),
              Wrap(
                spacing: 8,
                children: message.reactions!.entries.map((entry) {
                  return Chip(
                    label: Text('${entry.key} (${entry.value.length})'),
                    avatar: Text(entry.key),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMessagePreview(ChatMessage message) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            message.sender,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(message.text),
        ],
      ),
    );
  }

  Widget _buildStatusRow(String label, bool isComplete, IconData icon) {
    return ListTile(
      leading: Icon(icon, color: isComplete ? Colors.green : Colors.grey),
      title: Text(label),
      trailing: Text(isComplete ? 'Yes' : 'No'),
    );
  }
}

// ==================== Message Status Indicator ====================
class MessageStatusIndicator extends StatelessWidget {
  final bool isRead;
  final bool isDelivered;
  final bool isSent;
  final double size;

  const MessageStatusIndicator({
    Key? key,
    required this.isRead,
    required this.isDelivered,
    required this.isSent,
    this.size = 16,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    IconData icon;
    Color color;

    if (isRead) {
      icon = Icons.done_all;
      color = Colors.blue;
    } else if (isDelivered) {
      icon = Icons.done_all;
      color = Colors.grey;
    } else if (isSent) {
      icon = Icons.done;
      color = Colors.grey;
    } else {
      icon = Icons.access_time;
      color = Colors.grey;
    }

    return Icon(icon, color: color, size: size);
  }
}

// ==================== Media Gallery Screen ====================
class MediaGalleryScreen extends StatefulWidget {
  final List<String> mediaUrls;
  final int initialIndex;

  const MediaGalleryScreen({
    Key? key,
    required this.mediaUrls,
    this.initialIndex = 0,
  }) : super(key: key);

  @override
  _MediaGalleryScreenState createState() => _MediaGalleryScreenState();
}

class _MediaGalleryScreenState extends State<MediaGalleryScreen> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              itemCount: widget.mediaUrls.length,
              onPageChanged: (index) => setState(() => _currentIndex = index),
              itemBuilder: (context, index) {
                return PhotoView(
                  imageProvider: CachedNetworkImageProvider(widget.mediaUrls[index]),
                  minScale: PhotoViewComputedScale.contained,
                  maxScale: PhotoViewComputedScale.covered * 2,
                );
              },
            ),
          ),
          if (widget.mediaUrls.length > 1)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                '${_currentIndex + 1}/${widget.mediaUrls.length}',
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
}

// ==================== Document Preview Screen ====================
class DocumentPreviewScreen extends StatefulWidget {
  final String url;
  final String fileName;

  const DocumentPreviewScreen({
    Key? key,
    required this.url,
    required this.fileName,
  }) : super(key: key);

  @override
  _DocumentPreviewScreenState createState() => _DocumentPreviewScreenState();
}

class _DocumentPreviewScreenState extends State<DocumentPreviewScreen> {
  String? localPath;
  bool isLoading = true;
  bool isError = false;

  @override
  void initState() {
    super.initState();
    _loadDocument();
  }

  Future<void> _loadDocument() async {
    try {
      final response = await http.get(Uri.parse(widget.url));
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/${widget.fileName}');
      await file.writeAsBytes(response.bodyBytes);
      setState(() {
        localPath = file.path;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isError = true;
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.fileName)),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : isError
          ? const Center(child: Text('Failed to load document'))
          : PDFView(
        filePath: localPath,
        enableSwipe: true,
        swipeHorizontal: true,
        autoSpacing: false,
        pageFling: false,
        onRender: (_pages) {},
        onError: (error) {
          setState(() {
            isError = true;
          });
        },
        onPageError: (page, error) {},
        onViewCreated: (PDFViewController pdfViewController) {},
      ),
    );
  }
}

// ==================== Media Download Manager ====================
class MediaDownloadManager {
  static Future<String?> downloadMedia(String url, String fileName) async {
    try {
      if (!await _checkPermission()) return null;

      final response = await http.get(Uri.parse(url));
      final dir = await _getDownloadDirectory();
      final file = File('${dir.path}/$fileName');
      await file.writeAsBytes(response.bodyBytes);
      return file.path;
    } catch (e) {
      debugPrint('Download error: $e');
      return null;
    }
  }

  static Future<bool> _checkPermission() async {
    final status = await Permission.storage.request();
    return status.isGranted;
  }

  static Future<Directory> _getDownloadDirectory() async {
    if (Platform.isAndroid) {
      return Directory('/storage/emulated/0/Download');
    } else if (Platform.isIOS) {
      return await getApplicationDocumentsDirectory();
    }
    return await getDownloadsDirectory() ?? await getApplicationDocumentsDirectory();
  }
}

// ==================== Contact Card ====================
class ContactCard extends StatelessWidget {
  final String name;
  final String phoneNumber;
  final String? email;
  final String? photoUrl;
  final VoidCallback? onSharePressed;

  const ContactCard({
    Key? key,
    required this.name,
    required this.phoneNumber,
    this.email,
    this.photoUrl,
    this.onSharePressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
        margin: const EdgeInsets.all(8),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
          ListTile(
          leading: CircleAvatar(
          radius: 25,
            backgroundImage: photoUrl != null ? NetworkImage(photoUrl!) : null,
            child: photoUrl == null ? Text(name[0].toUpperCase()) : null,
          ),
          title: Text(name, style: Theme.of(context).textTheme.titleMedium),
          subtitle: Text(phoneNumber),
        ),
        if (email != null)
    Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        children: [
          const Icon(Icons.email, size: 16),
          const SizedBox(width: 8),
          Text(email!),
        ],
      ),
    ),
    const SizedBox(height: 8),
    ElevatedButton(
    onPressed: onSharePressed,
    child: const Text('Share Contact')),

    ],
    ),
    ),
    );
  }
}

// ==================== Location Picker ====================
class LocationPicker extends StatefulWidget {
  final Function(LatLng) onLocationSelected;

  const LocationPicker({Key? key, required this.onLocationSelected}) : super(key: key);

  @override
  _LocationPickerState createState() => _LocationPickerState();
}

class _LocationPickerState extends State<LocationPicker> {
  late GoogleMapController _mapController;
  LatLng? _selectedLocation;
  bool _isLoading = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Location'),
        actions: [
          if (_selectedLocation != null)
            IconButton(
              icon: const Icon(Icons.check),
              onPressed: () {
                widget.onLocationSelected(_selectedLocation!);
                Navigator.pop(context);
              },
            ),
        ],
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: const CameraPosition(
              target: LatLng(0, 0),
              zoom: 2,
            ),
            onMapCreated: (controller) {
              _mapController = controller;
              setState(() => _isLoading = false);
            },
            onTap: (latLng) {
              setState(() => _selectedLocation = latLng);
            },
            markers: _selectedLocation != null
                ? {
              Marker(
                markerId: const MarkerId('selected_location'),
                position: _selectedLocation!,
              ),
            }
                : {},
          ),
          if (_isLoading)
            const Center(child: CircularProgressIndicator()),
          const Center(
            child: Icon(Icons.location_on, size: 40, color: Colors.red),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.my_location),
        onPressed: () async {
          // TODO: Implement current location functionality
        },
      ),
    );
  }
}

// ==================== Poll Creator ====================
class PollCreator extends StatefulWidget {
  final Function(String, List<String>) onCreatePoll;

  const PollCreator({Key? key, required this.onCreatePoll}) : super(key: key);

  @override
  _PollCreatorState createState() => _PollCreatorState();
}

class _PollCreatorState extends State<PollCreator> {
  final _questionController = TextEditingController();
  final List<TextEditingController> _optionControllers = [
    TextEditingController(),
    TextEditingController(),
  ];

  @override
  void dispose() {
    _questionController.dispose();
    for (var controller in _optionControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Poll'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _createPoll,
          ),
        ],
      ),
      body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
            TextField(
            controller: _questionController,
            decoration: const InputDecoration(
              labelText: 'Poll Question',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 20),
          const Text('Options:', style: TextStyle(fontSize: 16)),
          ..._buildOptionFields(),
      TextButton(
          onPressed: _addOption,
          child: const Text('Add Option')),

    ],
    ),
    ),
    );
  }

  List<Widget> _buildOptionFields() {
    return List.generate(_optionControllers.length, (index) {
      return Padding(
        padding: const EdgeInsets.only(top: 8.0),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _optionControllers[index],
                decoration: InputDecoration(
                  labelText: 'Option ${index + 1}',
                  border: const OutlineInputBorder(),
                ),
              ),
            ),
            if (_optionControllers.length > 2)
              IconButton(
                icon: const Icon(Icons.remove),
                onPressed: () => _removeOption(index),
              ),
          ],
        ),
      );
    });
  }

  void _addOption() {
    setState(() {
      _optionControllers.add(TextEditingController());
    });
  }

  void _removeOption(int index) {
    setState(() {
      _optionControllers.removeAt(index);
    });
  }

  void _createPoll() {
    final question = _questionController.text.trim();
    final options = _optionControllers
        .map((c) => c.text.trim())
        .where((o) => o.isNotEmpty)
        .toList();

    if (question.isEmpty || options.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a question and at least 2 options')),
      );
      return;
    }

    widget.onCreatePoll(question, options);
    Navigator.pop(context);
  }
}

// ==================== Reaction Picker ====================
class ReactionPicker extends StatelessWidget {
  final Function(String) onReactionSelected;

  const ReactionPicker({Key? key, required this.onReactionSelected}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    const reactions = ['❤️', '😂', '😮', '😢', '👍', '👎'];

    return Container(
      height: 60,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: reactions.map((emoji) {
          return GestureDetector(
            onTap: () => onReactionSelected(emoji),
            child: Text(emoji, style: const TextStyle(fontSize: 24)),
          );
        }).toList(),
      ),
    );
  }
}

// ==================== Reaction Overlay ====================
class ReactionOverlay extends StatelessWidget {
  final Map<String, List<String>> reactions;
  final Function(String) onReactionSelected;
  final VoidCallback onDismiss;

  const ReactionOverlay({
    Key? key,
    required this.reactions,
    required this.onReactionSelected,
    required this.onDismiss,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onDismiss,
      behavior: HitTestBehavior.opaque,
      child: Material(
        color: Colors.transparent,
        child: Center(
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ],
            ),
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Reactions', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                const SizedBox(height: 10),
                ...reactions.entries.map((entry) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () => onReactionSelected(entry.key),
                          child: Text(entry.key, style: const TextStyle(fontSize: 24)),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            entry.value.join(', '),
                            style: Theme.of(context).textTheme.bodyMedium,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text('(${entry.value.length})'),
                      ],
                    ),
                  );
                }).toList(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ==================== Animated Reaction ====================
class AnimatedReaction extends StatefulWidget {
  final String emoji;
  final VoidCallback onTap;
  final bool isActive;

  const AnimatedReaction({
    Key? key,
    required this.emoji,
    required this.onTap,
    this.isActive = false,
  }) : super(key: key);

  @override
  _AnimatedReactionState createState() => _AnimatedReactionState();
}

class _AnimatedReactionState extends State<AnimatedReaction> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.5).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
  }

  @override
  void didUpdateWidget(AnimatedReaction oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive != oldWidget.isActive && widget.isActive) {
      _controller.forward().then((_) => _controller.reverse());
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: widget.isActive
                    ? Colors.blue.withOpacity(0.2)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(widget.emoji, style: const TextStyle(fontSize: 20)),
            ),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

// ==================== Date Separator ====================
class DateSeparator extends StatelessWidget {
  final DateTime date;

  const DateSeparator({Key? key, required this.date}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final yesterday = DateTime.now().subtract(const Duration(days: 1));

    String dateText;
    if (date.year == today.year && date.month == today.month && date.day == today.day) {
      dateText = 'Today';
    } else if (date.year == yesterday.year && date.month == yesterday.month && date.day == yesterday.day) {
      dateText = 'Yesterday';
    } else {
      dateText = DateFormat('MMMM d, y').format(date);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Expanded(child: Divider(thickness: 1)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              dateText,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey),
            ),
          ),
          Expanded(child: Divider(thickness: 1)),
        ],
      ),
    );
  }
}

// ==================== Typing Indicator ====================
class TypingIndicator extends StatefulWidget {
  final List<String> typingUsers;

  const TypingIndicator({Key? key, required this.typingUsers}) : super(key: key);

  @override
  _TypingIndicatorState createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<TypingIndicator> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat(reverse: true);

    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.typingUsers.isEmpty) return const SizedBox.shrink();

    String text;
    if (widget.typingUsers.length == 1) {
      text = '${widget.typingUsers[0]} is typing...';
    } else if (widget.typingUsers.length == 2) {
      text = '${widget.typingUsers[0]} and ${widget.typingUsers[1]} are typing...';
    } else {
      text = '${widget.typingUsers[0]} and ${widget.typingUsers.length - 1} others are typing...';
    }

    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 16, bottom: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              return Opacity(
                opacity: _animation.value,
                child: child,
              );
            },
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                text,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ==================== Online Status ====================
class OnlineStatus extends StatelessWidget {
  final bool isOnline;
  final DateTime? lastSeen;
  final double dotSize;
  final bool showText;

  const OnlineStatus({
    Key? key,
    required this.isOnline,
    this.lastSeen,
    this.dotSize = 10.0,
    this.showText = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: dotSize,
          height: dotSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isOnline ? Colors.green : Colors.grey,
          ),
        ),
        if (showText) ...[
          const SizedBox(width: 4),
          Text(
            isOnline ? 'Online' : _getLastSeenText(),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: isOnline ? Colors.green : Colors.grey,
            ),
          ),
        ],
      ],
    );
  }

  String _getLastSeenText() {
    if (lastSeen == null) return 'Offline';

    final now = DateTime.now();
    final difference = now.difference(lastSeen!);

    if (difference.inDays > 30) {
      return 'Last seen ${DateFormat('MMM d').format(lastSeen!)}';
    } else if (difference.inDays > 0) {
      return 'Last seen ${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    } else if (difference.inHours > 0) {
      return 'Last seen ${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else if (difference.inMinutes > 0) {
      return 'Last seen ${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago';
    } else {
      return 'Last seen just now';
    }
  }
}