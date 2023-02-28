import 'dart:async';
import 'dart:typed_data';

import 'package:alvaro/consumers/detector_consumer.dart';
import 'package:alvaro/models/detection.dart';
import 'package:alvaro/screens/static_image_screen.dart';
import 'package:alvaro/utils/image_utils.dart';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
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
  final ValueNotifier<FlashMode> flashMode = ValueNotifier<FlashMode>(FlashMode.off);
  final StreamController<List<CustomPaint>?> highlightedCustomPaints = StreamController<List<CustomPaint>?>();

  // TextRecognizer? _textRecognizer = TextRecognizer();

  late final DetectorConsumer consumer = DetectorConsumer();

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
    isCameraLoaded.value = true;
  }

  ///
  ///
  ///
  Future<void> takePhoto() async {
    XFile photo = await cameraController.takePicture();
    await _processStaticImage(await photo.readAsBytes());
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
      await _processStaticImage(await xFile.readAsBytes());
    }
  }

  ///
  ///
  ///
  Future<void> _processStaticImage(Uint8List bytes) async {
    try {
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

      Uint8List optmizedImageBytes = Uint8List.fromList(img.encodeJpg(optmizedImage));
      List<Detection> detections = await consumer.detectPlates(imageBytes: optmizedImageBytes);
      unawaited(Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => StaticImageScreen(
            image: optmizedImageBytes,
            detections: detections,
          ),
        ),
      ));
    } catch (e) {
      unawaited(showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            content: Text(e.toString()),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          );
        },
      ));
    }
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
    cameraController.dispose();
    highlightedCustomPaints.close();
    isCameraLoaded.dispose();
  }
}
