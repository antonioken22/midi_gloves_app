import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsProvider with ChangeNotifier {
  List<int> _sensorThresholds = [50, 50, 50, 50, 50];
  bool _hapticFeedbackEnabled = false;
  bool _isMLMode = false;

  List<int> get sensorThresholds => _sensorThresholds;
  bool get hapticFeedbackEnabled => _hapticFeedbackEnabled;
  bool get isMLMode => _isMLMode;

  SettingsProvider() {
    _loadSettings();
  }

  List<double> _accelOffsets = [0.0, 0.0, 0.0];
  List<double> get accelOffsets => _accelOffsets;

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final thresholds = prefs.getStringList('sensorThresholds');
    if (thresholds != null && thresholds.length == 5) {
      _sensorThresholds = thresholds.map((e) => int.parse(e)).toList();
    }
    _hapticFeedbackEnabled = prefs.getBool('hapticFeedbackEnabled') ?? false;
    _isMLMode = prefs.getBool('isMLMode') ?? false;

    final offsets = prefs.getStringList('accelOffsets');
    if (offsets != null && offsets.length == 3) {
      _accelOffsets = offsets.map((e) => double.parse(e)).toList();
    }
    notifyListeners();
  }

  Future<void> setSensorThreshold(int index, int value) async {
    if (index >= 0 && index < 5) {
      _sensorThresholds[index] = value;
      notifyListeners();
      _saveSettings();
    }
  }

  Future<void> resetThresholds() async {
    _sensorThresholds = [50, 50, 50, 50, 50];
    notifyListeners();
    _saveSettings();
  }

  Future<void> setHapticFeedback(bool enabled) async {
    _hapticFeedbackEnabled = enabled;
    notifyListeners();
    _saveSettings();
  }

  Future<void> setMLMode(bool enabled) async {
    _isMLMode = enabled;
    notifyListeners();
    _saveSettings();
  }

  Future<void> setAccelOffsets(double x, double y, double z) async {
    _accelOffsets = [x, y, z];
    notifyListeners();
    _saveSettings();
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      'sensorThresholds',
      _sensorThresholds.map((e) => e.toString()).toList(),
    );
    await prefs.setBool('hapticFeedbackEnabled', _hapticFeedbackEnabled);
    await prefs.setStringList(
      'accelOffsets',
      _accelOffsets.map((e) => e.toString()).toList(),
    );
    await prefs.setBool('isMLMode', _isMLMode);
  }
}
