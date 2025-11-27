import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class GestureSample {
  final List<double>
  features; // [flex1, flex2, flex3, flex4, flex5, accelX, accelY, accelZ]
  final String noteLabel; // "C", "D", "No Note", etc.

  GestureSample({required this.features, required this.noteLabel});

  Map<String, dynamic> toJson() => {
    'features': features,
    'noteLabel': noteLabel,
  };

  factory GestureSample.fromJson(Map<String, dynamic> json) {
    return GestureSample(
      features: List<double>.from(json['features']),
      noteLabel: json['noteLabel'],
    );
  }
}

class MLService with ChangeNotifier {
  List<GestureSample> _samples = [];
  List<GestureSample> get samples => _samples;

  MLService() {
    _loadSamples();
  }

  Future<void> addSample(GestureSample sample) async {
    _samples.add(sample);
    notifyListeners();
    await _saveSamples();
  }

  Future<void> clearData() async {
    _samples.clear();
    notifyListeners();
    await _saveSamples();
  }

  Future<void> _saveSamples() async {
    final prefs = await SharedPreferences.getInstance();
    final String encoded = jsonEncode(_samples.map((e) => e.toJson()).toList());
    await prefs.setString('ml_samples', encoded);
  }

  Future<void> _loadSamples() async {
    final prefs = await SharedPreferences.getInstance();
    final String? encoded = prefs.getString('ml_samples');
    if (encoded != null) {
      final List<dynamic> decoded = jsonDecode(encoded);
      _samples = decoded.map((e) => GestureSample.fromJson(e)).toList();
    }
  }

  // k-Nearest Neighbors Prediction
  String predict(List<double> features, {int k = 1}) {
    if (_samples.isEmpty) return "No Note";

    // Calculate distances
    List<MapEntry<double, String>> distances = [];
    for (var sample in _samples) {
      double dist = _euclideanDistance(features, sample.features);
      distances.add(MapEntry(dist, sample.noteLabel));
    }

    // Sort by distance (ascending)
    distances.sort((a, b) => a.key.compareTo(b.key));

    // Get top k neighbors
    int count = min(k, distances.length);
    Map<String, int> votes = {};
    for (int i = 0; i < count; i++) {
      String label = distances[i].value;
      votes[label] = (votes[label] ?? 0) + 1;
    }

    // Return label with most votes
    var sortedVotes = votes.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sortedVotes.first.key;
  }

  double _euclideanDistance(List<double> a, List<double> b) {
    double sum = 0;
    for (int i = 0; i < a.length; i++) {
      sum += pow(a[i] - b[i], 2);
    }
    return sqrt(sum);
  }
}
