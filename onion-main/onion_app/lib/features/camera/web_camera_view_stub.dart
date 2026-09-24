import 'package:flutter/material.dart';
import '../../models/image_input.dart';
import '../../models/inspection.dart';

class WebCameraView extends StatelessWidget {
  final Inspection inspection;
  final Function(ImageInput imageInput) onCaptured;
  final VoidCallback onCancel;
  final VoidCallback onUploadPressed;

  const WebCameraView({
    super.key,
    required this.inspection,
    required this.onCaptured,
    required this.onCancel,
    required this.onUploadPressed,
  });

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}
