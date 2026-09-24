import 'package:flutter_test/flutter_test.dart';
import 'package:onion_app/core/constants/app_constants.dart';
import 'package:onion_app/features/ai_analysis/domain/demo_inference_engine.dart';
import 'package:onion_app/features/grading/grading_engine.dart';
import 'package:onion_app/models/validation_record.dart';

void main() {
  group('GradingEngine Tests', () {
    test('Calculates Grade A correctly when healthy >= 70% and rotten <= 5%', () {
      final validations = <ValidationRecord>[];

      // 35 healthy out of 42 (83.3%)
      for (int i = 0; i < 35; i++) {
        validations.add(ValidationRecord(
          id: 'v-$i',
          inspectionId: 'test-insp',
          detectionId: 'd-$i',
          originalAiClass: OnionClass.healthy,
          aiConfidence: 0.95,
          inspectorClass: OnionClass.healthy,
          finalClass: OnionClass.healthy,
          isCorrected: false,
        ));
      }

      // 5 damaged (11.9%)
      for (int i = 35; i < 40; i++) {
        validations.add(ValidationRecord(
          id: 'v-$i',
          inspectionId: 'test-insp',
          detectionId: 'd-$i',
          originalAiClass: OnionClass.damaged,
          aiConfidence: 0.88,
          inspectorClass: OnionClass.damaged,
          finalClass: OnionClass.damaged,
          isCorrected: false,
        ));
      }

      // 2 rotten (4.8%)
      for (int i = 40; i < 42; i++) {
        validations.add(ValidationRecord(
          id: 'v-$i',
          inspectionId: 'test-insp',
          detectionId: 'd-$i',
          originalAiClass: OnionClass.rotten,
          aiConfidence: 0.89,
          inspectorClass: OnionClass.rotten,
          finalClass: OnionClass.rotten,
          isCorrected: false,
        ));
      }

      final result = GradingEngine.evaluate(
        inspectionId: 'test-insp',
        validations: validations,
      );

      expect(result.totalSample, 42);
      expect(result.gradeACount, 35);
      expect(result.gradeAPercentage, 83.3);
      expect(result.finalGrade, contains('Grade A'));
    });

    test('Calculates URS correctly when healthy is between 50% and 70%', () {
      final validations = <ValidationRecord>[];

      // 24 healthy out of 40 (60.0%)
      for (int i = 0; i < 24; i++) {
        validations.add(ValidationRecord(
          id: 'v-$i',
          inspectionId: 'test-insp',
          detectionId: 'd-$i',
          originalAiClass: OnionClass.healthy,
          aiConfidence: 0.90,
          inspectorClass: OnionClass.healthy,
          finalClass: OnionClass.healthy,
          isCorrected: false,
        ));
      }

      // 14 sprouted / undersized
      for (int i = 24; i < 38; i++) {
        validations.add(ValidationRecord(
          id: 'v-$i',
          inspectionId: 'test-insp',
          detectionId: 'd-$i',
          originalAiClass: OnionClass.sprouted,
          aiConfidence: 0.87,
          inspectorClass: OnionClass.sprouted,
          finalClass: OnionClass.sprouted,
          isCorrected: false,
        ));
      }

      // 2 rotten (5.0%)
      for (int i = 38; i < 40; i++) {
        validations.add(ValidationRecord(
          id: 'v-$i',
          inspectionId: 'test-insp',
          detectionId: 'd-$i',
          originalAiClass: OnionClass.rotten,
          aiConfidence: 0.85,
          inspectorClass: OnionClass.rotten,
          finalClass: OnionClass.rotten,
          isCorrected: false,
        ));
      }

      final result = GradingEngine.evaluate(
        inspectionId: 'test-insp',
        validations: validations,
      );

      expect(result.totalSample, 40);
      expect(result.gradeAPercentage, 60.0);
      expect(result.finalGrade, contains('URS'));
    });

    test('Flags Sub-Standard / Rejected when rotten exceeds threshold', () {
      final validations = <ValidationRecord>[];

      // 20 healthy out of 40 (50.0%)
      for (int i = 0; i < 20; i++) {
        validations.add(ValidationRecord(
          id: 'v-$i',
          inspectionId: 'test-insp',
          detectionId: 'd-$i',
          originalAiClass: OnionClass.healthy,
          aiConfidence: 0.90,
          inspectorClass: OnionClass.healthy,
          finalClass: OnionClass.healthy,
          isCorrected: false,
        ));
      }

      // 10 rotten (25%) -> well above 8% max
      for (int i = 20; i < 30; i++) {
        validations.add(ValidationRecord(
          id: 'v-$i',
          inspectionId: 'test-insp',
          detectionId: 'd-$i',
          originalAiClass: OnionClass.rotten,
          aiConfidence: 0.90,
          inspectorClass: OnionClass.rotten,
          finalClass: OnionClass.rotten,
          isCorrected: false,
        ));
      }

      // 10 damaged
      for (int i = 30; i < 40; i++) {
        validations.add(ValidationRecord(
          id: 'v-$i',
          inspectionId: 'test-insp',
          detectionId: 'd-$i',
          originalAiClass: OnionClass.damaged,
          aiConfidence: 0.85,
          inspectorClass: OnionClass.damaged,
          finalClass: OnionClass.damaged,
          isCorrected: false,
        ));
      }

      final result = GradingEngine.evaluate(
        inspectionId: 'test-insp',
        validations: validations,
      );

      expect(result.finalGrade, contains('Sub-Standard / Rejected'));
    });
  });

  group('DemoInferenceEngine Tests', () {
    test('Produces valid structured bounding boxes and confidence scores', () async {
      final engine = DemoInferenceEngine();
      final detections = await engine.analyze(
        inspectionId: 'test-insp-123',
        imagePath: 'dummy_path.jpg',
        sampleNumber: 1,
      );

      expect(detections.isNotEmpty, true);
      expect(detections.length >= 14, true);

      for (final det in detections) {
        expect(det.inspectionId, 'test-insp-123');
        expect(det.bboxX >= 0.0 && det.bboxX <= 1.0, true);
        expect(det.bboxY >= 0.0 && det.bboxY <= 1.0, true);
        expect(det.bboxW > 0.0 && det.bboxW <= 1.0, true);
        expect(det.bboxH > 0.0 && det.bboxH <= 1.0, true);
        expect(det.aiConfidence >= 0.80 && det.aiConfidence <= 1.0, true);
      }
    });
  });
}
