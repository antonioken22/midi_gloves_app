import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/bluetooth_provider.dart';
import '../widgets/sensor_indicator.dart';
import '../widgets/value_tile.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final btProvider = context.watch<BluetoothProvider>();

    if (btProvider.connectedDevice == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Dashboard')),
        body: const Center(
          child: Text(
            'Not connected to a device.\nPlease go to the Connection tab.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    final deviceName = btProvider.connectedDevice!.platformName.isNotEmpty
        ? btProvider.connectedDevice!.platformName
        : 'MIDI Glove';
    final gloveData = btProvider.gloveData;

    return Scaffold(
      appBar: AppBar(
        title: Text(deviceName),
        actions: [
          IconButton(
            icon: const Icon(Icons.bluetooth_disabled),
            tooltip: 'Disconnect',
            onPressed: () => context.read<BluetoothProvider>().disconnect(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Flex Sensors",
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            SensorIndicator(label: "Thumb", value: gloveData.flex1),
            SensorIndicator(label: "Index", value: gloveData.flex2),
            SensorIndicator(label: "Middle", value: gloveData.flex3),
            SensorIndicator(label: "Ring", value: gloveData.flex4),
            SensorIndicator(label: "Pinky", value: gloveData.flex5),
            const Divider(height: 40),
            Text(
              "Accelerometer",
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            ValueTile(label: "X-Axis", value: gloveData.accelX.toString()),
            ValueTile(label: "Y-Axis", value: gloveData.accelY.toString()),
            ValueTile(label: "Z-Axis", value: gloveData.accelZ.toString()),
          ],
        ),
      ),
    );
  }
}
