import 'dart:convert';
import 'dart:typed_data';
import '../core/constants/app_constants.dart';
import 'onion_detection.dart';
import 'validation_record.dart';
import 'grading_result.dart';

class Inspection {
  final String id;
  final String inspectionCode;
  final String batchId;
  final String? centerId;
  final String? centerName;
  final String? inspectorId;
  final String inspectorName;
  final int sampleCount;
  final double? quantity; // In kg
  final String? source; // e.g. Local Procurement
  final String? variety; // e.g. Red Onion
  final InspectionStatus status;
  final SyncStatus syncStatus;
  final String? notes;
  final List<String> imagePaths;
  final Uint8List? imageBytes; // Raw in-memory image bytes for cross-platform preview & inference
  final String? pdfReportPath;
  final DateTime inspectedAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? syncedAt;

  // Associated entities
  final List<OnionDetection> detections;
  final List<ValidationRecord> validations;
  final GradingResult? gradingResult;

  Inspection({
    required this.id,
    required this.inspectionCode,
    required this.batchId,
    this.centerId,
    this.centerName,
    this.inspectorId,
    required this.inspectorName,
    this.sampleCount = 0,
    this.quantity = 850.0,
    this.source = 'Local Procurement',
    this.variety = 'Red Onion',
    this.status = InspectionStatus.draft,
    this.syncStatus = SyncStatus.localOnly,
    this.notes,
    this.imagePaths = const [],
    this.imageBytes,
    this.pdfReportPath,
    DateTime? inspectedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.syncedAt,
    this.detections = const [],
    this.validations = const [],
    this.gradingResult,
  })  : inspectedAt = inspectedAt ?? DateTime.now(),
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Inspection copyWith({
    String? id,
    String? inspectionCode,
    String? batchId,
    String? centerId,
    String? centerName,
    String? inspectorId,
    String? inspectorName,
    int? sampleCount,
    double? quantity,
    String? source,
    String? variety,
    InspectionStatus? status,
    SyncStatus? syncStatus,
    String? notes,
    List<String>? imagePaths,
    Uint8List? imageBytes,
    String? pdfReportPath,
    DateTime? inspectedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? syncedAt,
    List<OnionDetection>? detections,
    List<ValidationRecord>? validations,
    GradingResult? gradingResult,
  }) {
    return Inspection(
      id: id ?? this.id,
      inspectionCode: inspectionCode ?? this.inspectionCode,
      batchId: batchId ?? this.batchId,
      centerId: centerId ?? this.centerId,
      centerName: centerName ?? this.centerName,
      inspectorId: inspectorId ?? this.inspectorId,
      inspectorName: inspectorName ?? this.inspectorName,
      sampleCount: sampleCount ?? this.sampleCount,
      quantity: quantity ?? this.quantity,
      source: source ?? this.source,
      variety: variety ?? this.variety,
      status: status ?? this.status,
      syncStatus: syncStatus ?? this.syncStatus,
      notes: notes ?? this.notes,
      imagePaths: imagePaths ?? this.imagePaths,
      imageBytes: imageBytes ?? this.imageBytes,
      pdfReportPath: pdfReportPath ?? this.pdfReportPath,
      inspectedAt: inspectedAt ?? this.inspectedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      syncedAt: syncedAt ?? this.syncedAt,
      detections: detections ?? this.detections,
      validations: validations ?? this.validations,
      gradingResult: gradingResult ?? this.gradingResult,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'inspection_code': inspectionCode,
      'batch_id': batchId,
      'center_id': centerId,
      'center_name': centerName,
      'inspector_id': inspectorId,
      'inspector_name': inspectorName,
      'sample_count': sampleCount,
      'status': status.name,
      'sync_status': syncStatus.name,
      'notes': notes,
      'image_paths_json': jsonEncode(imagePaths),
      'pdf_report_path': pdfReportPath,
      'inspected_at': inspectedAt.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'synced_at': syncedAt?.toIso8601String(),
    };
  }

  factory Inspection.fromMap(Map<String, dynamic> map) {
    List<String> images = [];
    if (map['image_paths_json'] != null) {
      try {
        final decoded = jsonDecode(map['image_paths_json'] as String);
        if (decoded is List) {
          images = decoded.map((e) => e.toString()).toList();
        }
      } catch (_) {}
    }

    return Inspection(
      id: map['id'] as String,
      inspectionCode: map['inspection_code'] as String,
      batchId: map['batch_id'] as String,
      centerId: map['center_id'] as String?,
      centerName: map['center_name'] as String?,
      inspectorId: map['inspector_id'] as String?,
      inspectorName: map['inspector_name'] as String? ?? 'Inspector',
      sampleCount: map['sample_count'] as int? ?? 0,
      status: InspectionStatus.values.firstWhere(
        (s) => s.name == (map['status'] as String? ?? 'draft'),
        orElse: () => InspectionStatus.draft,
      ),
      syncStatus: SyncStatus.values.firstWhere(
        (s) => s.name == (map['sync_status'] as String? ?? 'localOnly'),
        orElse: () => SyncStatus.localOnly,
      ),
      notes: map['notes'] as String?,
      imagePaths: images,
      pdfReportPath: map['pdf_report_path'] as String?,
      inspectedAt: DateTime.parse(map['inspected_at'] as String),
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
      syncedAt: map['synced_at'] != null ? DateTime.parse(map['synced_at'] as String) : null,
    );
  }
}
