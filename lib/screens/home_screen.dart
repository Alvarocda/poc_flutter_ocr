import 'package:alvaro/controllers/home_controller.dart';
import 'package:alvaro/widgets/custom_drawer_plate.dart';
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
      appBar: AppBar(
        title: const Text('Detector de placas'),
      ),
      endDrawer: CustomDrawerPlate(
        platesStreamController: _controller.onDetectPlate,
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
                    children: <Widget>[
                      AspectRatio(
                        aspectRatio: _controller.cameraController.value.aspectRatio,
                        child: _controller.cameraController.buildPreview(),
                      ),
                      StreamBuilder<List<CustomPaint>?>(
                        stream: _controller.highlightedCustomPaints.stream,
                        builder: (
                          BuildContext context,
                          AsyncSnapshot<List<CustomPaint>?> snapshot,
                        ) {
                          if (snapshot.data == null) {
                            return Container();
                          }
                          return Stack(
                            fit: StackFit.expand,
                            children: snapshot.data!,
                          );
                        },
                      ),
                    ],
                  );
                  // return CameraPreview(
                  //   _controller.cameraController,
                  //   child: StreamBuilder<List<CustomPaint>?>(
                  //     stream: _controller.highlightedCustomPaints.stream,
                  //     builder: (
                  //       BuildContext context,
                  //       AsyncSnapshot<List<CustomPaint>?> snapshot,
                  //     ) {
                  //       if (snapshot.data == null) {
                  //         return Container();
                  //       }
                  //       return Stack(
                  //         fit: StackFit.expand,
                  //         children: snapshot.data!,
                  //       );
                  //     },
                  //   ),
                  // );
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
              ],
            ),
          ),
        ],
      ),
    );
  }
}
