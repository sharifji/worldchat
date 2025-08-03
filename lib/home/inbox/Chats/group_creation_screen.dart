// group_creation_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'group_chat_screen.dart';

class GroupCreationScreen extends StatefulWidget {
  const GroupCreationScreen({super.key});

  @override
  State<GroupCreationScreen> createState() => _GroupCreationScreenState();
}

class _GroupCreationScreenState extends State<GroupCreationScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _groupNameController = TextEditingController();
  final List<String> _selectedUsers = [];
  bool _isCreating = false;
  String _groupDescription = '';
  String _groupImageUrl = '';

  @override
  void dispose() {
    _groupNameController.dispose();
    super.dispose();
  }

  Future<void> _pickGroupImage() async {
    try {
      final XFile? image = await ImagePicker().pickImage(source: ImageSource.gallery);
      if (image == null) return;

      // Here you would typically upload the image to Firebase Storage
      // and get the download URL. For now, we'll just use a placeholder.
      // Implement your actual image upload logic here.
      setState(() {
        _groupImageUrl = 'https://via.placeholder.com/150'; // Placeholder URL
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to pick image: $e')),
      );
    }
  }

  Future<void> _createGroup() async {
    final currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You must be signed in to create a group')),
      );
      return;
    }

    final groupName = _groupNameController.text.trim();
    if (groupName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a group name')),
      );
      return;
    }

    if (_selectedUsers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one participant')),
      );
      return;
    }

    setState(() {
      _isCreating = true;
    });

    try {
      // Add current user to selected users if not already included
      final members = List<String>.from(_selectedUsers);
      if (!members.contains(currentUserId)) {
        members.add(currentUserId);
      }

      final groupDoc = await _firestore.collection('groups').add({
        'name': groupName,
        'description': _groupDescription,
        'imageUrl': _groupImageUrl,
        'members': members,
        'admins': [currentUserId], // Store as array for multiple admins
        'createdBy': currentUserId,
        'createdAt': FieldValue.serverTimestamp(),
        'lastMessage': null,
        'lastMessageTimestamp': FieldValue.serverTimestamp(),
      });

      // Create initial members subcollection
      final batch = _firestore.batch();
      for (final memberId in members) {
        final memberRef = groupDoc.collection('members').doc(memberId);
        batch.set(memberRef, {
          'joinedAt': FieldValue.serverTimestamp(),
          'isAdmin': memberId == currentUserId,
        });
      }
      await batch.commit();

      // Navigate to the new group chat
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => GroupChatScreen(
            groupId: groupDoc.id,
            groupName: groupName,
            groupImage: _groupImageUrl,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error creating group: ${e.toString()}')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isCreating = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('New Group'),
        actions: [
          IconButton(
            icon: _isCreating
                ? const CircularProgressIndicator()
                : const Icon(Icons.check),
            onPressed: _isCreating ? null : _createGroup,
          ),
        ],
      ),
      body: Column(
        children: [
          GestureDetector(
            onTap: _pickGroupImage,
            child: Container(
              margin: const EdgeInsets.all(16),
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.grey[200],
                image: _groupImageUrl.isNotEmpty
                    ? DecorationImage(
                  image: NetworkImage(_groupImageUrl),
                  fit: BoxFit.cover,
                )
                    : null,
              ),
              child: _groupImageUrl.isEmpty
                  ? const Icon(Icons.camera_alt, size: 40)
                  : null,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _groupNameController,
              decoration: const InputDecoration(
                hintText: 'Group name',
                border: OutlineInputBorder(),
                labelText: 'Group Name',
              ),
              autofocus: true,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              onChanged: (value) => _groupDescription = value,
              decoration: const InputDecoration(
                hintText: 'Group description (optional)',
                border: OutlineInputBorder(),
                labelText: 'Description',
              ),
              maxLines: 2,
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text('Select participants',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore.collection('users').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final currentUserId = _auth.currentUser?.uid;
                if (currentUserId == null) {
                  return const Center(child: Text('Please sign in'));
                }

                final users = snapshot.data!.docs.where((doc) => doc.id != currentUserId).toList();

                if (users.isEmpty) {
                  return const Center(child: Text('No other users available'));
                }

                return ListView.builder(
                  itemCount: users.length,
                  itemBuilder: (context, index) {
                    final userDoc = users[index];
                    final userData = userDoc.data() as Map<String, dynamic>;
                    final userId = userDoc.id;
                    final name = userData['displayName'] ?? userData['email']?.split('@')[0] ?? 'Unknown';
                    final isSelected = _selectedUsers.contains(userId);

                    return CheckboxListTile(
                      value: isSelected,
                      onChanged: (bool? value) {
                        setState(() {
                          if (value == true) {
                            _selectedUsers.add(userId);
                          } else {
                            _selectedUsers.remove(userId);
                          }
                        });
                      },
                      title: Text(name),
                      subtitle: Text(userData['email'] ?? ''),
                      secondary: CircleAvatar(
                        backgroundColor: Colors.blueAccent,
                        child: Text(
                          name.isNotEmpty ? name[0].toUpperCase() : '?',
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}