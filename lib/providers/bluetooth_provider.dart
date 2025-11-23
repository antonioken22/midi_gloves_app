import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/glove_data.dart';
import '../services/audio_manager.dart';

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

  BluetoothProvider() {
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

  void startSimulation() {
    if (_isSimulating) return;
    _isSimulating = true;
    notifyListeners();

    _simulationTimer = Timer.periodic(const Duration(milliseconds: 100), (
      timer,
    ) {
      // Simulate random flex values (0-100)
      // and some accelerometer movement
      // We'll make them fluctuate a bit to look "alive"
      final now = DateTime.now().millisecondsSinceEpoch;

      // Simple sine wave for accel to simulate tilting
      final accelY = 10.0 * (0.5 + 0.5 * sin(now / 1000.0)); // 0 to 10

      _gloveData = GloveData(
        flex1: (50 + 50 * sin(now / 500.0)).toInt().abs() % 100,
        flex2: (50 + 50 * cos(now / 600.0)).toInt().abs() % 100,
        flex3: (50 + 50 * sin(now / 700.0)).toInt().abs() % 100,
        flex4: (50 + 50 * cos(now / 800.0)).toInt().abs() % 100,
        flex5: (50 + 50 * sin(now / 900.0)).toInt().abs() % 100,
        accelX: 0,
        accelY: accelY, // Varying Y for octave shift simulation
        accelZ: 9.8,
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
    // Determine Octave
    int octave = 4;
    if (data.accelY < 3)
      octave = 3;
    else if (data.accelY > 7)
      octave = 5;

    final baseNote = 12 * (octave + 1); // MIDI C is 12 * (octave + 1) usually

    // Map fingers to notes (C, D, E, F, G)
    _handleNote(data.flex1 > 50, baseNote + 0); // C
    _handleNote(data.flex2 > 50, baseNote + 2); // D
    _handleNote(data.flex3 > 50, baseNote + 4); // E
    _handleNote(data.flex4 > 50, baseNote + 5); // F
    _handleNote(data.flex5 > 50, baseNote + 7); // G
  }

  void _handleNote(bool isPressed, int note) {
    if (isPressed) {
      if (!_activeNotes.contains(note)) {
        AudioManager().playNote(note);
        _activeNotes.add(note);
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
