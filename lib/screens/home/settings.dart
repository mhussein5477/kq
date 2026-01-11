import 'package:flutter/material.dart';
import 'package:flutter_settings_screens/flutter_settings_screens.dart';
import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:kq/screens/auth/login.dart';
import 'package:kq/services/secure_storage_service.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Appearance
            // SettingsGroup(
            //   title: 'Appearance',
            //   children: [
            //     SwitchSettingsTile(
            //       title: 'Dark Mode',
            //       settingKey: 'dark_mode', // used to persist state
            //       leading: const Icon(Icons.dark_mode),
            //       onChange: (value) {
            //         if (value) {
            //           AdaptiveTheme.of(context).setDark();
            //         } else {
            //           AdaptiveTheme.of(context).setLight();
            //         }
            //       },
            //     ),
            //   ],
            // ),

            // General
            SettingsGroup(
              title: 'General',
              children: [
                SimpleSettingsTile(
                  title: 'Language',
                  leading: const Icon(Icons.language),
                  onTap: () {
                    // TODO: open language selection
                  },
                ),
                SimpleSettingsTile(
                  title: 'Terms & Conditions',
                  leading: const Icon(Icons.description),
                  onTap: () {
                    // TODO: navigate to T&C screen
                  },
                ),
                SimpleSettingsTile(
                  title: 'FAQs',
                  leading: const Icon(Icons.help),
                  onTap: () {
                    // TODO: navigate to FAQ screen
                  },
                ),
              ],
            ),

            // Logout
            SettingsGroup(
              title: 'Account',
              children: [
                SimpleSettingsTile(
                  title: 'Logout',
                  leading: const Icon(Icons.logout, color: Colors.red),
                  titleTextStyle: const TextStyle(color: Colors.red),
                  onTap: () async {
                    // Clear all secure storage
                    // await SecureStorageService.clearAll();

                    // Navigate to login screen and remove all previous routes
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                      (route) => false,
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
