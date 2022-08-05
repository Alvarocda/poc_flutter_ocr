import 'dart:async';
import 'dart:typed_data';

import 'package:alvaro/widgets/custom_text_recognize_painter.dart';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
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
  final ValueNotifier<String> textDetected = ValueNotifier<String>('');
  final StreamController<List<CustomPaint>?> platesWidget = StreamController<List<CustomPaint>?>();
  final ValueNotifier<bool> isStreaming = ValueNotifier<bool>(false);
  bool _isProcessing = false;
  TextRecognizer? _textRecognizer = TextRecognizer();
  final RegExp regexPlaca = RegExp('[a-zA-Z]{3}[0-9][A-Za-z0-9][0-9]{2}', caseSensitive: false);

  ///
  ///
  ///
  Future<void> initCamera() async {
    isCameraLoaded.value = false;
    _cameras = await availableCameras();
    cameraController = CameraController(
      _cameras.first,
      ResolutionPreset.low,
      imageFormatGroup: ImageFormatGroup.yuv420,
      enableAudio: false,
    );

    await cameraController.initialize();
    isCameraLoaded.value = true;
  }

  ///
  ///
  ///
  Future<void> startMonitoring() async {
    if (isStreaming.value) {
      await cameraController.stopImageStream();
      await _textRecognizer!.close();
      _textRecognizer = null;
      platesWidget.add(null);
      _isProcessing = false;
      isStreaming.value = false;
    } else {
      await cameraController.startImageStream(
        (CameraImage image) async {
          isStreaming.value = true;
          if (!_isProcessing) {
            InputImage? inputImage = _getStreamInputImage(image);
            if (inputImage != null) {
              platesDetected.value = await _detectText(inputImage) ?? '';
            }
          }
        },
      );
    }
  }

  ///
  ///
  ///
  InputImage? _getStreamInputImage(CameraImage image) {
    final Uint8List bytes = Uint8List.fromList(
      image.planes.fold(
        <int>[],
        (List<int> previousValue, Plane element) => previousValue..addAll(element.bytes),
      ),
    );

    final Size imageSize = Size(image.width.toDouble(), image.height.toDouble());

    final CameraDescription camera = _cameras.first;
    final InputImageRotation? imageRotation = InputImageRotationValue.fromRawValue(camera.sensorOrientation);
    if (imageRotation == null) {
      return null;
    }

    final InputImageFormat? inputImageFormat = InputImageFormatValue.fromRawValue(image.format.raw);
    if (inputImageFormat == null) {
      return null;
    }

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
  Future<void> getGalleryImage() async {
    ImagePicker imagePicker = ImagePicker();
    XFile? xFile = await imagePicker.pickImage(source: ImageSource.gallery);
    if (xFile != null) {
      InputImage inputImage = InputImage.fromFilePath(xFile.path);
      platesDetected.value = await _detectText(inputImage) ?? '';
    }
  }

  ///
  ///
  ///
  Future<String?> _detectText(InputImage inputImage) async {
    _isProcessing = true;
    _textRecognizer ??= TextRecognizer();
    RecognizedText recognizedText = await _textRecognizer!.processImage(inputImage);

    textDetected.value = recognizedText.text;
    StringBuffer plates = StringBuffer();
    List<CustomPaint> customPaints = <CustomPaint>[];
    // print('TEXTO RECONHECIDO: ${recognizedText.text}');
    if (regexPlaca.hasMatch(
      recognizedText.text.trim().replaceAll(' ', '').replaceAll('-', '').replaceAll('.', ''),
    )) {
      int elementIndex = 0;
      for (TextBlock block in recognizedText.blocks) {
        for (TextLine line in block.lines) {
          elementIndex = 0;
          for (TextElement element in line.elements) {
            print('Text Element: ${element.text}');
            String detectedPlate = element.text.trim().replaceAll(' ', '').replaceAll('-', '').replaceAll('.', '');
            if (detectedPlate.length == 7) {
              _highlightDetectedPlate(detectedPlate, plates, element.boundingBox, inputImage, customPaints);
            } else if (RegExp(r'^[0-9]{4}$').hasMatch(detectedPlate)) {
              TextElement lastTextElement = line.elements[elementIndex - 1];
              String detectedPlate = '${lastTextElement.text}${element.text}';
              detectedPlate = detectedPlate.trim().replaceAll(' ', '').replaceAll('-', '').replaceAll('.', '');
              if (detectedPlate.length == 7) {
                Rect rect = Rect.fromLTRB(
                  lastTextElement.boundingBox.left,
                  element.boundingBox.top,
                  element.boundingBox.right,
                  element.boundingBox.bottom,
                );
                _highlightDetectedPlate(detectedPlate, plates, rect, inputImage, customPaints);
              }
            }
            elementIndex++;
          }
        }
      }
      if (plates.isNotEmpty) {
        _isProcessing = false;
        platesWidget.add(customPaints);
        return plates.toString();
      }
    }
    platesWidget.add(null);
    plates.clear();
    _isProcessing = false;
    return null;
  }

  void _highlightDetectedPlate(
      String detectedPlate, StringBuffer plates, Rect rect, InputImage inputImage, List<CustomPaint> customPaints) {
    if (regexPlaca.hasMatch(detectedPlate)) {
      plates.writeln(detectedPlate);
      CustomPaint customPaint = CustomPaint(
        painter: CustomTextRecognizerPainter(
          rect,
          inputImage.inputImageData!.size,
          inputImage.inputImageData!.imageRotation,
        ),
      );
      customPaints.add(customPaint);
    }
  }
}
