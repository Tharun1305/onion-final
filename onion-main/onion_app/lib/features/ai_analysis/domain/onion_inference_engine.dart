import 'dart:typed_data';
import '../../../models/onion_detection.dart';

abstract class OnionInferenceEngine {
  String get engineName;
  bool get isSimulation;

  Future<List<OnionDetection>> analyze({
    required String inspectionId,
    required String imagePath,
    Uint8List? imageBytes,
    int sampleNumber = 1,
  });
}
