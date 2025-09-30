import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/glove_data.dart';

class BluetoothProvider with ChangeNotifier {
  BluetoothDevice? _connectedDevice;
  GloveData _gloveData = GloveData.zero();
  bool _isScanning = false;
  final Map<String, ScanResult> _scanResults = {};
  BluetoothAdapterState _adapterState = BluetoothAdapterState.unknown;
  late StreamSubscription<BluetoothAdapterState> _adapterStateSub;

  BluetoothDevice? get connectedDevice => _connectedDevice;
  GloveData get gloveData => _gloveData;
  bool get isScanning => _isScanning;
  List<ScanResult> get scanResults =>
      _scanResults.values.toList()..sort((a, b) => b.rssi.compareTo(a.rssi));
  BluetoothAdapterState get adapterState => _adapterState;

  StreamSubscription<List<int>>? _dataSub;

  final Guid _serviceUuid = Guid("4fafc201-1fb5-459e-8fcc-c5c9c331914b");
  final Guid _characteristicUuid = Guid("beb5483e-36e1-4688-b7f5-ea07361b26a8");

  BluetoothProvider() {
    _adapterStateSub = FlutterBluePlus.adapterState.listen((state) {
      _adapterState = state;
      notifyListeners();
    });

    FlutterBluePlus.isScanning.listen((scanning) {
      _isScanning = scanning;
      notifyListeners();
    });
    FlutterBluePlus.scanResults.listen((results) {
      for (var r in results) {
        _scanResults[r.device.remoteId.str] = r;
      }
      notifyListeners();
    });
  }

  Future<void> toggleScan() async {
    if (_adapterState != BluetoothAdapterState.on) {
      print("Bluetooth is off. Cannot scan.");
      return;
    }

    if (_isScanning) {
      await FlutterBluePlus.stopScan();
    } else {
      var statuses = await [
        Permission.bluetoothScan,
        Permission.bluetoothConnect,
      ].request();
      if (statuses[Permission.bluetoothScan]!.isGranted &&
          statuses[Permission.bluetoothConnect]!.isGranted) {
        _scanResults.clear();
        notifyListeners();
        await FlutterBluePlus.startScan(timeout: const Duration(seconds: 10));
      }
    }
  }

  Future<bool> connect(BluetoothDevice device) async {
    await FlutterBluePlus.stopScan();
    try {
      await device.connect(
        license: License.free,
        timeout: const Duration(seconds: 15),
      );
      _connectedDevice = device;
      _listenToGloveData();
      notifyListeners();
      return true;
    } catch (e) {
      print("ERROR CONNECTING: $e");
      return false;
    }
  }

  Future<void> disconnect() async {
    await _dataSub?.cancel();
    _dataSub = null;
    await _connectedDevice?.disconnect();
    _connectedDevice = null;
    _gloveData = GloveData.zero();
    notifyListeners();
  }

  Future<void> _listenToGloveData() async {
    if (_connectedDevice == null) return;
    try {
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
    super.dispose();
  }
}
