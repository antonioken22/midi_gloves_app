import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/glove_data.dart';
import '../models/simulation_playlist.dart';
import '../services/audio_manager.dart';
import '../services/ml_service.dart';
import 'settings_provider.dart';

class BluetoothProvider with ChangeNotifier {
  BluetoothDevice? _connectedDevice;
  GloveData _gloveData = GloveData.zero();
  List<BluetoothDevice> _bondedDevices = [];
  List<ScanResult> _scanResults = [];
  bool _isScanning = false;
  BluetoothAdapterState _adapterState = BluetoothAdapterState.unknown;

  late StreamSubscription<BluetoothAdapterState> _adapterStateSub;
  StreamSubscription<List<ScanResult>>? _scanSub;

  final Guid _serviceUuid = Guid("4fafc201-1fb5-459e-8fcc-c5c9c331914b");
  final Guid _characteristicUuid = Guid("beb5483e-36e1-4688-b7f5-ea07361b26a8");

  BluetoothDevice? get connectedDevice => _connectedDevice;
  GloveData get gloveData => _gloveData;
  List<BluetoothDevice> get bondedDevices => _bondedDevices;
  List<ScanResult> get scanResults => _scanResults;
  bool get isScanning => _isScanning;
  BluetoothAdapterState get adapterState => _adapterState;

  StreamSubscription<List<int>>? _dataSub;

  // Track active notes to stop them
  final Set<int> _activeNotes = {};

  SettingsProvider _settings;
  final MLService _mlService;

  BluetoothProvider(this._settings, this._mlService) {
    _adapterStateSub = FlutterBluePlus.adapterState.listen((state) {
      _adapterState = state;
      if (state == BluetoothAdapterState.on) {
        refreshBondedDevices();
      } else {
        _bondedDevices = [];
        _scanResults = [];
      }
      notifyListeners();
    });

    // Initialize Audio
    AudioManager().initialize();
  }

  void updateSettings(SettingsProvider settings) {
    _settings = settings;
    notifyListeners();
  }

  Future<void> _requestPermissions() async {
    // Permissions are handled differently or not needed on Desktop
    if (Platform.isLinux || Platform.isWindows || Platform.isMacOS) {
      return;
    }
    await [
      Permission.bluetooth,
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
    ].request();
  }

  Future<void> refreshBondedDevices() async {
    await _requestPermissions();

    _bondedDevices = await FlutterBluePlus.bondedDevices;

    notifyListeners();
  }

  Future<void> startScan() async {
    await _requestPermissions();
    if (_adapterState != BluetoothAdapterState.on || _isScanning) return;

    _isScanning = true;
    _scanResults = [];
    notifyListeners();

    try {
      await FlutterBluePlus.startScan(timeout: const Duration(seconds: 10));

      _scanSub = FlutterBluePlus.onScanResults.listen(
        (results) {
          _scanResults = results;
          notifyListeners();
        },
        onError: (e) {
          print("SCAN ERROR: $e");
          stopScan();
        },
      );

      await Future.delayed(const Duration(seconds: 10));
      stopScan();
    } catch (e) {
      print("ERROR STARTING SCAN: $e");
      stopScan();
    }
  }

  void stopScan() {
    if (!_isScanning) return;
    FlutterBluePlus.stopScan();
    _scanSub?.cancel();
    _scanSub = null;
    _isScanning = false;
    notifyListeners();
  }

  Future<void> connect(BluetoothDevice device) async {
    if (_isScanning) {
      stopScan();
    }
    try {
      await device.connect(
        license: License.free,
        timeout: const Duration(seconds: 15),
      );
      _connectedDevice = device;

      await refreshBondedDevices();

      _listenToGloveData();
      notifyListeners();
    } on FlutterBluePlusException catch (e) {
      print("ERROR CONNECTING (FBP): ${e.description}");
      throw Exception('Connection Failed: ${e.description}');
    } catch (e) {
      print("ERROR CONNECTING (Generic): $e");
      throw Exception('An unknown connection error occurred.');
    }
  }

