import 'package:flutter/material.dart';

class DashboardControlBar extends StatelessWidget {
  final bool effectiveSustain;
  final VoidCallback onToggleSustain;
  final bool effectiveBlackMode;
  final VoidCallback onToggleKeyFilter;
  final int octave;
  final VoidCallback? onOctaveDown;
  final VoidCallback? onOctaveUp;

  const DashboardControlBar({
    super.key,
    required this.effectiveSustain,
    required this.onToggleSustain,
    required this.effectiveBlackMode,
    required this.onToggleKeyFilter,
    required this.octave,
    required this.onOctaveDown,
    required this.onOctaveUp,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Sustain Toggle (Always visible)
          IconButton(
            style: IconButton.styleFrom(
              backgroundColor: effectiveSustain ? Colors.orange : null,
              foregroundColor: effectiveSustain ? Colors.white : Colors.black,
              side: effectiveSustain
                  ? null
                  : const BorderSide(color: Colors.black12),
            ),
            icon: Icon(
              effectiveSustain
                  ? Icons.my_library_music
                  : Icons.library_music_outlined,
            ),
            onPressed: onToggleSustain,
            tooltip: 'Sustain Pedal',
          ),
          const SizedBox(width: 8),
          // Octave Down
          IconButton(
            icon: const Icon(Icons.arrow_downward),
            onPressed: onOctaveDown,
            tooltip: 'Lower Octave',
          ),
          // Octave Display
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Color.lerp(Colors.black87, Colors.white, octave / 8.0),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.black12),
            ),
            child: Text(
              'Octave: $octave',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: octave <= 5 ? Colors.white : Colors.black,
              ),
            ),
          ),
          // Octave Up
          IconButton(
            icon: const Icon(Icons.arrow_upward),
            onPressed: onOctaveUp,
            tooltip: 'Raise Octave',
          ),
          const SizedBox(width: 8),
          // Key Filter Toggle (Always visible)
          IconButton(
            style: IconButton.styleFrom(
              backgroundColor: effectiveBlackMode ? Colors.black : Colors.white,
              foregroundColor: effectiveBlackMode ? Colors.white : Colors.black,
              side: BorderSide(
                color: effectiveBlackMode ? Colors.transparent : Colors.black12,
              ),
            ),
            icon: Icon(effectiveBlackMode ? Icons.piano : Icons.piano_outlined),
            onPressed: onToggleKeyFilter,
            tooltip: effectiveBlackMode ? 'Black Keys Mode' : 'White Keys Mode',
          ),
        ],
      ),
    );
  }
}
