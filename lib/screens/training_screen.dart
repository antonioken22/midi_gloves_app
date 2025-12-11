import 'dart:async';
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

  // Recording State
  bool _isRecording = false;
  final List<List<double>> _currentSequence = [];
  Timer? _recordingTimer;

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

          // Record Button ("Hold to Record")
          GestureDetector(
            onLongPressStart: (_) {
              // Haptic feedback could be added here
              setState(() {
                _isRecording = true;
                _currentSequence.clear();
              });

              // Start sampling timer (50Hz = 20ms)
              // 2 seconds limit = 2000ms / 20ms = 100 frames
              _recordingTimer = Timer.periodic(
                const Duration(milliseconds: 20),
                (timer) {
                  // Hard limit: 2 seconds
                  if (_currentSequence.length >= 100) {
                    _finishRecording();
                    return;
                  }

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
                  _currentSequence.add(features);
                },
              );
            },
            onLongPressEnd: (_) {
              if (_isRecording) {
                _finishRecording();
              }
            },
            child: Container(
              width: double.infinity,
              height: 60,
              decoration: BoxDecoration(
                color: _isRecording ? Colors.red.shade700 : Colors.redAccent,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  if (_isRecording)
                    const BoxShadow(
                      color: Colors.redAccent,
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                ],
              ),
              child: Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _isRecording
                          ? Icons.radio_button_checked
                          : Icons.touch_app,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _isRecording ? 'RECORDING...' : 'HOLD TO RECORD MOVEMENT',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
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

  Future<void> _finishRecording() async {
    _recordingTimer?.cancel();
    _recordingTimer = null;

    // Safety check: if already stopped
    if (!_isRecording) return;

    setState(() {
      _isRecording = false;
    });

    final mlService = context.read<MLService>();

    if (_currentSequence.length < 5) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gesture too short! Hold longer.')),
        );
      }
      return;
    }

    final sample = GestureSample(
      features: List.from(_currentSequence), // Copy
      noteLabel: _selectedLabel,
    );

    await mlService.addSample(sample);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Recorded dynamic sample for $_selectedLabel (${_currentSequence.length} frames)',
          ),
          duration: const Duration(milliseconds: 500),
        ),
      );
    }
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
