import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';
import '../../core/constants/app_constants.dart';
import '../../models/inspection.dart';
import '../../models/onion_detection.dart';
import '../../models/validation_record.dart';
import '../../models/grading_result.dart';
import '../../models/sync_item.dart';
import '../local/database_helper.dart';

class InspectionRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final Uuid _uuid = const Uuid();

  // In-memory web storage collections (prevents any sqflite / dart:io calls on Web)
  static final Map<String, Inspection> _webInspections = {};
  static final List<OnionDetection> _webDetections = [];
  static final List<ValidationRecord> _webValidations = [];
  static final Map<String, GradingResult> _webGradingResults = {};
  static final List<SyncItem> _webSyncQueue = [];
  static bool _webSeeded = false;

  Future<void> saveInspection(Inspection inspection) async {
    if (kIsWeb) {
      _webInspections[inspection.id] = inspection;
      return;
    }
    final db = await _dbHelper.database;
    await db.insert(
      'inspections',
      inspection.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateInspection(Inspection inspection) async {
    if (kIsWeb) {
      _webInspections[inspection.id] = inspection;
      return;
    }
    final db = await _dbHelper.database;
    await db.update(
      'inspections',
      inspection.toMap(),
      where: 'id = ?',
      whereArgs: [inspection.id],
    );
  }

  Future<void> saveDetections(List<OnionDetection> detections) async {
    if (detections.isEmpty) return;
    if (kIsWeb) {
      for (final d in detections) {
        _webDetections.removeWhere((item) => item.id == d.id);
        _webDetections.add(d);
      }
      return;
    }
    final db = await _dbHelper.database;
    final batch = db.batch();
    for (final d in detections) {
      batch.insert(
        'onion_detections',
        d.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  Future<void> saveValidations(List<ValidationRecord> validations) async {
    if (validations.isEmpty) return;
    if (kIsWeb) {
      for (final v in validations) {
        _webValidations.removeWhere((item) => item.id == v.id);
        _webValidations.add(v);
      }
      return;
    }
    final db = await _dbHelper.database;
    final batch = db.batch();
    for (final v in validations) {
      batch.insert(
        'validation_records',
        v.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  Future<void> saveGradingResult(GradingResult grading) async {
    if (kIsWeb) {
      _webGradingResults[grading.inspectionId] = grading;
      return;
    }
    final db = await _dbHelper.database;
    await db.insert(
      'grading_results',
      grading.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<Inspection?> getInspectionWithDetails(String id) async {
    if (kIsWeb) {
      final insp = _webInspections[id];
      if (insp == null) return null;
      final detections = _webDetections.where((d) => d.inspectionId == id).toList();
      final validations = _webValidations.where((v) => v.inspectionId == id).toList();
      final grading = _webGradingResults[id];
      return insp.copyWith(
        detections: detections,
        validations: validations,
        gradingResult: grading,
      );
    }

    final db = await _dbHelper.database;
    final inspRows = await db.query(
      'inspections',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (inspRows.isEmpty) return null;

    final inspection = Inspection.fromMap(inspRows.first);

    // Detections
    final detRows = await db.query(
      'onion_detections',
      where: 'inspection_id = ?',
      whereArgs: [id],
    );
    final detections = detRows.map((r) => OnionDetection.fromMap(r)).toList();

    // Validations
    final valRows = await db.query(
      'validation_records',
      where: 'inspection_id = ?',
      whereArgs: [id],
    );
    final validations = valRows.map((r) => ValidationRecord.fromMap(r)).toList();

    // Grading
    final gradeRows = await db.query(
      'grading_results',
      where: 'inspection_id = ?',
      whereArgs: [id],
      limit: 1,
    );
    GradingResult? grading;
    if (gradeRows.isNotEmpty) {
      grading = GradingResult.fromMap(gradeRows.first);
    }

    return inspection.copyWith(
      detections: detections,
      validations: validations,
      gradingResult: grading,
    );
  }

  Future<void> ensureSeedData() async {
    if (kIsWeb) {
      if (_webSeeded) return;
      _webSeeded = true;
      final now = DateTime.now();

      final insp1 = Inspection(
        id: 'insp-seed-001',
        inspectionCode: 'INS-2026-00124',
        batchId: 'ON-2026-0042',
        centerId: 'center-erode-01',
        centerName: 'Erode Onion Procurement Center',
        inspectorId: 'insp-1024',
        inspectorName: 'Arun Kumar',
        sampleCount: 42,
        status: InspectionStatus.completed,
        syncStatus: SyncStatus.synced,
        notes: 'Morning arrival lot #12. High bulb density, clean outer scales.',
        inspectedAt: now.subtract(const Duration(hours: 2)),
        createdAt: now.subtract(const Duration(hours: 2)),
        updatedAt: now.subtract(const Duration(hours: 1)),
        syncedAt: now.subtract(const Duration(hours: 1)),
      );
      _webInspections[insp1.id] = insp1;
      _webGradingResults[insp1.id] = GradingResult(
        id: 'grade-seed-001',
        inspectionId: insp1.id,
        rulesVersion: 'v1.0-demo',
        totalSample: 42,
        gradeACount: 32,
        gradeAPercentage: 76.0,
        ursCount: 5,
        ursPercentage: 12.0,
        otherDefectsCount: 5,
        otherDefectsPercentage: 12.0,
        finalGrade: 'Grade A',
        createdAt: now.subtract(const Duration(hours: 2)),
      );

      final insp2 = Inspection(
        id: 'insp-seed-002',
        inspectionCode: 'INS-2026-00123',
        batchId: 'ON-2026-0041',
        centerId: 'center-erode-01',
        centerName: 'Erode Onion Procurement Center',
        inspectorId: 'insp-1024',
        inspectorName: 'Arun Kumar',
        sampleCount: 50,
        status: InspectionStatus.completed,
        syncStatus: SyncStatus.synced,
        notes: 'Standard red onion sample lot. Excellent firmness.',
        inspectedAt: now.subtract(const Duration(hours: 4)),
        createdAt: now.subtract(const Duration(hours: 4)),
        updatedAt: now.subtract(const Duration(hours: 3)),
        syncedAt: now.subtract(const Duration(hours: 3)),
      );
      _webInspections[insp2.id] = insp2;
      _webGradingResults[insp2.id] = GradingResult(
        id: 'grade-seed-002',
        inspectionId: insp2.id,
        rulesVersion: 'v1.0-demo',
        totalSample: 50,
        gradeACount: 42,
        gradeAPercentage: 84.0,
        ursCount: 4,
        ursPercentage: 8.0,
        otherDefectsCount: 4,
        otherDefectsPercentage: 8.0,
        finalGrade: 'Grade A',
        createdAt: now.subtract(const Duration(hours: 4)),
      );

      final insp3 = Inspection(
        id: 'insp-seed-003',
        inspectionCode: 'INS-2026-00122',
        batchId: 'ON-2026-0040',
        centerId: 'center-erode-01',
        centerName: 'Erode Onion Procurement Center',
        inspectorId: 'insp-1024',
        inspectorName: 'Arun Kumar',
        sampleCount: 45,
        status: InspectionStatus.validated,
        syncStatus: SyncStatus.pendingSync,
        notes: 'Minor mechanical damage observed during grading.',
        inspectedAt: now.subtract(const Duration(hours: 6)),
        createdAt: now.subtract(const Duration(hours: 6)),
        updatedAt: now.subtract(const Duration(hours: 5)),
      );
      _webInspections[insp3.id] = insp3;
      _webGradingResults[insp3.id] = GradingResult(
        id: 'grade-seed-003',
        inspectionId: insp3.id,
        rulesVersion: 'v1.0-demo',
        totalSample: 45,
        gradeACount: 29,
        gradeAPercentage: 64.0,
        ursCount: 8,
        ursPercentage: 18.0,
        otherDefectsCount: 8,
        otherDefectsPercentage: 18.0,
        finalGrade: 'Grade B (URS)',
        createdAt: now.subtract(const Duration(hours: 6)),
      );
      _webSyncQueue.add(SyncItem(
        id: _uuid.v4(),
        inspectionId: insp3.id,
        action: 'CREATE',
        status: 'PENDING',
        createdAt: DateTime.now(),
      ));
      return;
    }

    final db = await _dbHelper.database;
    final count = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM inspections')) ?? 0;
    if (count > 0) return;

    final now = DateTime.now();

    // Seed 1: INS-2026-00124
    final insp1 = Inspection(
      id: 'insp-seed-001',
      inspectionCode: 'INS-2026-00124',
      batchId: 'ON-2026-0042',
      centerId: 'center-erode-01',
      centerName: 'Erode Onion Procurement Center',
      inspectorId: 'insp-1024',
      inspectorName: 'Arun Kumar',
      sampleCount: 42,
      status: InspectionStatus.completed,
      syncStatus: SyncStatus.synced,
      notes: 'Morning arrival lot #12. High bulb density, clean outer scales.',
      inspectedAt: now.subtract(const Duration(hours: 2)),
      createdAt: now.subtract(const Duration(hours: 2)),
      updatedAt: now.subtract(const Duration(hours: 1)),
      syncedAt: now.subtract(const Duration(hours: 1)),
    );
    await saveInspection(insp1);
    await saveGradingResult(GradingResult(
      id: 'grade-seed-001',
      inspectionId: insp1.id,
      rulesVersion: 'v1.0-demo',
      totalSample: 42,
      gradeACount: 32,
      gradeAPercentage: 76.0,
      ursCount: 5,
      ursPercentage: 12.0,
      otherDefectsCount: 5,
      otherDefectsPercentage: 12.0,
      finalGrade: 'Grade A',
      createdAt: now.subtract(const Duration(hours: 2)),
    ));

    // Seed 2: INS-2026-00123
    final insp2 = Inspection(
      id: 'insp-seed-002',
      inspectionCode: 'INS-2026-00123',
      batchId: 'ON-2026-0041',
      centerId: 'center-erode-01',
      centerName: 'Erode Onion Procurement Center',
      inspectorId: 'insp-1024',
      inspectorName: 'Arun Kumar',
      sampleCount: 50,
      status: InspectionStatus.completed,
      syncStatus: SyncStatus.synced,
      notes: 'Standard red onion sample lot. Excellent firmness.',
      inspectedAt: now.subtract(const Duration(hours: 4)),
      createdAt: now.subtract(const Duration(hours: 4)),
      updatedAt: now.subtract(const Duration(hours: 3)),
      syncedAt: now.subtract(const Duration(hours: 3)),
    );
    await saveInspection(insp2);
    await saveGradingResult(GradingResult(
      id: 'grade-seed-002',
      inspectionId: insp2.id,
      rulesVersion: 'v1.0-demo',
      totalSample: 50,
      gradeACount: 42,
      gradeAPercentage: 84.0,
      ursCount: 4,
      ursPercentage: 8.0,
      otherDefectsCount: 4,
      otherDefectsPercentage: 8.0,
      finalGrade: 'Grade A',
      createdAt: now.subtract(const Duration(hours: 4)),
    ));

    // Seed 3: INS-2026-00122 (Pending Sync)
    final insp3 = Inspection(
      id: 'insp-seed-003',
      inspectionCode: 'INS-2026-00122',
      batchId: 'ON-2026-0040',
      centerId: 'center-erode-01',
      centerName: 'Erode Onion Procurement Center',
      inspectorId: 'insp-1024',
      inspectorName: 'Arun Kumar',
      sampleCount: 45,
      status: InspectionStatus.validated,
      syncStatus: SyncStatus.pendingSync,
      notes: 'Minor mechanical damage observed during grading.',
      inspectedAt: now.subtract(const Duration(hours: 6)),
      createdAt: now.subtract(const Duration(hours: 6)),
      updatedAt: now.subtract(const Duration(hours: 5)),
    );
    await saveInspection(insp3);
    await saveGradingResult(GradingResult(
      id: 'grade-seed-003',
      inspectionId: insp3.id,
      rulesVersion: 'v1.0-demo',
      totalSample: 45,
      gradeACount: 29,
      gradeAPercentage: 64.0,
      ursCount: 8,
      ursPercentage: 18.0,
      otherDefectsCount: 8,
      otherDefectsPercentage: 18.0,
      finalGrade: 'Grade B (URS)',
      createdAt: now.subtract(const Duration(hours: 6)),
    ));
    await enqueueSync(insp3.id);
  }

  Future<List<Inspection>> getAllInspections() async {
    await ensureSeedData();
    if (kIsWeb) {
      final list = _webInspections.values.toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list.map((insp) {
        final grading = _webGradingResults[insp.id];
        return insp.copyWith(gradingResult: grading);
      }).toList();
    }

    final db = await _dbHelper.database;
    final rows = await db.query('inspections', orderBy: 'created_at DESC');
    final inspections = rows.map((r) => Inspection.fromMap(r)).toList();

    final populated = <Inspection>[];
    for (final insp in inspections) {
      final gradeRows = await db.query(
        'grading_results',
        where: 'inspection_id = ?',
        whereArgs: [insp.id],
        limit: 1,
      );
      if (gradeRows.isNotEmpty) {
        populated.add(insp.copyWith(gradingResult: GradingResult.fromMap(gradeRows.first)));
      } else {
        populated.add(insp);
      }
    }
    return populated;
  }

  Future<void> updateSyncStatus(String inspectionId, SyncStatus status, {DateTime? syncedAt}) async {
    if (kIsWeb) {
      final existing = _webInspections[inspectionId];
      if (existing != null) {
        _webInspections[inspectionId] = existing.copyWith(
          syncStatus: status,
          syncedAt: syncedAt ?? existing.syncedAt,
          updatedAt: DateTime.now(),
        );
      }
      return;
    }
    final db = await _dbHelper.database;
    final data = <String, dynamic>{
      'sync_status': status.name,
      'updated_at': DateTime.now().toIso8601String(),
    };
    if (syncedAt != null) {
      data['synced_at'] = syncedAt.toIso8601String();
    }
    await db.update(
      'inspections',
      data,
      where: 'id = ?',
      whereArgs: [inspectionId],
    );
  }

  Future<void> enqueueSync(String inspectionId, {String action = 'CREATE'}) async {
    if (kIsWeb) {
      _webSyncQueue.add(SyncItem(
        id: _uuid.v4(),
        inspectionId: inspectionId,
        action: action,
        status: 'PENDING',
        createdAt: DateTime.now(),
      ));
      return;
    }
    final db = await _dbHelper.database;
    final item = SyncItem(
      id: _uuid.v4(),
      inspectionId: inspectionId,
      action: action,
      status: 'PENDING',
      createdAt: DateTime.now(),
    );
    await db.insert('sync_queue', item.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<SyncItem>> getPendingSyncItems() async {
    if (kIsWeb) {
      return _webSyncQueue
          .where((item) => item.status == 'PENDING' || item.status == 'FAILED')
          .toList();
    }
    final db = await _dbHelper.database;
    final rows = await db.query(
      'sync_queue',
      where: "status = 'PENDING' OR status = 'FAILED'",
      orderBy: 'created_at ASC',
    );
    return rows.map((r) => SyncItem.fromMap(r)).toList();
  }

  Future<void> updateSyncItem(SyncItem item) async {
    if (kIsWeb) {
      final idx = _webSyncQueue.indexWhere((i) => i.id == item.id);
      if (idx != -1) {
        _webSyncQueue[idx] = item;
      }
      return;
    }
    final db = await _dbHelper.database;
    await db.update(
      'sync_queue',
      item.toMap(),
      where: 'id = ?',
      whereArgs: [item.id],
    );
  }

  Future<int> getPendingSyncCount() async {
    if (kIsWeb) {
      return _webInspections.values
          .where((i) => i.syncStatus == SyncStatus.pendingSync || i.syncStatus == SyncStatus.localOnly)
          .length;
    }
    final db = await _dbHelper.database;
    final res = await db.rawQuery(
      "SELECT COUNT(*) as count FROM inspections WHERE sync_status = 'pendingSync' OR sync_status = 'localOnly'",
    );
    return Sqflite.firstIntValue(res) ?? 0;
  }

  Future<int> getTodayInspectionsCount() async {
    final now = DateTime.now();
    final todayStr = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

    if (kIsWeb) {
      return _webInspections.values.where((i) {
        final d = i.createdAt;
        final dStr = "${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}";
        return dStr == todayStr;
      }).length;
    }

    final db = await _dbHelper.database;
    final res = await db.rawQuery(
      "SELECT COUNT(*) as count FROM inspections WHERE created_at LIKE '$todayStr%'",
    );
    return Sqflite.firstIntValue(res) ?? 0;
  }

  Future<int> getVerifiedCount() async {
    if (kIsWeb) {
      return _webInspections.values.where((i) =>
        i.status == InspectionStatus.validated ||
        i.status == InspectionStatus.reportGenerated ||
        i.status == InspectionStatus.completed
      ).length;
    }

    final db = await _dbHelper.database;
    final res = await db.rawQuery(
      "SELECT COUNT(*) as count FROM inspections WHERE status = 'validated' OR status = 'reportGenerated' OR status = 'completed'",
    );
    return Sqflite.firstIntValue(res) ?? 0;
  }
}
