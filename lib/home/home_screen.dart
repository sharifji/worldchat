import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:worldchat/ai_chatbot/controllers/ai_chat_controller.dart';
import 'package:worldchat/ai_chatbot/screens/ai_chat_screen.dart';
import 'package:worldchat/home/profile/profile_screen.dart';
import 'package:worldchat/home/profile/user_profile_screen.dart';
import 'package:worldchat/home/uploaded%20video/upload_custom_icon.dart';
import 'package:worldchat/home/uploaded%20video/upload_video_screen.dart';
import 'package:worldchat/home/inbox/inbox_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _searchController = TextEditingController();

  int screenIndex = 0;
  String _searchQuery = '';

  final List<Widget> screensList = [
    const _HomeTabContent(),
    ChangeNotifierProvider(
      create: (_) => AiChatController(),
      child: const AiChatScreen(),
    ),
    const UploadVideoScreen(),
    const InboxScreen(chatId: '', recipientId: '', recipientName: ''),
    const ProfileScreen(userId: ''),
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: screensList[screenIndex],
      bottomNavigationBar: BottomNavigationBar(
        onTap: (index) {
          setState(() {
            screenIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.black,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.grey,
        currentIndex: screenIndex,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home, size: 28),
            label: "Home",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble, size: 28),
            label: "AI Chat",
          ),
          BottomNavigationBarItem(
            icon: UploadCustomIcon(),
            label: "",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.inbox, size: 28),
            label: "Inbox",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person, size: 28),
            label: "Me",
          ),
        ],
      ),
    );
  }
}

class _HomeTabContent extends StatefulWidget {
  const _HomeTabContent({super.key});

  @override
  State<_HomeTabContent> createState() => _HomeTabContentState();
}

class _HomeTabContentState extends State<_HomeTabContent> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _openProfileScreen(String userId, Map<String, dynamic> userData) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UserProfileScreen(
          userId: userId,
          userData: userData,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          color: Colors.black,
          padding: const EdgeInsets.only(top: 40, left: 16, right: 16, bottom: 8),
          child: Column(
            children: [
              const SizedBox(height: 8),
              Container(
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.grey[900],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value.toLowerCase();
                    });
                  },
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    prefixIcon: Icon(Icons.search, color: Colors.grey),
                    hintText: 'Search',
                    hintStyle: TextStyle(color: Colors.grey),
                    contentPadding: EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
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

              final filteredUsers = snapshot.data!.docs.where((doc) {
                final userData = doc.data() as Map<String, dynamic>;
                final userId = doc.id;
                final name = _getUserName(userData).toLowerCase();
                final email = userData['email']?.toString().toLowerCase() ?? '';

                return userId != currentUserId &&
                    (name.contains(_searchQuery) || email.contains(_searchQuery));
              }).toList();

              if (filteredUsers.isEmpty) {
                return Center(
                  child: Text(
                    'No users found',
                    style: TextStyle(color: Colors.grey),
                  ),
                );
              }

              return Column(
                children: [
                  _buildTopUsers(filteredUsers),
                  const Divider(color: Colors.grey, height: 1),
                ],
              );
            },
          ),
        ),
      ],
    );
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

  Widget _buildTopUsers(List<QueryDocumentSnapshot> users) {
    return SizedBox(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: users.length,
        itemBuilder: (context, index) {
          final userDoc = users[index];
          final userData = userDoc.data() as Map<String, dynamic>;
          final name = _getUserName(userData);
          final photoUrl = _getUserPhotoUrl(userData);
          final userId = userDoc.id;

          return GestureDetector(
            onTap: () => _openProfileScreen(userId, userData),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildUserAvatar(name, photoUrl, radius: 28),
                  const SizedBox(height: 4),
                  SizedBox(
                    width: 60,
                    child: Text(
                      name.split(' ')[0],
                      style: const TextStyle(color: Colors.white),
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  String? _getUserPhotoUrl(Map<String, dynamic> userData) {
    final photoUrl = userData['photoUrl'] ??
        userData['profileImage'] ??
        userData['image'] ??
        userData['profilePicture'];
    return photoUrl?.toString().trim();
  }

  Widget _buildUserAvatar(String name, String? photoUrl, {double radius = 24}) {
    if (photoUrl != null && photoUrl.isNotEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: Colors.grey[800],
        backgroundImage: NetworkImage(photoUrl),
        onBackgroundImageError: (exception, stackTrace) {
          debugPrint('Failed to load profile image: $exception');
        },
      );
    }
    return CircleAvatar(
      radius: radius,
      backgroundColor: Colors.grey[800],
      child: Text(
        _getUserInitial(name),
        style: const TextStyle(color: Colors.white),
      ),
    );
  }

  String _getUserInitial(String name) {
    if (name.isEmpty) return '?';
    return name[0].toUpperCase();
  }
}