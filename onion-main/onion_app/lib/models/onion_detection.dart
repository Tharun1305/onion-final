import '../core/constants/app_constants.dart';

class OnionDetection {
  final String id;
  final String inspectionId;
  final int sampleNumber;
  final double bboxX;
  final double bboxY;
  final double bboxW;
  final double bboxH;
  final OnionClass aiClass;
  final double aiConfidence;
  final SizeCategory sizeCategory;
  final DateTime createdAt;
  final Map<String, double>? probabilities;
  final String? rawClassName;

  OnionDetection({
    required this.id,
    required this.inspectionId,
    this.sampleNumber = 1,
    required this.bboxX,
    required this.bboxY,
    required this.bboxW,
    required this.bboxH,
    required this.aiClass,
    required this.aiConfidence,
    this.sizeCategory = SizeCategory.normal,
    DateTime? createdAt,
    this.probabilities,
    this.rawClassName,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'inspection_id': inspectionId,
      'sample_number': sampleNumber,
      'bbox_x': bboxX,
      'bbox_y': bboxY,
      'bbox_w': bboxW,
      'bbox_h': bboxH,
      'ai_class': aiClass.name,
      'ai_confidence': aiConfidence,
      'size_category': sizeCategory.name,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory OnionDetection.fromMap(Map<String, dynamic> map) {
    return OnionDetection(
      id: map['id'] as String,
      inspectionId: map['inspection_id'] as String,
      sampleNumber: map['sample_number'] as int? ?? 1,
      bboxX: (map['bbox_x'] as num).toDouble(),
      bboxY: (map['bbox_y'] as num).toDouble(),
      bboxW: (map['bbox_w'] as num).toDouble(),
      bboxH: (map['bbox_h'] as num).toDouble(),
      aiClass: AppConstants.parseOnionClass(map['ai_class'] as String),
      aiConfidence: (map['ai_confidence'] as num).toDouble(),
      sizeCategory: SizeCategory.values.firstWhere(
        (s) => s.name == (map['size_category'] as String? ?? 'normal'),
        orElse: () => SizeCategory.normal,
      ),
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => toMap();
}
