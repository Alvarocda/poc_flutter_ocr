import 'package:alvaro/controllers/home_controller.dart';
import 'package:camera/camera.dart';
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
class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  late final HomeController _controller = HomeController(context: context);

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
      appBar: AppBar(
        title: const Text('Detector de placas'),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Expanded(
            child: ValueListenableBuilder<bool>(
              valueListenable: _controller.isCameraLoaded,
              builder: (BuildContext context, bool value, Widget? child) {
                if (value) {
                  return Stack(
                    fit: StackFit.expand,
                    alignment: Alignment.center,
                    children: <Widget>[
                      AspectRatio(
                        aspectRatio: _controller.cameraController.value.aspectRatio,
                        child: _controller.cameraController.buildPreview(),
                      ),
                      ValueListenableBuilder<FlashMode>(
                        valueListenable: _controller.flashMode,
                        builder: (BuildContext context, FlashMode value, Widget? child) {
                          return Positioned(
                            bottom: 15,
                            child: GestureDetector(
                              onTap: _controller.toogleFlash,
                              child: Container(
                                decoration: const BoxDecoration(
                                  color: Colors.grey,
                                  shape: BoxShape.circle,
                                ),
                                width: 55,
                                height: 55,
                                child: Center(
                                  child: Icon(value == FlashMode.off ? Icons.flash_on : Icons.flash_off),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ],
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
          Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                ElevatedButton(
                  onPressed: _controller.takePhoto,
                  child: const Text('Fotografar'),
                ),
                ElevatedButton(
                  onPressed: _controller.getGalleryImage,
                  child: const Text('Galeria'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  ///
  ///
  ///
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _controller.didChangeAppLifeCycleState(state);
  }
}
