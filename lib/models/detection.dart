import 'dart:typed_data';

import 'package:flutter/material.dart';

///
///
///
class Detection {
  late double confidence;
  late Uint8List image;
  late String tag;
  late double x1;
  late double x2;
  late double y1;
  late double y2;
  late CustomPaint rect;

  ///
  ///
  ///
  Detection.fromMap(Map<String, dynamic> map) {
    confidence = map['confidence'];
    image = map['image'];
    tag = map['tag'];
    x1 = map['box']['x1'];
    x2 = map['box']['x2'];
    y1 = map['box']['y1'];
    y2 = map['box']['y2'];
  }
}
