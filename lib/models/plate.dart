import 'dart:io';
import 'dart:typed_data';

import 'package:image_picker/image_picker.dart';

///
///
///
class Plate {
  String plate;
  DateTime detectedAt = DateTime.now();
  Uint8List imageBytes;
  File? imageFile;
  XFile? xfile;

  ///
  ///
  ///
  Plate({
    required this.plate,
    required this.imageBytes,
    this.imageFile,
    this.xfile,
  });
}
