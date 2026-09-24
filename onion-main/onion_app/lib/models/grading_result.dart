class GradingResult {
  final String id;
  final String inspectionId;
  final int totalSample;
  final int gradeACount;
  final double gradeAPercentage;
  final int ursCount;
  final double ursPercentage;
  final int otherDefectsCount;
  final double otherDefectsPercentage;
  final String finalGrade;
  final String rulesVersion;
  final DateTime createdAt;

  // Convenience getters
  String get gradeName => finalGrade;
  String get gradeAName => 'Grade A';
  double get defectPercentage => otherDefectsPercentage;
  int get totalSamples => totalSample;
  bool get isApproved => finalGrade.toUpperCase().contains('GRADE A');

  GradingResult({
    required this.id,
    required this.inspectionId,
    required this.totalSample,
    this.gradeACount = 0,
    required this.gradeAPercentage,
    this.ursCount = 0,
    required this.ursPercentage,
    this.otherDefectsCount = 0,
    required this.otherDefectsPercentage,
    required this.finalGrade,
    this.rulesVersion = 'v1.0-demo',
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'inspection_id': inspectionId,
      'total_sample': totalSample,
      'grade_a_count': gradeACount,
      'grade_a_percentage': gradeAPercentage,
      'urs_count': ursCount,
      'urs_percentage': ursPercentage,
      'other_defects_count': otherDefectsCount,
      'other_defects_percentage': otherDefectsPercentage,
      'final_grade': finalGrade,
      'rules_version': rulesVersion,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory GradingResult.fromMap(Map<String, dynamic> map) {
    return GradingResult(
      id: map['id'] as String,
      inspectionId: map['inspection_id'] as String,
      totalSample: map['total_sample'] as int,
      gradeACount: map['grade_a_count'] as int? ?? 0,
      gradeAPercentage: (map['grade_a_percentage'] as num).toDouble(),
      ursCount: map['urs_count'] as int? ?? 0,
      ursPercentage: (map['urs_percentage'] as num).toDouble(),
      otherDefectsCount: map['other_defects_count'] as int? ?? 0,
      otherDefectsPercentage: (map['other_defects_percentage'] as num).toDouble(),
      finalGrade: map['final_grade'] as String,
      rulesVersion: map['rules_version'] as String? ?? 'v1.0-demo',
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}
