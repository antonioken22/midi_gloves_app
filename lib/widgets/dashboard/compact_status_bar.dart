import 'package:flutter/material.dart';
import '../../models/glove_data.dart';

class CompactStatusBar extends StatelessWidget {
  final GloveData gloveData;
  final bool isSimulating;
  final VoidCallback onToggleSimulation;

  const CompactStatusBar({
    super.key,
    required this.gloveData,
    required this.isSimulating,
    required this.onToggleSimulation,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Flex sensors
          _miniDataChip("Thumb", gloveData.flex1),
          const SizedBox(width: 20),
          _miniDataChip("Index", gloveData.flex2),
          const SizedBox(width: 20),
          _miniDataChip("Middle", gloveData.flex3),
          const SizedBox(width: 20),
          _miniDataChip("Ring", gloveData.flex4),
          const SizedBox(width: 20),
          _miniDataChip("Pinky", gloveData.flex5),
          const SizedBox(width: 20),
          const VerticalDivider(indent: 6, endIndent: 6),
          const SizedBox(width: 20),
          // Accel data
          _miniAccelChip("Acc X", gloveData.accelX),
          const SizedBox(width: 20),
          _miniAccelChip("Acc Y", gloveData.accelY),
          const SizedBox(width: 20),
          _miniAccelChip("Acc Z", gloveData.accelZ),
          const SizedBox(width: 20),
          const VerticalDivider(indent: 6, endIndent: 6),
          // Simulate Button (Landscape) - Icon Only
          IconButton(
            onPressed: onToggleSimulation,
            icon: Icon(isSimulating ? Icons.stop : Icons.play_arrow),
            tooltip: isSimulating ? "Stop Simulation" : "Start Simulation",
            style: IconButton.styleFrom(
              padding: const EdgeInsets.all(4),
              minimumSize: const Size(32, 32),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
        ],
      ),
    );
  }

  Widget _miniDataChip(String label, int value) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 9, // Smaller
            fontWeight: FontWeight.w300, // Thinner
          ),
        ),
        const SizedBox(height: 2),
        Container(
          width: 30,
          height: 4, // Slightly thinner bar
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(2),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: (value / 100).clamp(0.0, 1.0),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.blue, // Match Portrait
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _miniAccelChip(String label, double value) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w300),
        ),
        const SizedBox(height: 2),
        Container(
          width: 30,
          height: 4,
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(2),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: ((value + 1) / 2).clamp(0.0, 1.0),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.orange, // Match Portrait
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
