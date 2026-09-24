import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/empty_state_view.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../data/repositories/inspection_repository.dart';
import '../../../models/inspection.dart';
import 'report_viewer_screen.dart';

class ReportsListScreen extends StatefulWidget {
  const ReportsListScreen({super.key});

  @override
  State<ReportsListScreen> createState() => _ReportsListScreenState();
}

class _ReportsListScreenState extends State<ReportsListScreen> {
  final InspectionRepository _repository = InspectionRepository();
  List<Inspection> _reports = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadReports();
  }

  Future<void> _loadReports() async {
    setState(() => _isLoading = true);
    final all = await _repository.getAllInspections();
    if (mounted) {
      setState(() {
        _reports = all.where((i) =>
            i.status == InspectionStatus.completed ||
            i.status == InspectionStatus.aiAssessed ||
            i.gradingResult != null ||
            i.detections.isNotEmpty).toList();
        _isLoading = false;
      });
    }
  }

  Future<void> _openReport(Inspection inspection) async {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ReportViewerScreen(
          pdfPath: inspection.pdfReportPath,
          inspectionCode: inspection.inspectionCode,
          inspection: inspection,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _reports.where((i) {
      if (_searchQuery.isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      return i.inspectionCode.toLowerCase().contains(q) || i.batchId.toLowerCase().contains(q);
    }).toList();

    return Scaffold(
      backgroundColor: AppTheme.bgSlate,
      appBar: AppBar(
        title: const Text('Inspection Reports'),
      ),
      body: Column(
        children: [
          // Search bar
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search by Inspection ID or Batch ID',
                prefixIcon: const Icon(Icons.search, size: 20),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onChanged: (val) => setState(() => _searchQuery = val.trim()),
            ),
          ),
          const Divider(height: 1),

          // Content
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : filtered.isEmpty
                    ? const EmptyStateView(
                        icon: Icons.description,
                        title: 'No reports available',
                        description: 'Complete onion inspections to view and generate official procurement quality certificates.',
                      )
                    : RefreshIndicator(
                        onRefresh: _loadReports,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: filtered.length,
                          itemBuilder: (context, index) {
                            final insp = filtered[index];
                            final grading = insp.gradingResult;
                            final dateStr = DateFormat('dd MMM yyyy, hh:mm a').format(insp.inspectedAt);

                            return Card(
                              margin: const EdgeInsets.only(bottom: 10),
                              child: Padding(
                                padding: const EdgeInsets.all(14),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          insp.inspectionCode,
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w800,
                                            color: AppTheme.primaryTeal,
                                          ),
                                        ),
                                        StatusBadge.verified(),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      'Batch: ${insp.batchId} • ${insp.centerName}',
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: AppTheme.darkSlate,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      dateStr,
                                      style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                                    ),
                                    const SizedBox(height: 10),
                                    const Divider(height: 1),
                                    const SizedBox(height: 10),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        if (grading != null) ...[
                                          Text(
                                            'Grade: ${grading.gradeName} (${grading.gradeAPercentage.toStringAsFixed(0)}%)',
                                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                          ),
                                        ] else ...[
                                          const Text('Assessment Finalized', style: TextStyle(fontSize: 12)),
                                        ],
                                        ElevatedButton.icon(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: AppTheme.primaryTeal,
                                            foregroundColor: Colors.white,
                                            minimumSize: const Size(120, 36),
                                            padding: const EdgeInsets.symmetric(horizontal: 12),
                                          ),
                                          icon: const Icon(Icons.visibility, size: 14),
                                          label: const Text('View Report', style: TextStyle(fontSize: 12)),
                                          onPressed: () => _openReport(insp),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}
