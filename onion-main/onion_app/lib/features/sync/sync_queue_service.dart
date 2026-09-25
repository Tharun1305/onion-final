import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../config/api_config.dart';
import '../../core/constants/app_constants.dart';
import '../../core/network/network_service.dart';
import '../../data/repositories/inspection_repository.dart';
import '../../models/sync_item.dart';

class SyncResult {
  final bool success;
  final String message;
  final bool isOffline;

  SyncResult({required this.success, required this.message, this.isOffline = false});
}

class SyncQueueService extends ChangeNotifier {
  static final SyncQueueService _instance = SyncQueueService._internal();
  factory SyncQueueService() => _instance;
  SyncQueueService._internal();

  final InspectionRepository _repository = InspectionRepository();
  final NetworkService _networkService = NetworkService();
  final Uuid _uuid = const Uuid();

  bool _isSyncing = false;
  bool get isSyncing => _isSyncing;

  int _pendingCount = 0;
  int get pendingCount => _pendingCount;

  Future<void> processQueue() async {
    await syncAllPending();
    _pendingCount = await _repository.getPendingSyncCount();
    notifyListeners();
  }

  String get backendBaseUrl => ApiConfig.baseUrl;

  void initialize() {
    // Listen to network transitions to automatically drain sync queue when online
    _networkService.addListener(() {
      if (_networkService.isOnline && !_isSyncing) {
        debugPrint('[SyncQueueService] Online detected. Attempting pending sync queue drain...');
        syncAllPending();
      }
    });
  }

  Future<SyncResult> syncInspection(String inspectionId) async {
    final inspection = await _repository.getInspectionWithDetails(inspectionId);
    if (inspection == null) {
      return SyncResult(success: false, message: 'Inspection not found in local database.');
    }

    if (!_networkService.isOnline) {
      await _repository.updateSyncStatus(inspectionId, SyncStatus.pendingSync);
      await _repository.enqueueSync(inspectionId);
      notifyListeners();
      return SyncResult(
        success: false,
        isOffline: true,
        message: 'No internet connection. Inspection queued safely in local SQLite.',
      );
    }

    _isSyncing = true;
    notifyListeners();
    await _repository.updateSyncStatus(inspectionId, SyncStatus.syncing);

    try {
      final clientSyncId = _uuid.v4();
      final payload = {
        'client_sync_id': clientSyncId,
        'id': inspection.id,
        'inspection_code': inspection.inspectionCode,
        'batch_id': inspection.batchId,
        'center_id': inspection.centerId,
        'inspector_id': inspection.inspectorId,
        'inspector_name': inspection.inspectorName,
        'sample_count': inspection.sampleCount,
        'status': inspection.status.name,
        'notes': inspection.notes,
        'inspected_at': inspection.inspectedAt.toIso8601String(),
        'created_at': inspection.createdAt.toIso8601String(),
        'updated_at': inspection.updatedAt.toIso8601String(),
        'images': [
          for (int i = 0; i < inspection.imagePaths.length; i++)
            {
              'id': '${inspection.id}-img-$i',
              'sample_number': i + 1,
              'local_path': inspection.imagePaths[i],
              'blur_score': 0.85,
              'quality_status': 'PASSED',
              'created_at': DateTime.now().toIso8601String(),
            }
        ],
        'detections': inspection.detections.map((d) => d.toMap()).toList(),
        'validations': inspection.validations.map((v) => v.toJson()).toList(),
        'grading': inspection.gradingResult?.toMap(),
      };

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_session_token');

      final url = Uri.parse('$backendBaseUrl/inspections/sync');
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode(payload),
      ).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final now = DateTime.now();
        await _repository.updateSyncStatus(inspectionId, SyncStatus.synced, syncedAt: now);
        _isSyncing = false;
        notifyListeners();
        return SyncResult(success: true, message: 'Inspection successfully synced to cloud.');
      } else {
        await _repository.updateSyncStatus(inspectionId, SyncStatus.syncFailed);
        _isSyncing = false;
        notifyListeners();
        return SyncResult(
          success: false,
          message: 'Backend returned error ${response.statusCode}: ${response.body}',
        );
      }
    } catch (e) {
      debugPrint('[SyncQueueService] Network sync error: $e');
      await _repository.updateSyncStatus(inspectionId, SyncStatus.syncFailed);
      _isSyncing = false;
      notifyListeners();
      return SyncResult(
        success: false,
        message: 'Sync failed ($e). Data is safely preserved locally in SQLite and will retry.',
      );
    }
  }

  Future<void> syncAllPending() async {
    if (!_networkService.isOnline || _isSyncing) return;
    _isSyncing = true;
    notifyListeners();

    try {
      final items = await _repository.getPendingSyncItems();
      for (final item in items) {
        final res = await syncInspection(item.inspectionId);
        if (res.success) {
          final updated = SyncItem(
            id: item.id,
            inspectionId: item.inspectionId,
            action: item.action,
            status: 'COMPLETED',
            retryCount: item.retryCount + 1,
            createdAt: item.createdAt,
            lastAttemptAt: DateTime.now(),
          );
          await _repository.updateSyncItem(updated);
        } else {
          final updated = SyncItem(
            id: item.id,
            inspectionId: item.inspectionId,
            action: item.action,
            status: 'FAILED',
            retryCount: item.retryCount + 1,
            lastError: res.message,
            createdAt: item.createdAt,
            lastAttemptAt: DateTime.now(),
          );
          await _repository.updateSyncItem(updated);
        }
      }
    } catch (e) {
      debugPrint('[SyncQueueService] Error draining sync queue: $e');
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }
}
