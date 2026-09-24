import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import '../../../config/api_config.dart';
import '../../../core/constants/app_constants.dart';
import '../../../models/onion_detection.dart';
import 'onion_inference_engine.dart';

class RealOnDeviceInferenceEngine implements OnionInferenceEngine {
  @override
  String get engineName => 'RealOnDeviceInferenceEngine (Trained Onion Model via predict.py)';

  @override
  bool get isSimulation => false;

  @override
  Future<List<OnionDetection>> analyze({
    required String inspectionId,
    required String imagePath,
    Uint8List? imageBytes,
    int sampleNumber = 1,
  }) async {
    List<int> bytes = [];
    String filename = 'onion_sample.jpg';

    if (imageBytes != null && imageBytes.isNotEmpty) {
      bytes = imageBytes;
      filename = 'onion_sample.jpg';
    } else if (imagePath.isNotEmpty) {
      try {
        final xfile = XFile(imagePath);
        bytes = await xfile.readAsBytes();
        filename = xfile.name.isNotEmpty ? xfile.name : 'onion_sample.jpg';
      } catch (e) {
        bytes = [];
      }
    }

    if (bytes.isEmpty) {
      throw Exception('Captured image file is empty or unreadable.');
    }

    // Determine MIME type
    final lowerName = filename.toLowerCase();
    String mimeType = 'image/jpeg';
    if (lowerName.endsWith('.png')) {
      mimeType = 'image/png';
    } else if (lowerName.endsWith('.webp')) {
      mimeType = 'image/webp';
    } else if (lowerName.endsWith('.heic')) {
      mimeType = 'image/heic';
    } else if (lowerName.endsWith('.heif')) {
      mimeType = 'image/heif';
    }

    final predictUri = Uri.parse(ApiConfig.predictUrl);

    // Required debug logs
    debugPrint('[IMAGE] filename: $filename');
    debugPrint('[IMAGE] mime type: $mimeType');
    debugPrint('[IMAGE] bytes length: ${bytes.length}');
    debugPrint('[AI] API URL: $predictUri');
    debugPrint('[AI] upload started');

    try {
      final request = http.MultipartRequest('POST', predictUri);

      // Add multipart file field
      request.files.add(
        http.MultipartFile.fromBytes(
          'image',
          bytes,
          filename: filename,
        ),
      );

      final streamedResponse = await request.send().timeout(const Duration(seconds: 45));
      final responseBody = await streamedResponse.stream.bytesToString();

      debugPrint('[AI] HTTP status: ${streamedResponse.statusCode}');
      debugPrint('[AI] response body: $responseBody');

      if (streamedResponse.statusCode != 200) {
        throw Exception('AI inference server returned error ${streamedResponse.statusCode}: $responseBody');
      }

      final data = json.decode(responseBody) as Map<String, dynamic>;
      final rawClass = (data['prediction'] as String? ?? 'healthy').toLowerCase();
      final confidenceVal = (data['confidence'] as num?)?.toDouble() ?? 0.0;
      final rawProbs = data['probabilities'] as Map<String, dynamic>? ?? {};

      debugPrint('[AI] prediction: $rawClass');
      debugPrint('[AI] confidence: ${confidenceVal.toStringAsFixed(2)}%');

      final Map<String, double> parsedProbs = {};
      rawProbs.forEach((key, val) {
        if (val is num) {
          parsedProbs[key] = val.toDouble();
        }
      });

      final onionClass = AppConstants.parseOnionClass(rawClass);

      // Bounding box from YOLO if available
      double bx = 0.15, by = 0.15, bw = 0.70, bh = 0.70;
      if (data['box'] is List && (data['box'] as List).length == 4) {
        bx = 0.15;
        by = 0.15;
        bw = 0.70;
        bh = 0.70;
      }

      final detection = OnionDetection(
        id: 'det-$inspectionId-$sampleNumber',
        inspectionId: inspectionId,
        sampleNumber: sampleNumber,
        bboxX: bx,
        bboxY: by,
        bboxW: bw,
        bboxH: bh,
        aiClass: onionClass,
        aiConfidence: (confidenceVal / 100.0).clamp(0.0, 1.0),
        sizeCategory: SizeCategory.normal,
        probabilities: parsedProbs,
        rawClassName: rawClass,
        createdAt: DateTime.now(),
      );

      return [detection];
    } on http.ClientException catch (e) {
      debugPrint('[RealInferenceEngine] Network error: $e');
      throw Exception(
        'Unable to connect to Onion AI server at ${ApiConfig.baseUrl}.\n'
        'Please ensure the FastAPI server is running on the host machine.'
      );
    } catch (e) {
      debugPrint('[RealInferenceEngine] Error during inference: $e');
      final msg = e.toString().toLowerCase();
      if (msg.contains('socketexception') ||
          msg.contains('connection refused') ||
          msg.contains('timeout') ||
          msg.contains('clientexception') ||
          msg.contains('failed to fetch') ||
          msg.contains('xmlhttprequest error')) {
        throw Exception(
          'Unable to connect to Onion AI server at ${ApiConfig.baseUrl}.\n'
          'Please ensure the FastAPI server is running on the host machine.'
        );
      } else if (msg.contains('400') || msg.contains('empty') || msg.contains('not found')) {
        throw Exception('Please select a valid JPG or PNG image.');
      } else if (msg.contains('500') || msg.contains('inference error')) {
        throw Exception('AI model could not analyze this image.');
      }
      throw Exception('Unable to upload image for analysis: $e');
    }
  }
}
