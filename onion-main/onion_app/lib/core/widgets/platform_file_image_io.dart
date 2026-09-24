import 'dart:io';
import 'package:flutter/material.dart';

Widget getPlatformFileImage(String path, {BoxFit fit = BoxFit.cover, Widget? fallback}) {
  try {
    final file = File(path);
    if (file.existsSync()) {
      return Image.file(
        file,
        fit: fit,
        errorBuilder: (ctx, err, stack) => fallback ?? const Center(child: Icon(Icons.broken_image, size: 40, color: Colors.grey)),
      );
    }
  } catch (_) {}
  return fallback ?? const Center(child: Icon(Icons.image, size: 40, color: Colors.grey));
}
