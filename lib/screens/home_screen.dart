import 'package:alvaro/controllers/home_controller.dart';
import 'package:alvaro/widgets/custom_text_recognize_painter.dart';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

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
  final HomeController _controller = HomeController();

  @override
  void initState() {
    _controller.initCamera();
    super.initState();
  }

  ///
  ///
  ///
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Expanded(
            child: ValueListenableBuilder<bool>(
              valueListenable: _controller.isCameraLoaded,
              builder: (BuildContext context, bool value, Widget? child) {
                if (value) {
                  return CameraPreview(
                    _controller.cameraController,
                    child: ValueListenableBuilder<CustomPaint?>(
                      valueListenable: _controller.platesWidget,
                      builder: (BuildContext context, CustomPaint? value, Widget? child) {
                        if(value == null){
                          return Container();
                        }
                        return value;
                      },
                    ),
                  );
                }
                return const Center(
                  child: SizedBox(
                    width: 25,
                    height: 25,
                    child: CircularProgressIndicator(),
                  ),
                );
              },
            ),
          ),
          ValueListenableBuilder<bool>(
            valueListenable: _controller.isStreaming,
            builder: (BuildContext context, bool isStreaming, Widget? child) {
              return ElevatedButton(
                onPressed: _controller.startMonitoring,
                child: Text(isStreaming ? 'Parar' : 'Ativar'),
              );
            },
          ),
          ElevatedButton(
            onPressed: _controller.getGalleryImage,
            child: const Text('Galeria'),
          ),
          SizedBox(
            height: 120,
            child: ValueListenableBuilder<String>(
              valueListenable: _controller.platesDetected,
              builder: (BuildContext context, String value, Widget? child) {
                return Column(
                  children: <Widget>[
                    const Text('Placas detectadas:'),
                    Text(value),
                    const Text('Texto detectado:'),
                    ValueListenableBuilder<String>(
                      valueListenable: _controller.textDetected,
                      builder: (BuildContext context, String value, Widget? child) {
                        return Text(value);
                      },
                    )
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
