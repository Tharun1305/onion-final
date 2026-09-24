import 'package:uuid/uuid.dart';
import '../../core/constants/app_constants.dart';
import '../../models/grading_result.dart';
import '../../models/validation_record.dart';

class GradingThresholdConfig {
  final double minGradeAHealthyPercentage;
  final double maxGradeARottenPercentage;
  final double maxGradeADamagedPercentage;
  final double minUrsHealthyPercentage;
  final double maxUrsRottenPercentage;
  final String rulesVersion;

  const GradingThresholdConfig({
    this.minGradeAHealthyPercentage = 70.0,
    this.maxGradeARottenPercentage = 5.0,
    this.maxGradeADamagedPercentage = 15.0,
    this.minUrsHealthyPercentage = 50.0,
    this.maxUrsRottenPercentage = 8.0,
    this.rulesVersion = 'v1.0-demo-thresholds',
  });
}

class GradingEngine {
  static const Uuid _uuid = Uuid();

  /// Evaluates validated observations against configurable grading criteria.
  /// Does NOT guess or invent official government standards: uses explicit configurable thresholds.
  static GradingResult evaluate({
    required String inspectionId,
    required List<ValidationRecord> validations,
    GradingThresholdConfig config = const GradingThresholdConfig(),
  }) {
    if (validations.isEmpty) {
      return GradingResult(
        id: _uuid.v4(),
        inspectionId: inspectionId,
        totalSample: 0,
        gradeACount: 0,
        gradeAPercentage: 0.0,
        ursCount: 0,
        ursPercentage: 0.0,
        otherDefectsCount: 0,
        otherDefectsPercentage: 0.0,
        finalGrade: 'Incomplete Sample',
        rulesVersion: config.rulesVersion,
      );
    }

    final total = validations.length;
    int healthyCount = 0;
    int damagedCount = 0;
    int rottenCount = 0;
    int sproutedCount = 0;
    int undersizedCount = 0;
    int unknownCount = 0;

    for (final v in validations) {
      switch (v.finalClass) {
        case OnionClass.healthy:
          healthyCount++;
          break;
        case OnionClass.damaged:
          damagedCount++;
          break;
        case OnionClass.blackRot:
        case OnionClass.softRot:
        case OnionClass.mold:
        case OnionClass.rotten:
          rottenCount++;
          break;
        case OnionClass.sprouted:
          sproutedCount++;
          break;
        case OnionClass.undersized:
          undersizedCount++;
          break;
        case OnionClass.unknown:
          unknownCount++;
          break;
      }
    }

    final healthyPct = double.parse(((healthyCount / total) * 100).toStringAsFixed(1));
    final rottenPct = double.parse(((rottenCount / total) * 100).toStringAsFixed(1));
    final damagedPct = double.parse(((damagedCount / total) * 100).toStringAsFixed(1));
    final otherDefectsCount = damagedCount + rottenCount + sproutedCount + undersizedCount + unknownCount;
    final otherDefectsPct = double.parse(((otherDefectsCount / total) * 100).toStringAsFixed(1));

    // Calculate URS (Under-Recovery Sample: acceptable onions that don't qualify as prime Grade A, e.g. minor defects/sprouted/undersized)
    final ursCount = sproutedCount + undersizedCount + (damagedCount > 2 ? damagedCount ~/ 2 : 0);
    final ursPct = double.parse(((ursCount / total) * 100).toStringAsFixed(1));

    String finalGrade;
    if (healthyPct >= config.minGradeAHealthyPercentage &&
        rottenPct <= config.maxGradeARottenPercentage &&
        damagedPct <= config.maxGradeADamagedPercentage) {
      finalGrade = 'Grade A (Best Quality)';
    } else if (healthyPct >= config.minUrsHealthyPercentage &&
        rottenPct <= config.maxUrsRottenPercentage) {
      finalGrade = 'Grade B (Good Quality)';
    } else if (rottenPct <= 15.0) {
      finalGrade = 'Grade C (Lower Quality)';
    } else {
      finalGrade = 'Grade D (Worst Quality / Rejected)';
    }

    return GradingResult(
      id: _uuid.v4(),
      inspectionId: inspectionId,
      totalSample: total,
      gradeACount: healthyCount,
      gradeAPercentage: healthyPct,
      ursCount: ursCount,
      ursPercentage: ursPct,
      otherDefectsCount: otherDefectsCount,
      otherDefectsPercentage: otherDefectsPct,
      finalGrade: finalGrade,
      rulesVersion: config.rulesVersion,
      createdAt: DateTime.now(),
    );
  }
}
