import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import 'calibration_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          // Sensor-related settings.
          _SettingsGroup(
            title: 'Sensor Settings',
            children: [
              ListTile(
                leading: const Icon(Icons.tune),
                title: const Text('Sensor Thresholds'),
                subtitle: const Text('Calibrate gesture activation points'),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CalibrationScreen(),
                    ),
                  );
                },
              ),
              Consumer<SettingsProvider>(
                builder: (context, settings, child) {
                  return SwitchListTile(
                    secondary: const Icon(Icons.vibration),
                    title: const Text('Haptic Feedback'),
                    subtitle: const Text('Vibrate on gesture recognition'),
                    value: settings.hapticFeedbackEnabled,
                    onChanged: (bool value) {
                      settings.setHapticFeedback(value);
                    },
                  );
                },
              ),
            ],
          ),
          // General app information.
          _SettingsGroup(
            title: 'About',
            children: [
              ListTile(
                leading: const Icon(Icons.info_outline),
                title: const Text('About this App'),
                subtitle: const Text('Version 1.0.0'),
                onTap: () {
                  showAboutDialog(
                    context: context,
                    applicationName: 'MIDI Gloves',
                    applicationVersion: '1.0.0',
                    applicationLegalese:
                        'Developed by Tres Juans\nAll Rights Reserved 2025',
                    children: [
                      const SizedBox(height: 20),
                      const Text(
                        'Research Integration:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'We are exploring the integration of On-Device Machine Learning to create an Adaptive Gesture-to-MIDI Interface. '
                        'By training a model on raw sensor data (Flex + IMU), the glove could learn personalized gesture mappings, '
                        'enabling more expressive and nuanced instrument control beyond simple threshold-based triggering. '
                        'This advancement aims to contribute to our research on accessible and adaptive musical interfaces.',
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SettingsGroup extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _SettingsGroup({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const Divider(),
          ...children,
        ],
      ),
    );
  }
}
