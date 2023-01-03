import 'dart:async';
import 'dart:typed_data';

import 'package:alvaro/models/detection.dart';
import 'package:alvaro/models/plate.dart';
import 'package:alvaro/screens/static_image_screen.dart';
import 'package:alvaro/utils/image_utils.dart';
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
  final BuildContext context;

  ///
  ///
  ///
  HomeController({required this.context});

  late List<CameraDescription> _cameras;

  late CameraController cameraController;

  // late CameraController _recognitionCameraController;

  final ValueNotifier<bool> isCameraLoaded = ValueNotifier<bool>(false);
  final ValueNotifier<bool> isStreaming = ValueNotifier<bool>(false);
  final ValueNotifier<FlashMode> flashMode = ValueNotifier<FlashMode>(FlashMode.off);
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
  Future<void> initCamera({CameraDescription? cameraDescription}) async {
    isCameraLoaded.value = false;
    _cameras = await availableCameras();
    cameraController = CameraController(
      cameraDescription ?? _cameras.first,
      ResolutionPreset.high,
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
  Future<void> takePhoto() async {
    XFile photo = await cameraController.takePicture();
    img.Image? decodedImage = img.decodeImage(await photo.readAsBytes());
    await _processStaticImage(await photo.readAsBytes(), decodedImage!.height, decodedImage.width);
  }

  ///
  ///
  ///
  Future<void> toogleFlash() async {
    if (flashMode.value == FlashMode.off) {
      flashMode.value = FlashMode.always;
    } else {
      flashMode.value = FlashMode.off;
    }
    await cameraController.setFlashMode(flashMode.value);
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
      await _processStaticImage(await xFile.readAsBytes(), decodedImage!.height, decodedImage.width);

      // await _processImage(inputImage);
    }
  }

  ///
  ///
  ///
  Future<void> _processStaticImage(Uint8List bytes, int height, int width) async {
    _isProcessing = true;
    List<CustomPaint> highlights = <CustomPaint>[];
    List<Detection> detections = <Detection>[];

    img.Image optmizedImage = img.decodeImage(bytes)!;

    if (optmizedImage.width <= 1920) {
      double targetHeight = optmizedImage.height + optmizedImage.height * 0.5;
      double targetWidth = optmizedImage.width + optmizedImage.width * 0.5;

      optmizedImage = img.copyResize(
        optmizedImage,
        width: targetWidth.toInt(),
        height: targetHeight.toInt(),
        interpolation: img.Interpolation.cubic,
      );
    } else if (optmizedImage.width > 2880) {
      double aspectRatio = calculateAspectRatio(optmizedImage.width, optmizedImage.height, 1920, 1080);
      double newWidth = optmizedImage.width - optmizedImage.width * aspectRatio;
      double newHeight = optmizedImage.height - optmizedImage.height * aspectRatio;
      optmizedImage = img.copyResize(
        optmizedImage,
        width: newWidth.toInt(),
        height: newHeight.toInt(),
        interpolation: img.Interpolation.cubic,
      );
    }

    optmizedImage = img.grayscale(optmizedImage);

    // img.gaussianBlur(grayScaleImage, 2);

    Uint8List encodedImage = Uint8List.fromList(img.encodeJpg(optmizedImage));

    encodedImage = convertGreytoYuv(encodedImage.toList(), optmizedImage.width, optmizedImage.height);

    ResponseHandler responseHandler = await _vision.yoloOnImage(
      bytesList: encodedImage,
      imageHeight: optmizedImage.height,
      imageWidth: optmizedImage.width,
      confThreshold: 0.5,
      iouThreshold: 0.5,
    );

    if (responseHandler.type == 'success') {
      if (responseHandler.data.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Nenhuma placa detectada na imagem'),
          ),
        );
      } else {
        for (Map<String, dynamic> detectedObject in responseHandler.data) {
          Detection detection = Detection.fromMap(detectedObject);

          Rect rect = Rect.fromPoints(Offset(detection.x1, detection.y1), Offset(detection.x2, detection.y2));

          _highlightDetectedPlate(
            'detectedPlate',
            rect,
            height.toDouble(),
            width.toDouble(),
            detection.image,
            highlights,
            detection,
          );
          detections.add(detection);
        }
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Falha ao detectar placas na imagem'),
        ),
      );
    }

    // _onDetectPlate.add(_detectedPlates);
    if (highlights.isNotEmpty) {
      highlightedCustomPaints.add(highlights);
      // await Future<void>.delayed(const Duration(seconds: 1));
      _isProcessing = false;
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => StaticImageScreen(
            image: encodedImage,
            detections: detections,
            aspectRatio: cameraController.value.aspectRatio,
          ),
        ),
      );
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

        _highlightDetectedPlate(
          'detectedPlate',
          rect,
          cameraImage.height.toDouble(),
          cameraImage.width.toDouble(),
          detection.image,
          highlights,
          detection,
        );
      }
    }

    _onDetectPlate.add(_detectedPlates);
    await Future<void>.delayed(const Duration(seconds: 1));
    if (highlights.isNotEmpty) {
      highlightedCustomPaints.add(highlights);
      _isProcessing = false;
      return;
    }
    highlightedCustomPaints.add(null);
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
        // highlightedArea: highlightedArea,
      ));
    }
  }

  ///
  ///
  ///
  void _highlightDetectedPlate(
    String detectedPlate,
    Rect rect,
    double imageHeight,
    double imageWidth,
    Uint8List imageBytes,
    List<CustomPaint> customPaints,
    Detection detection,
  ) {
    _addPlateToList(detectedPlate, imageBytes, rect);

    CustomPaint customPaint = CustomPaint(
      painter: CustomTextRecognizerPainter(rect, Size(imageHeight, imageWidth), InputImageRotation.rotation0deg,
          '${detection.tag} - ${detection.confidence.toStringAsFixed(3)}'),
    );
    customPaints.add(customPaint);
    detection.rect = customPaint;
  }

  void didChangeAppLifeCycleState(AppLifecycleState state) {
    final CameraController cameraController = this.cameraController;

    // App state changed before we got the chance to initialize.
    if (!cameraController.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive) {
      cameraController.dispose();
    } else if (state == AppLifecycleState.resumed) {
      initCamera(cameraDescription: cameraController.description);
    }
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
