import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:worldchat/settings/widgets/settings_widgets.dart';

class SecuritySettingsScreen extends StatefulWidget {
  final bool twoStepVerification;
  final bool showSecurityNotifications;
  final Function(bool, bool) onSettingsChanged;

  const SecuritySettingsScreen({
    super.key,
    required this.twoStepVerification,
    required this.showSecurityNotifications,
    required this.onSettingsChanged,
  });

  @override
  State<SecuritySettingsScreen> createState() => _SecuritySettingsScreenState();
}

class _SecuritySettingsScreenState extends State<SecuritySettingsScreen> {
  late bool twoStepVerification;
  late bool showSecurityNotifications;

  @override
  void initState() {
    super.initState();
    twoStepVerification = widget.twoStepVerification;
    showSecurityNotifications = widget.showSecurityNotifications;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Security Settings')),
      body: ListView(
        children: [
          buildSwitchTile(
            title: 'Two-step verification',
            value: twoStepVerification,
            onChanged: (value) {
              setState(() {
                twoStepVerification = value;
                widget.onSettingsChanged(twoStepVerification, showSecurityNotifications);
              });
              if (value) {
                _showTwoStepSetup();
              }
            },
          ),
          buildSwitchTile(
            title: 'Show security notifications',
            value: showSecurityNotifications,
            onChanged: (value) {
              setState(() {
                showSecurityNotifications = value;
                widget.onSettingsChanged(twoStepVerification, showSecurityNotifications);
              });
            },
          ),
          buildListTile(
            title: 'Active sessions',
            value: 'This device',
            onTap: _showActiveSessions,
          ),
          buildListTile(
            title: 'Change password',
            onTap: _changePassword,
          ),
        ],
      ),
    );
  }

  void _showTwoStepSetup() {
    Get.to(() => Scaffold(
      appBar: AppBar(title: const Text('Two-Step Verification')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Set up two-step verification to add an extra layer of security to your account.'),
            const SizedBox(height: 20),
            const Text('Step 1: Enter your email for recovery'),
            const TextField(
              decoration: InputDecoration(labelText: 'Email'),
            ),
            const SizedBox(height: 20),
            const Text('Step 2: Set up authentication method'),
            RadioListTile(
              title: const Text('Text message (SMS)'),
              value: 'sms',
              groupValue: 'sms',
              onChanged: (value) {},
            ),
            RadioListTile(
              title: const Text('Authenticator app'),
              value: 'app',
              groupValue: 'sms',
              onChanged: (value) {},
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Get.back();
                Get.snackbar('Success', 'Two-step verification enabled');
              },
              child: const Text('Complete Setup'),
            ),
          ],
        ),
      ),
    ));
  }

  void _showActiveSessions() {
    Get.to(() => Scaffold(
      appBar: AppBar(title: const Text('Active Sessions')),
      body: ListView(
        children: const [
          ListTile(
            title: Text('This device (iPhone)'),
            subtitle: Text('Currently active • iOS 16.4.1'),
            trailing: Icon(Icons.check, color: Colors.green),
          ),
          ListTile(
            title: Text('MacBook Pro'),
            subtitle: Text('Last active 2 days ago • macOS 13.2.1'),
            trailing: Icon(Icons.more_vert),
          ),
          ListTile(
            title: Text('iPad'),
            subtitle: Text('Last active 1 week ago • iPadOS 16.3'),
            trailing: Icon(Icons.more_vert),
          ),
        ],
      ),
    ));
  }

  Future<void> _changePassword() async {
    final controller = TextEditingController();
    Get.dialog(
      AlertDialog(
        title: const Text('Change Password'),
        content: TextField(
          controller: controller,
          obscureText: true,
          decoration: const InputDecoration(labelText: 'New Password'),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              try {
                await FirebaseAuth.instance.currentUser?.updatePassword(controller.text);
                Get.back();
                Get.snackbar('Success', 'Password changed successfully');
              } catch (e) {
                Get.back();
                Get.snackbar('Error', 'Failed to change password: ${e.toString()}');
              }
            },
            child: const Text('Change'),
          ),
        ],
      ),
    );
  }
}