import 'package:flutter/material.dart';

Widget getPlatformFileImage(String path, {BoxFit fit = BoxFit.cover, Widget? fallback}) {
  return fallback ?? const Center(child: Icon(Icons.image, size: 40, color: Colors.grey));
}
