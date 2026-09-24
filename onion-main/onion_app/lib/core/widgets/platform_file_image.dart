import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'platform_file_image_stub.dart'
    if (dart.library.io) 'platform_file_image_io.dart' as platform_impl;

Widget buildSafeImage({
  Uint8List? bytes,
  String? path,
  BoxFit fit = BoxFit.cover,
  Widget? fallback,
}) {
  if (bytes != null && bytes.isNotEmpty) {
    return Image.memory(
      bytes,
      fit: fit,
      errorBuilder: (ctx, err, stack) => fallback ?? const Center(child: Icon(Icons.broken_image, size: 40, color: Colors.grey)),
    );
  }

  if (path != null && path.isNotEmpty) {
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return Image.network(
        path,
        fit: fit,
        errorBuilder: (ctx, err, stack) => fallback ?? const Center(child: Icon(Icons.broken_image, size: 40, color: Colors.grey)),
      );
    }

    return platform_impl.getPlatformFileImage(path, fit: fit, fallback: fallback);
  }

  return fallback ?? const Center(child: Icon(Icons.image, size: 40, color: Colors.grey));
}
