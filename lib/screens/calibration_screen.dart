import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/bluetooth_provider.dart';
import '../providers/settings_provider.dart';

class CalibrationScreen extends StatelessWidget {
  const CalibrationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final btProvider = context.watch<BluetoothProvider>();
    final settingsProvider = context.watch<SettingsProvider>();
    final gloveData = btProvider.gloveData;
    final thresholds = settingsProvider.sensorThresholds;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sensor Calibration'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Reset Thresholds',
            onPressed: () {
              settingsProvider.resetThresholds();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Thresholds reset to default')),
              );
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          const Text(
            'Flex Sensors Calibration',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Adjust the thresholds for each finger. When the sensor value exceeds the threshold, the note will trigger.',
          ),
          const SizedBox(height: 16),
          const SizedBox(height: 20),
          _buildCalibrationRow(
            context,
            'Thumb (C)',
            0,
            gloveData.flex1,
            thresholds[0],
            settingsProvider,
          ),
          _buildCalibrationRow(
            context,
            'Index (D)',
            1,
            gloveData.flex2,
            thresholds[1],
            settingsProvider,
          ),
          _buildCalibrationRow(
            context,
            'Middle (E)',
            2,
            gloveData.flex3,
            thresholds[2],
            settingsProvider,
          ),
          _buildCalibrationRow(
            context,
            'Ring (F)',
            3,
            gloveData.flex4,
            thresholds[3],
            settingsProvider,
          ),
          _buildCalibrationRow(
            context,
            'Pinky (G)',
            4,
            gloveData.flex5,
            thresholds[4],
            settingsProvider,
          ),
          const SizedBox(height: 16),
          Center(
            child: TextButton.icon(
              onPressed: () {
                settingsProvider.resetThresholds();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Thresholds reset to default')),
                );
              },
              icon: const Icon(Icons.restore),
              label: const Text('Reset Thresholds to Default (50)'),
            ),
          ),
          const Divider(height: 40),
          const Text(
            'Accelerometer Calibration',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Hold the glove steady in a neutral position and press Calibrate to zero the sensors.',
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildAccelValue('X', gloveData.accelX),
                      _buildAccelValue('Y', gloveData.accelY),
                      _buildAccelValue('Z', gloveData.accelZ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () {
                      settingsProvider.setAccelOffsets(
                        gloveData.accelX,
                        gloveData.accelY,
                        gloveData.accelZ,
                      );
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Accelerometer Calibrated'),
                        ),
                      );
                    },
                    icon: const Icon(Icons.gps_fixed),
                    label: const Text('Calibrate (Set Zero)'),
                  ),
                  if (settingsProvider.accelOffsets.any((e) => e != 0))
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: TextButton(
                        onPressed: () {
                          settingsProvider.setAccelOffsets(0, 0, 0);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Calibration Reset')),
                          );
                        },
                        child: const Text('Reset Calibration'),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccelValue(String label, double value) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        Text(value.toStringAsFixed(2), style: const TextStyle(fontSize: 14)),
      ],
    );
  }

  Widget _buildCalibrationRow(
    BuildContext context,
    String label,
    int index,
    int currentValue,
    int threshold,
    SettingsProvider settings,
  ) {
    final isActive = currentValue > threshold;

    return Card(
      margin: const EdgeInsets.only(bottom: 8), // Reduced margin
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 12.0,
          vertical: 8.0,
        ), // Reduced padding
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14, // Slightly smaller font
                    color: isActive ? Colors.green : null,
                  ),
                ),
                Text(
                  'Live: $currentValue',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12, // Slightly smaller font
                    color: isActive ? Colors.green : Colors.grey,
                  ),
                ),
              ],
            ),
            // Removed SizedBox(height: 8) to save space
            Row(
              children: [
                const Text('0', style: TextStyle(fontSize: 12)),
                Expanded(
                  child: SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      trackHeight: 2.0, // Thinner track
                      thumbShape: const RoundSliderThumbShape(
                        enabledThumbRadius: 6.0,
                      ), // Smaller thumb
                      overlayShape: const RoundSliderOverlayShape(
                        overlayRadius: 14.0,
                      ), // Smaller overlay
                    ),
                    child: Slider(
                      value: threshold.toDouble(),
                      min: 0,
                      max: 100,
                      divisions: 100,
                      label: threshold.toString(),
                      onChanged: (value) {
                        settings.setSensorThreshold(index, value.toInt());
                      },
                    ),
                  ),
                ),
                const Text('100', style: TextStyle(fontSize: 12)),
              ],
            ),
            Center(
              child: Text(
                'Threshold: $threshold',
                style: const TextStyle(fontSize: 12),
              ),
            ),
            const SizedBox(height: 4), // Reduced spacing
            // Visual Indicator
            Container(
              height: 6, // Thinner bar
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(3),
              ),
              child: Stack(
                children: [
                  // Current Value Bar
                  FractionallySizedBox(
                    widthFactor: (currentValue / 100).clamp(0.0, 1.0),
                    child: Container(
                      decoration: BoxDecoration(
                        color: isActive ? Colors.green : Colors.blue,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                  // Threshold Marker
                  Positioned(
                    left:
                        (threshold / 100) *
                            (MediaQuery.of(context).size.width -
                                56) - // Adjusted for new padding
                        2,
                    child: Container(width: 4, height: 6, color: Colors.red),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
