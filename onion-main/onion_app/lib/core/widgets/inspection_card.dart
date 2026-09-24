import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/inspection.dart';
import '../constants/app_constants.dart';
import '../theme/app_theme.dart';
import 'status_badge.dart';

class InspectionCard extends StatelessWidget {
  final Inspection inspection;
  final VoidCallback onTap;

  const InspectionCard({
    super.key,
    required this.inspection,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final grading = inspection.gradingResult;
    final dateStr = DateFormat('dd MMM yyyy, hh:mm a').format(inspection.inspectedAt);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 5),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Inspection Code & Sync Status
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    inspection.inspectionCode,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.primaryTeal,
                      letterSpacing: 0.1,
                    ),
                  ),
                  SyncStatusBadge(status: inspection.syncStatus),
                ],
              ),
              const SizedBox(height: 6),

              // Batch ID & Date
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Batch ${inspection.batchId}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.darkSlate,
                    ),
                  ),
                  Text(
                    dateStr,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppTheme.textMuted,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              const Divider(height: 1),
              const SizedBox(height: 10),

              // Quality Assessment & Grade
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (grading != null) ...[
                    Row(
                      children: [
                        StatusBadge.grade(grading.gradeName, percentage: grading.gradeAPercentage),
                        const SizedBox(width: 8),
                        Text(
                          'URS: ${grading.ursPercentage.toStringAsFixed(1)}%',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ] else ...[
                    Text(
                      '${inspection.sampleCount} Onions Sampled',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textMuted,
                      ),
                    ),
                  ],

                  if (inspection.status == InspectionStatus.completed ||
                      inspection.status == InspectionStatus.validated)
                    StatusBadge.verified()
                  else
                    StatusBadge.pendingValidation(),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
