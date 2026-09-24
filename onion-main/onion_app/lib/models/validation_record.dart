import '../core/constants/app_constants.dart';

class ValidationRecord {
  final String id;
  final String inspectionId;
  final String detectionId;
  final OnionClass originalAiClass;
  final double aiConfidence;
  final OnionClass inspectorClass;
  final String? correctionReason;
  final OnionClass finalClass;
  final bool isCorrected;
  final String? validatedBy;
  final DateTime validatedAt;

  ValidationRecord({
    required this.id,
    required this.inspectionId,
    required this.detectionId,
    required this.originalAiClass,
    required this.aiConfidence,
    required this.inspectorClass,
    this.correctionReason,
    required this.finalClass,
    required this.isCorrected,
    this.validatedBy,
    DateTime? validatedAt,
  }) : validatedAt = validatedAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'inspection_id': inspectionId,
      'detection_id': detectionId,
      'original_ai_class': originalAiClass.name,
      'ai_confidence': aiConfidence,
      'inspector_class': inspectorClass.name,
      'correction_reason': correctionReason,
      'final_class': finalClass.name,
      'is_corrected': isCorrected ? 1 : 0,
      'validated_by': validatedBy,
      'validated_at': validatedAt.toIso8601String(),
    };
  }

  factory ValidationRecord.fromMap(Map<String, dynamic> map) {
    final orig = AppConstants.parseOnionClass(map['original_ai_class'] as String);
    final insp = AppConstants.parseOnionClass(map['inspector_class'] as String);
    final fin = AppConstants.parseOnionClass(map['final_class'] as String);
    final isCorr = map['is_corrected'] == 1 || map['is_corrected'] == true;

    return ValidationRecord(
      id: map['id'] as String,
      inspectionId: map['inspection_id'] as String,
      detectionId: map['detection_id'] as String,
      originalAiClass: orig,
      aiConfidence: (map['ai_confidence'] as num).toDouble(),
      inspectorClass: insp,
      correctionReason: map['correction_reason'] as String?,
      finalClass: fin,
      isCorrected: isCorr,
      validatedBy: map['validated_by'] as String?,
      validatedAt: DateTime.parse(map['validated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    final m = toMap();
    m['is_corrected'] = isCorrected;
    return m;
  }
}
