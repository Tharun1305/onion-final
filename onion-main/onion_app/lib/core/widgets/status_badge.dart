import 'package:flutter/material.dart';
import '../constants/app_constants.dart';
import '../theme/app_theme.dart';

class StatusBadge extends StatelessWidget {
  final String label;
  final Color backgroundColor;
  final Color textColor;
  final IconData? icon;

  const StatusBadge({
    super.key,
    required this.label,
    required this.backgroundColor,
    required this.textColor,
    this.icon,
  });

  factory StatusBadge.verified() {
    return const StatusBadge(
      label: 'INSPECTOR VERIFIED',
      backgroundColor: Color(0xFFDCFCE7),
      textColor: AppTheme.successGreen,
      icon: Icons.verified_user,
    );
  }

  factory StatusBadge.pendingValidation() {
    return const StatusBadge(
      label: 'AI ASSESSED',
      backgroundColor: Color(0xFFFEF3C7),
      textColor: AppTheme.warningAmber,
      icon: Icons.psychology,
    );
  }

  factory StatusBadge.grade(String grade, {double? percentage}) {
    final text = percentage != null ? '$grade (${percentage.toStringAsFixed(0)}%)' : grade;
    final isA = grade.toUpperCase().contains('A');
    return StatusBadge(
      label: text,
      backgroundColor: isA ? const Color(0xFFCCFBF1) : const Color(0xFFFEF3C7),
      textColor: isA ? AppTheme.primaryTealDark : AppTheme.warningAmber,
      icon: Icons.military_tech,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: textColor.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: textColor),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: textColor,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}

class SyncStatusBadge extends StatelessWidget {
  final SyncStatus status;

  const SyncStatusBadge({
    super.key,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    final color = AppConstants.getSyncStatusColor(status);
    final text = AppConstants.formatSyncStatus(status);

    IconData icon;
    switch (status) {
      case SyncStatus.synced:
        icon = Icons.check_circle;
        break;
      case SyncStatus.syncing:
        icon = Icons.sync;
        break;
      case SyncStatus.pendingSync:
        icon = Icons.schedule;
        break;
      case SyncStatus.syncFailed:
        icon = Icons.error_outline;
        break;
      case SyncStatus.localOnly:
        icon = Icons.cloud_off;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: color,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}
