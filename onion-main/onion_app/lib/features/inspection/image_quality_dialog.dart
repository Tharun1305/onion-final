import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../ai_analysis/image_quality_checker.dart';

class ImageQualityDialog extends StatelessWidget {
  final ImageQualityResult result;
  final VoidCallback onUseAnyway;
  final VoidCallback onRetake;

  const ImageQualityDialog({
    super.key,
    required this.result,
    required this.onUseAnyway,
    required this.onRetake,
  });

  @override
  Widget build(BuildContext context) {
    final passed = result.isPassed;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      actionsPadding: const EdgeInsets.all(16),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: passed ? const Color(0xFFDCFCE7) : const Color(0xFFFEE2E2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              passed ? Icons.check_circle_outline : Icons.warning_amber_rounded,
              color: passed ? AppTheme.successGreen : AppTheme.errorRed,
              size: 26,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              passed ? 'Image Quality Passed' : 'Image Quality Poor',
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppTheme.darkSlate),
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!passed) ...[
            const Text(
              'Please capture another image with:',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.darkSlate),
            ),
            const SizedBox(height: 8),
            ...result.recommendations.map(
              (rec) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    const Icon(Icons.check, size: 16, color: AppTheme.primaryTeal),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(rec, style: const TextStyle(fontSize: 13, color: AppTheme.textMuted)),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Diagnostic stats
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.bgSlate,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.borderGray),
            ),
            child: Column(
              children: [
                _buildScoreRow('Sharpness / Blur Score', '${(result.blurScore * 100).toInt()}%', result.blurScore >= 0.5),
                const SizedBox(height: 6),
                _buildScoreRow('Lighting Exposure', '${(result.brightnessScore * 100).toInt()}%', result.brightnessScore >= 0.25 && result.brightnessScore <= 0.88),
              ],
            ),
          ),
        ],
      ),
      actions: [
        if (!passed)
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.textMuted,
              side: const BorderSide(color: AppTheme.borderGray),
              minimumSize: const Size(110, 44),
            ),
            onPressed: () {
              Navigator.of(context).pop();
              onUseAnyway();
            },
            child: const Text('Use Anyway'),
          ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: passed ? AppTheme.primaryTeal : AppTheme.errorRed,
            minimumSize: const Size(120, 44),
          ),
          onPressed: () {
            Navigator.of(context).pop();
            if (passed) {
              onUseAnyway();
            } else {
              onRetake();
            }
          },
          child: Text(passed ? 'Proceed to AI' : 'Retake Image'),
        ),
      ],
    );
  }

  Widget _buildScoreRow(String label, String value, bool isOk) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
        Row(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isOk ? AppTheme.successGreen : AppTheme.errorRed,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              isOk ? Icons.check_circle : Icons.error_outline,
              size: 14,
              color: isOk ? AppTheme.successGreen : AppTheme.errorRed,
            ),
          ],
        ),
      ],
    );
  }
}
