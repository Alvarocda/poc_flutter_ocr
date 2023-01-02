import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

///
///
///
Uint8List convertGreytoYuv(List<int> greyscaleImage, int width, int height) {
  int size = width * height;
  List<int> yuvRaw = List<int>.empty(growable: true);
  yuvRaw.addAll(greyscaleImage);
  yuvRaw.addAll(List<int>.filled(size ~/ 2, 0));
  return Uint8List.fromList(yuvRaw);
}

///
///
///
double calculateAspectRatio(int srcWidth, int srcHeight, int targetWidth, int targetHeight) =>
    min(targetWidth / srcWidth, targetHeight / srcHeight);

///
///
///
Future<File> saveFile(img.Image image) async {
  Uint8List imageBytes = Uint8List.fromList(img.encodePng(image));

  Directory tempDir = await getTemporaryDirectory();

  File file = await File(join(tempDir.path, '${tempDir.hashCode}.png')).create(recursive: true);

  if (!tempDir.existsSync()) {
    await tempDir.create(recursive: true);
  }

  if (file.existsSync()) {
    await file.delete();
  }

  return file.writeAsBytes(imageBytes);
}

///
///
///
Future<void> deleteAllCachedImages() async {
  Directory tempDir = await getTemporaryDirectory();
  List<FileSystemEntity> files = tempDir.listSync();
  for (FileSystemEntity file in files) {
    await file.delete();
  }
}
