import 'dart:math';
import 'package:flutter/foundation.dart';
import '../../../core/constants/app_constants.dart';
import '../../../models/onion_detection.dart';
import 'onion_inference_engine.dart';

class DemoInferenceEngine implements OnionInferenceEngine {
  final Random _random = Random(42); // Seeded for realistic consistency

  @override
  String get engineName => 'DemoOnDeviceInferenceEngine (Quantized Mobile Simulation)';

  @override
  bool get isSimulation => true;

  @override
  Future<List<OnionDetection>> analyze({
    required String inspectionId,
    required String imagePath,
    Uint8List? imageBytes,
    int sampleNumber = 1,
  }) async {
    // Simulate lightweight on-device CPU inference delay
    await Future.delayed(const Duration(milliseconds: 350));

    final List<OnionClass> targetClasses = [];
    for (int i = 0; i < 32; i++) {
      targetClasses.add(OnionClass.healthy);
    }
    for (int i = 0; i < 4; i++) {
      targetClasses.add(OnionClass.damaged);
    }
    for (int i = 0; i < 2; i++) {
      targetClasses.add(OnionClass.rotten);
    }
    for (int i = 0; i < 1; i++) {
      targetClasses.add(OnionClass.sprouted);
    }
    for (int i = 0; i < 3; i++) {
      targetClasses.add(OnionClass.undersized);
    }

    targetClasses.shuffle(Random(1024));

    final detections = <OnionDetection>[];
    const cols = 7;

    for (int i = 0; i < targetClasses.length; i++) {
      final c = targetClasses[i];
      final col = i % cols;
      final row = i ~/ cols;

      final x = 0.05 + (col * 0.13) + (_random.nextDouble() * 0.02);
      final y = 0.06 + (row * 0.15) + (_random.nextDouble() * 0.02);
      final w = (c == OnionClass.undersized) ? 0.09 : 0.11;
      final h = (c == OnionClass.undersized) ? 0.09 : 0.11;

      double confidence;
      SizeCategory size;

      if (c == OnionClass.damaged) {
        confidence = 0.87;
        size = SizeCategory.normal;
      } else if (c == OnionClass.rotten) {
        confidence = 0.91 + (_random.nextDouble() * 0.05);
        size = SizeCategory.normal;
      } else if (c == OnionClass.sprouted) {
        confidence = 0.89 + (_random.nextDouble() * 0.04);
        size = SizeCategory.large;
      } else if (c == OnionClass.undersized) {
        confidence = 0.94 + (_random.nextDouble() * 0.04);
        size = SizeCategory.small;
      } else {
        confidence = 0.92 + (_random.nextDouble() * 0.06);
        size = (i % 3 == 0) ? SizeCategory.large : SizeCategory.normal;
      }

      detections.add(
        OnionDetection(
          id: 'det-$inspectionId-${i + 1}',
          inspectionId: inspectionId,
          sampleNumber: sampleNumber,
          bboxX: double.parse(x.clamp(0.02, 0.88).toStringAsFixed(3)),
          bboxY: double.parse(y.clamp(0.02, 0.88).toStringAsFixed(3)),
          bboxW: double.parse(w.toStringAsFixed(3)),
          bboxH: double.parse(h.toStringAsFixed(3)),
          aiClass: c,
          aiConfidence: double.parse(confidence.toStringAsFixed(2)),
          sizeCategory: size,
          createdAt: DateTime.now(),
        ),
      );
    }

    return detections;
  }
}
