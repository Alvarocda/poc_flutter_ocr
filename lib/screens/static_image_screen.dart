import 'dart:typed_data';

import 'package:flutter/material.dart';

///
///
///
class StaticImageScreen extends StatefulWidget {
  final Uint8List image;
  final List<CustomPaint> detectionsRect;

  const StaticImageScreen({required this.image, required this.detectionsRect, Key? key}) : super(key: key);

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
          Image.memory(
            widget.image,
          ),
          ...widget.detectionsRect,
        ],
      ),
    );
  }
}
