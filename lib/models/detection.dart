import 'package:flutter/material.dart';

///
///
///
class Detection {
  late double confidence;
  late double x1;
  late double x2;
  late double y1;
  late double y2;
  late CustomPaint rect;
  late String tag;

  ///
  ///
  ///
  Detection.fromMap(Map<String, dynamic> map) {
    confidence = map['confidence'];
    x1 = map['xmin'];
    x2 = map['xmax'];
    y1 = map['ymin'];
    y2 = map['ymax'];
    tag = map['name'];
  }
}
