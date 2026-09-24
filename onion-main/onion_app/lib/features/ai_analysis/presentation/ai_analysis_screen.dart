import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/platform_file_image.dart';
import '../../../models/image_input.dart';
import '../../../models/inspection.dart';
import '../../../models/validation_record.dart';
import '../../grading/onion_quality_grader.dart';
import '../../../models/grading_result.dart';
import '../domain/onion_inference_engine.dart';
import '../domain/real_on_device_inference_engine.dart';
import 'ai_result_screen.dart';

class AiAnalysisScreen extends StatefulWidget {
  final Inspection inspection;
  final ImageInput? imageInput;

  const AiAnalysisScreen({
    super.key,
    required this.inspection,
    this.imageInput,
  });

  @override
  State<AiAnalysisScreen> createState() => _AiAnalysisScreenState();
}

class _AiAnalysisScreenState extends State<AiAnalysisScreen> {
  final OnionInferenceEngine _engine = RealOnDeviceInferenceEngine();
  int _currentStep = 0;
  String? _errorMessage;

  final List<String> _stages = [
    'Loading sample image',
    'Preprocessing & tensor normalization (384x384)',
    'Running trained EfficientNetV2-S model',
    'Evaluating defect probabilities',
    'Finalizing health assessment',
  ];

  @override
  void initState() {
    super.initState();
    _runPipeline();
  }

