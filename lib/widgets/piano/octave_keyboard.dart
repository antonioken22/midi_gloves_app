import 'package:flutter/material.dart';
import 'piano_key.dart';
import '../../services/audio_manager.dart';

class OctaveKeyboard extends StatelessWidget {
  final int octaveNumber;
  final List<int> activeKeys; // Indices of keys currently pressed (0-11)
  final Function(int)? onKeyPress;
  final Function(int)? onKeyRelease;

  const OctaveKeyboard({
    super.key,
    required this.octaveNumber,
    required this.activeKeys,
    this.onKeyPress,
    this.onKeyRelease,
  });

  int _getMidiNote(int keyIndex) {
    // MIDI note calculation: C0 is 12, then C1 is 24, C2 is 36, etc.
    // Octave N starts at 12 * (N + 1)
    final baseNote = 12 * (octaveNumber + 1);
    return baseNote + keyIndex;
  }

  @override
  Widget build(BuildContext context) {
    // Standard octave: C, C#, D, D#, E, F, F#, G, G#, A, A#, B
    final keys = [
      {'label': 'C', 'isBlack': false},
      {'label': 'C#', 'isBlack': true},
      {'label': 'D', 'isBlack': false},
      {'label': 'D#', 'isBlack': true},
      {'label': 'E', 'isBlack': false},
      {'label': 'F', 'isBlack': false},
      {'label': 'F#', 'isBlack': true},
      {'label': 'G', 'isBlack': false},
      {'label': 'G#', 'isBlack': true},
      {'label': 'A', 'isBlack': false},
      {'label': 'A#', 'isBlack': true},
      {'label': 'B', 'isBlack': false},
    ];

    return Column(
      children: [
        // Keys
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Stack(
                children: [
                  // White Keys Layer
                  Positioned.fill(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (int i = 0; i < keys.length; i++)
                          if (keys[i]['isBlack'] == false)
                            Expanded(
                              flex: 1,
                              child: PianoKey(
                                isBlackKey: false,
                                label: "${keys[i]['label']}$octaveNumber",
                                isPressed: activeKeys.contains(i),
                                onTap: () {
                                  onKeyPress?.call(i);
                                  AudioManager().playNote(_getMidiNote(i));
                                },
                                onTapUp: () {
                                  onKeyRelease?.call(i);
                                  AudioManager().stopNote(_getMidiNote(i));
                                },
                              ),
                            ),
                      ],
                    ),
                  ),
                  // Black Keys Layer
                  Positioned.fill(
                    child: IgnorePointer(
                      ignoring: false,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // C (White) - Spacer
                          const Expanded(
                            flex: 2,
                            child: IgnorePointer(child: SizedBox.expand()),
                          ),
                          // C# (Black)
                          Expanded(
                            flex: 2,
                            child: FractionallySizedBox(
                              heightFactor: 0.6,
                              child: PianoKey(
                                isBlackKey: true,
                                label: "${keys[1]['label']}$octaveNumber",
                                isPressed: activeKeys.contains(1),
                                onTap: () {
                                  onKeyPress?.call(1);
                                  AudioManager().playNote(_getMidiNote(1));
                                },
                                onTapUp: () {
                                  onKeyRelease?.call(1);
                                  AudioManager().stopNote(_getMidiNote(1));
                                },
                              ),
                            ),
                          ),
                          // D (White) - Spacer
                          const Expanded(
                            flex: 1,
                            child: IgnorePointer(child: SizedBox.expand()),
                          ),
                          // D# (Black)
                          Expanded(
                            flex: 2,
                            child: FractionallySizedBox(
                              heightFactor: 0.6,
                              child: PianoKey(
                                isBlackKey: true,
                                label: "${keys[3]['label']}$octaveNumber",
                                isPressed: activeKeys.contains(3),
                                onTap: () {
                                  onKeyPress?.call(3);
                                  AudioManager().playNote(_getMidiNote(3));
                                },
                                onTapUp: () {
                                  onKeyRelease?.call(3);
                                  AudioManager().stopNote(_getMidiNote(3));
                                },
                              ),
                            ),
                          ),
                          // E (White) - Spacer
                          const Expanded(
                            flex: 2,
                            child: IgnorePointer(child: SizedBox.expand()),
                          ),
                          // F (White) - Spacer
                          const Expanded(
                            flex: 2,
                            child: IgnorePointer(child: SizedBox.expand()),
                          ),
                          // F# (Black)
                          Expanded(
                            flex: 2,
                            child: FractionallySizedBox(
                              heightFactor: 0.6,
                              child: PianoKey(
                                isBlackKey: true,
                                label: "${keys[6]['label']}$octaveNumber",
                                isPressed: activeKeys.contains(6),
                                onTap: () {
                                  onKeyPress?.call(6);
                                  AudioManager().playNote(_getMidiNote(6));
                                },
                                onTapUp: () {
                                  onKeyRelease?.call(6);
                                  AudioManager().stopNote(_getMidiNote(6));
                                },
                              ),
                            ),
                          ),
                          // G (White) - Spacer
                          const Expanded(
                            flex: 1,
                            child: IgnorePointer(child: SizedBox.expand()),
                          ),
                          // G# (Black)
                          Expanded(
                            flex: 2,
                            child: FractionallySizedBox(
                              heightFactor: 0.6,
                              child: PianoKey(
                                isBlackKey: true,
                                label: "${keys[8]['label']}$octaveNumber",
                                isPressed: activeKeys.contains(8),
                                onTap: () {
                                  onKeyPress?.call(8);
                                  AudioManager().playNote(_getMidiNote(8));
                                },
                                onTapUp: () {
                                  onKeyRelease?.call(8);
                                  AudioManager().stopNote(_getMidiNote(8));
                                },
                              ),
                            ),
                          ),
                          // A (White) - Spacer
                          const Expanded(
                            flex: 1,
                            child: IgnorePointer(child: SizedBox.expand()),
                          ),
                          // A# (Black)
                          Expanded(
                            flex: 2,
                            child: FractionallySizedBox(
                              heightFactor: 0.6,
                              child: PianoKey(
                                isBlackKey: true,
                                label: "${keys[10]['label']}$octaveNumber",
                                isPressed: activeKeys.contains(10),
                                onTap: () {
                                  onKeyPress?.call(10);
                                  AudioManager().playNote(_getMidiNote(10));
                                },
                                onTapUp: () {
                                  onKeyRelease?.call(10);
                                  AudioManager().stopNote(_getMidiNote(10));
                                },
                              ),
                            ),
                          ),
                          // B (White) - Spacer
                          const Expanded(
                            flex: 2,
                            child: IgnorePointer(child: SizedBox.expand()),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}
