import 'package:alvaro/models/plate.dart';
import 'package:flutter/material.dart';

class PlateScreen extends StatelessWidget {
  final List<Plate> plates;

  const PlateScreen({required this.plates, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Detected plate'),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: plateCards(),
        ),
      ),
    );
  }

  List<Widget> plateCards() {
    List<Widget> cardPlates = <Widget>[];
    for (Plate plate in plates) {
      Widget card = Padding(
        padding: const EdgeInsets.all(8.0),
        child: Card(
          child: Column(
            children: [
              Text(plate.plate),
              Text('Bytes'),
              Image.memory(plate.imageBytes),
            ],
          ),
        ),
      );
      cardPlates.add(card);
    }
    return cardPlates;
  }
}
