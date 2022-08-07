import 'dart:typed_data';

import 'package:flutter/material.dart';

///
///
///
class Plate {
  String plate;
  DateTime detectedAt = DateTime.now();
  Uint8List imageBytes;
  Rect highlightedArea;

  ///
  ///
  ///
  Plate({
    required this.plate,
    required this.imageBytes,
    required this.highlightedArea,
  });
}
