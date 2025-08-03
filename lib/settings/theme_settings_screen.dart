import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:worldchat/settings/widgets/settings_widgets.dart';

class ThemeSettingsScreen extends StatelessWidget {
  final String currentTheme;
  final String currentAccentColor;
  final Function(String, String) onThemeChanged;

  const ThemeSettingsScreen({
    super.key,
    required this.currentTheme,
    required this.currentAccentColor,
    required this.onThemeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Theme Settings')),
      body: ListView(
        children: [
          _buildThemeOption('System default', currentTheme),
          _buildThemeOption('Light', currentTheme),
          _buildThemeOption('Dark', currentTheme),
          buildSectionHeader('Accent Color'),
          _buildColorOption('Blue', currentAccentColor),
          _buildColorOption('Green', currentAccentColor),
          _buildColorOption('Purple', currentAccentColor),
          _buildColorOption('Orange', currentAccentColor),
        ],
      ),
    );
  }

  Widget _buildThemeOption(String theme, String currentTheme) {
    return ListTile(
      title: Text(theme),
      trailing: theme == currentTheme
          ? const Icon(Icons.check, color: Colors.blue)
          : null,
      onTap: () {
        onThemeChanged(theme, currentAccentColor);
        Get.back();
      },
    );
  }

  Widget _buildColorOption(String color, String currentColor) {
    return ListTile(
      title: Text(color),
      trailing: color == currentColor
          ? const Icon(Icons.check, color: Colors.blue)
          : null,
      onTap: () {
        onThemeChanged(currentTheme, color);
        Get.back();
      },
    );
  }
}