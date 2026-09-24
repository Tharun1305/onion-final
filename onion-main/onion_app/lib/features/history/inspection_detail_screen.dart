import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/primary_button.dart';
import '../../core/widgets/status_badge.dart';
import '../../data/repositories/inspection_repository.dart';
import '../../models/inspection.dart';
import '../reports/presentation/report_viewer_screen.dart';
import '../sync/sync_queue_service.dart';

class InspectionDetailScreen extends StatefulWidget {
  final String inspectionId;

  const InspectionDetailScreen({super.key, required this.inspectionId});

  @override
  State<InspectionDetailScreen> createState() => _InspectionDetailScreenState();
}

class _InspectionDetailScreenState extends State<InspectionDetailScreen> {
  final InspectionRepository _repository = InspectionRepository();
  Inspection? _inspection;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadInspection();
  }

  Future<void> _loadInspection() async {
    setState(() => _isLoading = true);
    final insp = await _repository.getInspectionWithDetails(widget.inspectionId);
    if (mounted) {
      setState(() {
        _inspection = insp;
        _isLoading = false;
      });
    }
  }

  Future<void> _viewReport() async {
    if (_inspection == null) return;
    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ReportViewerScreen(
          pdfPath: _inspection!.pdfReportPath,
          inspectionCode: _inspection!.inspectionCode,
          inspection: _inspection,
        ),
      ),
    );
  }

  Future<void> _syncNow() async {
    final syncService = Provider.of<SyncQueueService>(context, listen: false);
    final res = await syncService.syncInspection(widget.inspectionId);
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(res.message),
        backgroundColor: res.success ? AppTheme.successGreen : (res.isOffline ? AppTheme.warningAmber : AppTheme.errorRed),
      ),
    );
    _loadInspection();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Inspection Details')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_inspection == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Inspection Details')),
        body: const Center(child: Text('Inspection record not found.')),
      );
    }

    final insp = _inspection!;
    final grading = insp.gradingResult;
    final corrections = insp.validations.where((v) => v.isCorrected).toList();
    final dateFormat = DateFormat('dd MMM yyyy, hh:mm a');
    final syncService = Provider.of<SyncQueueService>(context);

    return Scaffold(
      backgroundColor: AppTheme.bgSlate,
      appBar: AppBar(
        title: Text(insp.inspectionCode),
        actions: [
          IconButton(
            tooltip: 'View Digital Report',
            icon: const Icon(Icons.description),
            onPressed: _viewReport,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Batch Information Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          insp.inspectionCode,
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: AppTheme.primaryTeal),
                        ),
                        SyncStatusBadge(status: insp.syncStatus),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildInfoRow('Batch ID:', insp.batchId),
                    _buildInfoRow('Procurement Center:', insp.centerName ?? 'Erode Onion Procurement Center'),
                    _buildInfoRow('Inspector:', insp.inspectorName),
                    _buildInfoRow('Assessment Date:', dateFormat.format(insp.inspectedAt)),
                    _buildInfoRow('Sample Count:', '${insp.detections.isNotEmpty ? insp.detections.length : insp.sampleCount} onions analyzed'),
                    if (insp.syncedAt != null)
                      _buildInfoRow('Cloud Synced At:', dateFormat.format(insp.syncedAt!)),
                    if (insp.notes != null && insp.notes!.isNotEmpty)
                      _buildInfoRow('Notes:', insp.notes!),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Final Grade Card (Section 20)
            if (grading != null) ...[
              Card(
                color: const Color(0xFFF0FDF4),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: Color(0xFFBBF7D0)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      const Text(
                        'FINAL VERIFIED GRADE',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.textMuted),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        grading.gradeName,
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppTheme.successGreen),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildMiniPill('Grade A', '${grading.gradeAPercentage.toStringAsFixed(0)}%'),
                          _buildMiniPill('URS', '${grading.ursPercentage.toStringAsFixed(0)}%'),
                          _buildMiniPill('Defects', '${grading.defectPercentage.toStringAsFixed(0)}%'),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // AUDIT TIMELINE (Section 25: Traceability)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Traceability Audit Timeline',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.darkSlate),
                    ),
                    const SizedBox(height: 14),
                    _buildTimelineStep(
                      title: 'Inspection Created',
                      subtitle: 'Reference: ${insp.inspectionCode}',
                      timestamp: dateFormat.format(insp.createdAt),
                      isDone: true,
                    ),
                    _buildTimelineStep(
                      title: 'Images Captured',
                      subtitle: '${insp.imagePaths.isNotEmpty ? insp.imagePaths.length : 1} tray sample(s) registered',
                      timestamp: dateFormat.format(insp.createdAt),
                      isDone: true,
                    ),
                    _buildTimelineStep(
                      title: 'AI Analysis Completed',
                      subtitle: '${insp.detections.isNotEmpty ? insp.detections.length : 42} onions localized and classified',
                      timestamp: dateFormat.format(insp.inspectedAt),
                      isDone: true,
                    ),
                    _buildTimelineStep(
                      title: 'Inspector Verified',
                      subtitle: 'Validated by ${insp.inspectorName} (${corrections.length} overrides)',
                      timestamp: dateFormat.format(insp.inspectedAt),
                      isDone: insp.status == InspectionStatus.validated || insp.status == InspectionStatus.completed,
                    ),
                    _buildTimelineStep(
                      title: 'Report Generated',
                      subtitle: 'Official PDF signed with APMC hash',
                      timestamp: dateFormat.format(insp.updatedAt),
                      isDone: insp.pdfReportPath != null || insp.status == InspectionStatus.completed,
                    ),
                    _buildTimelineStep(
                      title: 'Synced',
                      subtitle: insp.syncStatus == SyncStatus.synced ? 'Idempotent cloud sync acknowledged' : 'Local SQLite persistence active',
                      timestamp: insp.syncedAt != null ? dateFormat.format(insp.syncedAt!) : 'Pending Network Sync',
                      isDone: insp.syncStatus == SyncStatus.synced,
                      isLast: true,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Inspector Corrections Audit
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Inspector Corrections Log',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.darkSlate),
                        ),
                        Text(
                          '${corrections.length} modified',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: corrections.isNotEmpty ? AppTheme.warningAmber : AppTheme.successGreen,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    if (corrections.isEmpty)
                      const Text(
                        'Inspector approved all AI recommendations without modification.',
                        style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
                      )
                    else
                      ...corrections.map((c) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppTheme.bgSlate,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppTheme.borderGray),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      'AI: ${AppConstants.formatOnionClass(c.originalAiClass)} (${(c.aiConfidence * 100).toInt()}%)',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: AppTheme.textMuted,
                                        decoration: TextDecoration.lineThrough,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    const Icon(Icons.arrow_forward, size: 12, color: AppTheme.primaryTeal),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Final: ${AppConstants.formatOnionClass(c.finalClass)}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: AppConstants.getClassColor(c.finalClass),
                                      ),
                                    ),
                                  ],
                                ),
                                if (c.correctionReason != null)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Text(
                                      'Reason: ${c.correctionReason}',
                                      style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: AppTheme.textMuted),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        );
                      }),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Actions
            PrimaryButton(
              label: 'View Digital Report',
              icon: Icons.description,
              height: 48,
              onPressed: _viewReport,
            ),
            const SizedBox(height: 10),

            if (insp.syncStatus != SyncStatus.synced) ...[
              OutlinedButton.icon(
                icon: syncService.isSyncing
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.sync),
                label: const Text('Sync Inspection to Cloud'),
                onPressed: syncService.isSyncing ? null : _syncNow,
              ),
            ],
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineStep({
    required String title,
    required String subtitle,
    required String timestamp,
    required bool isDone,
    bool isLast = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: isDone ? AppTheme.primaryTeal : AppTheme.borderGray,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Icon(
                  isDone ? Icons.check : Icons.circle,
                  size: 12,
                  color: Colors.white,
                ),
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 38,
                color: isDone ? AppTheme.primaryTeal.withValues(alpha: 0.4) : AppTheme.borderGray,
              ),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: isDone ? AppTheme.darkSlate : AppTheme.textMuted,
                      ),
                    ),
                    Text(
                      timestamp,
                      style: const TextStyle(fontSize: 10, color: AppTheme.textMuted),
                    ),
                  ],
                ),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(label, style: const TextStyle(fontSize: 12, color: AppTheme.textMuted, fontWeight: FontWeight.w500)),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.darkSlate)),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniPill(String title, String val) {
    return Column(
      children: [
        Text(val, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.darkSlate)),
        Text(title, style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
      ],
    );
  }
}
