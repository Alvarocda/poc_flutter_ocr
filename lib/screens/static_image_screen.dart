import 'dart:typed_data';

import 'package:alvaro/models/detection.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;

///
///
///
class StaticImageScreen extends StatefulWidget {
  final Uint8List image;
  final List<Detection> detections;

  const StaticImageScreen({required this.image, required this.detections, Key? key}) : super(key: key);

  ///
  ///
  ///
  @override
  State<StaticImageScreen> createState() => _StaticImageScreenState();
}

///
///
///
class _StaticImageScreenState extends State<StaticImageScreen> {
  ///
  ///
  ///
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Resultado'),
      ),
      body: Stack(
        fit: StackFit.expand,
        alignment: Alignment.topCenter,
        children: <Widget>[
          Image.memory(imageWithRects()),
          // ...widget.detectionsRect,
        ],
      ),
    );
  }

  ///
  ///
  ///
  Uint8List imageWithRects() {
    img.Image? image = img.decodeImage(widget.image.toList());
    for (Detection detection in widget.detections) {
      img.drawRect(
        image!,
        detection.x1.toInt(),
        detection.y1.toInt(),
        detection.x2.toInt(),
        detection.y2.toInt(),
        0xFF00FF00,
      );
    }
    return Uint8List.fromList(img.encodeJpg(image!));
  }
}