  Future<void> disconnect() async {
    try {
      await _dataSub?.cancel();
      _dataSub = null;
      await _connectedDevice?.disconnect();
      _connectedDevice = null;
      stopSimulation(); // Ensure simulation stops on disconnect
      _gloveData = GloveData.zero();
      _stopAllNotes();
      notifyListeners();
    } on FlutterBluePlusException catch (e) {
      print("ERROR DISCONNECTING (FBP): ${e.description}");
      throw Exception('Disconnect Failed: ${e.description}');
    } catch (e) {
      print("ERROR DISCONNECTING (Generic): $e");
      throw Exception('An unknown disconnection error occurred.');
    }
  }

  Future<void> _listenToGloveData() async {
    if (_connectedDevice == null) return;
    try {
      await _connectedDevice!.createBond();

      await _connectedDevice!.discoverServices();
      BluetoothCharacteristic? char;
      for (var s in _connectedDevice!.servicesList) {
        if (s.uuid == _serviceUuid) {
          for (var c in s.characteristics) {
            if (c.uuid == _characteristicUuid) {
              char = c;
              break;
            }
          }
        }
      }
      if (char != null) {
        await char.setNotifyValue(true);
        _dataSub = char.onValueReceived.listen((value) {
          try {
            final String jsonString = utf8.decode(value);

            if (jsonString.isNotEmpty) {
              _gloveData = GloveData.fromJsonString(jsonString);
              _processAudio(_gloveData);
              notifyListeners();
            }
          } catch (e) {
            print("Error decoding or parsing BLE data: $e");
          }
        });
      }
    } catch (e) {
      print("ERROR LISTENING TO DATA: $e");
    }
  }

  // Simulation
  bool _isSimulating = false;
  Timer? _simulationTimer;
  bool get isSimulating => _isSimulating;

  void toggleSimulation() {
    if (_isSimulating) {
      stopSimulation();
    } else {
      startSimulation();
    }
  }

  // Simulation State
  List<SimStep> _simulationSequence = [];
  int _sequenceIndex = 0;

  void startSimulation() {
    if (_isSimulating) return;
    _isSimulating = true;
    _simulationSequence = SimulationPlaylist.buildSequence();
    _sequenceIndex = 0;
    notifyListeners();

    _simulationTimer = Timer.periodic(const Duration(milliseconds: 100), (
      timer,
    ) {
      if (_simulationSequence.isEmpty) return;

      final step = _simulationSequence[_sequenceIndex];
      _sequenceIndex = (_sequenceIndex + 1) % _simulationSequence.length;

      // Gentle breathing for Z to show life
      final now = DateTime.now().millisecondsSinceEpoch;
      final accelZ = 0.9 + 0.05 * cos(now / 2000.0);

      _gloveData = GloveData(
        flex1: step.fingers.contains(1) ? 100 : 0,
        flex2: step.fingers.contains(2) ? 100 : 0,
        flex3: step.fingers.contains(3) ? 100 : 0,
        flex4: step.fingers.contains(4) ? 100 : 0,
        flex5: step.fingers.contains(5) ? 100 : 0,
        accelX: step.accelX,
        accelY: step.accelY,
        accelZ: accelZ,
      );
      _processAudio(_gloveData);
      notifyListeners();
    });
  }

  void stopSimulation() {
    _simulationTimer?.cancel();
    _simulationTimer = null;
    _isSimulating = false;
    _gloveData = GloveData.zero();
    _stopAllNotes();
    notifyListeners();
  }

