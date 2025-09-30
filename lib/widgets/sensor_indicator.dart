import 'package:flutter/material.dart';

class SensorIndicator extends StatelessWidget {
  final String label;
  final int value;
  const SensorIndicator({super.key, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    double progress = value / 255.0;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          SizedBox(width: 60, child: Text(label)),
          Expanded(
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 20,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          SizedBox(
            width: 60,
            child: Text(value.toString(), textAlign: TextAlign.right),
          ),
        ],
      ),
    );
  }
}
