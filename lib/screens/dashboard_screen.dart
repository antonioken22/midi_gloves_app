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

    if (_blackKeysMode) {
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

    // Map Accel Y to Octave (for glove mode)
    // 0-10 range from simulation. Let's map 0-3 -> Octave 3, 3-7 -> Octave 4, 7-10 -> Octave 5
    int gloveOctave = 4;
    if (gloveData.accelY < 3)
      gloveOctave = 3;
    else if (gloveData.accelY > 7)
      gloveOctave = 5;

    // Use glove octave if connected/simulating, otherwise use manual octave
    final octave =
        (btProvider.connectedDevice != null || btProvider.isSimulating)
        ? gloveOctave
        : _manualOctave;

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
                    // Bottom: Piano with octave controls
                    Expanded(
                      flex: 3,
                      child: Column(
                        children: [
                          // Octave controls (only show in manual mode)
                          if (btProvider.connectedDevice == null &&
                              !btProvider.isSimulating)
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.arrow_downward),
                                    onPressed: _manualOctave > 0
                                        ? () => setState(() => _manualOctave--)
                                        : null,
                                    tooltip: 'Lower Octave',
                                  ),
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
                                  IconButton(
                                    icon: const Icon(Icons.arrow_upward),
                                    onPressed: _manualOctave < 8
                                        ? () => setState(() => _manualOctave++)
                                        : null,
                                    tooltip: 'Raise Octave',
                                  ),
                                ],
                              ),
                            ),
                          // Keyboard
                          Expanded(
                            child: Stack(
                              children: [
                                OctaveKeyboard(
                                  octaveNumber: octave,
                                  activeKeys: activeKeys,
                                  onKeyPress: _onKeyPress,
                                  onKeyRelease: _onKeyRelease,
                                ),
                                // Control buttons
                                Positioned(
                                  left: 16,
                                  top: 16,
                                  child: Column(
                                    children: [
                                      FloatingActionButton.small(
                                        heroTag: 'sustain_portrait',
                                        backgroundColor: _sustainEnabled
                                            ? Colors.green
                                            : Colors.grey,
                                        onPressed: _toggleSustain,
                                        tooltip: 'Sustain Pedal',
                                        child: Icon(
                                          _sustainEnabled
                                              ? Icons.my_library_music
                                              : Icons.library_music_outlined,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      FloatingActionButton.small(
                                        heroTag: 'key_filter_portrait',
                                        backgroundColor: _blackKeysMode
                                            ? Colors.black
                                            : Colors.white,
                                        foregroundColor: _blackKeysMode
                                            ? Colors.white
                                            : Colors.black,
                                        onPressed: _toggleKeyFilter,
                                        tooltip: _blackKeysMode
                                            ? 'Black Keys Mode'
                                            : 'White Keys Mode',
                                        child: Icon(
                                          _blackKeysMode
                                              ? Icons.piano_outlined
                                              : Icons.piano,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
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
                          // Flex sensors in a row
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
                          // Octave indicator
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Theme.of(
                                context,
                              ).colorScheme.primaryContainer,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              "Oct: $octave",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(
                                  context,
                                ).colorScheme.onPrimaryContainer,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Center: Piano (Maximized) with octave controls
                    Expanded(
                      child: Stack(
                        children: [
                          OctaveKeyboard(
                            octaveNumber: octave,
                            activeKeys: activeKeys,
                            onKeyPress: _onKeyPress,
                            onKeyRelease: _onKeyRelease,
                          ),
                          // Sustain and key filter buttons (left side)
                          Positioned(
                            left: 16,
                            top: 16,
                            child: Column(
                              children: [
                                FloatingActionButton.small(
                                  heroTag: 'sustain_landscape',
                                  backgroundColor: _sustainEnabled
                                      ? Colors.green
                                      : Colors.grey,
                                  onPressed: _toggleSustain,
                                  tooltip: 'Sustain Pedal',
                                  child: Icon(
                                    _sustainEnabled
                                        ? Icons.my_library_music
                                        : Icons.library_music_outlined,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                FloatingActionButton.small(
                                  heroTag: 'key_filter_landscape',
                                  backgroundColor: _blackKeysMode
                                      ? Colors.black
                                      : Colors.white,
                                  foregroundColor: _blackKeysMode
                                      ? Colors.white
                                      : Colors.black,
                                  onPressed: _toggleKeyFilter,
                                  tooltip: _blackKeysMode
                                      ? 'Black Keys Mode'
                                      : 'White Keys Mode',
                                  child: Icon(
                                    _blackKeysMode
                                        ? Icons.piano_outlined
                                        : Icons.piano,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Octave controls (only show in manual mode)
                          if (btProvider.connectedDevice == null &&
                              !btProvider.isSimulating)
                            Positioned(
                              right: 16,
                              top: 16,
                              child: Column(
                                children: [
                                  FloatingActionButton.small(
                                    heroTag: 'octave_up',
                                    onPressed: _manualOctave < 8
                                        ? () => setState(() => _manualOctave++)
                                        : null,
                                    tooltip: 'Raise Octave',
                                    child: const Icon(Icons.arrow_upward),
                                  ),
                                  const SizedBox(height: 8),
                                  FloatingActionButton.small(
                                    heroTag: 'octave_down',
                                    onPressed: _manualOctave > 0
                                        ? () => setState(() => _manualOctave--)
                                        : null,
                                    tooltip: 'Lower Octave',
                                    child: const Icon(Icons.arrow_downward),
                                  ),
                                ],
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
                color: value > 50 ? Colors.green : Colors.blue,
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
        : Theme.of(context).textTheme.headlineSmall;

    // Use a Column with MainAxisSize.min to take only needed space
    // Or use Spacer/Expanded to distribute space if we want it to fill
    return LayoutBuilder(
      builder: (context, constraints) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceEvenly, // Distribute space
          children: [
            Text("Flex Sensors", style: style),
            if (isCompact) ...[
              Text("T: ${gloveData.flex1}"),
              Text("I: ${gloveData.flex2}"),
              Text("M: ${gloveData.flex3}"),
              Text("R: ${gloveData.flex4}"),
              Text("P: ${gloveData.flex5}"),
            ] else ...[
              // Use a Wrap or Row for sensors if vertical space is tight
              // But for now, let's just make them compact
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _compactSensor("Thumb", gloveData.flex1),
                  _compactSensor("Index", gloveData.flex2),
                  _compactSensor("Mid", gloveData.flex3),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _compactSensor("Ring", gloveData.flex4),
                  _compactSensor("Pinky", gloveData.flex5),
                ],
              ),
            ],

            if (!isCompact) const Divider(),

            Text("Accelerometer", style: style),
            if (isCompact) ...[
              Text("X: ${gloveData.accelX.toStringAsFixed(1)}"),
              Text("Y: ${gloveData.accelY.toStringAsFixed(1)}"),
              Text("Z: ${gloveData.accelZ.toStringAsFixed(1)}"),
            ] else ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _compactTile("X", gloveData.accelX.toStringAsFixed(1)),
                  _compactTile("Y", gloveData.accelY.toStringAsFixed(1)),
                  _compactTile("Z", gloveData.accelZ.toStringAsFixed(1)),
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

  Widget _compactTile(String label, String value) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        Text(value, style: const TextStyle(fontSize: 18)),
      ],
    );
  }
}
