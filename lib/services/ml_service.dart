import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class GestureSample {
  final List<List<double>>
  features; // List of frames: [ [flex1...accelZ], [flex1...accelZ], ... ]
  final String noteLabel; // "C", "D", "No Note", etc.

  GestureSample({required this.features, required this.noteLabel});

  Map<String, dynamic> toJson() => {
    'features': features,
    'noteLabel': noteLabel,
  };

  factory GestureSample.fromJson(Map<String, dynamic> json) {
    // Handle migration from old format (List<double>) to new format (List<List<double>>)
    // If the JSON has a 1D list, wrap it in a 2D list or discard (simplest is clear old data).
    // For safety, let's assume valid new structure or robustly parse.

    var rawFeatures = json['features'];
    List<List<double>> parsedFeatures = [];

    if (rawFeatures is List) {
      if (rawFeatures.isNotEmpty && rawFeatures[0] is List) {
        // It's already 2D
        parsedFeatures = (rawFeatures)
            .map((frame) => List<double>.from(frame))
            .toList();
      } else if (rawFeatures.isNotEmpty && rawFeatures[0] is num) {
        // It's 1D (legacy snapshot), update to 1-frame sequence
        parsedFeatures = [List<double>.from(rawFeatures)];
      }
    }

    return GestureSample(
      features: parsedFeatures,
      noteLabel: json['noteLabel'],
    );
  }
}

class MLService with ChangeNotifier {
  List<GestureSample> _samples = [];
  List<GestureSample> get samples => _samples;

  // DTW parameters
  static const int kWindowSize =
      40; // Approx 1-2 seconds of data depending on sample rate

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

  Future<void> clearDataForLabel(String label) async {
    _samples.removeWhere((s) => s.noteLabel == label);
    notifyListeners();
    await _saveSamples();
  }

  Future<void> _saveSamples() async {
    final prefs = await SharedPreferences.getInstance();
    final String encoded = jsonEncode(_samples.map((e) => e.toJson()).toList());
    await prefs.setString('ml_samples_dtw', encoded); // New key for new format
  }

  Future<void> _loadSamples() async {
    final prefs = await SharedPreferences.getInstance();
    // Try load new format
    String? encoded = prefs.getString('ml_samples_dtw');

    // If empty, try migrating legacy (optional, but good UX)
    if (encoded == null) {
      final legacy = prefs.getString('ml_samples');
      if (legacy != null) {
        // We could migrate, but honestly for a big switch like this, starting fresh is safer/cleaner
        // effectively ignoring old data to prevent crashes.
        // Let's just start fresh.
        _samples = [];
        return;
      }
    }

    if (encoded != null) {
      try {
        final List<dynamic> decoded = jsonDecode(encoded);
        _samples = decoded.map((e) => GestureSample.fromJson(e)).toList();
      } catch (e) {
        print("Error loading samples: $e");
        _samples = [];
      }
    }
  }

  // --- Dynamic Time Warping (DTW) Prediction ---

  /// Predicts the gesture based on a sequence of frames
  String predictSequence(List<List<double>> inputSequence) {
    if (_samples.isEmpty) return "No Note";
    // We assume inputSequence is roughly the length of our gestures.
    // If significantly shorter, wait.

    if (inputSequence.length < 5) return "No Note"; // Too short

    double minDistance = double.infinity;
    String bestLabel = "No Note";

    for (var sample in _samples) {
      // Optimization: Skip if length mismatch is massive (e.g. searching for a 10s gesture in a 1s recording)
      // DTW handles length diffs, but within reason.

      double dist = _dtwDistance(inputSequence, sample.features);

      // Simple normalization by path length to make long/short gestures comparable
      double normalizedDist =
          dist / (inputSequence.length + sample.features.length);

      if (normalizedDist < minDistance) {
        minDistance = normalizedDist;
        bestLabel = sample.noteLabel;
      }
    }

    // Thresholding (Tunable)
    // If the closest match is still very far, return "No Note"
    // For normalized distance, a value < 0.5-1.0 is usually good for normalized Euclidean
    // Let's pick a conservative threshold to start.
    if (minDistance > 2.0) {
      return "No Note";
    }

    return bestLabel;
  }

  double _dtwDistance(List<List<double>> s1, List<List<double>> s2) {
    int n = s1.length;
    int m = s2.length;

    // DTW Matrix
    // Initialize with infinity
    List<List<double>> dtw = List.generate(
      n + 1,
      (_) => List.filled(m + 1, double.infinity),
    );
    dtw[0][0] = 0;

    for (int i = 1; i <= n; i++) {
      for (int j = 1; j <= m; j++) {
        double cost = _euclideanDistance(s1[i - 1], s2[j - 1]);
        dtw[i][j] =
            cost +
            minimum(
              dtw[i - 1][j], // insertion
              dtw[i][j - 1], // deletion
              dtw[i - 1][j - 1], // match
            );
      }
    }
    return dtw[n][m];
  }

  double minimum(double a, double b, double c) {
    return min(a, min(b, c));
  }

  double _euclideanDistance(List<double> a, List<double> b) {
    double sum = 0;
    // Lengths should match (8 sensors)
    for (int i = 0; i < min(a.length, b.length); i++) {
      sum += pow(a[i] - b[i], 2);
    }
    return sqrt(sum);
  }
}
