class SyncItem {
  final String id;
  final String inspectionId;
  final String action; // CREATE, UPDATE, REPORT
  final String status; // PENDING, PROCESSING, FAILED, COMPLETED
  final int retryCount;
  final String? lastError;
  final DateTime createdAt;
  final DateTime? lastAttemptAt;

  SyncItem({
    required this.id,
    required this.inspectionId,
    this.action = 'CREATE',
    this.status = 'PENDING',
    this.retryCount = 0,
    this.lastError,
    DateTime? createdAt,
    this.lastAttemptAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'inspection_id': inspectionId,
      'action': action,
      'status': status,
      'retry_count': retryCount,
      'last_error': lastError,
      'created_at': createdAt.toIso8601String(),
      'last_attempt_at': lastAttemptAt?.toIso8601String(),
    };
  }

  factory SyncItem.fromMap(Map<String, dynamic> map) {
    return SyncItem(
      id: map['id'] as String,
      inspectionId: map['inspection_id'] as String,
      action: map['action'] as String? ?? 'CREATE',
      status: map['status'] as String? ?? 'PENDING',
      retryCount: map['retry_count'] as int? ?? 0,
      lastError: map['last_error'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      lastAttemptAt: map['last_attempt_at'] != null ? DateTime.parse(map['last_attempt_at'] as String) : null,
    );
  }
}
