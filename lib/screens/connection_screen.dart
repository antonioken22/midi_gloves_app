import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:midi_gloves_app/providers/loading_provider.dart';
import 'package:provider/provider.dart';
import '../providers/bluetooth_provider.dart';
import '../widgets/bluetooth/bluetooth_off_screen.dart';
import '../widgets/bluetooth/scan_result_tile.dart';

class ConnectionScreen extends StatelessWidget {
  const ConnectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final btProvider = context.watch<BluetoothProvider>();
    final btProviderReader = context.read<BluetoothProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Connect to MIDI Gloves'),
        actions: [
          if (btProvider.adapterState == BluetoothAdapterState.on &&
              btProvider.connectedDevice == null)
            // Show scan/stop button
            btProvider.isScanning
                ? IconButton(
                    icon: const Icon(Icons.stop),
                    onPressed: () => btProviderReader.stopScan(),
                    tooltip: 'Stop Scanning',
                  )
                : IconButton(
                    icon: const Icon(Icons.search),
                    onPressed: () => btProviderReader.startScan(),
                    tooltip: 'Scan for New Devices',
                  ),
        ],
      ),
      body: _buildMainView(context, btProvider, btProviderReader),
    );
  }

  Widget _buildMainView(
    BuildContext context,
    BluetoothProvider provider,
    BluetoothProvider reader,
  ) {
    if (provider.connectedDevice != null) {
      return _buildConnectedView(context, provider, reader);
    }

    if (provider.adapterState == BluetoothAdapterState.on) {
      return _buildScanningView(context, provider, reader);
    }

    return const BluetoothOffScreen();
  }

  Widget _buildScanningView(
    BuildContext context,
    BluetoothProvider provider,
    BluetoothProvider reader,
  ) {
    return SingleChildScrollView(
      child: Column(
        children: [
          // List of Bonded (Paired) Devices
          _buildSectionTitle(context, 'Paired Devices'),
          _buildBondedDevicesList(context, provider, reader),

          const Divider(height: 1),

          // List of Scanned (Available) Devices
          _buildSectionTitle(context, 'Available Devices'),
          if (provider.isScanning)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(width: 16),
                  Text('Scanning for 10 seconds...'),
                ],
              ),
            ),
          _buildScanResultsList(context, provider, reader),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }

  Widget _buildBondedDevicesList(
    BuildContext context,
    BluetoothProvider provider,
    BluetoothProvider reader,
  ) {
    final loadingProvider = context.read<LoadingProvider>();

    return provider.bondedDevices.isEmpty
        ? const Center(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'No paired devices found.\nTry scanning for new devices below.',
                textAlign: TextAlign.center,
              ),
            ),
          )
        : ListView.builder(
            itemCount: provider.bondedDevices.length,
            itemBuilder: (context, index) {
              final device = provider.bondedDevices[index];
              return ListTile(
                title: Text(
                  device.platformName.isNotEmpty
                      ? device.platformName
                      : 'Unknown Device',
                ),
                subtitle: Text('MAC: ${device.remoteId.str} (Paired)'),
                trailing: ElevatedButton(
                  onPressed: () =>
                      loadingProvider.runTask(() => reader.connect(device)),
                  child: const Text('Connect'),
                ),
                onTap: () =>
                    loadingProvider.runTask(() => reader.connect(device)),
              );
            },
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
          );
  }

  Widget _buildScanResultsList(
    BuildContext context,
    BluetoothProvider provider,
    BluetoothProvider reader,
  ) {
    final loadingProvider = context.read<LoadingProvider>();

    return provider.scanResults.isEmpty && !provider.isScanning
        ? const SizedBox(
            height: 100,
            child: Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'No new devices found.\nTap the search icon to scan.',
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          )
        : ListView.builder(
            itemCount: provider.scanResults.length,
            itemBuilder: (context, index) {
              final result = provider.scanResults[index];
              return ScanResultTile(
                result: result,
                onTap: () => loadingProvider.runTask(
                  () => reader.connect(result.device),
                ),
              );
            },
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
          );
  }

  Widget _buildConnectedView(
    BuildContext context,
    BluetoothProvider provider,
    BluetoothProvider reader,
  ) {
    final loadingProvider = context.read<LoadingProvider>();
    final deviceName = provider.connectedDevice!.platformName.isNotEmpty
        ? provider.connectedDevice!.platformName
        : 'Unknown Device';

    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.bluetooth_connected, size: 80, color: Colors.blue),
            const SizedBox(height: 20),
            Text(
              'Connected to:',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Text(deviceName, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () =>
                  loadingProvider.runTask(() => reader.disconnect()),
              child: const Text('Disconnect'),
            ),
          ],
        ),
      ),
    );
  }
}
