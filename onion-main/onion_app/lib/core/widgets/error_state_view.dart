import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'primary_button.dart';

class ErrorStateView extends StatelessWidget {
  final String title;
  final String message;
  final String? retryLabel;
  final VoidCallback? onRetry;
  final IconData icon;

  const ErrorStateView({
    super.key,
    required this.title,
    required this.message,
    this.retryLabel = 'Try Again',
    this.onRetry,
    this.icon = Icons.error_outline,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFEE2E2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 36,
                color: AppTheme.errorRed,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppTheme.darkSlate,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              message,
              style: const TextStyle(
                fontSize: 13,
                color: AppTheme.textMuted,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 20),
              PrimaryButton(
                label: retryLabel ?? 'Retry',
                onPressed: onRetry,
                icon: Icons.refresh,
                height: 44,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
