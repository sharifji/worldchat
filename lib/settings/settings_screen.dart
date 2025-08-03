import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:worldchat/authentication/login_screen.dart';
import 'package:worldchat/settings/security_settings_screen.dar.dart';
//import/settings_screen.dart' show SecuritySettingsScreen;

import 'package:worldchat/settings/settings_screen.dart'

;import 'package:worldchat/settings/settings_screen.dart';





import 'package:worldchat/settings/widgets/settings_widgets.dart';


import 'package:worldchat/settings/privacy_settings_screen.dart' hide PrivacySettingsScreen;
import 'privacy_settings_screen.dart';
import 'package:worldchat/settings/widgets/settings_widgets.dart';
//import 'package:worldchat/home/profile/authentication/settings/screens/security_settings_screen.dart';
import 'package:worldchat/settings//theme_settings_screen.dart';
import 'package:worldchat/settings/widgets/settings_widgets.dart';
import 'package:worldchat/settings/widgets/settings_widgets.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late SharedPreferences _prefs;
  bool enterIsSend = false;
  bool readReceipts = true;
  bool vibrate = true;
  bool twoStepVerification = false;
  bool showSecurityNotifications = true;
  String theme = 'System default';
  String accentColor = 'Blue';

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    _prefs = await SharedPreferences.getInstance();
    setState(() {
      enterIsSend = _prefs.getBool('enterIsSend') ?? false;
      readReceipts = _prefs.getBool('readReceipts') ?? true;
      vibrate = _prefs.getBool('vibrate') ?? true;
      twoStepVerification = _prefs.getBool('twoStepVerification') ?? false;
      showSecurityNotifications = _prefs.getBool('showSecurityNotifications') ?? true;
      theme = _prefs.getString('theme') ?? 'System default';
      accentColor = _prefs.getString('accentColor') ?? 'Blue';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings and Privacy'),
      ),
      body: ListView(
        children: [
          buildProfileHeader(context),
          buildSectionHeader('Account'),
          buildListTile(
            title: 'Profile',
            icon: Icons.person_outline,
            onTap: _navigateToProfile,
          ),
          buildListTile(
            title: 'Privacy',
            icon: Icons.lock_outline,
            onTap: () => Get.to(() => const PrivacySettingsScreen()),
          ),
          buildListTile(
            title: 'Security',
            icon: Icons.security_outlined,
            onTap: () => Get.to(() => SecuritySettingsScreen(
              twoStepVerification: twoStepVerification,
              showSecurityNotifications: showSecurityNotifications,
              onSettingsChanged: _updateSecuritySettings,
            )),
          ),
          buildListTile(
            title: 'Linked Devices',
            icon: Icons.devices_outlined,
            onTap: _showLinkedDevices,
          ),

          buildSectionHeader('Chats'),
          buildSwitchTile(
            title: 'Enter is send',
            icon: Icons.keyboard_outlined,
            value: enterIsSend,
            onChanged: (value) {
              setState(() {
                enterIsSend = value;
                _prefs.setBool('enterIsSend', value);
              });
            },
          ),
          buildSwitchTile(
            title: 'Read receipts',
            icon: Icons.done_all_outlined,
            value: readReceipts,
            onChanged: (value) {
              setState(() {
                readReceipts = value;
                _prefs.setBool('readReceipts', value);
              });
            },
          ),
          buildListTile(
            title: 'Chat backup',
            icon: Icons.cloud_upload_outlined,
            onTap: _showBackupOptions,
          ),
          buildListTile(
            title: 'Chat history',
            icon: Icons.history_outlined,
            onTap: _showChatHistoryOptions,
          ),
          buildListTile(
            title: 'Wallpaper',
            icon: Icons.wallpaper_outlined,
            onTap: _showWallpaperOptions,
          ),

          buildSectionHeader('Notifications'),
          buildListTile(
            title: 'Message notifications',
            icon: Icons.notifications_outlined,
            onTap: _showNotificationSettings,
          ),
          buildListTile(
            title: 'Sounds',
            icon: Icons.volume_up_outlined,
            onTap: _showSoundOptions,
          ),
          buildSwitchTile(
            title: 'Vibrate',
            icon: Icons.vibration_outlined,
            value: vibrate,
            onChanged: (value) {
              setState(() {
                vibrate = value;
                _prefs.setBool('vibrate', value);
              });
            },
          ),

          buildSectionHeader('Storage and Data'),
          buildListTile(
            title: 'Storage usage',
            icon: Icons.storage_outlined,
            onTap: _showStorageUsage,
          ),
          buildListTile(
            title: 'Network usage',
            icon: Icons.network_check_outlined,
            onTap: _showNetworkUsage,
          ),
          buildListTile(
            title: 'Media auto-download',
            icon: Icons.download_outlined,
            onTap: _showAutoDownloadOptions,
          ),

          buildSectionHeader('Appearance'),
          buildListTile(
            title: 'Theme',
            icon: Icons.palette_outlined,
            onTap: () => Get.to(() => ThemeSettingsScreen(
              currentTheme: theme,
              currentAccentColor: accentColor,
              onThemeChanged: (newTheme, newAccentColor) {
                setState(() {
                  theme = newTheme;
                  accentColor = newAccentColor;
                  _prefs.setString('theme', newTheme);
                  _prefs.setString('accentColor', newAccentColor);
                });
              },
            )),
          ),
          buildListTile(
            title: 'Language',
            icon: Icons.language_outlined,
            onTap: _showLanguageOptions,
          ),

          buildSectionHeader('Support & About'),
          buildListTile(
            title: 'Help Center',
            icon: Icons.help_outline,
            onTap: _openHelpCenter,
          ),
          buildListTile(
            title: 'Contact Us',
            icon: Icons.email_outlined,
            onTap: _contactSupport,
          ),
          buildListTile(
            title: 'Terms of Service',
            icon: Icons.description_outlined,
            onTap: _showTermsOfService,
          ),
          buildListTile(
            title: 'App Info',
            icon: Icons.info_outline,
            onTap: () => _showAppInfo(context),
          ),

          buildSectionHeader('Actions'),
          buildListTile(
            title: 'Logout',
            icon: Icons.logout,
            onTap: () async => await _showLogoutConfirmation(context),
            textColor: Colors.red,
            iconColor: Colors.red,
          ),
          buildListTile(
            title: 'Delete Account',
            icon: Icons.delete_outline,
            onTap: () => _showDeleteAccountConfirmation(context),
            textColor: Colors.red,
            iconColor: Colors.red,
          ),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: () => _showDetailedVersionInfo(context),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'App Version 1.0.0 (Build 123)',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Profile methods
  void _navigateToProfile() {
    Get.to(() => Scaffold(
      appBar: AppBar(title: const Text('Edit Profile')),
      body: const Center(child: Text('Profile editing screen')),
    ));
  }

  // Privacy methods
  void _showLinkedDevices() {
    Get.to(() => Scaffold(
      appBar: AppBar(title: const Text('Linked Devices')),
      body: ListView(
        children: const [
          ListTile(
            title: Text('This device'),
            subtitle: Text('Active now'),
            trailing: Icon(Icons.check, color: Colors.green),
          ),
          ListTile(
            title: Text('iPhone 13'),
            subtitle: Text('Last active 2 hours ago'),
          ),
        ],
      ),
    ));
  }

  // Chat methods
  void _showBackupOptions() {
    Get.to(() => Scaffold(
      appBar: AppBar(title: const Text('Chat Backup')),
      body: ListView(
        children: [
          buildSectionHeader('Google Drive Backup'),
          buildListTile(
            title: 'Backup to Google Drive',
            value: 'Last backup: Today, 10:30 AM',
          ),
          buildListTile(
            title: 'Backup frequency',
            value: 'Daily',
          ),
          buildListTile(
            title: 'Backup over',
            value: 'Wi-Fi only',
          ),
          buildListTile(
            title: 'Include videos',
            value: 'On',
          ),
          ElevatedButton(
            onPressed: () {},
            child: const Text('Backup Now'),
          ),
        ],
      ),
    ));
  }

  void _showChatHistoryOptions() {
    Get.to(() => Scaffold(
      appBar: AppBar(title: const Text('Chat History')),
      body: ListView(
        children: [
          buildListTile(
            title: 'Keep messages',
            value: 'Forever',
          ),
          buildListTile(
            title: 'Export chat',
          ),
          buildListTile(
            title: 'Clear all chats',
            textColor: Colors.red,
            iconColor: Colors.red,
          ),
        ],
      ),
    ));
  }

  void _showWallpaperOptions() {
    Get.bottomSheet(
      Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            buildSectionHeader('Wallpaper'),
            buildListTile(
              title: 'Default',
              icon: Icons.wallpaper,
            ),
            buildListTile(
              title: 'Solid Colors',
              icon: Icons.color_lens,
            ),
            buildListTile(
              title: 'Gallery',
              icon: Icons.photo_library,
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // Notification methods
  void _showNotificationSettings() {
    Get.to(() => Scaffold(
      appBar: AppBar(title: const Text('Notification Settings')),
      body: ListView(
        children: [
          buildSwitchTile(
            title: 'Message notifications',
            value: true,
            onChanged: (value) {},
          ),
          buildSwitchTile(
            title: 'Group notifications',
            value: true,
            onChanged: (value) {},
          ),
          buildListTile(
            title: 'Notification tone',
            value: 'Default (Chime)',
          ),
          buildListTile(
            title: 'Vibrate',
            value: 'Default',
          ),
          buildListTile(
            title: 'Popup notification',
            value: 'No popup',
          ),
          buildListTile(
            title: 'Light',
            value: 'White',
          ),
        ],
      ),
    ));
  }

  void _showSoundOptions() {
    Get.to(() => Scaffold(
      appBar: AppBar(title: const Text('Sound Settings')),
      body: ListView(
        children: [
          buildListTile(
            title: 'Notification sound',
            value: 'Chime',
          ),
          buildListTile(
            title: 'Ringtone',
            value: 'Default',
          ),
          buildListTile(
            title: 'Call ringtone',
            value: 'Default',
          ),
        ],
      ),
    ));
  }

  // Storage methods
  void _showStorageUsage() {
    Get.to(() => Scaffold(
      appBar: AppBar(title: const Text('Storage Usage')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: CircularProgressIndicator(
              value: 0.65,
              semanticsLabel: 'Storage usage',
            ),
          ),
          buildListTile(
            title: 'Photos',
            value: '1.2 GB',
          ),
          buildListTile(
            title: 'Videos',
            value: '3.5 GB',
          ),
          buildListTile(
            title: 'Documents',
            value: '256 MB',
          ),
          ElevatedButton(
            onPressed: () {},
            child: const Text('Free Up Space'),
          ),
        ],
      ),
    ));
  }

  void _showNetworkUsage() {
    Get.to(() => Scaffold(
      appBar: AppBar(title: const Text('Network Usage')),
      body: Column(
        children: [
          buildListTile(
            title: 'Data sent',
            value: '245 MB',
          ),
          buildListTile(
            title: 'Data received',
            value: '1.2 GB',
          ),
          buildListTile(
            title: 'Media auto-download',
            value: 'Wi-Fi only',
          ),
        ],
      ),
    ));
  }

  void _showAutoDownloadOptions() {
    Get.to(() => Scaffold(
      appBar: AppBar(title: const Text('Media Auto-Download')),
      body: ListView(
        children: [
          buildSectionHeader('When using mobile data'),
          buildListTile(
            title: 'Photos',
            value: 'On',
          ),
          buildListTile(
            title: 'Audio',
            value: 'On',
          ),
          buildListTile(
            title: 'Videos',
            value: 'Off',
          ),
          buildListTile(
            title: 'Documents',
            value: 'On',
          ),
          buildSectionHeader('When connected on Wi-Fi'),
          buildListTile(
            title: 'Photos',
            value: 'On',
          ),
          buildListTile(
            title: 'Audio',
            value: 'On',
          ),
          buildListTile(
            title: 'Videos',
            value: 'On',
          ),
          buildListTile(
            title: 'Documents',
            value: 'On',
          ),
        ],
      ),
    ));
  }

  // Appearance methods
  void _showLanguageOptions() {
    Get.to(() => Scaffold(
      appBar: AppBar(title: const Text('Language')),
      body: ListView(
        children: [
          buildListTile(
            title: 'English',
            isSelected: true,
          ),
          buildListTile(
            title: 'Spanish',
          ),
          buildListTile(
            title: 'French',
          ),
          buildListTile(
            title: 'German',
          ),
        ],
      ),
    ));
  }

  // Support methods
  void _openHelpCenter() {
    Get.to(() => Scaffold(
      appBar: AppBar(title: const Text('Help Center')),
      body: ListView(
        children: const [
          ListTile(
            title: Text('Getting Started'),
            subtitle: Text('Learn how to use the app'),
          ),
          ListTile(
            title: Text('Account Settings'),
            subtitle: Text('Manage your account'),
          ),
          ListTile(
            title: Text('Privacy & Security'),
            subtitle: Text('Keep your account safe'),
          ),
          ListTile(
            title: Text('Troubleshooting'),
            subtitle: Text('Fix common issues'),
          ),
        ],
      ),
    ));
  }

  void _contactSupport() {
    Get.to(() => Scaffold(
      appBar: AppBar(title: const Text('Contact Support')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const TextField(
              decoration: InputDecoration(labelText: 'Subject'),
            ),
            const TextField(
              decoration: InputDecoration(labelText: 'Message'),
              maxLines: 5,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Get.back();
                Get.snackbar('Success', 'Your message has been sent');
              },
              child: const Text('Send Message'),
            ),
          ],
        ),
      ),
    ));
  }

  void _showTermsOfService() {
    Get.to(() => Scaffold(
      appBar: AppBar(title: const Text('Terms of Service')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text('Terms of Service', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            SizedBox(height: 16),
            Text('''Lorem ipsum dolor sit amet, consectetur adipiscing elit. Nullam auctor, nisl eget ultricies tincidunt, nisl nisl aliquam nisl, eget ultricies nisl nisl eget nisl. Nullam auctor, nisl eget ultricies tincidunt, nisl nisl aliquam nisl, eget ultricies nisl nisl eget nisl.

Nullam auctor, nisl eget ultricies tincidunt, nisl nisl aliquam nisl, eget ultricies nisl nisl eget nisl. Nullam auctor, nisl eget ultricies tincidunt, nisl nisl aliquam nisl, eget ultricies nisl nisl eget nisl.

Nullam auctor, nisl eget ultricies tincidunt, nisl nisl aliquam nisl, eget ultricies nisl nisl eget nisl. Nullam auctor, nisl eget ultricies tincidunt, nisl nisl aliquam nisl, eget ultricies nisl nisl eget nisl.'''),
          ],
        ),
      ),
    ));
  }

  // Account actions
  Future<void> _showLogoutConfirmation(BuildContext context) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Logout'),
          content: const Text('Are you sure you want to logout?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text('Logout', style: TextStyle(color: Colors.red)),
              onPressed: () async {
                Navigator.of(context).pop();
                await _performLogout();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _showDeleteAccountConfirmation(BuildContext context) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Account'),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('This will permanently:'),
              Text('• Delete your account'),
              Text('• Remove all your messages'),
              Text('• Delete all your contacts'),
              SizedBox(height: 16),
              Text('This action cannot be undone.'),
            ],
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
              onPressed: () {
                Navigator.of(context).pop();
                _performAccountDeletion();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _showAppInfo(BuildContext context) async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('App Information'),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Version: 1.0.0'),
              Text('Build: 123'),
              Text('Release Date: 2023-11-15'),
              SizedBox(height: 16),
              Text('© 2023 ChatApp Inc.'),
            ],
          ),
          actions: [
            TextButton(
              child: const Text('OK'),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showDetailedVersionInfo(BuildContext context) async {
    showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Detailed Version Info'),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Version: 1.0.0 (123)'),
              Text('Flutter: 3.13.0'),
              Text('Dart: 3.1.0'),
              SizedBox(height: 16),
              Text('Build fingerprint: release-1.0.0-123'),
              Text('Build date: 2023-11-15'),
            ],
          ),
          actions: [
            TextButton(
              child: const Text('OK'),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        );
      },
    );
  }

  Future<void> _performLogout() async {
    try {
      await FirebaseAuth.instance.signOut();
      Get.offAll(() => const LoginScreen());
    } catch (e) {
      Get.snackbar('Error', 'Failed to logout: ${e.toString()}');
    }
  }

  Future<void> _performAccountDeletion() async {
    try {
      Get.dialog(
        const Center(child: CircularProgressIndicator()),
        barrierDismissible: false,
      );

      await FirebaseAuth.instance.currentUser?.delete();

      Get.offAll(() => const LoginScreen());
      Get.snackbar('Success', 'Your account has been deleted');
    } catch (e) {
      Get.back();
      Get.snackbar('Error', 'Failed to delete account: ${e.toString()}');
    }
  }

  void _updateSecuritySettings(bool twoStep, bool showNotifications) {
    setState(() {
      twoStepVerification = twoStep;
      showSecurityNotifications = showNotifications;
      _prefs.setBool('twoStepVerification', twoStep);
      _prefs.setBool('showSecurityNotifications', showNotifications);
    });
  }
}