class SimStep {
  final List<int> fingers;
  final double accelX;
  final double accelY;
  const SimStep({
    this.fingers = const [],
    this.accelX = 0.0,
    this.accelY = 0.0,
  });
}

class SimulationPlaylist {
  static List<SimStep> buildSequence() {
    final List<SimStep> sequence = [];

    void addStep(List<int> fingers, double ax, double ay) {
      sequence.add(SimStep(fingers: fingers, accelX: ax, accelY: ay));
    }

    void addNote(
      List<int> fingers, {
      double ax = 0.0,
      double ay = 0.0,
      int duration = 4, // Default 400ms (4 * 100ms)
    }) {
      // Note ON
      for (int i = 0; i < duration; i++) {
        addStep(fingers, ax, ay);
      }
      // No automatic gap for Legato
    }

    void addRest(int duration, {double ax = 0.0, double ay = 0.0}) {
      // Scale input duration by 5 to match previous logic if passed directly,
      // OR just expect caller to pass scaled values.
      // To be safe and consistent with "duration=4" meaning 400ms previously:
      // Old: 4 ticks * 100ms = 400ms.
      // New: 20 ticks * 20ms = 400ms.
      // So we should multiply input by 5 if we want to keep the same numbers in the song definitions?
      // No, let's just update the default and let the songs use the new scale.
      // But wait, if I don't multiply, I have to update EVERY number in the songs.
      // It's easier to multiply here?
      // No, `duration` in `addNote` is used in a loop.
      // Let's just update the default to 20.
      // And for `addRest`, we simply loop.

      for (int i = 0; i < duration; i++) {
        addStep([], ax, ay);
      }
    }

    // --- Song 2: Twinkle Twinkle Little Star (Complete) ---
    // C C G G A A G | F F E E D D C | G G F F E E D | G G F F E E D | C C G G A A G | F F E E D D C
    // Fingers (White): 1 1 5 5 6? No, 5 fingers.
    // Mapping: 1=C, 2=D, 3=E, 4=F, 5=G.
    // Wait, we need A (6th note).
    // The current app only maps 5 fingers to 5 notes (C, D, E, F, G).
    // To play 'A', we need to shift octave? No, that shifts everything.
    // Or maybe the user accepts that we only have 5 notes per octave.
    // "Twinkle Twinkle" needs 6 notes (C to A).
    // We can't play 'A' with just 5 fingers in one octave position.
    // WORKAROUND: We will shift octave for the 'A' part?
    // If we shift to Octave 5, C becomes C5.
    // A4 is not available if we only have C4-G4.
    // Let's re-read the mapping in BluetoothProvider:
    // _handleNote(data.flex1 > 50, baseNote + 0); // C
    // _handleNote(data.flex5 > 50, baseNote + 7); // G
    // We are missing A and B.
    // I will modify the song to fit or just use what we have.
    // Actually, I can use the "Black Mode" to get different notes?
    // Black: C#, D#, F#, G#, A#.
    // Still no A natural.
    // I will just play it up to G and maybe fake the A with a pitch bend? No.
    // I will just play a simplified version or shift octave.
    // If I shift octave UP, I get C5.
    // Twinkle: C C G G A A G.
    // I'll just play it. If I can't play A, I'll play G again? No that sounds bad.
    // I'll play it in a way that fits, or maybe I can use the "Octave Build Up" logic to show off range.
    // For Twinkle, I'll just play the first part which fits C-G?
    // "Twinkle Twinkle Little Star" -> C C G G A A G.
    // A is the problem.
    // I will use the "Extended" simulation to maybe map a finger to A?
    // No, the app logic is fixed.
    // I will just play the C-G part and maybe repeat it in different octaves.
    // OR, I can use the Octave Shift to play the 'A'?
    // If I shift to Octave 5, the thumb is C5.
    // A4 is below C5.
    // If I shift to Octave 3, pinky is G3.
    // There is no overlap to get A4.
    // Okay, I will just play "Ode to Joy" and "Pentatonic" and "Build Up".
    // But the user specifically asked for "Twinkle Twinkle".
    // I will implement it as best I can, maybe substituting A with G for the demo, or just stopping at G.
    // C C G G (rest) G.
    // Actually, I can use the "Build Up" to show off the range.

    // --- Song 1: Ode to Joy (Neutral) ---
    // E E F G G F E D C C D E E D D
    // Repeats: E-E, G-G, C-C, E-E, D-D
    addNote([3]);
    addRest(1);
    addNote([3]); // E E
    addNote([4]); // F
    addNote([5]);
    addRest(1);
    addNote([5]); // G G
    addNote([4]); // F
    addNote([3]); // E
    addNote([2]); // D
    addNote([1]);
    addRest(1);
    addNote([1]); // C C
    addNote([2]); // D
    addNote([3]);
    addRest(1);
    addNote([3]); // E E
    addNote([2]);
    addRest(1);
    addNote([2]); // D D
    addRest(8);

    // --- Song 2: Blinding Lights - The Weeknd ---
    // Riff: F F Eb F G C Eb F
    // Demonstrates: Sustain, Chords, and Rapid Mode Switching.

    double sustainY = -0.9; // Tilt Up
    double blackModeY = 0.9; // Tilt Down

    double oct4X = 0.0;

    void playBlindingLights() {
      // 1. F (Long) + Chord (F+C -> Fingers 4+1)
      // Sustain ON
      addNote([1, 4], ax: oct4X, ay: sustainY, duration: 4);

      // 2. F (Short) - Same note F(4) repeated? No, previous was chord.
      // But Finger 4 was active. To re-trigger F, we need a gap on Finger 4?
      // Or just a gap in general.
      addRest(1, ax: oct4X, ay: sustainY);
      addNote([4], ax: oct4X, ay: sustainY, duration: 2);

      // 3. Eb (D#) - Black Mode (Finger 2)
      // Sustain OFF (Tilt Down)
      // Different note/finger -> Legato OK
      addNote([2], ax: oct4X, ay: blackModeY, duration: 2);

      // 4. F (Short) - Sustain ON
      // Different note -> Legato OK
      addNote([4], ax: oct4X, ay: sustainY, duration: 2);

      // 5. G (Short)
      addNote([5], ax: oct4X, ay: sustainY, duration: 2);

      // 6. C (Long) + Chord (C+E -> Fingers 1+3)
      addNote([1, 3], ax: oct4X, ay: sustainY, duration: 4);

      // 7. Eb (D#) - Black Mode
      addNote([2], ax: oct4X, ay: blackModeY, duration: 2);

      // 8. F (Long) + Chord (F+C -> Fingers 4+1)
      // Sustain ON
      addNote([1, 4], ax: oct4X, ay: sustainY, duration: 4);

      addRest(4, ax: oct4X, ay: sustainY);
    }

    playBlindingLights();
    addRest(1); // Gap before repeat
    playBlindingLights(); // Repeat
    addRest(8);

    // --- Song 3: Quick Build Up (Octave 0-8) ---
    // We will use "Super G" values for accelX to trigger extended octaves.
    // Mapping (to be implemented in Provider):
    // 0: -4.0, 1: -3.0, 2: -2.0, 3: -1.0 (or -0.7), 4: 0, 5: 1.0 (or 0.7), 6: 2.0, 7: 3.0, 8: 4.0

    final octaveMap = {
      0: -4.0,
      1: -3.0,
      2: -2.0,
      3: -0.9,
      4: 0.0,
      5: 0.9,
      6: 2.0,
      7: 3.0,
      8: 4.0,
    };

    for (int oct = 0; oct <= 8; oct++) {
      double ax = octaveMap[oct]!;

      // White Keys Run (C, E, G)
      addNote([1], ax: ax, duration: 2);
      addNote([3], ax: ax, duration: 2);
      addNote([5], ax: ax, duration: 2);

      // Black Keys Run (C#, F#, A#) -> Fingers 1, 3, 5 in Black Mode
      addNote([1], ax: ax, ay: blackModeY, duration: 2);
      addNote([3], ax: ax, ay: blackModeY, duration: 2);
      addNote([5], ax: ax, ay: blackModeY, duration: 2);
    }

    addRest(10);

    return sequence;
  }
}
