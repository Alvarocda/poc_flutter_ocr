import 'package:alvaro/models/plate.dart';
import 'package:flutter/material.dart';

class PlateScreen extends StatelessWidget {
  final Plate plate;

  const PlateScreen({required this.plate, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Detected plate'),
      ),
      body: Column(
        children: <Widget>[
          Text(plate.plate),
          Text('Bytes'),
          Image.memory(plate.imageBytes),
          Text('File'),
          Image.file(plate.imageFile!),
        ],
      ),
    );
  }
}
