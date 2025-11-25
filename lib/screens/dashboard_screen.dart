import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/bluetooth_provider.dart';
import '../widgets/octave_keyboard.dart';
import '../services/audio_manager.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _manualOctave = 4; // Default octave for manual mode
  final Set<int> _manuallyPressedKeys = {}; // Track keys being pressed manually
  bool _sustainEnabled = false; // MIDI sustain pedal state
  bool _blackKeysMode =
      false; // When true, only black keys respond to glove input

  void _onKeyPress(int keyIndex) {
    setState(() => _manuallyPressedKeys.add(keyIndex));
  }

  void _onKeyRelease(int keyIndex) {
    setState(() => _manuallyPressedKeys.remove(keyIndex));
  }

  void _toggleSustain() {
    setState(() => _sustainEnabled = !_sustainEnabled);
    AudioManager().setSustain(_sustainEnabled);
  }

  void _toggleKeyFilter() {
    setState(() => _blackKeysMode = !_blackKeysMode);
  }

  @override
  Widget build(BuildContext context) {
    final btProvider = context.watch<BluetoothProvider>();

    final deviceName =
        btProvider.connectedDevice?.platformName.isNotEmpty == true
        ? btProvider.connectedDevice!.platformName
        : (btProvider.isSimulating ? 'Simulation Mode' : 'Manual Mode');

    final gloveData = btProvider.gloveData;

    // Map Flex values to Keys (Simple mapping for demo)
    // Threshold > 50 means pressed
    final List<int> gloveActiveKeys = [];

    // Determine effective modes (Manual Toggle OR Gesture)
    // Arduino: Up (-Y) -> Sustain. Down (+Y) -> Black Mode.
    final bool isGloveConnected =
        btProvider.connectedDevice != null || btProvider.isSimulating;
    final bool gestureSustain = isGloveConnected && gloveData.accelY < -0.7;
    final bool gestureBlack = isGloveConnected && gloveData.accelY > 0.7;

    final bool effectiveSustain = _sustainEnabled || gestureSustain;
    final bool effectiveBlackMode = _blackKeysMode || gestureBlack;

    // Sync Audio Manager
    AudioManager().setSustain(effectiveSustain);

    if (effectiveBlackMode) {
      // In black keys mode, map to black keys (C#, D#, F#, G#, A#)
      if (gloveData.flex1 > 50) gloveActiveKeys.add(1); // C#
      if (gloveData.flex2 > 50) gloveActiveKeys.add(3); // D#
      if (gloveData.flex3 > 50) gloveActiveKeys.add(6); // F#
      if (gloveData.flex4 > 50) gloveActiveKeys.add(8); // G#
      if (gloveData.flex5 > 50) gloveActiveKeys.add(10); // A#
    } else {
      // In white keys mode, map to white keys (C, D, E, F, G)
      if (gloveData.flex1 > 50) gloveActiveKeys.add(0); // C
      if (gloveData.flex2 > 50) gloveActiveKeys.add(2); // D
      if (gloveData.flex3 > 50) gloveActiveKeys.add(4); // E
      if (gloveData.flex4 > 50) gloveActiveKeys.add(5); // F
      if (gloveData.flex5 > 50) gloveActiveKeys.add(7); // G
    }

    // Combine glove keys with manually pressed keys for visual feedback
    final activeKeys = [...gloveActiveKeys, ..._manuallyPressedKeys];

    // Map Accel X to Octave (for glove mode)
    // Extended Simulation Mapping:
    // -4.0 -> 0, -3.0 -> 1, -2.0 -> 2, -0.7 -> 3
    // 0.0 -> 4
    // 0.7 -> 5, 2.0 -> 6, 3.0 -> 7, 4.0 -> 8
    int gloveOctave = 4;

    if (gloveData.accelX <= -3.5)
      gloveOctave = 0;
    else if (gloveData.accelX <= -2.5)
      gloveOctave = 1;
    else if (gloveData.accelX <= -1.5)
      gloveOctave = 2;
    else if (gloveData.accelX < -0.7)
      gloveOctave = 3;
    else if (gloveData.accelX > 3.5)
      gloveOctave = 8;
    else if (gloveData.accelX > 2.5)
      gloveOctave = 7;
    else if (gloveData.accelX > 1.5)
      gloveOctave = 6;
    else if (gloveData.accelX > 0.7)
      gloveOctave = 5;

    // Use glove octave if connected/simulating, otherwise use manual octave
    final octave =
        (btProvider.connectedDevice != null || btProvider.isSimulating)
        ? gloveOctave
        : _manualOctave;

    // Determine if we are in manual mode (controls enabled)
    final isManualMode =
        btProvider.connectedDevice == null && !btProvider.isSimulating;

    return OrientationBuilder(
      builder: (context, orientation) {
        final isLandscape = orientation == Orientation.landscape;

        return Scaffold(
          // Hide AppBar in landscape mode
          appBar: isLandscape
              ? null
              : AppBar(
                  title: Text(deviceName),
                  actions: [
                    TextButton.icon(
                      onPressed: () =>
                          context.read<BluetoothProvider>().toggleSimulation(),
                      icon: Icon(
                        btProvider.isSimulating ? Icons.stop : Icons.play_arrow,
                      ),
                      label: Text(
                        btProvider.isSimulating ? "Stop Sim" : "Simulate",
                      ),
                    ),
                    if (btProvider.connectedDevice != null)
                      IconButton(
                        icon: const Icon(Icons.bluetooth_disabled),
                        tooltip: 'Disconnect',
                        onPressed: () =>
                            context.read<BluetoothProvider>().disconnect(),
                      ),
                  ],
                ),
          body: orientation == Orientation.portrait
              ? Column(
                  children: [
                    // Top: Data
                    Expanded(
                      flex: 4,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: _buildDataView(context, gloveData),
                      ),
                    ),
                    const Divider(height: 1),
                    // Bottom: Piano with persistent controls
                    Expanded(
                      flex: 3,
                      child: Column(
                        children: [
                          // Persistent Control Bar
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                // Sustain Toggle (Always visible)
                                IconButton(
                                  icon: Icon(
                                    effectiveSustain
                                        ? Icons.my_library_music
                                        : Icons.library_music_outlined,
                                    color: effectiveSustain
                                        ? Colors.green
                                        : null,
                                  ),
                                  onPressed: _toggleSustain,
                                  tooltip: 'Sustain Pedal',
                                ),
                                const SizedBox(width: 8),
                                // Octave Down (Disabled in Sim/Glove mode)
                                IconButton(
                                  icon: const Icon(Icons.arrow_downward),
                                  onPressed: isManualMode && _manualOctave > 0
                                      ? () => setState(() => _manualOctave--)
                                      : null,
                                  tooltip: 'Lower Octave',
                                ),
                                // Octave Display
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primaryContainer,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    'Octave: $octave',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onPrimaryContainer,
                                    ),
                                  ),
                                ),
                                // Octave Up (Disabled in Sim/Glove mode)
                                IconButton(
                                  icon: const Icon(Icons.arrow_upward),
                                  onPressed: isManualMode && _manualOctave < 8
                                      ? () => setState(() => _manualOctave++)
                                      : null,
                                  tooltip: 'Raise Octave',
                                ),
                                const SizedBox(width: 8),
                                // Key Filter Toggle (Always visible)
                                IconButton(
                                  icon: Icon(
                                    effectiveBlackMode
                                        ? Icons.piano_outlined
                                        : Icons.piano,
                                    color: effectiveBlackMode
                                        ? Theme.of(context).colorScheme.primary
                                        : null,
                                  ),
                                  onPressed: _toggleKeyFilter,
                                  tooltip: effectiveBlackMode
                                      ? 'Black Keys Mode'
                                      : 'White Keys Mode',
                                ),
                              ],
                            ),
                          ),
                          // Keyboard
                          Expanded(
                            child: OctaveKeyboard(
                              octaveNumber: octave,
                              activeKeys: activeKeys,
                              onKeyPress: _onKeyPress,
                              onKeyRelease: _onKeyRelease,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                )
              : Column(
                  children: [
                    // Top: Data (Compact horizontal strip)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(
                          context,
                        ).colorScheme.surfaceContainerHighest,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          // Flex sensors
                          _miniDataChip("T", gloveData.flex1),
                          _miniDataChip("I", gloveData.flex2),
                          _miniDataChip("M", gloveData.flex3),
                          _miniDataChip("R", gloveData.flex4),
                          _miniDataChip("P", gloveData.flex5),
                          const VerticalDivider(),
                          // Accel data
                          _miniAccelChip("X", gloveData.accelX),
                          _miniAccelChip("Y", gloveData.accelY),
                          _miniAccelChip("Z", gloveData.accelZ),
                          const VerticalDivider(),
                          // Simulate Button (Landscape)
                          TextButton.icon(
                            onPressed: () => context
                                .read<BluetoothProvider>()
                                .toggleSimulation(),
                            icon: Icon(
                              btProvider.isSimulating
                                  ? Icons.stop
                                  : Icons.play_arrow,
                              size: 20,
                            ),
                            label: Text(
                              btProvider.isSimulating ? "Stop" : "Simulate",
                              style: const TextStyle(fontSize: 12),
                            ),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Center: Piano (Maximized) with persistent controls
                    Expanded(
                      child: Column(
                        children: [
                          // Persistent Control Bar (Landscape - Top Row)
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 4,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                // Sustain Toggle
                                IconButton(
                                  icon: Icon(
                                    effectiveSustain
                                        ? Icons.my_library_music
                                        : Icons.library_music_outlined,
                                    color: effectiveSustain
                                        ? Colors.green
                                        : null,
                                  ),
                                  onPressed: _toggleSustain,
                                  tooltip: 'Sustain Pedal',
                                ),
                                const SizedBox(width: 8),
                                // Octave Down
                                IconButton(
                                  icon: const Icon(Icons.arrow_downward),
                                  onPressed: isManualMode && _manualOctave > 0
                                      ? () => setState(() => _manualOctave--)
                                      : null,
                                  tooltip: 'Lower Octave',
                                ),
                                // Octave Display
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primaryContainer,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    'Octave: $octave',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onPrimaryContainer,
                                    ),
                                  ),
                                ),
                                // Octave Up
                                IconButton(
                                  icon: const Icon(Icons.arrow_upward),
                                  onPressed: isManualMode && _manualOctave < 8
                                      ? () => setState(() => _manualOctave++)
                                      : null,
                                  tooltip: 'Raise Octave',
                                ),
                                const SizedBox(width: 8),
                                // Key Filter Toggle
                                IconButton(
                                  icon: Icon(
                                    effectiveBlackMode
                                        ? Icons.piano_outlined
                                        : Icons.piano,
                                    color: effectiveBlackMode
                                        ? Theme.of(context).colorScheme.primary
                                        : null,
                                  ),
                                  onPressed: _toggleKeyFilter,
                                  tooltip: effectiveBlackMode
                                      ? 'Black Keys Mode'
                                      : 'White Keys Mode',
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: OctaveKeyboard(
                              octaveNumber: octave,
                              activeKeys: activeKeys,
                              onKeyPress: _onKeyPress,
                              onKeyRelease: _onKeyRelease,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
        );
      },
    );
  }

  Widget _miniDataChip(String label, int value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          "$label:",
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        ),
        const SizedBox(width: 4),
        Container(
          width: 30,
          height: 6,
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(3),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: (value / 100).clamp(0.0, 1.0),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.blue, // Match Portrait
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          "$value",
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _miniAccelChip(String label, double value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          "$label:",
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        ),
        const SizedBox(width: 4),
        Container(
          width: 30,
          height: 6,
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(3),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: ((value + 1) / 2).clamp(0.0, 1.0),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.orange, // Match Portrait
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          value.toStringAsFixed(1),
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildDataView(
    BuildContext context,
    dynamic gloveData, {
    bool isCompact = false,
  }) {
    final style = isCompact
        ? Theme.of(context).textTheme.titleSmall
        : Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold);

    // Use a Column with MainAxisSize.min to take only needed space
    // Or use Spacer/Expanded to distribute space if we want it to fill
    return LayoutBuilder(
      builder: (context, constraints) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceEvenly, // Distribute space
          children: [
            Text("Flex Sensors (ZD10-100)", style: style),
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
                      child: _compactSensor("Mid", gloveData.flex3),
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
              const SizedBox(height: 8),
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

            if (!isCompact) const Divider(),

            Text("Accelerometer (MPU9250)", style: style),
            if (isCompact) ...[
              Text("X: ${gloveData.accelX.toStringAsFixed(1)}"),
              Text("Y: ${gloveData.accelY.toStringAsFixed(1)}"),
              Text("Z: ${gloveData.accelZ.toStringAsFixed(1)}"),
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
        Text("$value"),
      ],
    );
  }

  Widget _compactAccel(String label, double value) {
    // Normalize accel value for display (assuming range -1 to 1 roughly)
    // We'll map -1..1 to 0..1 for the bar
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
        Text(value.toStringAsFixed(1)),
      ],
    );
  }
}
