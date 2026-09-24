import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

Future<String?> saveReportFile(String inspectionCode, Uint8List bytes) async {
  try {
    final outputDir = await getApplicationDocumentsDirectory();
    final reportsDir = Directory(p.join(outputDir.path, 'reports'));
    if (!await reportsDir.exists()) {
      await reportsDir.create(recursive: true);
    }
    final file = File(p.join(reportsDir.path, '${inspectionCode}_report.pdf'));
    await file.writeAsBytes(bytes);
    debugPrint('[REPORT] saved report to ${file.path}');
    return file.path;
  } catch (e) {
    debugPrint('[REPORT] error saving file locally: $e');
    return null;
  }
}

Future<Uint8List?> readReportFile(String path) async {
  try {
    final file = File(path);
    if (await file.exists()) {
      return await file.readAsBytes();
    }
  } catch (e) {
    debugPrint('[REPORT] error reading file: $e');
  }
  return null;
}
