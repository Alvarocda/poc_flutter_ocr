import 'dart:convert';
import 'dart:typed_data';

import 'package:alvaro/models/detection.dart';
import 'package:http/http.dart';

///
///
///
class DetectorConsumer {
  ///
  ///
  ///
  Future<List<Detection>> detectPlates({required Uint8List imageBytes}) async {
    Client httpClient = Client();
    Uri uri = Uri.parse(String.fromEnvironment('PREDICT_URL'));
    MultipartRequest request = MultipartRequest('POST', uri);
    MultipartFile image = MultipartFile.fromBytes('image', imageBytes, filename: 'image');
    request.files.add(image);
    StreamedResponse streamedResponse = await request.send();
    Response response = await Response.fromStream(streamedResponse);
    if (response.statusCode == 200) {
      List<Detection> detections = <Detection>[];
      List<dynamic> detectionsJson = json.decode(response.body);
      for (Map<String, dynamic> detection in detectionsJson) {
        detections.add(Detection.fromMap(detection));
      }
      httpClient.close();
      return detections;
    } else {
      if (response.statusCode == 404) {
        throw Exception('No plates found in the selected image');
      } else {
        throw Exception('Fail to detect plates');
      }
    }
  }
}
