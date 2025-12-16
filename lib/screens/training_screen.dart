import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/bluetooth_provider.dart';
import '../services/ml_service.dart';

class TrainingScreen extends StatefulWidget {
  const TrainingScreen({super.key});

  @override
  State<TrainingScreen> createState() => _TrainingScreenState();
}

class _TrainingScreenState extends State<TrainingScreen> {
  String _selectedLabel = "C";
  final List<String> _labels = ["C", "D", "E", "F", "G", "A", "B", "No Note"];

  @override
  Widget build(BuildContext context) {
    final btProvider = context.watch<BluetoothProvider>();
    final mlService = context.watch<MLService>();
    final gloveData = btProvider.gloveData;

    return Scaffold(
      appBar: AppBar(title: const Text('Gesture Training'), actions: []),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // Instructions
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'Select a note, hold the desired hand gesture, and tap "Record Sample". '
                'Record multiple samples (3 or more) for each note to improve accuracy.',
                style: TextStyle(fontSize: 16),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Label Selector
          DropdownButtonFormField<String>(
            initialValue: _selectedLabel,
            decoration: const InputDecoration(
              labelText: 'Target Note/Label',
              border: OutlineInputBorder(),
            ),
            items: _labels.map((label) {
              return DropdownMenuItem(value: label, child: Text(label));
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() => _selectedLabel = value);
              }
            },
          ),
          const SizedBox(height: 20),

          // Live Data Preview
          const Text(
            'Live Sensor Data',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          // Fingers (I, M, R, P)
          Row(
            children: [
              Expanded(
                child: Center(child: _dataChip('Index', gloveData.flex2)),
              ),
              Expanded(
                child: Center(child: _dataChip('Middle', gloveData.flex3)),
              ),
              Expanded(
                child: Center(child: _dataChip('Ring', gloveData.flex4)),
              ),
              Expanded(
                child: Center(child: _dataChip('Pinky', gloveData.flex5)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Thumb (T) - Aligned with Index
          Row(
            children: [
              Expanded(
                child: Center(child: _dataChip('Thumb', gloveData.flex1)),
              ),
              const Expanded(child: SizedBox()),
              const Expanded(child: SizedBox()),
              const Expanded(child: SizedBox()),
            ],
          ),
          const Divider(height: 24),
          // Accelerometer
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _accelChip('Accel X', gloveData.accelX),
              _accelChip('Accel Y', gloveData.accelY),
              _accelChip('Accel Z', gloveData.accelZ),
            ],
          ),
          const SizedBox(height: 30),

          // Record Button ("Tap to Record")
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: () async {
                final features = [
                  gloveData.flex1.toDouble(),
                  gloveData.flex2.toDouble(),
                  gloveData.flex3.toDouble(),
                  gloveData.flex4.toDouble(),
                  gloveData.flex5.toDouble(),
                  gloveData.accelX,
                  gloveData.accelY,
                  gloveData.accelZ,
                ];

                final sample = GestureSample(
                  features: features,
                  noteLabel: _selectedLabel,
                );

                await mlService.addSample(sample);

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Recorded sample for $_selectedLabel'),
                      duration: const Duration(milliseconds: 500),
                    ),
                  );
                }
              },
              icon: const Icon(Icons.fiber_manual_record),
              label: const Text('RECORD SAMPLE'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Stats
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: const Text(
                  'Training Data Stats:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ),
              const Divider(),
              ListView(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: _labels.map((label) {
                  final count = mlService.samples
                      .where((s) => s.noteLabel == label)
                      .length;
                  if (count == 0) return const SizedBox.shrink();
                  return ListTile(
                    title: Text('Label: $label'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('$count samples'),
                        IconButton(
                          icon: const Icon(
                            Icons.delete_outline,
                            color: Colors.red,
                          ),
                          onPressed: () async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: Text('Clear $label Data?'),
                                content: Text(
                                  'This will delete all $count samples for $label. This action cannot be undone.',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, false),
                                    child: const Text('Cancel'),
                                  ),
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, true),
                                    child: const Text('Delete'),
                                  ),
                                ],
                              ),
                            );

                            if (confirm == true) {
                              await mlService.clearDataForLabel(label);
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Cleared data for $label'),
                                  ),
                                );
                              }
                            }
                          },
                        ),
                      ],
                    ),
                    dense: true,
                  );
                }).toList(),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  'Total Samples: ${mlService.samples.length}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _dataChip(String label, int value) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        Text(value.toString()),
      ],
    );
  }

  Widget _accelChip(String label, double value) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        Text(value.toStringAsFixed(2)),
      ],
    );
  }
}
