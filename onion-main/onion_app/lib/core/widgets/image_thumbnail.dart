import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'platform_file_image.dart';

class ImageThumbnail extends StatelessWidget {
  final String imagePath;
  final Uint8List? imageBytes;
  final int sampleNumber;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;
  final VoidCallback? onRetake;
  final bool isQualityLow;

  const ImageThumbnail({
    super.key,
    required this.imagePath,
    this.imageBytes,
    required this.sampleNumber,
    this.onTap,
    this.onDelete,
    this.onRetake,
    this.isQualityLow = false,
  });

  @override
  Widget build(BuildContext context) {
    final imageWidget = buildSafeImage(
      bytes: imageBytes,
      path: imagePath,
      fit: BoxFit.cover,
      fallback: _buildFallback(),
    );

    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(
          color: isQualityLow ? AppTheme.errorRed : AppTheme.borderGray,
          width: isQualityLow ? 2 : 1,
        ),
      ),
      child: Stack(
        children: [
          // Background / Image
          InkWell(
            onTap: onTap,
            child: SizedBox.expand(
              child: imageWidget,
            ),
          ),

          // Sample Number Badge
          Positioned(
            top: 8,
            left: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'Sample $sampleNumber',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),

          // Quality warning badge if low
          if (isQualityLow)
            Positioned(
              bottom: 8,
              left: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.errorRed,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.warning, color: Colors.white, size: 10),
                    SizedBox(width: 4),
                    Text(
                      'Low Quality',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Controls (Delete / Retake)
          Positioned(
            top: 6,
            right: 6,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (onRetake != null)
                  InkWell(
                    onTap: onRetake,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      margin: const EdgeInsets.only(right: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.6),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.refresh, color: Colors.white, size: 14),
                    ),
                  ),
                if (onDelete != null)
                  InkWell(
                    onTap: onDelete,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: AppTheme.errorRed.withValues(alpha: 0.8),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close, color: Colors.white, size: 14),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFallback() {
    return Container(
      color: const Color(0xFFE2E8F0),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.image, size: 32, color: AppTheme.textMuted),
            const SizedBox(height: 4),
            Text(
              'Sample $sampleNumber',
              style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}
