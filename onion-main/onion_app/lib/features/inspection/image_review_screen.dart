import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/image_thumbnail.dart';
import '../../core/widgets/platform_file_image.dart';
import '../../core/widgets/primary_button.dart';
import '../../models/inspection.dart';
import '../ai_analysis/image_quality_checker.dart';
import '../ai_analysis/presentation/ai_analysis_screen.dart';

class ImageReviewScreen extends StatefulWidget {
  final Inspection inspection;
  final List<String> imagePaths;

  const ImageReviewScreen({
    super.key,
    required this.inspection,
    required this.imagePaths,
  });

  @override
  State<ImageReviewScreen> createState() => _ImageReviewScreenState();
}

class _ImageReviewScreenState extends State<ImageReviewScreen> {
  late List<String> _paths;
  final Map<String, ImageQualityResult> _qualityResults = {};
  bool _isCheckingQuality = true;

  @override
  void initState() {
    super.initState();
    _paths = List<String>.from(widget.imagePaths);
    _checkAllQualities();
  }

  Future<void> _checkAllQualities() async {
    setState(() => _isCheckingQuality = true);
    for (final p in _paths) {
      final res = await ImageQualityChecker.checkImage(p);
      _qualityResults[p] = res;
    }
    if (mounted) {
      setState(() => _isCheckingQuality = false);
    }
  }

  void _removeImage(int index) {
    setState(() {
      final removed = _paths.removeAt(index);
      _qualityResults.remove(removed);
    });
    if (_paths.isEmpty) {
      Navigator.of(context).pop();
    }
  }

  void _showFullscreenPreview(String path, int index) {
    final quality = _qualityResults[path];
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(12),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppBar(
                title: Text('Sample #${index + 1} Preview'),
                backgroundColor: Colors.white,
                elevation: 0,
                leading: IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(ctx).pop(),
                ),
              ),
              Flexible(
                child: buildSafeImage(
                  path: path,
                  fit: BoxFit.contain,
                  fallback: Container(
                    height: 240,
                    color: AppTheme.bgSlate,
                    child: const Center(child: Icon(Icons.broken_image, size: 48, color: AppTheme.textMuted)),
                  ),
                ),
              ),
              if (quality != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  color: quality.isPassed ? const Color(0xFFDCFCE7) : const Color(0xFFFEF3C7),
                  child: Row(
                    children: [
                      Icon(
                        quality.isPassed ? Icons.check_circle : Icons.warning_amber,
                        color: quality.isPassed ? AppTheme.successGreen : AppTheme.warningAmber,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          quality.isPassed ? '✓ Image quality acceptable' : 'Image quality is low: ${quality.issues.join(", ")}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: quality.isPassed ? AppTheme.successGreen : const Color(0xFF92400E),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _proceedToAiAnalysis() {
    final hasLowQuality = _qualityResults.values.any((q) => !q.isPassed);

    if (hasLowQuality) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Image Quality Notice'),
          content: const Text(
            'One or more sample images have low resolution, blur, or uneven lighting.\n\nDo you want to proceed with AI analysis anyway or retake?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Retake'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryTeal),
              onPressed: () {
                Navigator.of(ctx).pop();
                _navigateToAnalysis();
              },
              child: const Text('Use Anyway'),
            ),
          ],
        ),
      );
    } else {
      _navigateToAnalysis();
    }
  }

  void _navigateToAnalysis() {
    final updated = widget.inspection.copyWith(
      imagePaths: _paths,
      status: InspectionStatus.imagesReady,
    );

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AiAnalysisScreen(inspection: updated),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasLowQuality = _qualityResults.values.any((q) => !q.isPassed);

    return Scaffold(
      backgroundColor: AppTheme.bgSlate,
      appBar: AppBar(
        title: const Text('Review Samples'),
      ),
      body: Column(
        children: [
          // Header banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: Colors.white,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Review Samples',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.darkSlate),
                    ),
                    Text(
                      '${_paths.length} ${_paths.length == 1 ? "image" : "images"} captured for Batch ${widget.inspection.batchId}',
                      style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                    ),
                  ],
                ),
                if (_isCheckingQuality) ...[
                  const Row(
                    children: [
                      SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2)),
                      SizedBox(width: 6),
                      Text('Checking image...', style: TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                    ],
                  ),
                ] else if (!hasLowQuality) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDCFCE7),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      '✓ Image quality acceptable',
                      style: TextStyle(color: AppTheme.successGreen, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
                ] else ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'Low quality detected',
                      style: TextStyle(color: AppTheme.warningAmber, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const Divider(height: 1),

          // Low quality notice banner if applicable
          if (!_isCheckingQuality && hasLowQuality) ...[
            Container(
              margin: const EdgeInsets.all(12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFBEB),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFFDE68A)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.warning_amber, color: AppTheme.warningAmber, size: 20),
                  SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Image quality is low',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF92400E)),
                        ),
                        Text(
                          'Possible issue: Blur / Low light / Poor visibility',
                          style: TextStyle(fontSize: 11, color: Color(0xFFB45309)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Grid of sample images
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.95,
              ),
              itemCount: _paths.length,
              itemBuilder: (context, index) {
                final path = _paths[index];
                final q = _qualityResults[path];
                final isLow = q != null && !q.isPassed;

                return ImageThumbnail(
                  imagePath: path,
                  sampleNumber: index + 1,
                  isQualityLow: isLow,
                  onTap: () => _showFullscreenPreview(path, index),
                  onDelete: () => _removeImage(index),
                );
              },
            ),
          ),

          // Bottom Action
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: PrimaryButton(
              label: 'Analyze Samples',
              icon: Icons.psychology,
              height: 52,
              onPressed: _isCheckingQuality ? null : _proceedToAiAnalysis,
            ),
          ),
        ],
      ),
    );
  }
}
