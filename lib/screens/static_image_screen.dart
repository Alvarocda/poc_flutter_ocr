import 'dart:io';
import 'dart:typed_data';

import 'package:alvaro/models/detection.dart';
import 'package:alvaro/models/plate.dart';
import 'package:alvaro/screens/plate_screen.dart';
import 'package:alvaro/utils/image_utils.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
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
  final RegExp plateRegex = RegExp('[a-zA-Z]{3}[0-9][A-Za-z0-9][0-9]{2}', caseSensitive: false);

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
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => PlateScreen(
            plates: plates,
          ),
        ),
      );
      await deleteAllCachedImages();
    }
  }

  ///
  ///
  ///
  Future<Plate?> _extractPlate(Detection detection) async {
    img.Image? plateImage = img.decodeImage(widget.image);

    // img.grayscale(plateImage!);

    double width = detection.x2 - detection.x1;
    double height = detection.y2 - detection.y1;

    plateImage = img.copyCrop(
      plateImage!,
      detection.x1.toInt() - 10,
      detection.y1.toInt() - 10,
      width.toInt() + 20,
      height.toInt() + 20,
    );

    // plateImage = img.copyResize(
    //   plateImage,
    //   width: targetWidth.toInt(),
    //   height: targetHeight.toInt(),
    //   interpolation: img.Interpolation.cubic,
    // );

    // img.gaussianBlur(plateImage, 5);

    File file = await saveFile(plateImage);

    InputImage inputImage = InputImage.fromFile(file);

    TextRecognizer textRecognizer = TextRecognizer();

    RecognizedText recognizedText = await textRecognizer.processImage(inputImage);

    String? licensePlate = extractLicensePlate(recognizedText);

    await textRecognizer.close();

    if (licensePlate == null) {
      return null;
    }

    return Plate(
      plate: licensePlate,
      imageBytes: Uint8List.fromList(img.encodeJpg(plateImage)),
      imageFile: file,
    );
  }

  ///
  ///
  ///
  Uint8List imageWithRects() {
    img.Image? image = img.decodeImage(widget.image.toList());
    for (Detection detection in widget.detections) {
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

  ///
  ///
  ///
  String? extractLicensePlate(RecognizedText recognizedText) {
    // if the detected plate does not meet the minimum requirements for a license plate, discard the text
    if (recognizedText.text.isEmpty || recognizedText.text.length < 7) {
      return null;
    }
    String rawText =
        recognizedText.text.replaceAll('\n', '').replaceAll(' ', '').replaceAll('-', '').replaceAll('.', '');
    if (plateRegex.hasMatch(rawText)) {
      RegExpMatch? match = plateRegex.firstMatch(rawText);
      return match?.group(0);
    }
    return recognizedText.text;
  }
}
