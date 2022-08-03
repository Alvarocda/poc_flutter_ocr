import 'package:alvaro/models/placa.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:image_picker/image_picker.dart';

///
///
///
class HomeScreen extends StatefulWidget {
  ///
  ///
  ///
  const HomeScreen({Key? key}) : super(key: key);

  ///
  ///
  ///
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

///
///
///
class _HomeScreenState extends State<HomeScreen> {
  List<Placa> placasReconhecidas = <Placa>[];
  String _recognizedText = '';

  ///
  ///
  ///
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Column(
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              ElevatedButton(onPressed: () => getImage(ImageSource.camera), child: const Text('Camera')),
              const SizedBox(width: 15),
              ElevatedButton(onPressed: () => getImage(ImageSource.gallery), child: const Text('Galeria')),
            ],
          ),
          const Text('Placas encontradas:'),
          Text(_recognizedText.isEmpty ? 'Nenhum texto reconhecido' : _recognizedText),
        ],
      ),
    );
  }

  ///
  ///
  ///
  Future<void> getImage(ImageSource imageSource) async {
    ImagePicker imagePicker = ImagePicker();
    XFile? xFile = await imagePicker.pickImage(source: imageSource);
    if (xFile != null) {
      await readTextsInImage(xFile);
    }
  }

  ///
  ///
  ///
  Future<void> readTextsInImage(XFile xFile) async {
    InputImage inputImage = InputImage.fromFilePath(xFile.path);
    TextRecognizer textDetector = GoogleMlKit.vision.textRecognizer();
    RecognizedText recognizedText = await textDetector.processImage(inputImage);
    await textDetector.close();
    _recognizedText = '';
    RegExp regexPlaca = RegExp(
      r'^[a-zA-Z]{3}[0-9][A-Za-z0-9][0-9]{2}$',
      caseSensitive: false,
    );

    for (TextBlock block in recognizedText.blocks) {
      for (TextLine line in block.lines) {
        if (regexPlaca.hasMatch(line.text.replaceAll('-', '').replaceAll(':', '').replaceAll(' ', ''))) {
          _recognizedText += '${line.text}\n';
        }
      }
    }
    if (_recognizedText.isNotEmpty) {
      setState(() {});
    }
  }
}
