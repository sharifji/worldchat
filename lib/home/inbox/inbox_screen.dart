import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'Chats/Chats_screen.dart';
import 'Chats/group_creation_screen.dart';
import 'Chats/group_chat_screen.dart';

class InboxScreen extends StatefulWidget {
  const InboxScreen({super.key, required String chatId, required String recipientId, required String recipientName});

  @override
  State<InboxScreen> createState() => _InboxScreenState();
}

class _InboxScreenState extends State<InboxScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _showGroups = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _getUserName(Map<String, dynamic> userData) {
    final name = userData['name']?.toString().trim();
    if (name != null && name.isNotEmpty) return name;

    final displayName = userData['displayName']?.toString().trim();
    if (displayName != null && displayName.isNotEmpty) return displayName;

    final email = userData['email']?.toString().trim() ?? '';
    if (email.contains('@')) return email.split('@')[0];

    return 'Unknown User';
  }

  String _getGroupName(Map<String, dynamic> groupData) {
    return groupData['name']?.toString().trim() ?? 'Unnamed Group';
  }

  String _getUserInitial(String name) {
    if (name.isEmpty) return '?';
    return name[0].toUpperCase();
  }

  Widget _buildDrawerItem(IconData icon, String title, {VoidCallback? onTap}) {
    return ListTile(
      leading: Icon(icon, color: Colors.white),
      title: Text(title, style: const TextStyle(color: Colors.white)),
      onTap: onTap ?? () {
        Navigator.pop(context);
      },
    );
  }

  void _navigateToGroupCreation() {
    Navigator.pop(context);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const GroupCreationScreen(),
      ),
    );
  }
  void _toggleView() {
    setState(() {
      _showGroups = !_showGroups;
    });
  }

  String? _getUserPhotoUrl(Map<String, dynamic> userData) {
    // Check all possible photo URL fields
    final photoUrl = userData['photoUrl'] ??
        userData['profileImage'] ??
        userData['image'] ??
        userData['profilePicture'];
    return photoUrl?.toString().trim();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      drawer: Drawer(
        backgroundColor: Colors.grey[900],
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.black,
              ),
              child: Text(
                'Menu',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                ),
              ),
            ),
            _buildDrawerItem(Icons.markunread, 'Marketing messages'),
            _buildDrawerItem(
              Icons.group_add,
              'New group',
              onTap: _navigateToGroupCreation,
            ),
            _buildDrawerItem(Icons.business, 'Business broadcasts'),
            _buildDrawerItem(Icons.people, 'Communities'),
            _buildDrawerItem(Icons.label, 'Labels'),
            _buildDrawerItem(Icons.devices, 'Linked devices'),
            _buildDrawerItem(Icons.star, 'Starred'),
            _buildDrawerItem(Icons.settings, 'Settings'),
            const Divider(color: Colors.grey),
          ],
        ),
      ),
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('Messages', style: TextStyle(color: Colors.white)),
        actions: [
          IconButton(
            icon: Icon(
              _showGroups ? Icons.person : Icons.group,
              color: Colors.white,
            ),
            onPressed: _toggleView,
            tooltip: _showGroups ? 'Show Users' : 'Show Groups',
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase();
                });
              },
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.grey[900],
                hintText: _showGroups ? 'Search groups...' : 'Search users...',
                hintStyle: const TextStyle(color: Colors.grey),
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
        ),
      ),
      body: _showGroups ? _buildGroupsList() : _buildUsersList(),
    );
  }

  Widget _buildUsersList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore.collection('users').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          debugPrint('Error fetching users: ${snapshot.error}');
          return Center(
            child: Text(
              'Error loading users',
              style: TextStyle(color: Colors.white),
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final currentUserId = _auth.currentUser?.uid;
        if (currentUserId == null) {
          return const Center(
            child: Text(
              'Please sign in',
              style: TextStyle(color: Colors.white),
            ),
          );
        }

        final users = snapshot.data!.docs.where((doc) {
          final userData = doc.data() as Map<String, dynamic>;
          final userId = doc.id;
          final name = _getUserName(userData).toLowerCase();
          final email = userData['email']?.toString().toLowerCase() ?? '';

          return userId != currentUserId &&
              (name.contains(_searchQuery) || email.contains(_searchQuery));
        }).toList();

        if (users.isEmpty) {
          return Center(
            child: Text(
              'No users found',
              style: TextStyle(color: Colors.grey),
            ),
          );
        }

        return ListView.builder(
          itemCount: users.length,
          itemBuilder: (context, index) {
            final userDoc = users[index];
            final userData = userDoc.data() as Map<String, dynamic>;
            final userId = userDoc.id;
            final name = _getUserName(userData);
            final email = userData['email'] ?? 'No email';
            final photoUrl = _getUserPhotoUrl(userData);

            debugPrint('Loading user: $name - Photo URL: $photoUrl');

            return ListTile(
              leading: _buildUserAvatar(name, photoUrl),
              title: Text(
                name,
                style: const TextStyle(color: Colors.white),
              ),
              subtitle: Text(
                email,
                style: const TextStyle(color: Colors.grey),
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ChatScreen(
                      recipientId: userId,
                      recipientName: name,
                      recipientPhotoUrl: photoUrl,
                      chatId: _generateChatId(currentUserId, userId),
                      isRecipientOnline: false, // or true based on your logic
                      recipientLastSeen: DateTime.now(), isRecipientOnlin: null, // or null if not available
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildUserAvatar(String name, String? photoUrl) {
    if (photoUrl != null && photoUrl.isNotEmpty) {
      return CircleAvatar(
        radius: 24,
        backgroundColor: Colors.grey[800],
        backgroundImage: NetworkImage(photoUrl),
        onBackgroundImageError: (exception, stackTrace) {
          debugPrint('Failed to load profile image: $exception');
        },
        child: null,
      );
    }
    return CircleAvatar(
      radius: 24,
      backgroundColor: Colors.grey[800],
      child: Text(
        _getUserInitial(name),
        style: const TextStyle(color: Colors.white),
      ),
    );
  }

  Widget _buildGroupsList() {
    final currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null) {
      return const Center(
        child: Text(
          'Please sign in',
          style: TextStyle(color: Colors.white),
        ),
      );
    }

    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('groups')
          .where('members', arrayContains: currentUserId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          debugPrint('Error fetching groups: ${snapshot.error}');
          return Center(
            child: Text(
              'Error loading groups',
              style: TextStyle(color: Colors.white),
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final groups = snapshot.data!.docs.where((doc) {
          final groupData = doc.data() as Map<String, dynamic>;
          final name = _getGroupName(groupData).toLowerCase();
          return name.contains(_searchQuery);
        }).toList();

        if (groups.isEmpty) {
          return Center(
            child: Text(
              'No groups found',
              style: TextStyle(color: Colors.grey),
            ),
          );
        }

        return ListView.builder(
          itemCount: groups.length,
          itemBuilder: (context, index) {
            final groupDoc = groups[index];
            final groupData = groupDoc.data() as Map<String, dynamic>;
            final groupId = groupDoc.id;
            final name = _getGroupName(groupData);
            final membersCount = (groupData['members'] as List?)?.length ?? 0;
            final groupImage = groupData['groupImage']?.toString().trim();

            return ListTile(
              leading: _buildGroupAvatar(groupImage),
              title: Text(
                name,
                style: const TextStyle(color: Colors.white),
              ),
              subtitle: Text(
                '$membersCount members',
                style: const TextStyle(color: Colors.grey),
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => GroupChatScreen(
                      groupId: groupId,
                      groupName: name,
                      groupImage: groupImage,
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildGroupAvatar(String? groupImage) {
    if (groupImage != null && groupImage.isNotEmpty) {
      return CircleAvatar(
        radius: 24,
        backgroundColor: Colors.grey[800],
        backgroundImage: NetworkImage(groupImage),
        onBackgroundImageError: (exception, stackTrace) {
          debugPrint('Failed to load group image: $exception');
        },
      );
    }
    return CircleAvatar(
      radius: 24,
      backgroundColor: Colors.grey[800],
      child: const Icon(Icons.group, color: Colors.white),
    );
  }

  String _generateChatId(String userId1, String userId2) {
    // Generate consistent chat ID regardless of user order
    return userId1.compareTo(userId2) < 0
        ? '${userId1}_$userId2'
        : '${userId2}_$userId1';
  }
}

