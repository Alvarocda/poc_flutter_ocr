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
  final RegExp plateRegex = RegExp('[a-zA-Z]{3}[0-9][A-Za-z0-9][0-9]{2}', caseSensitive: false);

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
              platesDetected.value = await _processImage(inputImage) ?? '';
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
      platesDetected.value = await _processImage(inputImage) ?? '';
    }
  }

  ///
  ///
  ///
  Future<String?> _processImage(InputImage inputImage) async {
    _isProcessing = true;
    _textRecognizer ??= TextRecognizer();
    RecognizedText recognizedText = await _textRecognizer!.processImage(inputImage);
    textDetected.value = recognizedText.text;
    StringBuffer? plates;
    List<CustomPaint>? customPaints;

    ///If somewhere in all the detected text it finds a plate, the algorithm will display the plates found on the screen.
    if (plateRegex.hasMatch(_normalizePlate(recognizedText.text))) {
      int elementIndex = 0;
      for (TextBlock block in recognizedText.blocks) {
        for (TextLine line in block.lines) {
          elementIndex = 0;
          for (TextElement element in line.elements) {
            String detectedPlate = _normalizePlate(element.text);

            /// If the text is not exactly 7 characters long, it will try to concatenate the text of the previous
            /// element with the current element and check if the junction of the two forms a valid plate.
            /// As the algorithm is working with TextElements, it ends up splitting into different elements when it
            /// detects a space in the middle of the plate.
            if (detectedPlate.length == 7) {
              if (_isValidPlate(detectedPlate)) {
                plates ?? StringBuffer();
                customPaints ??= <CustomPaint>[];
                _highlightDetectedPlate(detectedPlate, plates!, element.boundingBox, inputImage, customPaints);
              }

              /// If the text in the current element has less than 7 letters, it will check if the text size is 4 characters
              /// and if it is composed of 4 numbers, if it is composed of 4 numbers, it will check if the text in the
              /// previous element is composed of 3 letters, if both conditions are true, the algorithm will understand
              /// that it can be a plate and will assemble a String with the junction of the two.
            } else if (detectedPlate.length == 4 && RegExp(r'^[0-9]{4}$').hasMatch(detectedPlate)) {
              TextElement lastTextElement = line.elements[elementIndex - 1];
              if (RegExp('[a-zA-Z]{3}').hasMatch(lastTextElement.text)) {
                String detectedPlate = '${lastTextElement.text}${element.text}';
                detectedPlate = _normalizePlate(detectedPlate);

                if (detectedPlate.length == 7) {
                  if (_isValidPlate(detectedPlate)) {
                    Rect rect = Rect.fromLTRB(
                      lastTextElement.boundingBox.left,
                      element.boundingBox.top,
                      element.boundingBox.right,
                      element.boundingBox.bottom,
                    );
                    plates ?? StringBuffer();
                    customPaints ??= <CustomPaint>[];
                    _highlightDetectedPlate(detectedPlate, plates!, rect, inputImage, customPaints);
                  }
                }
              }
            }
            elementIndex++;
          }
        }
      }
      if (plates != null && plates.isNotEmpty) {
        _isProcessing = false;
        platesWidget.add(customPaints);
        return plates.toString();
      }
    }
    platesWidget.add(null);
    plates?.clear();
    _isProcessing = false;
    return null;
  }

  /// Prepares the text to be
  ///
  ///
  String _normalizePlate(String plate) {
    return plate.trim().replaceAll(' ', '').replaceAll('-', '').replaceAll('.', '');
  }

  ///
  ///
  ///
  bool _isValidPlate(String plate) {
    return plateRegex.hasMatch(plate);
  }

  ///
  ///
  ///
  void _highlightDetectedPlate(
    String detectedPlate,
    StringBuffer plates,
    Rect rect,
    InputImage inputImage,
    List<CustomPaint> customPaints,
  ) {
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
