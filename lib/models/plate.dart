import 'dart:typed_data';

///
///
///
class Plate {
  String plate;
  DateTime detectedAt = DateTime.now();
  Uint8List imageBytes;

  ///
  ///
  ///
  Plate({
    required this.plate,
    required this.imageBytes,
  });
}
