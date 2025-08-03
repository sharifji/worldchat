import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:worldchat/settings/settings_screen.dart';
import 'package:worldchat/services/cloudinary_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProfileScreen extends StatefulWidget {
  final String userId;
  const ProfileScreen({super.key, required this.userId});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String? bio;
  String username = 'username';
  String country = 'Country';
  int followingCount = 0;
  int followersCount = 0;
  int likesCount = 0;
  bool isPrivate = false;
  bool showLikes = true;
  bool showLockedVideos = true;
  File? _profileImage;
  String? _profileImageUrl;
  final ImagePicker _picker = ImagePicker();
  final CloudinaryService _cloudinary = CloudinaryService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final userDoc = await _firestore.collection('users').doc(widget.userId).get();
      if (userDoc.exists) {
        final userData = userDoc.data() as Map<String, dynamic>;
        setState(() {
          username = userData['username'] ?? 'username';
          bio = userData['bio'];
          country = userData['country'] ?? 'Country';
          followingCount = userData['followingCount'] ?? 0;
          followersCount = userData['followersCount'] ?? 0;
          likesCount = userData['likesCount'] ?? 0;
          isPrivate = userData['isPrivate'] ?? false;
          showLikes = userData['showLikes'] ?? true;
          showLockedVideos = userData['showLockedVideos'] ?? true;
          _profileImageUrl = userData['profileImageUrl'];
        });
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to load user data: ${e.toString()}');
    }
  }

  Future<void> _editProfile() async {
    final result = await Get.dialog(
      AlertDialog(
        title: const Text('Edit Profile'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                decoration: const InputDecoration(labelText: 'Username'),
                controller: TextEditingController(text: username),
                onChanged: (value) => username = value,
              ),
              TextField(
                decoration: const InputDecoration(labelText: 'Bio'),
                controller: TextEditingController(text: bio ?? ''),
                onChanged: (value) => bio = value,
                maxLines: 3,
              ),
              TextField(
                decoration: const InputDecoration(labelText: 'Country'),
                controller: TextEditingController(text: country),
                onChanged: (value) => country = value,
              ),
              SwitchListTile(
                title: const Text('Private Account'),
                value: isPrivate,
                onChanged: (value) => setState(() => isPrivate = value),
              ),
              SwitchListTile(
                title: const Text('Show Likes'),
                value: showLikes,
                onChanged: (value) => setState(() => showLikes = value),
              ),
              SwitchListTile(
                title: const Text('Show Locked Videos'),
                value: showLockedVideos,
                onChanged: (value) => setState(() => showLockedVideos = value),
              ),
              ElevatedButton(
                onPressed: _pickImage,
                child: const Text('Change Profile Picture'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Get.back(result: true),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result == true) {
      await _saveProfileChanges();
    }
  }

  Future<void> _pickImage() async {
    try {
      final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        setState(() {
          _profileImage = File(pickedFile.path);
          _profileImageUrl = null;
        });
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to pick image: ${e.toString()}');
    }
  }

  Future<void> _saveProfileChanges() async {
    try {
      String? newImageUrl = _profileImageUrl;

      if (_profileImage != null) {
        newImageUrl = await _cloudinary.uploadImage(_profileImage!);
      }

      await _firestore.collection('users').doc(widget.userId).update({
        'username': username,
        'bio': bio,
        'country': country,
        'isPrivate': isPrivate,
        'showLikes': showLikes,
        'showLockedVideos': showLockedVideos,
        if (newImageUrl != null) 'profileImageUrl': newImageUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      setState(() {
        if (newImageUrl != null) {
          _profileImageUrl = newImageUrl;
        }
      });

      Get.snackbar('Success', 'Profile updated successfully');
    } catch (e) {
      Get.snackbar('Error', 'Failed to update profile: ${e.toString()}');
    }
  }

  Future<List<Map<String, dynamic>>> _fetchUserVideos() async {
    try {
      final querySnapshot = await _firestore
          .collection('videos')
          .where('userId', isEqualTo: widget.userId)
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return {
          'id': doc.id,
          'thumbnailUrl': data['thumbnailUrl'],
          'views': data['views'] ?? 0,
          // Add other video properties as needed
        };
      }).toList();
    } catch (e) {
      Get.snackbar('Error', 'Failed to load videos: ${e.toString()}');
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) async {
              if (value == 'edit') {
                await _editProfile();
              } else if (value == 'settings') {
                Get.to(() => const SettingsScreen());
              } else if (value == 'promote') {
                Get.snackbar('Promote', 'Promotion options will appear here');
              }
            },
            itemBuilder: (BuildContext context) => [
              const PopupMenuItem<String>(
                value: 'promote',
                child: Text('Promote'),
              ),
              const PopupMenuItem<String>(
                value: 'settings',
                child: Text('Settings and privacy'),
              ),
              const PopupMenuItem<String>(
                value: 'edit',
                child: Text('Edit profile'),
              ),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            Center(
              child: GestureDetector(
                onTap: () {
                  if (_profileImage != null || _profileImageUrl != null) {
                    Get.dialog(
                      Dialog(
                        backgroundColor: Colors.transparent,
                        child: GestureDetector(
                          onTap: () => Get.back(),
                          child: CircleAvatar(
                            radius: 100,
                            backgroundImage: _profileImage != null
                                ? FileImage(_profileImage!)
                                : _profileImageUrl != null
                                ? NetworkImage(_profileImageUrl!)
                                : const NetworkImage(
                                'https://via.placeholder.com/100')
                            as ImageProvider,
                          ),
                        ),
                      ),
                    );
                  }
                },
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundImage: _profileImage != null
                          ? FileImage(_profileImage!)
                          : _profileImageUrl != null
                          ? NetworkImage(_profileImageUrl!)
                          : const NetworkImage(
                          'https://via.placeholder.com/100')
                      as ImageProvider,
                      backgroundColor: Colors.grey,
                    ),
                    if (isPrivate)
                      const Positioned(
                        bottom: 0,
                        right: 0,
                        child: Icon(Icons.lock, size: 20, color: Colors.white),
                      ),
                    if (_profileImage == null && _profileImageUrl == null)
                      const Icon(Icons.person, size: 28, color: Colors.white),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Center(
              child: Text(
                username,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            if (bio != null && bio!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Text(
                  bio!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.location_on, size: 16),
                  const SizedBox(width: 5),
                  Text(country),
                ],
              ),
            ),
            const Divider(height: 30, thickness: 1),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatColumn(followersCount, 'Followers'),
                  _buildStatColumn(followingCount, 'Following'),
                  _buildStatColumn(likesCount, 'Likes'),
                ],
              ),
            ),
            const Divider(height: 30, thickness: 1),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Account Privacy',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Icon(isPrivate ? Icons.lock : Icons.public,
                          color: Colors.grey),
                      const SizedBox(width: 10),
                      Text(isPrivate ? 'Private Account' : 'Public Account'),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Visibility Settings',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  SwitchListTile(
                    title: const Text('Show Likes on Profile'),
                    value: showLikes,
                    onChanged: null,
                  ),
                  SwitchListTile(
                    title: const Text('Show Locked Videos'),
                    value: showLockedVideos,
                    onChanged: null,
                  ),
                ],
              ),
            ),
            const Divider(height: 30, thickness: 1),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: _fetchUserVideos(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 20),
                          child:
                          Text('No videos yet', style: TextStyle(fontSize: 16)),
                        ));
                  }

                  final videos = snapshot.data!;

                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 2,
                      mainAxisSpacing: 2,
                      childAspectRatio: 9 / 16,
                    ),
                    itemCount: videos.length,
                    itemBuilder: (context, index) {
                      final video = videos[index];
                      return GestureDetector(
                        onTap: () {
                          // Navigate to video player screen
                        },
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            Image.network(
                              video['thumbnailUrl'],
                              fit: BoxFit.cover,
                            ),
                            Positioned(
                              bottom: 8,
                              left: 8,
                              child: Row(
                                children: [
                                  const Icon(Icons.play_arrow,
                                      color: Colors.white, size: 16),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${video['views'] ?? 0}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatColumn(int count, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          count.toString(),
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 14, color: Colors.grey),
        ),
      ],
    );
  }
}