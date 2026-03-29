import 'package:flutter/material.dart';
import '../models/app_settings_model.dart';
import '../services/local_storage_service.dart';
import '../utils/ui_feedback.dart';
import '../widgets/app_widgets.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  AppSettings settings = const AppSettings();
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadSettings();
  }

  Future<void> loadSettings() async {
    final savedSettings = await LocalStorageService.getSettings();
    if (!mounted) return;
    setState(() {
      settings = savedSettings;
      isLoading = false;
    });
  }

  Future<void> saveSettings() async {
    await LocalStorageService.saveSettings(settings);
    if (!mounted) return;
    showAppSnackBar(context, 'Settings saved for this device.');
  }

  Future<void> resetSettings() async {
    const defaults = AppSettings();
    await LocalStorageService.saveSettings(defaults);
    if (!mounted) return;
    setState(() {
      settings = defaults;
    });
    showAppSnackBar(context, 'Settings reset to defaults.');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AppSectionTitle(
              title: 'Settings',
              subtitle: 'Preferences that control app behavior on this device.',
            ),
            const SizedBox(height: 16),
            AppInfoCard(
              child: Column(
                children: [
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Notification Alerts'),
                    subtitle: const Text('Keeps in-app notification reminders enabled.'),
                    value: settings.notificationAlerts,
                    onChanged: (value) => setState(() => settings = settings.copyWith(notificationAlerts: value)),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('GPS Assistance'),
                    subtitle: const Text('Allows the report flow to keep location help enabled.'),
                    value: settings.gpsAssist,
                    onChanged: (value) => setState(() => settings = settings.copyWith(gpsAssist: value)),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Strong Blue Theme Accent'),
                    subtitle: const Text('Updates the app accent color immediately and persists it.'),
                    value: settings.strongBlueAccent,
                    onChanged: (value) => setState(() => settings = settings.copyWith(strongBlueAccent: value)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            AppPrimaryButton(
              label: 'Save Settings',
              icon: Icons.save,
              onPressed: saveSettings,
            ),
            const SizedBox(height: 10),
            AppSecondaryButton(
              label: 'Reset to Defaults',
              icon: Icons.refresh,
              onPressed: resetSettings,
            ),
          ],
        ),
      ),
    );
  }
}
