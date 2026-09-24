import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';

class ReportShareResult {
  final bool success;
  final bool downloaded;
  final String message;

  const ReportShareResult({
    required this.success,
    required this.downloaded,
    required this.message,
  });
}

Future<ReportShareResult> platformDownloadPdf(Uint8List bytes, String filename) async {
  try {
    Directory? targetDir;
    if (Platform.isAndroid) {
      // Try external storage downloads or app documents
      try {
        targetDir = Directory('/storage/emulated/0/Download');
        if (!await targetDir.exists()) {
          targetDir = await getExternalStorageDirectory();
        }
      } catch (_) {
        targetDir = await getApplicationDocumentsDirectory();
      }
    } else {
      // Windows / Desktop
      try {
        targetDir = await getDownloadsDirectory();
      } catch (_) {
        targetDir = await getApplicationDocumentsDirectory();
      }
    }

    targetDir ??= await getApplicationDocumentsDirectory();
    final filePath = p.join(targetDir.path, filename);
    final file = File(filePath);
    await file.writeAsBytes(bytes);

    debugPrint('[ReportSharingIO] PDF saved to $filePath');
    return ReportShareResult(
      success: true,
      downloaded: true,
      message: 'PDF saved to: $filePath',
    );
  } catch (e) {
    debugPrint('[ReportSharingIO] Download error: $e');
    return ReportShareResult(
      success: false,
      downloaded: false,
      message: 'Error saving PDF: $e',
    );
  }
}

Future<ReportShareResult> platformSharePdf(Uint8List bytes, String filename) async {
  try {
    // Native sharing (Android share sheet with WhatsApp, Gmail, Drive, etc.)
    await Printing.sharePdf(
      bytes: bytes,
      filename: filename,
    );
    return const ReportShareResult(
      success: true,
      downloaded: false,
      message: 'Opening system share sheet...',
    );
  } catch (e) {
    debugPrint('[ReportSharingIO] Share error: $e. Falling back to local save.');
    // Graceful fallback to download/save
    return await platformDownloadPdf(bytes, filename);
  }
}
