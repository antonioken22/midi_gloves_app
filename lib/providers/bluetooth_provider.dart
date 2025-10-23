import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/glove_data.dart';

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
  }

  Future<void> _requestPermissions() async {
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
      _gloveData = GloveData.zero();
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
          _gloveData = GloveData.fromBytes(value);
          notifyListeners();
        });
      }
    } catch (e) {
      print("ERROR LISTENING TO DATA: $e");
    }
  }

  @override
  void dispose() {
    _adapterStateSub.cancel();
    _dataSub?.cancel();
    _scanSub?.cancel();
    super.dispose();
  }
}
