import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:worldchat/home/inbox/Chats/Chats_screen.dart'; // Import the ChatScreen

class UserProfileScreen extends StatefulWidget {
  final String userId;
  final Map<String, dynamic> userData;

  const UserProfileScreen({
    Key? key,
    required this.userId,
    required this.userData,
  }) : super(key: key);

  @override
  _UserProfileScreenState createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  late Map<String, dynamic> user;
  bool _isFollowing = false;

  @override
  void initState() {
    super.initState();
    // Initialize with the passed userData, falling back to mock data if fields are missing
    user = {
      'name': widget.userData['name'] ?? widget.userData['displayName'] ?? 'Unknown User',
      'username': '@${widget.userData['username'] ?? widget.userData['email']?.split('@')[0] ?? 'user'}',
      'profilePic': widget.userData['photoUrl'] ??
          widget.userData['profileImage'] ??
          widget.userData['image'] ??
          widget.userData['profilePicture'] ??
          'https://randomuser.me/api/portraits/men/1.jpg',
      'coverPhoto': widget.userData['coverPhoto'] ?? 'https://picsum.photos/800/300',
      'bio': widget.userData['bio'] ?? 'No bio yet',
      'age': widget.userData['age'] ?? 0,
      'gender': widget.userData['gender'] ?? 'Not specified',
      'country': widget.userData['country'] ?? 'Unknown',
      'city': widget.userData['city'] ?? 'Unknown',
      'friendsCount': widget.userData['friendsCount'] ?? 0,
      'followersCount': widget.userData['followersCount'] ?? 0,
      'isFriend': widget.userData['isFriend'] ?? false,
      'friendRequestSent': widget.userData['friendRequestSent'] ?? false,
    };

    _isFollowing = user['isFriend'] || user['friendRequestSent'];
  }

  void _startChat() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatScreen(
          recipientId: widget.userId,
          recipientName: user['name'],
          recipientPhotoUrl: user['profilePic'],
          chatId: 'chat_${widget.userId}', // You might want to generate a proper chat ID
          isRecipientOnline: false, // You can fetch this from your backend
          recipientLastSeen: DateTime.now(), // You can fetch this from your backend
          isRecipientOnlin: false, // This seems to be a typo in the original code
        ),
      ),
    );
  }

  void _toggleFollow() {
    setState(() {
      if (user['isFriend']) {
        // Unfriend
        user['isFriend'] = false;
        user['friendsCount'] = (user['friendsCount'] as int) - 1;
        _isFollowing = false;
      } else if (user['friendRequestSent']) {
        // Cancel friend request
        user['friendRequestSent'] = false;
        _isFollowing = false;
      } else {
        // Send friend request
        user['friendRequestSent'] = true;
        _isFollowing = true;
        // In a real app, you would send this to your backend
      }
    });

    // Show a snackbar based on the action
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          user['isFriend']
              ? 'You are now friends with ${user['name']}'
              : user['friendRequestSent']
              ? 'Friend request sent to ${user['name']}'
              : 'Removed from friends',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200.0,
            floating: false,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: CachedNetworkImage(
                imageUrl: user['coverPhoto'],
                fit: BoxFit.cover,
              ),
            ),
          ),
          SliverList(
            delegate: SliverChildListDelegate([
              _buildProfileHeader(),
              _buildUserDetails(),
              _buildFriendsSection(),
              _buildBioSection(),
              _buildActionButtons(),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              CircleAvatar(
                radius: 50,
                backgroundColor: Colors.grey[200],
                backgroundImage: CachedNetworkImageProvider(user['profilePic']),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user['name'],
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    user['username'],
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUserDetails() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.location_on, size: 18, color: Colors.grey),
              const SizedBox(width: 4),
              Text(
                '${user['city']}, ${user['country']}',
                style: TextStyle(color: Colors.grey[700]),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.person, size: 18, color: Colors.grey),
              const SizedBox(width: 4),
              Text(
                '${user['gender']}, ${user['age']} years',
                style: TextStyle(color: Colors.grey[700]),
              ),
            ],
          ),
          const Divider(height: 24),
        ],
      ),
    );
  }

  Widget _buildFriendsSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem('Friends', user['friendsCount']),
          _buildStatItem('Followers', user['followersCount']),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, int count) {
    return Column(
      children: [
        Text(
          count.toString(),
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildBioSection() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Text(
        user['bio'],
        style: const TextStyle(fontSize: 16),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isFollowing ? Colors.grey[300] : Colors.blue,
                    foregroundColor: _isFollowing ? Colors.black : Colors.white,
                  ),
                  onPressed: _toggleFollow,
                  child: Text(
                    user['isFriend']
                        ? 'Friends'
                        : user['friendRequestSent']
                        ? 'Request Sent'
                        : 'Follow',
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: _startChat,
                  child: const Text('Message'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (user['isFriend'])
            OutlinedButton(
              onPressed: () {
                // Additional friend actions could go here
              },
              child: const Text('Friend Options'),
            ),
        ],
      ),
    );
  }
}