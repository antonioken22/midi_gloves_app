import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/bluetooth_provider.dart';
import '../widgets/piano/octave_keyboard.dart';
import '../widgets/dashboard/control_bar.dart';
import '../widgets/dashboard/sensor_view.dart';
import '../widgets/dashboard/compact_status_bar.dart';
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

    if (gloveData.accelX <= -3.5) {
      gloveOctave = 0;
    } else if (gloveData.accelX <= -2.5) {
      gloveOctave = 1;
    } else if (gloveData.accelX <= -1.5) {
      gloveOctave = 2;
    } else if (gloveData.accelX < -0.7) {
      gloveOctave = 3;
    } else if (gloveData.accelX > 3.5) {
      gloveOctave = 8;
    } else if (gloveData.accelX > 2.5) {
      gloveOctave = 7;
    } else if (gloveData.accelX > 1.5) {
      gloveOctave = 6;
    } else if (gloveData.accelX > 0.7) {
      gloveOctave = 5;
    }

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
          body: SafeArea(
            child: Container(
              child: orientation == Orientation.portrait
                  ? Column(
                      children: [
                        // Top: Data
                        Expanded(
                          flex: 4,
                          child: SingleChildScrollView(
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: SensorDataView(gloveData: gloveData),
                            ),
                          ),
                        ),
                        const Divider(height: 1),
                        // Bottom: Piano with persistent controls
                        Expanded(
                          flex: 3,
                          child: Column(
                            children: [
                              // Persistent Control Bar
                              DashboardControlBar(
                                effectiveSustain: effectiveSustain,
                                onToggleSustain: _toggleSustain,
                                effectiveBlackMode: effectiveBlackMode,
                                onToggleKeyFilter: _toggleKeyFilter,
                                octave: octave,
                                onOctaveDown: isManualMode && _manualOctave > 0
                                    ? () => setState(() => _manualOctave--)
                                    : null,
                                onOctaveUp: isManualMode && _manualOctave < 8
                                    ? () => setState(() => _manualOctave++)
                                    : null,
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
                        // Consolidated Top Bar (Sensors + Controls)
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: IntrinsicHeight(
                            child: Row(
                              children: [
                                CompactStatusBar(gloveData: gloveData),
                                const VerticalDivider(
                                  indent: 8,
                                  endIndent: 8,
                                  width: 1,
                                ),
                                DashboardControlBar(
                                  effectiveSustain: effectiveSustain,
                                  onToggleSustain: _toggleSustain,
                                  effectiveBlackMode: effectiveBlackMode,
                                  onToggleKeyFilter: _toggleKeyFilter,
                                  octave: octave,
                                  onOctaveDown:
                                      isManualMode && _manualOctave > 0
                                      ? () => setState(() => _manualOctave--)
                                      : null,
                                  onOctaveUp: isManualMode && _manualOctave < 8
                                      ? () => setState(() => _manualOctave++)
                                      : null,
                                ),
                                const VerticalDivider(
                                  indent: 8,
                                  endIndent: 8,
                                  width: 1,
                                ),
                                // Simulate Button (Moved Here)
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8.0,
                                  ),
                                  child: IconButton(
                                    onPressed: () => context
                                        .read<BluetoothProvider>()
                                        .toggleSimulation(),
                                    icon: Icon(
                                      btProvider.isSimulating
                                          ? Icons.stop
                                          : Icons.play_arrow,
                                    ),
                                    tooltip: btProvider.isSimulating
                                        ? "Stop Simulation"
                                        : "Start Simulation",
                                    style: IconButton.styleFrom(
                                      padding: const EdgeInsets.all(4),
                                      minimumSize: const Size(32, 32),
                                      tapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        // Center: Piano (Maximized)
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
          ),
        );
      },
    );
  }
}
