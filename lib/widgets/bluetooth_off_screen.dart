import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class BluetoothOffScreen extends StatelessWidget {
  const BluetoothOffScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const Icon(Icons.bluetooth_disabled, size: 80.0, color: Colors.grey),
          const SizedBox(height: 20),
          Text(
            'Bluetooth is required to connect to your MIDI gloves.',
            style: Theme.of(context).textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          ElevatedButton(
            child: const Text('Turn On Bluetooth'),
            onPressed: () => FlutterBluePlus.turnOn(),
          ),
        ],
      ),
    );
  }
}
