import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/image_input.dart';
import '../../../models/inspection.dart';
import '../ai_analysis/presentation/ai_analysis_screen.dart';
import 'sample_capture_screen.dart';

class AddOnionImageScreen extends StatefulWidget {
  final Inspection inspection;

  const AddOnionImageScreen({super.key, required this.inspection});

  @override
  State<AddOnionImageScreen> createState() => _AddOnionImageScreenState();
}

class _AddOnionImageScreenState extends State<AddOnionImageScreen> {
  final ImagePicker _picker = ImagePicker();
  bool _isPicking = false;

  void _openCamera() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SampleCaptureScreen(inspection: widget.inspection),
      ),
    );
  }


  Future<void> _uploadImage() async {
    if (_isPicking) return;
    setState(() => _isPicking = true);

    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 95,
      );

      if (pickedFile == null) {
        // User cancelled selection
        return;
      }

      // Check file extension using name (safe across Web, Windows, Android)
      final nameLower = pickedFile.name.toLowerCase();
      final pathLower = pickedFile.path.toLowerCase();
      final isSupported = nameLower.endsWith('.jpg') ||
          nameLower.endsWith('.jpeg') ||
          nameLower.endsWith('.png') ||
          nameLower.endsWith('.webp') ||
          nameLower.endsWith('.heic') ||
          nameLower.endsWith('.heif') ||
          pathLower.endsWith('.jpg') ||
          pathLower.endsWith('.jpeg') ||
          pathLower.endsWith('.png') ||
          pathLower.endsWith('.webp') ||
          pathLower.endsWith('.heic') ||
          pathLower.endsWith('.heif');

      if (!isSupported) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please select a valid image (JPG, PNG, WEBP, or HEIC).')),
          );
        }
        return;
      }

      // Read raw bytes directly for cross-platform processing
      final bytes = await pickedFile.readAsBytes();
      if (bytes.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Selected image is empty. Please select another image.')),
          );
        }
        return;
      }

      final imageInput = await ImageInput.fromXFile(pickedFile);

      final updatedInspection = widget.inspection.copyWith(
        imagePaths: [pickedFile.path],
        imageBytes: bytes,
        status: InspectionStatus.imagesReady,
        updatedAt: DateTime.now(),
      );

      if (!mounted) return;

      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => AiAnalysisScreen(
            inspection: updatedInspection,
            imageInput: imageInput,
          ),
        ),
      );
    } catch (e) {
      debugPrint('[AddOnionImageScreen] Image pick error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open image picker: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isPicking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgSlate,
      appBar: AppBar(
        title: const Text('Add Onion Image'),
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 12),
              // Header Illustration & Title
              Center(
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryTeal.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.camera_alt_outlined,
                      size: 40,
                      color: AppTheme.primaryTeal,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'How would you like to provide the onion image?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.darkSlate,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Capture a single onion using the device camera or select an existing photo from storage.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: AppTheme.textMuted,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 32),

              // Batch Summary Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.borderGray),
                ),
                child: Column(
                  children: [
                    _buildSummaryRow('Batch ID', widget.inspection.batchId),
                    const Divider(height: 16),
                    _buildSummaryRow('Variety', widget.inspection.variety ?? ''),
                    const Divider(height: 16),
                    _buildSummaryRow('Inspector', widget.inspection.inspectorName),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Option 1: Open Camera
              _buildActionCard(
                icon: Icons.camera_alt,
                title: 'Open Camera',
                subtitle: 'Capture a live photo using the real phone camera with viewfinder',
                color: AppTheme.primaryTeal,
                isPrimary: true,
                onTap: _openCamera,
              ),
              const SizedBox(height: 16),

              // Option 2: Upload Image
              _buildActionCard(
                icon: Icons.photo_library_outlined,
                title: 'Upload Image',
                subtitle: 'Choose an existing photo (JPG, PNG, WEBP, HEIC) from storage',
                color: const Color(0xFF0284C7),
                isPrimary: false,
                onTap: _uploadImage,
              ),

              if (_isPicking) ...[
                const SizedBox(height: 24),
                const Center(
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primaryTeal),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
        Text(
          value.isNotEmpty ? value : '-',
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.darkSlate),
        ),
      ],
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required bool isPrimary,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          decoration: BoxDecoration(
            color: isPrimary ? color : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isPrimary ? color : AppTheme.borderGray,
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: isPrimary ? color.withValues(alpha: 0.25) : Colors.black.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: isPrimary ? Colors.white.withValues(alpha: 0.2) : color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: isPrimary ? Colors.white : color,
                  size: 26,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: isPrimary ? Colors.white : AppTheme.darkSlate,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: isPrimary ? Colors.white.withValues(alpha: 0.85) : AppTheme.textMuted,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: isPrimary ? Colors.white : AppTheme.textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
