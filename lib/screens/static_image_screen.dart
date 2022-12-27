import 'dart:io';
import 'dart:typed_data';

import 'package:alvaro/models/detection.dart';
import 'package:alvaro/models/plate.dart';
import 'package:alvaro/screens/plate_screen.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as pth;
import 'package:path_provider/path_provider.dart';

///
///
///
class StaticImageScreen extends StatefulWidget {
  final Uint8List image;
  final List<Detection> detections;

  const StaticImageScreen(
      {required this.image, required this.detections, Key? key})
      : super(key: key);

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
          Positioned(
            bottom: 0,
            child: ElevatedButton(
              child: const Text('Extract Plate text'),
              onPressed: () {
                extractAllPlates();
              },
            ),
          )
          // ...widget.detectionsRect,
        ],
      ),
    );
  }

  Future<void> extractAllPlates() async {
    List<Plate> plates = <Plate>[];
    for (Detection detection in widget.detections) {
      try {
        Plate? plate = await _extractPlate(detection);
        if (plate != null) {
          plates.add(plate);
        }
      } catch (e) {
        print('Error $e');
      }
    }
    if (plates.isNotEmpty) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => PlateScreen(
            plates: plates,
          ),
        ),
      );
    }
  }

  ///
  ///
  ///
  Future<Plate?> _extractPlate(Detection detection) async {
    img.Image? plateImage = img.decodeImage(widget.image);

    plateImage = img.grayscale(plateImage!);

    double width = detection.x2 - detection.x1;
    double height = detection.y2 - detection.y1;

    if (height <= 32 || width <= 32) {
      plateImage = img.copyCrop(
        plateImage,
        detection.x1.toInt() - 20,
        detection.y1.toInt() - 20,
        width.toInt() + 30,
        height.toInt() + 30,
      );
    } else {
      plateImage = img.copyCrop(
        plateImage,
        detection.x1.toInt() - 10,
        detection.y1.toInt() - 10,
        width.toInt() + 20,
        height.toInt() + 20,
      );
    }

    width += width * 2;
    height += height * 2;

    plateImage = img.copyResize(plateImage,
        width: width.toInt(), height: height.toInt());

    // img.contrast(plateImage, 500);
    // plateImage = img.gaussianBlur(plateImage, 2);
    Uint8List imageBytes = Uint8List.fromList(img.encodePng(plateImage));

    Directory tempDir = await getTemporaryDirectory();

    File file = await File(pth.join(tempDir.path, 'ocr${tempDir.hashCode}.png'))
        .create(recursive: true);

    if (!tempDir.existsSync()) {
      await tempDir.create(recursive: true);
    }

    if (file.existsSync()) {
      await file.delete();
    }

    file = await file.writeAsBytes(imageBytes);

    InputImage inputImage = InputImage.fromFile(file);

    TextRecognizer textRecognizer = TextRecognizer();

    RecognizedText recognizedText =
        await textRecognizer.processImage(inputImage);

    await textRecognizer.close();

    return Plate(
      plate: recognizedText.text,
      imageBytes: imageBytes,
      imageFile: file,
    );
  }

  ///
  ///
  ///
  Uint8List imageWithRects() {
    img.Image? image = img.decodeImage(widget.image.toList());
    for (Detection detection in widget.detections) {
      // img.drawRect(
      //   image!,
      //   detection.x1.toInt(),
      //   detection.y1.toInt(),
      //   detection.x2.toInt(),
      //   detection.y2.toInt(),
      //   0xFF00FF00,
      // );
      for (int i = 0; i < 10; i++) {
        img.drawRect(
          image!,
          detection.x1.toInt() - i,
          detection.y1.toInt() - i,
          detection.x2.toInt() + i,
          detection.y2.toInt() + i,
          0xFF00FF00,
        );
      }
    }
    return Uint8List.fromList(img.encodeJpg(image!));
  }

// Uint8List convertGreytoYuv(List<int> grey, int width, int height) {
//   int size = width * height;
//   List<int> yuvRaw = List.empty(growable: true);
//   yuvRaw.addAll(grey);
//   yuvRaw.addAll(List.filled(size ~/ 2, 0));
//   return Uint8List.fromList(yuvRaw);
// }
}
