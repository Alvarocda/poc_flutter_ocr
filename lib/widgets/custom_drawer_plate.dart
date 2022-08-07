import 'dart:async';

import 'package:alvaro/models/plate.dart';
import 'package:flutter/material.dart';

///
///
///
class CustomDrawerPlate extends StatelessWidget {
  final Stream<List<Plate>> platesStreamController;

  ///
  ///
  ///
  const CustomDrawerPlate({required this.platesStreamController, Key? key})
      : super(key: key);

  ///
  ///
  ///
  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: StreamBuilder<List<Plate>>(
          stream: platesStreamController,
          builder: (BuildContext context, AsyncSnapshot<List<Plate>> snapshot) {
            if (snapshot.data == null || snapshot.data!.isEmpty) {
              return const Center(child: Text('Nenhuma placa detectada ainda'));
            }
            return ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: snapshot.data!.length,
              itemBuilder: (BuildContext context, int index) {
                Plate plate = snapshot.data![index];
                return Card(
                  elevation: 5,
                  child: ListTile(
                    title: Text(plate.plate),
                    subtitle: Text(
                      'Detectado em: ${plate.detectedAt.toString()}',
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
