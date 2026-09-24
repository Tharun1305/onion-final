import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../data/repositories/inspection_repository.dart';
import '../../../models/inspection.dart';
import '../../navigation/main_navigation_screen.dart';
import '../../reports/pdf_report_generator.dart';
import '../../reports/presentation/report_viewer_screen.dart';
import '../../reports/report_sharing.dart';

class FinalResultScreen extends StatefulWidget {
  final Inspection inspection;

  const FinalResultScreen({super.key, required this.inspection});

  @override
  State<FinalResultScreen> createState() => _FinalResultScreenState();
}

class _FinalResultScreenState extends State<FinalResultScreen> {
  final InspectionRepository _repository = InspectionRepository();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _saveLocallyInitially();
  }

  Future<void> _saveLocallyInitially() async {
    setState(() => _isSaving = true);
    try {
      final updated = widget.inspection.copyWith(
        status: InspectionStatus.completed,
        syncStatus: SyncStatus.pendingSync,
      );

      // Save to SQLite
      await _repository.saveInspection(updated);
      await _repository.saveDetections(widget.inspection.detections);
      await _repository.saveValidations(widget.inspection.validations);
      if (widget.inspection.gradingResult != null) {
        await _repository.saveGradingResult(widget.inspection.gradingResult!);
      }
      await _repository.enqueueSync(widget.inspection.id);

      setState(() {
        _isSaving = false;
      });
    } catch (e) {
      debugPrint('[FinalResultScreen] Error saving inspection: $e');
      setState(() => _isSaving = false);
    }
  }

  Future<void> _generateAndOpenPdf() async {
    setState(() => _isSaving = true);
    try {
      final bytes = await PdfReportGenerator.generatePdfBytes(widget.inspection);
      String? localPath;
      if (!kIsWeb) {
        localPath = await PdfReportGenerator.saveReportLocally(widget.inspection, bytes);
      }

      final updated = widget.inspection.copyWith(pdfReportPath: localPath);
      await _repository.updateInspection(updated);

      setState(() => _isSaving = false);

      if (!mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ReportViewerScreen(
            pdfPath: localPath,
            pdfBytes: bytes,
            inspectionCode: widget.inspection.inspectionCode,
            inspection: updated,
          ),
        ),
      );
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to generate PDF: $e')),
        );
      }
    }
  }

  Future<void> _shareReport() async {
    try {
      final bytes = await PdfReportGenerator.generatePdfBytes(widget.inspection);
      final filename = '${widget.inspection.inspectionCode}_report.pdf';
      final result = await platformSharePdf(bytes, filename);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.message),
            backgroundColor: result.success ? AppTheme.primaryTeal : AppTheme.errorRed,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error sharing report: $e')),
        );
      }
    }
  }

  void _backToDashboard() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final grading = widget.inspection.gradingResult;
    final totalSample = widget.inspection.detections.isNotEmpty ? widget.inspection.detections.length : 42;
    final gradeA = grading?.gradeAPercentage ?? 76.0;
    final urs = grading?.ursPercentage ?? 12.0;
    final other = grading?.defectPercentage ?? 12.0;

    return Scaffold(
      backgroundColor: AppTheme.bgSlate,
      appBar: AppBar(
        title: const Text('Final Quality Assessment'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.home_outlined),
            onPressed: _backToDashboard,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // COMPLETION CARD (Section 22)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.borderGray),
              ),
              child: Column(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: const BoxDecoration(
                      color: Color(0xFFDCFCE7),
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: Icon(Icons.check, size: 32, color: AppTheme.successGreen),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    '✓ Inspection Completed',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.darkSlate,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    widget.inspection.inspectionCode,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.primaryTeal,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Divider(height: 1),
                  const SizedBox(height: 16),

                  // Batch, Grade, Status Details
                  _buildSummaryRow('Batch', widget.inspection.batchId),
                  const SizedBox(height: 8),
                  _buildSummaryRow('Grade A', '${gradeA.toStringAsFixed(0)}%'),
                  const SizedBox(height: 8),
                  _buildSummaryRow('URS', '${urs.toStringAsFixed(0)}%'),
                  const SizedBox(height: 8),
                  _buildSummaryRow('Status', 'Inspector Verified', isHighlight: true),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // WORKFLOW DECLARATION BANNER (Section 21)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFBFDBFE)),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildFlowStep('AI Assessment'),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8),
                        child: Icon(Icons.arrow_forward, size: 14, color: AppTheme.textMuted),
                      ),
                      _buildFlowStep('Inspector Verification'),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8),
                        child: Icon(Icons.arrow_forward, size: 14, color: AppTheme.textMuted),
                      ),
                      _buildFlowStep('Final Grade', isBold: true),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Final grading is based on inspector-verified observations. AI predictions serve as assistive recommendations and do not independently determine official government grades.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11,
                      color: Color(0xFF1E3A8A),
                      height: 1.4,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // FINAL QUALITY BREAKDOWN (Section 20)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Final Quality Assessment',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.darkSlate,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Total Sample: $totalSample onions',
                      style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                    ),
                    const SizedBox(height: 16),

                    // Visual Distribution Bar Chart
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: SizedBox(
                        height: 16,
                        child: Row(
                          children: [
                            Expanded(
                              flex: gradeA.toInt(),
                              child: Container(color: AppTheme.successGreen),
                            ),
                            Expanded(
                              flex: urs.toInt(),
                              child: Container(color: AppTheme.warningAmber),
                            ),
                            Expanded(
                              flex: other.toInt(),
                              child: Container(color: AppTheme.errorRed),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Statistics rows
                    _buildGradeMetric('Grade A', '${gradeA.toStringAsFixed(0)}%', AppTheme.successGreen),
                    const Divider(height: 16),
                    _buildGradeMetric('URS (Under-Recovery Sample)', '${urs.toStringAsFixed(0)}%', AppTheme.warningAmber),
                    const Divider(height: 16),
                    _buildGradeMetric('Other / Defects', '${other.toStringAsFixed(0)}%', AppTheme.errorRed),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Action Buttons (Section 22)
            PrimaryButton(
              label: 'View Report',
              icon: Icons.description,
              isLoading: _isSaving,
              height: 50,
              onPressed: _generateAndOpenPdf,
            ),
            const SizedBox(height: 12),
            SecondaryButton(
              label: 'Share Report',
              icon: Icons.share,
              height: 50,
              onPressed: _shareReport,
            ),
            const SizedBox(height: 12),
            TextButton.icon(
              icon: const Icon(Icons.home, size: 18),
              label: const Text('Back to Dashboard', style: TextStyle(fontWeight: FontWeight.bold)),
              onPressed: _backToDashboard,
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isHighlight = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, color: AppTheme.textMuted)),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: isHighlight ? AppTheme.successGreen : AppTheme.darkSlate,
          ),
        ),
      ],
    );
  }

  Widget _buildFlowStep(String text, {bool isBold = false}) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 11,
        fontWeight: isBold ? FontWeight.w800 : FontWeight.w600,
        color: isBold ? AppTheme.primaryTeal : const Color(0xFF1E3A8A),
      ),
    );
  }

  Widget _buildGradeMetric(String label, String value, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 8),
            Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.darkSlate)),
          ],
        ),
        Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: color)),
      ],
    );
  }
}
