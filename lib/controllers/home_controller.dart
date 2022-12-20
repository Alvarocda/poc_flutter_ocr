import 'dart:async';
import 'dart:typed_data';

import 'package:alvaro/models/detection.dart';
import 'package:alvaro/models/plate.dart';
import 'package:alvaro/widgets/custom_text_recognize_painter.dart';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_vision/flutter_vision.dart';
import 'package:flutter_vision/src/utils/response_handler.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image/image.dart' as img;
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

  // late CameraController _recognitionCameraController;

  final ValueNotifier<bool> isCameraLoaded = ValueNotifier<bool>(false);
  final ValueNotifier<bool> isStreaming = ValueNotifier<bool>(false);

  final StreamController<List<CustomPaint>?> highlightedCustomPaints = StreamController<List<CustomPaint>?>();
  bool _isProcessing = false;

  // TextRecognizer? _textRecognizer = TextRecognizer();
  final RegExp plateRegex = RegExp('[a-zA-Z]{3}[0-9][A-Za-z0-9][0-9]{2}', caseSensitive: false);
  final List<Plate> _detectedPlates = <Plate>[];
  final StreamController<List<Plate>> _onDetectPlate = StreamController<List<Plate>>.broadcast();
  late final FlutterVision _vision;

  ///
  ///
  ///
  Stream<List<Plate>> get onDetectPlate => _onDetectPlate.stream;

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
    _vision = FlutterVision();
    await _vision.loadYoloModel(modelPath: 'assets/best.tflite', labels: 'assets/labels.txt', useGpu: true);
    isCameraLoaded.value = true;
  }

  ///
  ///
  ///
  Future<void> startMonitoring() async {
    if (isStreaming.value) {
      await cameraController.stopImageStream();
      highlightedCustomPaints.add(null);
      _isProcessing = false;
      isStreaming.value = false;
    } else {
      isStreaming.value = true;
      await cameraController.startImageStream(_processImage);
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
      // InputImage inputImage = InputImage.fromFilePath(xFile.path);

      img.Image? decodedImage = img.decodeImage(await xFile.readAsBytes());

      await _processStaticImage(
          decodedImage!.getBytes(format: img.Format.rgb), decodedImage.height, decodedImage.width);
      // await _processImage(inputImage);
    }
  }

  ///
  ///
  ///
  Future<void> _processStaticImage(Uint8List bytes, int height, int width) async {
    _isProcessing = true;
    List<CustomPaint> highlights = <CustomPaint>[];
    ResponseHandler responseHandler = await _vision.yoloOnImage(
      bytesList: bytes,
      imageHeight: height,
      imageWidth: width,
      confThreshold: 0.5,
      iouThreshold: 0.5,
    );

    if (responseHandler.type == 'success') {
      for (Map<String, dynamic> detectedObject in responseHandler.data) {
        Detection detection = Detection.fromMap(detectedObject);

        // Rect rect = Rect.fromPoints(Offset(detection.x1, detection.y1), Offset(detection.x2, detection.y2));

        // _highlightDetectedPlate('detectedPlate', rect, cameraImage, detection.image, highlights, detection);
      }
    }

    _onDetectPlate.add(_detectedPlates);
    if (highlights.isNotEmpty) {
      highlightedCustomPaints.add(highlights);
      // await Future<void>.delayed(const Duration(seconds: 1));
      _isProcessing = false;
      return;
    }
    highlightedCustomPaints.add(null);
    // await Future<void>.delayed(const Duration(seconds: 1));
    _isProcessing = false;
    return null;
  }

  ///
  ///
  ///
  Future<void> _processImage(CameraImage cameraImage) async {
    if (_isProcessing) {
      return;
    }
    _isProcessing = true;
    List<CustomPaint> highlights = <CustomPaint>[];
    ResponseHandler responseHandler = await _vision.yoloOnFrame(
      bytesList: cameraImage.planes.map((Plane plane) => plane.bytes).toList(),
      imageHeight: cameraImage.height,
      imageWidth: cameraImage.width,
      confThreshold: 0.5,
      iouThreshold: 0.5,
    );

    if (responseHandler.type == 'success') {
      for (Map<String, dynamic> detectedObject in responseHandler.data) {
        Detection detection = Detection.fromMap(detectedObject);

        Rect rect = Rect.fromPoints(Offset(detection.x1, detection.y1), Offset(detection.x2, detection.y2));

        _highlightDetectedPlate('detectedPlate', rect, cameraImage, detection.image, highlights, detection);
      }
    }

    _onDetectPlate.add(_detectedPlates);
    if (highlights.isNotEmpty) {
      highlightedCustomPaints.add(highlights);
      await Future<void>.delayed(const Duration(seconds: 2));
      _isProcessing = false;
      return;
    }
    highlightedCustomPaints.add(null);
    await Future<void>.delayed(const Duration(seconds: 2));
    _isProcessing = false;
    return null;
  }

  ///
  ///
  ///
  void _addPlateToList(String detectedPlate, Uint8List image, Rect highlightedArea) {
    if (!_detectedPlates.any((Plate plate) => plate.plate == detectedPlate)) {
      _detectedPlates.add(Plate(
        plate: detectedPlate,
        imageBytes: image,
        highlightedArea: highlightedArea,
      ));
    }
  }

  ///
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
    Rect rect,
    CameraImage inputImage,
    Uint8List imageBytes,
    List<CustomPaint> customPaints,
    Detection detection,
  ) {
    _addPlateToList(detectedPlate, imageBytes, rect);

    CustomPaint customPaint = CustomPaint(
      painter: CustomTextRecognizerPainter(rect, Size(inputImage.height.toDouble(), inputImage.width.toDouble()),
          InputImageRotation.rotation0deg, '${detection.tag} - ${detection.confidence.toStringAsFixed(3)}'),
    );
    customPaints.add(customPaint);
  }

  ///
  ///
  ///
  void dispose() {
    _onDetectPlate.close();
    // _textRecognizer?.close();
    // _recognitionCameraController.dispose();
    cameraController.dispose();
    highlightedCustomPaints.close();
    isCameraLoaded.dispose();
    isStreaming.dispose();
    _vision.closeYoloModel();
  }
}
