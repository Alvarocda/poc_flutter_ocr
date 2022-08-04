import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class TextDetectorPainter extends CustomPainter {
  TextDetectorPainter(this.absoluteImageSize, this.recognizedLine);

  final Size absoluteImageSize;
  final TextLine recognizedLine;

  @override
  void paint(Canvas canvas, Size size) {
    final double scaleX = size.width / absoluteImageSize.width;
    final double scaleY = size.height / absoluteImageSize.height;

    Rect scaleRect(Rect container) {
      return Rect.fromLTRB(
        container.left * scaleX,
        container.top * scaleY,
        container.right * scaleX,
        container.bottom * scaleY,
      );
    }

    final Paint paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    for (TextElement element in recognizedLine.elements) {
      paint.color = Colors.green;
      canvas.drawRect(scaleRect(element.boundingBox), paint);
    }
  }

  @override
  bool shouldRepaint(TextDetectorPainter oldDelegate) {
    return oldDelegate.absoluteImageSize != absoluteImageSize || oldDelegate.recognizedLine != recognizedLine;
  }
}
