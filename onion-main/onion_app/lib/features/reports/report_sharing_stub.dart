import 'dart:typed_data';

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
  return const ReportShareResult(
    success: false,
    downloaded: false,
    message: 'PDF download not supported on this platform.',
  );
}

Future<ReportShareResult> platformSharePdf(Uint8List bytes, String filename) async {
  return const ReportShareResult(
    success: false,
    downloaded: false,
    message: 'PDF sharing not supported on this platform.',
  );
}
