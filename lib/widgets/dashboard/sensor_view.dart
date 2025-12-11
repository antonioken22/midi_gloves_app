import 'package:flutter/material.dart';
import '../../models/glove_data.dart';

class SensorDataView extends StatelessWidget {
  final GloveData gloveData;
  final bool isCompact;

  const SensorDataView({
    super.key,
    required this.gloveData,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    final style = isCompact
        ? Theme.of(context).textTheme.titleSmall
        : Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold);

    return LayoutBuilder(
      builder: (context, constraints) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Text("Flex Sensors (2.2\" Resistive)", style: style),
            const SizedBox(height: 20), // Increased from 12
            if (isCompact) ...[
              Text("T: ${gloveData.flex1}"),
              Text("I: ${gloveData.flex2}"),
              Text("M: ${gloveData.flex3}"),
              Text("R: ${gloveData.flex4}"),
              Text("P: ${gloveData.flex5}"),
            ] else ...[
              // 4 Columns for fingers (Top)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Expanded(
                    child: Center(
                      child: _compactSensor("Index", gloveData.flex2),
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: _compactSensor("Middle", gloveData.flex3),
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: _compactSensor("Ring", gloveData.flex4),
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: _compactSensor("Pinky", gloveData.flex5),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // Thumb separate (Bottom Left)
              Row(
                children: [
                  Expanded(
                    child: Center(
                      child: _compactSensor("Thumb", gloveData.flex1),
                    ),
                  ),
                  const Expanded(child: SizedBox()),
                  const Expanded(child: SizedBox()),
                  const Expanded(child: SizedBox()),
                ],
              ),
            ],

            if (!isCompact) ...[
              const SizedBox(height: 20),
              const Divider(),
              const SizedBox(height: 20),
            ],

            Text("Accelerometer (MPU9250)", style: style),
            const SizedBox(height: 20),
            if (isCompact) ...[
              Text("X: ${gloveData.accelX.toStringAsFixed(2)}"),
              Text("Y: ${gloveData.accelY.toStringAsFixed(2)}"),
              Text("Z: ${gloveData.accelZ.toStringAsFixed(2)}"),
            ] else ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _compactAccel("X", gloveData.accelX),
                  _compactAccel("Y", gloveData.accelY),
                  _compactAccel("Z", gloveData.accelZ),
                ],
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _compactSensor(String label, int value) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        Container(
          width: 40,
          height: 10,
          margin: const EdgeInsets.symmetric(vertical: 4),
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(5),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: (value / 100).clamp(0.0, 1.0),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.blue,
                borderRadius: BorderRadius.circular(5),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _compactAccel(String label, double value) {
    final normalized = ((value + 1) / 2).clamp(0.0, 1.0);

    return Column(
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        Container(
          width: 40,
          height: 10,
          margin: const EdgeInsets.symmetric(vertical: 4),
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(5),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: normalized,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.orange,
                borderRadius: BorderRadius.circular(5),
              ),
            ),
          ),
        ),
        Text(value.toStringAsFixed(2)),
      ],
    );
  }
}
