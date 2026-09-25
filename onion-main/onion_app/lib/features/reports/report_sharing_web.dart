// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:html' as html;
import 'package:flutter/foundation.dart';

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
    final blob = html.Blob([bytes], 'application/pdf');
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement(href: url)
      ..setAttribute('download', filename)
      ..style.display = 'none';

    html.document.body?.children.add(anchor);
    anchor.click();
    html.document.body?.children.remove(anchor);
    
    // Allow the browser download pipeline time to initiate before revoking
    Future.delayed(const Duration(seconds: 10), () {
      try {
        html.Url.revokeObjectUrl(url);
      } catch (_) {}
    });

    return ReportShareResult(
      success: true,
      downloaded: true,
      message: 'PDF report "$filename" downloaded to your device.',
    );
  } catch (e) {
    debugPrint('[ReportSharingWeb] Download error: $e');
    return ReportShareResult(
      success: false,
      downloaded: false,
      message: 'Failed to download PDF: $e',
    );
  }
}

Future<ReportShareResult> platformSharePdf(Uint8List bytes, String filename) async {
  try {
    // Attempt Web Share API if supported by the browser
    final nav = html.window.navigator;
    final file = html.File([bytes], filename, {'type': 'application/pdf'});
    await nav.share({
      'files': [file],
      'title': 'Onion Inspection Report',
      'text': 'Onion Quality Assessment & Inspection Report: $filename',
    });
    return const ReportShareResult(
      success: true,
      downloaded: false,
      message: 'Report shared successfully.',
    );
  } catch (e) {
    debugPrint('[ReportSharingWeb] Web share not supported or cancelled: $e. Falling back to download.');
  }

  // Graceful fallback: Download the PDF and notify the user
  final downloadResult = await platformDownloadPdf(bytes, filename);
  if (downloadResult.success) {
    return const ReportShareResult(
      success: true,
      downloaded: true,
      message: 'PDF downloaded to your device. Direct app sharing is not supported by this browser.',
    );
  }

  return downloadResult;
}
