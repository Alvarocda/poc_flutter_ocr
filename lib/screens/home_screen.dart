import 'package:alvaro/controllers/home_controller.dart';
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
                    child: StreamBuilder<Rect>(
                      builder:
                          (BuildContext context, AsyncSnapshot<Rect> snapshot) {
                        return Stack(
                          children: <Widget>[
                            Positioned.fromRect(
                              rect: snapshot.data ?? Rect.zero,
                              child: Container(
                                height: 10,
                                width: 10,
                                color: Colors.red,
                              ),
                            ),
                          ],
                        );
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
          ElevatedButton(
            onPressed: _controller.startMonitoring,
            child: const Text('Ativar'),
          ),
          SizedBox(
            height: 100,
            child: ValueListenableBuilder<String>(
              valueListenable: _controller.platesDetected,
              builder: (BuildContext context, String value, Widget? child) {
                return Column(
                  children: <Widget>[
                    const Text('Placas detectadas:'),
                    Text(value),
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
