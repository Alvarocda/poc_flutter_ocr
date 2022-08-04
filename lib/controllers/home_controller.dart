import 'dart:async';
import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:image_picker/image_picker.dart';

///
///
///
class HomeController {
  ///
  ///
  ///
  HomeController();

  late List<CameraDescription> _cameras;
  late CameraController cameraController;

  final ValueNotifier<bool> isCameraLoaded = ValueNotifier<bool>(false);
  final ValueNotifier<String> platesDetected = ValueNotifier<String>('');
  final StreamController<Rect> platesRect = StreamController<Rect>();
  bool _isProcessing = false;

  ///
  ///
  ///
  Future<void> initCamera() async {
    isCameraLoaded.value = false;
    _cameras = await availableCameras();
    cameraController = CameraController(
      _cameras.first,
      ResolutionPreset.max,
    );
    await cameraController.initialize();
    isCameraLoaded.value = true;
  }

  ///
  ///
  ///
  void startMonitoring() {
    cameraController.startImageStream(
      (CameraImage image) async {
        if (!_isProcessing) {
          InputImage inputImage = _getStreamInputImage(image);
          await _detectText(inputImage);
        }
      },
    );
  }

  ///
  ///
  ///
  InputImage _getStreamInputImage(CameraImage image) {
    // final Uint8List bytes = allBytes.done().buffer.asUint8List();
    final Uint8List bytes = Uint8List.fromList(
      image.planes.fold(
        <int>[],
        (List<int> previousValue, Plane element) =>
            previousValue..addAll(element.bytes),
      ),
    );

    final Size imageSize =
        Size(image.width.toDouble(), image.height.toDouble());

    final InputImageRotation imageRotation =
        InputImageRotationValue.fromRawValue(
                cameraController.description.sensorOrientation) ??
            InputImageRotation.rotation0deg;

    final InputImageFormat inputImageFormat =
        InputImageFormatValue.fromRawValue(image.format.raw) ??
            InputImageFormat.nv21;

    final List<InputImagePlaneMetadata> planeData = image.planes.map(
      (Plane plane) {
        return InputImagePlaneMetadata(
          bytesPerRow: plane.bytesPerRow,
          height: plane.height,
          width: plane.width,
        );
      },
    ).toList();

    final InputImageData inputImageData = InputImageData(
      size: imageSize,
      imageRotation: imageRotation,
      inputImageFormat: inputImageFormat,
      planeData: planeData,
    );

    return InputImage.fromBytes(bytes: bytes, inputImageData: inputImageData);
  }

  ///
  ///
  ///
  Future<void> getImage(ImageSource imageSource) async {
    ImagePicker imagePicker = ImagePicker();
    XFile? xFile = await imagePicker.pickImage(source: imageSource);
    if (xFile != null) {
      InputImage inputImage = InputImage.fromFilePath(xFile.path);
      await _detectText(inputImage);
    }
  }

  ///
  ///
  ///
  Future<void> _detectText(InputImage inputImage) async {
    _isProcessing = true;
    TextRecognizer textDetector = GoogleMlKit.vision.textRecognizer();
    RecognizedText recognizedText = await textDetector.processImage(inputImage);
    await textDetector.close();
    RegExp regexPlaca = RegExp(
      r'^[a-zA-Z]{3}[0-9][A-Za-z0-9][0-9]{2}$',
      caseSensitive: false,
    );
    StringBuffer plates = StringBuffer();
    print('TEXTO RECONHECIDO: ${recognizedText.text}');
    for (TextBlock block in recognizedText.blocks) {
      for (TextLine line in block.lines) {
        if (regexPlaca.hasMatch(line.text
            .replaceAll('-', '')
            .replaceAll(':', '')
            .replaceAll(' ', ''))) {
          plates.writeln(line.text);
          platesRect.add(line.boundingBox);
        }
      }
    }
    if (plates.isNotEmpty) {
      platesDetected.value = plates.toString();
    }
    _isProcessing = false;
  }
}
