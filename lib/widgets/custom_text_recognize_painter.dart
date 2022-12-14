import 'dart:ui';
import 'dart:ui' as ui;

import 'package:alvaro/utils/coordinates_translator.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

///
///
///
class CustomTextRecognizerPainter extends CustomPainter {
  ///
  ///
  ///
  CustomTextRecognizerPainter(this.rect, this.absoluteImageSize, this.rotation, this.tag);

  final Rect rect;
  final Size absoluteImageSize;
  final InputImageRotation rotation;
  final String tag;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..color = Colors.lightGreenAccent;

    final Paint background = Paint()..color = const Color(0x99000000);

    final ParagraphBuilder builder = ParagraphBuilder(
      ParagraphStyle(textAlign: TextAlign.left, fontSize: 16, textDirection: TextDirection.ltr),
    );
    builder.pushStyle(ui.TextStyle(color: Colors.lightGreenAccent, background: background));
    builder.addText(tag);
    builder.pop();

    final double left = translateX(rect.left, rotation, size, absoluteImageSize);
    final double top = translateY(rect.top, rotation, size, absoluteImageSize);
    final double right = translateX(rect.right, rotation, size, absoluteImageSize);
    final double bottom = translateY(rect.bottom, rotation, size, absoluteImageSize);

    canvas.drawRect(
      Rect.fromLTRB(left, top, right, bottom),
      paint,
    );

    canvas.drawParagraph(
      builder.build()
        ..layout(ParagraphConstraints(
          width: right - left,
        )),
      Offset(left, top),
    );
  }

  @override
  bool shouldRepaint(CustomTextRecognizerPainter oldDelegate) {
    return oldDelegate.rect != rect;
  }
}
