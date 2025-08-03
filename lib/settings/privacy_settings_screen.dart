import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:worldchat/settings/widgets/settings_widgets.dart';

class PrivacySettingsScreen extends StatelessWidget {
  const PrivacySettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Privacy Settings')),
      body: ListView(
        children: [
          buildSectionHeader('Last Seen & Online'),
          buildListTile(
            title: 'Who can see my last seen',
            value: 'Everyone',
            onTap: () => _showPrivacyOption('last_seen'),
          ),
          buildSectionHeader('Profile Photo'),
          buildListTile(
            title: 'Who can see my profile photo',
            value: 'Everyone',
            onTap: () => _showPrivacyOption('profile_photo'),
          ),
          buildSectionHeader('Groups'),
          buildListTile(
            title: 'Who can add me to groups',
            value: 'Everyone',
            onTap: () => _showPrivacyOption('groups'),
          ),
          buildSectionHeader('Blocked Contacts'),
          buildListTile(
            title: 'Blocked users',
            value: '5 blocked',
            onTap: _showBlockedUsers,
          ),
        ],
      ),
    );
  }

  void _showPrivacyOption(String option) {
    Get.bottomSheet(
      Container(
        color: Colors.white,
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Who can see my ${option.replaceAll('_', ' ')}',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _buildOptionTile('Everyone', true),
            _buildOptionTile('My Contacts', false),
            _buildOptionTile('Nobody', false),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => Get.back(),
              child: const Text('Cancel'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionTile(String title, bool selected) {
    return ListTile(
      title: Text(title),
      trailing: selected ? const Icon(Icons.check, color: Colors.blue) : null,
      onTap: () {
        Get.back();
        Get.snackbar('Setting changed', '$title selected');
      },
    );
  }

  void _showBlockedUsers() {
    Get.to(() => Scaffold(
      appBar: AppBar(title: const Text('Blocked Users')),
      body: ListView(
        children: const [
          ListTile(
            title: Text('user1@example.com'),
            trailing: Icon(Icons.block, color: Colors.red),
          ),
          ListTile(
            title: Text('user2@example.com'),
            trailing: Icon(Icons.block, color: Colors.red),
          ),
          ListTile(
            title: Text('user3@example.com'),
            trailing: Icon(Icons.block, color: Colors.red),
          ),
        ],
      ),
    ));
  }
}