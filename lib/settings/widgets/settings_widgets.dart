import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

Widget buildProfileHeader(BuildContext context) {
  final user = FirebaseAuth.instance.currentUser;
  return Padding(
    padding: const EdgeInsets.all(16.0),
    child: Row(
      children: [
        CircleAvatar(
          radius: 30,
          backgroundImage: user?.photoURL != null
              ? NetworkImage(user!.photoURL!)
              : const AssetImage('assets/default_profile.png') as ImageProvider,
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              user?.displayName ?? 'User Name',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            Text(
              user?.email ?? 'user@example.com',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ],
    ),
  );
}

Widget buildSectionHeader(String title) {
  return Padding(
    padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
    child: Text(
      title,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.bold,
        color: Colors.grey,
      ),
    ),
  );
}

Widget buildListTile({
  required String title,
  IconData? icon,
  VoidCallback? onTap,
  String? value,
  Color? textColor,
  Color? iconColor,
  bool isSelected = false,
}) {
  return ListTile(
    leading: icon != null ? Icon(icon, color: iconColor) : null,
    title: Text(
      title,
      style: TextStyle(color: textColor),
    ),
    trailing: value != null
        ? Text(value, style: const TextStyle(color: Colors.grey))
        : isSelected
        ? const Icon(Icons.check, color: Colors.blue)
        : const Icon(Icons.chevron_right),
    onTap: onTap,
  );
}

Widget buildSwitchTile({
  required String title,
  IconData? icon,
  required bool value,
  required ValueChanged<bool> onChanged,
}) {
  return ListTile(
    leading: icon != null ? Icon(icon) : null,
    title: Text(title),
    trailing: Switch(
      value: value,
      onChanged: onChanged,
    ),
    onTap: () => onChanged(!value),
  );
}