import 'package:flutter/material.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          // MIDI configurations.
          _SettingsGroup(
            title: 'MIDI Configuration',
            children: [
              ListTile(
                leading: const Icon(Icons.music_note),
                title: const Text('Gesture to MIDI Mapping'),
                subtitle: const Text('Assign gestures to specific notes'),
                onTap: () {
                  // TODO: Navigate to a detailed mapping screen.
                },
              ),
              ListTile(
                leading: const Icon(Icons.graphic_eq),
                title: const Text('Control Change Mapping'),
                subtitle: const Text('Map accelerometer data to effects'),
                onTap: () {
                  // TODO: Navigate to CC mapping screen.
                },
              ),
            ],
          ),
          // Sensor-related settings.
          _SettingsGroup(
            title: 'Sensor Settings',
            children: [
              ListTile(
                leading: const Icon(Icons.tune),
                title: const Text('Sensor Thresholds'),
                subtitle: const Text('Calibrate gesture activation points'),
                onTap: () {
                  // TODO: Navigate to a calibration screen.
                },
              ),
              SwitchListTile(
                secondary: const Icon(Icons.vibration),
                title: const Text('Haptic Feedback'),
                subtitle: const Text('Vibrate on gesture recognition'),
                value: false,
                onChanged: (bool value) {
                  // TODO: Save this setting.
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
                  // TODO: Show an about dialog.
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
