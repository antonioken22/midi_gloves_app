import 'dart:typed_data';

class GloveData {
  final int flex1, flex2, flex3, flex4, flex5;
  final int accelX, accelY, accelZ;

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

  factory GloveData.fromBytes(List<int> bytes) {
    if (bytes.length < 8) return GloveData.zero();
    final byteData = ByteData.sublistView(Uint8List.fromList(bytes));
    return GloveData(
      flex1: byteData.getUint8(0),
      flex2: byteData.getUint8(1),
      flex3: byteData.getUint8(2),
      flex4: byteData.getUint8(3),
      flex5: byteData.getUint8(4),
      accelX: byteData.getUint8(5),
      accelY: byteData.getUint8(6),
      accelZ: byteData.getUint8(7),
    );
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