  Future<void> _runPipeline() async {
    setState(() {
      _currentStep = 0;
      _errorMessage = null;
    });

    try {
      final imagePath = widget.inspection.imagePaths.isNotEmpty
          ? widget.inspection.imagePaths.first
          : '';
      final imageBytes = widget.inspection.imageBytes ?? widget.imageInput?.bytes;

      if (imagePath.isEmpty && (imageBytes == null || imageBytes.isEmpty)) {
        throw Exception('No captured image found for analysis.');
      }

      // Step 0: Loading sample image
      setState(() => _currentStep = 0);
      await Future.delayed(const Duration(milliseconds: 250));

      // Step 1: Preprocessing
      if (!mounted) return;
      setState(() => _currentStep = 1);
      await Future.delayed(const Duration(milliseconds: 250));

      // Step 2: Running trained model asynchronously
      if (!mounted) return;
      setState(() => _currentStep = 2);

      final detections = await _engine.analyze(
        inspectionId: widget.inspection.id,
        imagePath: imagePath,
        imageBytes: imageBytes,
        sampleNumber: 1,
      );

      if (detections.isEmpty) {
        throw Exception('AI model did not return any prediction for this image.');
      }

      final primaryDetection = detections.first;

      // Step 3: Evaluating defect probabilities
      if (!mounted) return;
      setState(() => _currentStep = 3);
      await Future.delayed(const Duration(milliseconds: 250));

      // Step 4: Finalizing
      if (!mounted) return;
      setState(() => _currentStep = 4);
      await Future.delayed(const Duration(milliseconds: 250));

      // Build initial validation record
      final validations = [
        ValidationRecord(
          id: 'val-${primaryDetection.id}',
          inspectionId: widget.inspection.id,
          detectionId: primaryDetection.id,
          originalAiClass: primaryDetection.aiClass,
          aiConfidence: primaryDetection.aiConfidence,
          inspectorClass: primaryDetection.aiClass,
          finalClass: primaryDetection.aiClass,
          isCorrected: false,
          validatedBy: widget.inspection.inspectorName,
          validatedAt: DateTime.now(),
        ),
      ];

      // Calculate deterministic Quality Grade (A/B/C/D) from real model output
      final qualityGrade = OnionQualityGrader.evaluate(
        rawPrediction: primaryDetection.rawClassName ?? primaryDetection.aiClass.name,
        confidence: primaryDetection.aiConfidence * 100.0,
        probabilities: primaryDetection.probabilities ?? {},
      );

      final initialGrading = GradingResult(
        id: 'grade-${widget.inspection.id}',
        inspectionId: widget.inspection.id,
        totalSample: 1,
        gradeACount: qualityGrade == QualityGrade.A ? 1 : 0,
        gradeAPercentage: qualityGrade == QualityGrade.A ? 100.0 : 0.0,
        ursCount: qualityGrade == QualityGrade.B ? 1 : 0,
        ursPercentage: qualityGrade == QualityGrade.B ? 100.0 : 0.0,
        otherDefectsCount: (qualityGrade == QualityGrade.C || qualityGrade == QualityGrade.D) ? 1 : 0,
        otherDefectsPercentage: (qualityGrade == QualityGrade.C || qualityGrade == QualityGrade.D) ? 100.0 : 0.0,
        finalGrade: qualityGrade.title,
        rulesVersion: 'v2.0-deterministic-quality',
      );

      final updated = widget.inspection.copyWith(
        sampleCount: 1,
        status: InspectionStatus.aiAssessed,
        detections: [primaryDetection],
        validations: validations,
        gradingResult: initialGrading,
        updatedAt: DateTime.now(),
      );

      if (!mounted) return;

      // Navigate to AI Result Screen
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => AiResultScreen(
            inspection: updated,
            primaryDetection: primaryDetection,
          ),
        ),
      );
    } catch (e) {
      debugPrint('[AiAnalysisScreen] Analysis error: $e');
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceFirst('Exception: ', '');
        });
      }
    }
  }

  Widget _buildImagePreview() {
    final imageBytes = widget.inspection.imageBytes ?? widget.imageInput?.bytes;
    final imagePath = widget.inspection.imagePaths.isNotEmpty
        ? widget.inspection.imagePaths.first
        : null;

    return buildSafeImage(
      bytes: imageBytes,
      path: imagePath,
      fit: BoxFit.cover,
      fallback: const Center(
        child: Icon(Icons.image, size: 40, color: AppTheme.textMuted),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgSlate,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Title
                  const Text(
                    'Analyzing Onion...',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.darkSlate,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Running AI health assessment',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13, color: AppTheme.textMuted),
                  ),
                  const SizedBox(height: 20),

                  // Captured Image Preview
                  Center(
                    child: Container(
                      width: 180,
                      height: 180,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppTheme.primaryTeal, width: 2),
                        boxShadow: const [
                          BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4)),
                        ],
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          _buildImagePreview(),
                          if (_errorMessage == null)
                            Container(
                              color: Colors.black.withValues(alpha: 0.2),
                              child: const Center(
                                child: SizedBox(
                                  width: 32,
                                  height: 32,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 3,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  if (_errorMessage != null) ...[
                    // Error state card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF2F2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFFCA5A5)),
                      ),
                      child: Column(
                        children: [
                          const Icon(Icons.error_outline, color: Color(0xFFDC2626), size: 36),
                          const SizedBox(height: 10),
                          const Text(
                            'Unable to analyze this image',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF991B1B),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _errorMessage!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 12, color: Color(0xFF7F1D1D)),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () => Navigator.of(context).pop(),
                                  child: const Text('Back'),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.primaryTeal,
                                    foregroundColor: Colors.white,
                                  ),
                                  onPressed: _runPipeline,
                                  child: const Text('Retry'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    // Staged Progress Checklist
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.borderGray),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: List.generate(_stages.length, (index) {
                          final isCompleted = index < _currentStep;
                          final isCurrent = index == _currentStep;

                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Row(
                              children: [
                                if (isCompleted)
                                  Container(
                                    width: 22,
                                    height: 22,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFFDCFCE7),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Center(
                                      child: Icon(Icons.check, size: 14, color: AppTheme.successGreen),
                                    ),
                                  )
                                else if (isCurrent)
                                  Container(
                                    width: 22,
                                    height: 22,
                                    decoration: BoxDecoration(
                                      color: AppTheme.primaryTeal.withValues(alpha: 0.15),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Center(
                                      child: SizedBox(
                                        width: 12,
                                        height: 12,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: AppTheme.primaryTeal,
                                        ),
                                      ),
                                    ),
                                  )
                                else
                                  Container(
                                    width: 22,
                                    height: 22,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(color: AppTheme.borderGray, width: 1.5),
                                    ),
                                  ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Text(
                                    _stages[index],
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: isCurrent
                                          ? FontWeight.w700
                                          : (isCompleted ? FontWeight.w600 : FontWeight.normal),
                                      color: isCompleted
                                          ? AppTheme.darkSlate
                                          : (isCurrent ? AppTheme.primaryTeal : AppTheme.textMuted),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Center(
                      child: Text(
                        'AI inference using trained Onion model\nPrecision assessment in progress...',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 11, color: AppTheme.textMuted, height: 1.4),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
