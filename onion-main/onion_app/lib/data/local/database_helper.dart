import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDatabase();
    return _db!;
  }

  Future<Database> _initDatabase() async {
    // Setup FFI for desktop (Windows / Linux / macOS)
    if (!kIsWeb) {
      if (defaultTargetPlatform == TargetPlatform.windows ||
          defaultTargetPlatform == TargetPlatform.linux ||
          defaultTargetPlatform == TargetPlatform.macOS) {
        sqfliteFfiInit();
        databaseFactory = databaseFactoryFfi;
      }
    }

    String path;
    if (kIsWeb) {
      path = 'onion_grading_app.db';
    } else {
      final docsDir = await getApplicationDocumentsDirectory();
      path = join(docsDir.path, 'onion_grading_app.db');
    }

    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // 1. Inspections
    await db.execute('''
      CREATE TABLE inspections (
        id TEXT PRIMARY KEY,
        inspection_code TEXT NOT NULL UNIQUE,
        batch_id TEXT NOT NULL,
        center_id TEXT,
        center_name TEXT,
        inspector_id TEXT,
        inspector_name TEXT NOT NULL,
        sample_count INTEGER NOT NULL DEFAULT 0,
        status TEXT NOT NULL,
        sync_status TEXT NOT NULL,
        notes TEXT,
        image_paths_json TEXT,
        pdf_report_path TEXT,
        inspected_at TEXT NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        synced_at TEXT
      )
    ''');

    // 2. Onion Detections
    await db.execute('''
      CREATE TABLE onion_detections (
        id TEXT PRIMARY KEY,
        inspection_id TEXT NOT NULL,
        sample_number INTEGER NOT NULL DEFAULT 1,
        bbox_x REAL NOT NULL,
        bbox_y REAL NOT NULL,
        bbox_w REAL NOT NULL,
        bbox_h REAL NOT NULL,
        ai_class TEXT NOT NULL,
        ai_confidence REAL NOT NULL,
        size_category TEXT NOT NULL,
        created_at TEXT NOT NULL,
        FOREIGN KEY (inspection_id) REFERENCES inspections (id) ON DELETE CASCADE
      )
    ''');

    // 3. Validation Records
    await db.execute('''
      CREATE TABLE validation_records (
        id TEXT PRIMARY KEY,
        inspection_id TEXT NOT NULL,
        detection_id TEXT NOT NULL,
        original_ai_class TEXT NOT NULL,
        ai_confidence REAL NOT NULL,
        inspector_class TEXT NOT NULL,
        correction_reason TEXT,
        final_class TEXT NOT NULL,
        is_corrected INTEGER NOT NULL DEFAULT 0,
        validated_by TEXT,
        validated_at TEXT NOT NULL,
        FOREIGN KEY (inspection_id) REFERENCES inspections (id) ON DELETE CASCADE,
        FOREIGN KEY (detection_id) REFERENCES onion_detections (id) ON DELETE CASCADE
      )
    ''');

    // 4. Grading Results
    await db.execute('''
      CREATE TABLE grading_results (
        id TEXT PRIMARY KEY,
        inspection_id TEXT NOT NULL UNIQUE,
        total_sample INTEGER NOT NULL,
        grade_a_count INTEGER NOT NULL,
        grade_a_percentage REAL NOT NULL,
        urs_count INTEGER NOT NULL,
        urs_percentage REAL NOT NULL,
        other_defects_count INTEGER NOT NULL,
        other_defects_percentage REAL NOT NULL,
        final_grade TEXT NOT NULL,
        rules_version TEXT NOT NULL,
        created_at TEXT NOT NULL,
        FOREIGN KEY (inspection_id) REFERENCES inspections (id) ON DELETE CASCADE
      )
    ''');

    // 5. Sync Queue
    await db.execute('''
      CREATE TABLE sync_queue (
        id TEXT PRIMARY KEY,
        inspection_id TEXT NOT NULL,
        action TEXT NOT NULL,
        status TEXT NOT NULL,
        retry_count INTEGER NOT NULL DEFAULT 0,
        last_error TEXT,
        created_at TEXT NOT NULL,
        last_attempt_at TEXT
      )
    ''');

    debugPrint('[DatabaseHelper] SQLite database schema initialized successfully.');
  }

  Future<void> close() async {
    if (_db != null && _db!.isOpen) {
      await _db!.close();
      _db = null;
    }
  }
}
