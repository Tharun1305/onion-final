import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/platform_file_image.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../data/repositories/inspection_repository.dart';
import '../../../models/inspection.dart';
import '../../../models/onion_detection.dart';
import '../../../models/grading_result.dart';
import '../../grading/onion_quality_grader.dart';
import '../../inspection/add_onion_image_screen.dart';
import '../../reports/presentation/report_viewer_screen.dart';

class AiResultScreen extends StatefulWidget {
  final Inspection inspection;
  final OnionDetection? primaryDetection;

  const AiResultScreen({
    super.key,
    required this.inspection,
    this.primaryDetection,
  });

  @override
  State<AiResultScreen> createState() => _AiResultScreenState();
}

class _AiResultScreenState extends State<AiResultScreen> {
  final InspectionRepository _repository = InspectionRepository();
  bool _isSaving = false;

  // Configurable confidence threshold
  static const double lowConfidenceThresholdPercent = 60.0;

  OnionDetection? get _detection {
    if (widget.primaryDetection != null) return widget.primaryDetection;
    if (widget.inspection.detections.isNotEmpty) return widget.inspection.detections.first;
    return null;
  }

  void _onRetake() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => AddOnionImageScreen(inspection: widget.inspection),
      ),
    );
  }

  Future<Inspection?> _persistInspection() async {
    setState(() => _isSaving = true);
    try {
      final now = DateTime.now();
      final det = _detection;
      final rawProb = det?.probabilities ?? {};
      final conf = (det?.aiConfidence ?? 0.8) * 100.0;
      final rawClass = det?.rawClassName ?? (det?.aiClass.name ?? 'healthy');

      final qualityGrade = OnionQualityGrader.evaluate(
        rawPrediction: rawClass,
        confidence: conf,
        probabilities: rawProb,
      );

      final grading = widget.inspection.gradingResult ??
          GradingResult(
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

      final finalInspection = widget.inspection.copyWith(
        status: InspectionStatus.completed,
        syncStatus: SyncStatus.pendingSync,
        gradingResult: grading,
        updatedAt: now,
      );

      // Save via repository architecture (In-memory on Web, SQLite on Android/Desktop)
      await _repository.saveInspection(finalInspection);
      if (finalInspection.detections.isNotEmpty) {
        await _repository.saveDetections(finalInspection.detections);
      }
      if (finalInspection.validations.isNotEmpty) {
        await _repository.saveValidations(finalInspection.validations);
      }
      if (finalInspection.gradingResult != null) {
        await _repository.saveGradingResult(finalInspection.gradingResult!);
      }

      return finalInspection;
    } catch (e) {
      debugPrint('[AiResultScreen] Save inspection error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving inspection: $e'),
            backgroundColor: AppTheme.errorRed,
          ),
        );
      }
      return null;
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _saveAndContinue() async {
    final finalInspection = await _persistInspection();
    if (finalInspection == null || !mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Inspection ${finalInspection.inspectionCode} saved successfully.'),
        backgroundColor: AppTheme.successGreen,
        duration: const Duration(seconds: 2),
      ),
    );

    // Return to Dashboard
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  Future<void> _saveAndViewReport() async {
    final finalInspection = await _persistInspection();
    if (finalInspection == null || !mounted) return;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ReportViewerScreen(
          inspectionCode: finalInspection.inspectionCode,
          inspection: finalInspection,
        ),
      ),
    );
  }

  String _formatClassLabel(String key) {
    switch (key.toLowerCase().replaceAll('_', '').replaceAll(' ', '').trim()) {
      case 'healthy':
        return 'Healthy';
      case 'sprouted':
        return 'Sprouted';
      case 'blackrot':
        return 'Black Rot';
      case 'mold':
        return 'Mold';
      case 'damaged':
        return 'Damaged';
      case 'softrot':
        return 'Soft Rot';
      default:
        return key.replaceAll('_', ' ').titleCase();
    }
  }

  Color _getClassColor(String key) {
    final parsed = AppConstants.parseOnionClass(key);
    return AppConstants.getClassColor(parsed);
  }

  Widget _buildImagePreview() {
    final imagePath = widget.inspection.imagePaths.isNotEmpty
        ? widget.inspection.imagePaths.first
        : null;

    return buildSafeImage(
      bytes: widget.inspection.imageBytes,
      path: imagePath,
      fit: BoxFit.cover,
      fallback: const Center(
        child: Icon(Icons.image, size: 40, color: AppTheme.textMuted),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final det = _detection;

    // If no real detection exists, show error state instead of fake prediction
    if (det == null) {
      return Scaffold(
        backgroundColor: AppTheme.bgSlate,
        appBar: AppBar(
          title: const Text('Analysis Result'),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 56, color: AppTheme.errorRed),
                const SizedBox(height: 16),
                const Text(
                  'No AI prediction available',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.darkSlate),
                ),
                const SizedBox(height: 8),
                const Text(
                  'The AI inference pipeline did not return valid detection results for this sample.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryTeal,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retake Sample'),
                  onPressed: _onRetake,
                ),
              ],
            ),
          ),
        ),
      );
    }

    final confidencePercent = det.aiConfidence * 100.0;
    final isHealthy = det.aiClass == OnionClass.healthy;
    final isLowConfidence = confidencePercent < lowConfidenceThresholdPercent;

    final probabilities = det.probabilities ?? {
      (det.rawClassName ?? 'healthy'): confidencePercent,
    };

    // Sort probabilities in descending order
    final sortedEntries = probabilities.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final displayPrediction = AppConstants.formatOnionClass(det.aiClass);
    final statusText = isHealthy ? 'Healthy' : 'Defective';
    final statusColor = isHealthy ? AppTheme.successGreen : AppTheme.errorRed;

    final qualityGrade = OnionQualityGrader.evaluate(
      rawPrediction: det.rawClassName ?? det.aiClass.name,
      confidence: confidencePercent,
      probabilities: probabilities,
    );

    return Scaffold(
      backgroundColor: AppTheme.bgSlate,
      appBar: AppBar(
        title: const Text(
          'Onion Health Assessment',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppTheme.darkSlate),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Captured Onion Image Card
              Center(
                child: Container(
                  height: 220,
                  width: double.infinity,
                  constraints: const BoxConstraints(maxWidth: 360),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.borderGray),
                    boxShadow: const [
                      BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 3)),
                    ],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      _buildImagePreview(),
                      // Batch Tag on Image
                      Positioned(
                        top: 10,
                        left: 10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.7),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Batch: ${widget.inspection.batchId}',
                            style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Low Confidence Banner
              if (isLowConfidence) ...[
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFFCD34D)),
                  ),
                  child: const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.warning_amber_rounded, color: Color(0xFFD97706), size: 22),
                      SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Low Confidence Prediction',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF92400E),
                              ),
                            ),
                            SizedBox(height: 3),
                            Text(
                              'Please capture another image with better lighting and ensure the onion is clearly visible.',
                              style: TextStyle(fontSize: 11, color: Color(0xFFB45309), height: 1.3),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
              ],

              // Primary Assessment Summary Card
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppTheme.borderGray),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Top Row: PREDICTION & STATUS
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'PREDICTION',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.textMuted,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              displayPrediction,
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                                color: _getClassColor(det.rawClassName ?? det.aiClass.name),
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                statusText.toUpperCase(),
                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: statusColor),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // VISUALLY PROMINENT QUALITY GRADE BANNER
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: qualityGrade.bgColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: qualityGrade.borderColor, width: 1.5),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              color: qualityGrade.color,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: qualityGrade.color.withValues(alpha: 0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Center(
                              child: Text(
                                qualityGrade.letter,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 26,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Text(
                                      'QUALITY GRADE',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w800,
                                        color: AppTheme.textMuted,
                                        letterSpacing: 0.8,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: qualityGrade.color.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        qualityGrade.shortLabel,
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: qualityGrade.color,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  qualityGrade.title,
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                    color: qualityGrade.color,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  qualityGrade.description,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFF64748B),
                                    height: 1.25,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const Divider(height: 24),

                    // Key Summary Metrics: CONFIDENCE, QUALITY GRADE, STATUS, VARIETY
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildSummaryItem('CONFIDENCE', '${confidencePercent.toStringAsFixed(2)}%', isHighlight: true),
                        _buildSummaryItem('QUALITY GRADE', qualityGrade.letter, isHighlight: true, highlightColor: qualityGrade.color),
                        _buildSummaryItem('STATUS', statusText),
                        _buildSummaryItem('VARIETY', widget.inspection.variety ?? 'Red Onion'),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // AI Analysis Probability Breakdown Table
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppTheme.borderGray),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'AI Analysis',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppTheme.darkSlate),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryTeal.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'Trained Model',
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.primaryTeal),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Probabilities List
                    ...sortedEntries.map((entry) {
                      final label = _formatClassLabel(entry.key);
                      final val = entry.value;
                      final isTop = entry.key == (det.rawClassName ?? det.aiClass.name);
                      final color = _getClassColor(entry.key);

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      width: 10,
                                      height: 10,
                                      decoration: BoxDecoration(
                                        color: color,
                                        borderRadius: BorderRadius.circular(2),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      label,
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: isTop ? FontWeight.w800 : FontWeight.w500,
                                        color: isTop ? AppTheme.darkSlate : const Color(0xFF475569),
                                      ),
                                    ),
                                  ],
                                ),
                                Text(
                                  '${val.toStringAsFixed(2)}%',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: isTop ? FontWeight.w800 : FontWeight.w600,
                                    color: isTop ? AppTheme.primaryTeal : AppTheme.darkSlate,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: (val / 100.0).clamp(0.0, 1.0),
                                backgroundColor: const Color(0xFFF1F5F9),
                                valueColor: AlwaysStoppedAnimation<Color>(color),
                                minHeight: 6,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Consignment Details Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppTheme.borderGray),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'CONSIGNMENT DETAILS',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.textMuted),
                    ),
                    const SizedBox(height: 12),
                    _buildInfoRow('Inspection Code', widget.inspection.inspectionCode),
                    _buildInfoRow('Batch ID', widget.inspection.batchId),
                    _buildInfoRow('Procurement Center', widget.inspection.centerName ?? 'Erode Center'),
                    _buildInfoRow('Inspector', widget.inspection.inspectorName),
                    _buildInfoRow('Total Consignment', '${widget.inspection.quantity?.toStringAsFixed(0) ?? "850"} kg'),
                    _buildInfoRow('Source / Supplier', widget.inspection.source ?? 'Local Procurement'),
                    _buildInfoRow('Variety', widget.inspection.variety ?? 'Red Onion'),
                    if (widget.inspection.notes != null && widget.inspection.notes!.isNotEmpty)
                      _buildInfoRow('Notes', widget.inspection.notes!),
                    _buildInfoRow('Assessment Time', DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now())),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Action Buttons: Retake, View Report, and Accept & Save
              Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        flex: 1,
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.darkSlate,
                            side: const BorderSide(color: AppTheme.borderGray, width: 1.5),
                            minimumSize: const Size.fromHeight(48),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          icon: const Icon(Icons.refresh, size: 18),
                          label: const Text('Retake', style: TextStyle(fontWeight: FontWeight.bold)),
                          onPressed: _isSaving ? null : _onRetake,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 1,
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.primaryTeal,
                            side: const BorderSide(color: AppTheme.primaryTeal, width: 1.5),
                            minimumSize: const Size.fromHeight(48),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          icon: const Icon(Icons.description_outlined, size: 18),
                          label: const Text('View Report', style: TextStyle(fontWeight: FontWeight.bold)),
                          onPressed: _isSaving ? null : _saveAndViewReport,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  PrimaryButton(
                    label: 'Accept & Save Inspection',
                    icon: Icons.check_circle,
                    height: 52,
                    isLoading: _isSaving,
                    onPressed: _saveAndContinue,
                  ),
                ],
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, {bool isHighlight = false, Color? highlightColor}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppTheme.textMuted, letterSpacing: 0.3)),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isHighlight ? FontWeight.w800 : FontWeight.w600,
            color: highlightColor ?? (isHighlight ? AppTheme.primaryTeal : AppTheme.darkSlate),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.darkSlate),
            ),
          ),
        ],
      ),
    );
  }
}

extension StringExtension on String {
  String titleCase() {
    if (isEmpty) return this;
    return split(' ').map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }
}
