import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import '../../../core/constants/app_constants.dart';
import '../../../models/onion_detection.dart';
import 'onion_inference_engine.dart';

class DemoInferenceEngine implements OnionInferenceEngine {
  @override
  String get engineName => 'DemoOnDeviceInferenceEngine (Fallback Simulation)';

  @override
  bool get isSimulation => true;

  @override
  Future<List<OnionDetection>> analyze({
    required String inspectionId,
    required String imagePath,
    Uint8List? imageBytes,
    int sampleNumber = 1,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));

    OnionClass primaryClass = OnionClass.healthy;
    String rawClass = 'healthy';
    double primaryConfidence = 0.88;
    Map<String, double> primaryProbs = {
      'healthy': 88.0,
      'damaged': 5.0,
      'sprouted': 3.0,
      'black_rot': 2.0,
      'mold': 1.0,
      'soft_rot': 1.0,
    };

    // Analyze image bytes directly if available
    if (imageBytes != null && imageBytes.isNotEmpty) {
      try {
        final codec = await ui.instantiateImageCodec(
          imageBytes,
          targetWidth: 32,
          targetHeight: 32,
        );
        final frame = await codec.getNextFrame();
        final byteData = await frame.image.toByteData(format: ui.ImageByteFormat.rawRgba);

        if (byteData != null) {
          int darkRotPixels = 0;
          int greenSproutPixels = 0;
          int totalPixels = 32 * 32;

          for (int i = 0; i < byteData.lengthInBytes; i += 4) {
            final r = byteData.getUint8(i);
            final g = byteData.getUint8(i + 1);
            final b = byteData.getUint8(i + 2);

            // Dark rotting/decay/black rot spots: very low luminance
            final luminance = 0.299 * r + 0.587 * g + 0.114 * b;
            if (luminance < 65 && (r < 75 && g < 75 && b < 75)) {
              darkRotPixels++;
            }
            // Green sprouting shoot
            if (g > 70 && g > r * 1.25 && g > b * 1.25) {
              greenSproutPixels++;
            }
          }

          final rotRatio = darkRotPixels / totalPixels;
          final sproutRatio = greenSproutPixels / totalPixels;

          if (rotRatio >= 0.08) {
            // Defective onion with rot/decay (Grade D)
            primaryClass = OnionClass.rotten;
            rawClass = 'black_rot';
            primaryConfidence = 0.65 + min(rotRatio * 0.5, 0.25);
            final rotPercent = double.parse((primaryConfidence * 100).toStringAsFixed(2));
            final moldPercent = double.parse((12.0 + rotRatio * 10).toStringAsFixed(2));
            final healthyPercent = double.parse(max(100.0 - rotPercent - moldPercent - 5.0, 5.0).toStringAsFixed(2));
            primaryProbs = {
              'black_rot': rotPercent,
              'mold': moldPercent,
              'healthy': healthyPercent,
              'damaged': 3.5,
              'soft_rot': 1.0,
              'sprouted': 0.5,
            };
          } else if (sproutRatio >= 0.04) {
            // Sprouted onion (Grade B / C)
            primaryClass = OnionClass.sprouted;
            rawClass = 'sprouted';
            primaryConfidence = 0.82;
            primaryProbs = {
              'sprouted': 82.0,
              'healthy': 10.0,
              'damaged': 4.0,
              'black_rot': 2.0,
              'mold': 1.0,
              'soft_rot': 1.0,
            };
          }
        }
      } catch (e) {
        debugPrint('[DemoInferenceEngine] Image decode warning: $e');
      }
    }

    final detections = <OnionDetection>[
      OnionDetection(
        id: 'det-$inspectionId-$sampleNumber',
        inspectionId: inspectionId,
        sampleNumber: sampleNumber,
        bboxX: 0.15,
        bboxY: 0.15,
        bboxW: 0.70,
        bboxH: 0.70,
        aiClass: primaryClass,
        aiConfidence: primaryConfidence,
        sizeCategory: SizeCategory.normal,
        probabilities: primaryProbs,
        rawClassName: rawClass,
        createdAt: DateTime.now(),
      ),
    ];

    return detections;
  }
}
