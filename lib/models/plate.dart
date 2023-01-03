import 'dart:typed_data';

import 'package:image_picker/image_picker.dart';

///
///
///
class Plate {
  String plate;
  DateTime detectedAt = DateTime.now();
  Uint8List imageBytes;
  XFile? xfile;

  ///
  ///
  ///
  Plate({
    required this.plate,
    required this.imageBytes,
    this.xfile,
  });
}
