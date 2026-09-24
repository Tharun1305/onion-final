import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

/// Platform-agnostic image container holding raw bytes and metadata.
/// Works identically on Android, iOS, Windows Desktop, and Flutter Web.
class ImageInput {
  final Uint8List bytes;
  final String filename;
  final String mimeType;
  final String? localPath;

  const ImageInput({
    required this.bytes,
    required this.filename,
    this.mimeType = 'image/jpeg',
    this.localPath,
  });

  /// Creates an ImageInput asynchronously from an XFile (camera or picker).
  static Future<ImageInput> fromXFile(XFile file) async {
    final bytes = await file.readAsBytes();
    final name = file.name.isNotEmpty ? file.name : 'onion_sample.jpg';
    final mime = file.mimeType ?? _guessMimeType(name);
    return ImageInput(
      bytes: bytes,
      filename: name,
      mimeType: mime,
      localPath: kIsWeb ? null : file.path,
    );
  }

  static String _guessMimeType(String filename) {
    final lower = filename.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    if (lower.endsWith('.heic')) return 'image/heic';
    if (lower.endsWith('.heif')) return 'image/heif';
    return 'image/jpeg';
  }
}