  void _processAudio(GloveData data) {
    if (_settings.isMLMode) {
      // ML Mode: Use k-NN prediction
      final features = [
        data.flex1.toDouble(),
        data.flex2.toDouble(),
        data.flex3.toDouble(),
        data.flex4.toDouble(),
        data.flex5.toDouble(),
        data.accelX,
        data.accelY,
        data.accelZ,
      ];

      final predictedLabel = _mlService.predict(features, k: 1);

      // Map label to note
      // Simple mapping for now: Label -> Note Index relative to C4 (60)
      // C=0, D=2, E=4, F=5, G=7, A=9, B=11
      int? noteIndex;
      switch (predictedLabel) {
        case "C":
          noteIndex = 0;
          break;
        case "D":
          noteIndex = 2;
          break;
        case "E":
          noteIndex = 4;
          break;
        case "F":
          noteIndex = 5;
          break;
        case "G":
          noteIndex = 7;
          break;
        case "A":
          noteIndex = 9;
          break;
        case "B":
          noteIndex = 11;
          break;
        default:
          noteIndex = null; // No Note
      }

      // Determine Octave (still use Accel X for now, or could be part of ML)
      // For simplicity, let's keep the tilt-based octave for now to allow range.
      // Apply IMU Calibration Offsets
      final offsets = _settings.accelOffsets;
      final effectiveX = data.accelX - offsets[0];

      int octave = 4;
      if (effectiveX <= -3.5) {
        octave = 0;
      } else if (effectiveX <= -2.5)
        octave = 1;
      else if (effectiveX <= -1.5)
        octave = 2;
      else if (effectiveX < -0.7)
        octave = 3;
      else if (effectiveX > 3.5)
        octave = 8;
      else if (effectiveX > 2.5)
        octave = 7;
      else if (effectiveX > 1.5)
        octave = 6;
      else if (effectiveX > 0.7)
        octave = 5;

      final baseNote = 12 * (octave + 1);

      // Stop all other notes if they are not the predicted one
      // This is a monophonic implementation for ML (one gesture = one note)
      // To do polyphonic, we'd need multi-label classification or multiple classifiers.
      for (var note in List<int>.from(_activeNotes)) {
        if (noteIndex == null || note != baseNote + noteIndex) {
          _handleNote(false, note);
        }
      }

      if (noteIndex != null) {
        _handleNote(true, baseNote + noteIndex);
      }

      return; // Skip legacy logic
    }

    // Legacy Threshold Logic
    // Apply IMU Calibration Offsets
    final offsets = _settings.accelOffsets;
    final effectiveX = data.accelX - offsets[0];
    // ... rest of existing logic
    // Extended Simulation Mapping:
    // -4.0 -> 0, -3.0 -> 1, -2.0 -> 2, -0.7 -> 3
    // 0.0 -> 4
    // 0.7 -> 5, 2.0 -> 6, 3.0 -> 7, 4.0 -> 8
    int octave = 4;

    if (effectiveX <= -3.5) {
      octave = 0;
    } else if (effectiveX <= -2.5)
      octave = 1;
    else if (effectiveX <= -1.5)
      octave = 2;
    else if (effectiveX < -0.7)
      octave = 3;
    else if (effectiveX > 3.5)
      octave = 8;
    else if (effectiveX > 2.5)
      octave = 7;
    else if (effectiveX > 1.5)
      octave = 6;
    else if (effectiveX > 0.7)
      octave = 5;

    final baseNote = 12 * (octave + 1); // MIDI C is 12 * (octave + 1) usually

    // Map fingers to notes (C, D, E, F, G)
    // Use thresholds from SettingsProvider
    final thresholds = _settings.sensorThresholds;
    _handleNote(data.flex1 > thresholds[0], baseNote + 0); // C
    _handleNote(data.flex2 > thresholds[1], baseNote + 2); // D
    _handleNote(data.flex3 > thresholds[2], baseNote + 4); // E
    _handleNote(data.flex4 > thresholds[3], baseNote + 5); // F
    _handleNote(data.flex5 > thresholds[4], baseNote + 7); // G
  }

  void _handleNote(bool isPressed, int note) {
    if (isPressed) {
      if (!_activeNotes.contains(note)) {
        AudioManager().playNote(note);
        _activeNotes.add(note);
        if (_settings.hapticFeedbackEnabled) {
          HapticFeedback.lightImpact();
        }
      }
    } else {
      if (_activeNotes.contains(note)) {
        AudioManager().stopNote(note);
        _activeNotes.remove(note);
      }
    }
  }

  void _stopAllNotes() {
    for (var note in _activeNotes) {
      AudioManager().stopNote(note);
    }
    _activeNotes.clear();
  }

  @override
  void dispose() {
    _adapterStateSub.cancel();
    _dataSub?.cancel();
    _scanSub?.cancel();
    _simulationTimer?.cancel();
    _stopAllNotes();
    super.dispose();
  }
}
