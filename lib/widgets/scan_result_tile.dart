import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class ScanResultTile extends StatelessWidget {
  final ScanResult result;
  final VoidCallback onTap;

  const ScanResultTile({super.key, required this.result, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final name = result.device.platformName.isNotEmpty
        ? result.device.platformName
        : 'Unknown Device';
    final macAddress = result.device.remoteId.str;
    return ListTile(
      title: Text(name),
      subtitle: Text('MAC: $macAddress  •  RSSI: ${result.rssi}'),
      trailing: ElevatedButton(onPressed: onTap, child: const Text('Connect')),
      onTap: onTap,
    );
  }
}
