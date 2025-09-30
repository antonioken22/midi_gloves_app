import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:provider/provider.dart';
import '../providers/bluetooth_provider.dart';
import '../widgets/bluetooth_off_screen.dart';
import '../widgets/scan_result_tile.dart';

class ConnectionScreen extends StatelessWidget {
  const ConnectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final btProvider = context.watch<BluetoothProvider>();
    final btProviderReader = context.read<BluetoothProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Connect to MIDI Gloves')),
      body: _buildMainView(context, btProvider, btProviderReader),
    );
  }

  Widget _buildMainView(
    BuildContext context,
    BluetoothProvider provider,
    BluetoothProvider reader,
  ) {
    if (provider.adapterState == BluetoothAdapterState.on) {
      return _buildScannerView(context, provider, reader);
    } else {
      return const BluetoothOffScreen();
    }
  }

  Widget _buildScannerView(
    BuildContext context,
    BluetoothProvider provider,
    BluetoothProvider reader,
  ) {
    if (provider.connectedDevice != null) {
      return _buildConnectedView(context, provider, reader);
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12.0),
          child: ElevatedButton.icon(
            icon: Icon(provider.isScanning ? Icons.stop : Icons.search),
            label: Text(provider.isScanning ? 'Stop Scan' : 'Start Scan'),
            onPressed: reader.toggleScan,
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: provider.scanResults.isEmpty
              ? Center(
                  child: Text(
                    provider.isScanning ? 'Scanning...' : 'No devices found.',
                  ),
                )
              : ListView.builder(
                  itemCount: provider.scanResults.length,
                  itemBuilder: (context, index) {
                    final result = provider.scanResults[index];
                    return ScanResultTile(
                      result: result,
                      onTap: () => reader.connect(result.device),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildConnectedView(
    BuildContext context,
    BluetoothProvider provider,
    BluetoothProvider reader,
  ) {
    final deviceName = provider.connectedDevice!.platformName.isNotEmpty
        ? provider.connectedDevice!.platformName
        : 'Unknown Device';
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.bluetooth_connected, size: 80, color: Colors.blue),
          const SizedBox(height: 20),
          Text('Connected to:', style: Theme.of(context).textTheme.titleMedium),
          Text(deviceName, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: reader.disconnect,
            child: const Text('Disconnect'),
          ),
        ],
      ),
    );
  }
}
