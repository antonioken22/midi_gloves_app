import 'dart:convert';

class GloveData {
  final int flex1, flex2, flex3, flex4, flex5;
  final double accelX, accelY, accelZ;

  GloveData({
    required this.flex1,
    required this.flex2,
    required this.flex3,
    required this.flex4,
    required this.flex5,
    required this.accelX,
    required this.accelY,
    required this.accelZ,
  });

  factory GloveData.fromJsonString(String jsonString) {
    try {
      final Map<String, dynamic> json = jsonDecode(jsonString);
      final List<dynamic> flexList = json['flex'] ?? [0, 0, 0, 0, 0];

      // Helper to safely get int from list
      int getFlex(int index) {
        if (flexList.length > index) {
          final val = flexList[index];
          if (val is int) return val;
          if (val is double) return val.toInt();
        }
        return 0;
      }

      // Helper to safely get double from json
      double getDouble(String key) {
        if (json.containsKey(key) && json[key] is num) {
          return (json[key] as num).toDouble();
        }
        return 0.0;
      }

      return GloveData(
        flex1: getFlex(0),
        flex2: getFlex(1),
        flex3: getFlex(2),
        flex4: getFlex(3),
        flex5: getFlex(4),
        accelX: getDouble('x'),
        accelY: getDouble('y'),
        accelZ: getDouble('z'),
      );
    } catch (e) {
      print("Error parsing GloveData from JSON: $e");
      print("Received string: $jsonString");
      return GloveData.zero();
    }
  }

  factory GloveData.zero() => GloveData(
    flex1: 0,
    flex2: 0,
    flex3: 0,
    flex4: 0,
    flex5: 0,
    accelX: 0,
    accelY: 0,
    accelZ: 0,
  );
}
