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
  Future<img.Image> _prepareImage(Detection detection, int radius) async {
    img.Image? plateImage = img.decodeImage(widget.image);

    // img.grayscale(plateImage!);

    double width = detection.x2 - detection.x1;
    double height = detection.y2 - detection.y1;

    return img.copyCrop(
      plateImage!,
      detection.x1.toInt() - radius,
      detection.y1.toInt() - radius,
      width.toInt() + radius + 10,
      height.toInt() + radius + 10,
    );
  }

  ///
  ///
  ///
  Future<Plate?> _extractPlate(Detection detection) async {
    int radius = 0;

    img.Image plateImage = await _prepareImage(detection, radius);
    File file = await saveFile(plateImage);

    InputImage inputImage = InputImage.fromFile(file);

    TextRecognizer textRecognizer = TextRecognizer();

    RecognizedText recognizedText = await textRecognizer.processImage(inputImage);

    String? licensePlate = extractLicensePlate(recognizedText);
    int attempts = 0;
    while (licensePlate == null) {
      radius += 10;
      img.Image plateImage = await _prepareImage(detection, radius);
      file = await saveFile(plateImage);

      InputImage inputImage = InputImage.fromFile(file);
      recognizedText = await textRecognizer.processImage(inputImage);
      licensePlate = extractLicensePlate(recognizedText);
      if (licensePlate != null) {
        break;
      }
      attempts++;
      if (attempts == 7) {
        break;
      }
    }
    print('Tentativas: $attempts');

    await textRecognizer.close();

    if (licensePlate == null) {
      return null;
    }

    return Plate(
      plate: licensePlate.toUpperCase(),
      imageBytes: await file.readAsBytes(),
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
    String rawText = normalizePlate(recognizedText.text);
    if (plateRegex.hasMatch(rawText)) {
      RegExpMatch? match = plateRegex.firstMatch(rawText);
      return match?.group(0);
    } else {
      int elementIndex = 0;
      for (TextBlock block in recognizedText.blocks) {
        for (TextLine line in block.lines) {
          elementIndex = 0;
          for (TextElement element in line.elements) {
            String detectedPlate = normalizePlate(element.text);
            // dev.debugger(when: detectedPlate == 'XAS');
            // dev.debugger(when: detectedPlate == '4550');

            /// If the text is not exactly 7 characters long, it will try to concatenate the text of the previous
            /// element with the current element and check if the junction of the two forms a valid plate.
            /// As the algorithm is working with TextElements, it ends up splitting into different elements when it
            /// detects a space in the middle of the plate.
            if (detectedPlate.length == 7) {
              if (isValidPlate(detectedPlate)) {
                return detectedPlate;
              } else {
                String formatedPlate = formatPlate(detectedPlate);
                if (isValidPlate(formatedPlate)) {
                  return formatedPlate;
                }
              }

              /// If the text in the current element has less than 7 letters, it will check if the text size is 4 characters
              /// and if it is composed of 4 numbers, if it is composed of 4 numbers, it will check if the text in the
              /// previous element is composed of 3 letters, if both conditions are true, the algorithm will understand
              /// that it can be a plate and will assemble a String with the junction of the two.
            } else if (detectedPlate.length == 4) {
              if (elementIndex == 0) {
                return null;
              }
              TextElement lastTextElement = line.elements[elementIndex - 1];
              if (RegExp('[a-zA-Z]{3}').hasMatch(lastTextElement.text)) {
                String detectedPlate = '${lastTextElement.text}${element.text}';
                if (detectedPlate.length != 7) {
                  elementIndex++;
                  continue;
                }

                detectedPlate = normalizePlate(detectedPlate);

                if (isValidPlate(detectedPlate)) {
                  return detectedPlate;
                } else {
                  String formatedPlate = formatPlate(detectedPlate);
                  if (isValidPlate(formatedPlate)) {
                    return formatedPlate;
                  }
                }
              }
            } else {
              print('Discarded plate: ${element.text}');
            }
            elementIndex++;
          }
        }
      }
    }
    return null;
  }

  ///
  ///
  ///
  String normalizePlate(String plate) => plate
      .trim()
      .replaceAll('\n', '')
      .replaceAll(' ', '')
      .replaceAll('-', '')
      .replaceAll('.', '')
      .replaceAll(':', '')
      .replaceAll('·', '');

  ///
  ///
  ///
  bool isValidPlate(String plate) => plateRegex.hasMatch(plate);

  ///
  ///
  ///
  String formatPlate(String plate) {
    String firstPart = plate.substring(0, 3).toUpperCase();
    String secondPart = plate.substring(3, 7).toUpperCase();
    String formatedSecondPart = '';
    if (!RegExp('[a-zA-Z]{3}').hasMatch(firstPart)) {
      firstPart = firstPart
          .replaceAll('0', 'O')
          .replaceAll('1', 'I')
          .replaceAll('6', 'G')
          .replaceAll('8', 'B')
          .replaceAll('2', 'Z')
          .replaceAll('11', 'H')
          .replaceAll('5', 'S')
          .replaceAll('|', 'I');
    }
    if (!RegExp('[0-9][A-Za-z0-9][0-9]{2}').hasMatch(secondPart)) {
      List<String> secondPartLetters = secondPart.split('');
      int letterAux = 1;
      StringBuffer newSecondPart = StringBuffer();
      for (String letter in secondPartLetters) {
        if (RegExp('[0-9]').hasMatch(letter)) {
          newSecondPart.write(letter);
        } else {
          letter = letter
              .replaceAll('O', '0')
              .replaceAll('T', '1')
              .replaceAll('Z', '2')
              .replaceAll('S', '5')
              .replaceAll('|', '1');
          if (letterAux != 2) {
            letter = letter
                .replaceAll('H', '11')
                .replaceAll('I', '1')
                .replaceAll('B', '8')
                .replaceAll('G', '6')
                .replaceAll('|', 'I');
          }
          newSecondPart.write(letter);
        }
        letterAux++;
      }
      formatedSecondPart = newSecondPart.toString();
    }
    print('First part: $firstPart - Second Part $formatedSecondPart');

    return '${firstPart}${formatedSecondPart}';
  }
}
