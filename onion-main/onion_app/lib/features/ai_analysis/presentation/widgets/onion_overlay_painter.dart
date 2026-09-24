import 'package:flutter/material.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../models/onion_detection.dart';

class OnionOverlayPainter extends CustomPainter {
  final List<OnionDetection> detections;
  final String? selectedDetectionId;

  OnionOverlayPainter({
    required this.detections,
    this.selectedDetectionId,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (int i = 0; i < detections.length; i++) {
      final det = detections[i];
      final isSelected = det.id == selectedDetectionId;
      final classColor = AppConstants.getClassColor(det.aiClass);

      // Coordinates are normalized 0..1
      final left = det.bboxX * size.width;
      final top = det.bboxY * size.height;
      final width = det.bboxW * size.width;
      final height = det.bboxH * size.height;
      final rect = Rect.fromLTWH(left, top, width, height);

      // Box Paint
      final boxPaint = Paint()
        ..color = isSelected ? Colors.white : classColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = isSelected ? 3.5 : 2.0;

      // Fill slightly
      final fillPaint = Paint()
        ..color = (isSelected ? Colors.white : classColor).withValues(alpha: 0.12)
        ..style = PaintingStyle.fill;

      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(6)),
        fillPaint,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(6)),
        boxPaint,
      );

      // Label background tab
      final labelText = '#${i + 1} ${AppConstants.formatOnionClass(det.aiClass)} ${(det.aiConfidence * 100).toInt()}%';
      final textSpan = TextSpan(
        text: labelText,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      );
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      )..layout();

      final labelRect = Rect.fromLTWH(
        left,
        top - 18 < 0 ? top : top - 18,
        textPainter.width + 10,
        18,
      );

      final labelPaint = Paint()..color = classColor;
      canvas.drawRRect(
        RRect.fromRectAndRadius(labelRect, const Radius.circular(3)),
        labelPaint,
      );

      textPainter.paint(canvas, Offset(left + 5, (top - 18 < 0 ? top : top - 18) + 2));
    }
  }

  @override
  bool shouldRepaint(covariant OnionOverlayPainter oldDelegate) {
    return oldDelegate.detections != detections || oldDelegate.selectedDetectionId != selectedDetectionId;
  }
}
