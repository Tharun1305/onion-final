import 'package:flutter/material.dart';

/// Enumeration representing the quality grade of an inspected onion.
enum QualityGrade {
  A,
  B,
  C,
  D;

  String get letter => name;

  String get title {
    switch (this) {
      case QualityGrade.A:
        return 'Grade A - Best Quality';
      case QualityGrade.B:
        return 'Grade B - Good Quality';
      case QualityGrade.C:
        return 'Grade C - Lower Quality';
      case QualityGrade.D:
        return 'Grade D - Worst Quality';
    }
  }

  String get shortLabel {
    switch (this) {
      case QualityGrade.A:
        return 'Best Quality';
      case QualityGrade.B:
        return 'Good Quality';
      case QualityGrade.C:
        return 'Lower Quality';
      case QualityGrade.D:
        return 'Worst Quality';
    }
  }

  String get description {
    switch (this) {
      case QualityGrade.A:
        return 'Highest quality sound onion with minimal defect risk.';
      case QualityGrade.B:
        return 'Good acceptable quality with minor concerns or minor sprouting.';
      case QualityGrade.C:
        return 'Noticeable quality degradation, mechanical damage, or moderate defect signals.';
      case QualityGrade.D:
        return 'Severe pathological defect, active rot/mold, or critical damage.';
    }
  }

  Color get color {
    switch (this) {
      case QualityGrade.A:
        return const Color(0xFF059669); // Emerald Green
      case QualityGrade.B:
        return const Color(0xFF0D9488); // Teal
      case QualityGrade.C:
        return const Color(0xFFD97706); // Amber / Orange
      case QualityGrade.D:
        return const Color(0xFFDC2626); // Crimson Red
    }
  }

  Color get bgColor {
    switch (this) {
      case QualityGrade.A:
        return const Color(0xFFECFDF5);
      case QualityGrade.B:
        return const Color(0xFFF0FDFA);
      case QualityGrade.C:
        return const Color(0xFFFFFBEB);
      case QualityGrade.D:
        return const Color(0xFFFEF2F2);
    }
  }

  Color get borderColor {
    switch (this) {
      case QualityGrade.A:
        return const Color(0xFFA7F3D0);
      case QualityGrade.B:
        return const Color(0xFF99F6E4);
      case QualityGrade.C:
        return const Color(0xFFFDE68A);
      case QualityGrade.D:
        return const Color(0xFFFECACA);
    }
  }
}

/// Centralized deterministic grading engine.
/// Derives quality grades (A, B, C, D) strictly from the real trained-model output
/// (prediction, confidence, and full defect probability distribution).
class OnionQualityGrader {
  /// Evaluates the real AI output and returns a deterministic [QualityGrade].
  ///
  /// Criteria:
  /// - Grade A: Highest quality / Healthy onion
  ///   * Primary prediction is 'healthy'
  ///   * Healthy probability >= 70.0%
  ///   * No individual rot probability >= 20.0%
  ///
  /// - Grade B: Acceptable / Good quality with minor concerns
  ///   * Healthy prediction with moderate confidence (healthy prob 50.0% - 70.0%), OR
  ///   * Minor physiological defect (e.g. 'sprouted') where healthy/acceptable traits remain (sprouted >= 40.0% and rot < 25.0%), OR
  ///   * Healthy probability >= 50.0% with low-to-moderate defect signals
  ///
  /// - Grade C: Noticeable defects / Moderate quality issue
  ///   * Primary prediction is 'damaged' (cuts/bruises) with confidence < 75.0% or moderate healthy presence (>= 20.0%), OR
  ///   * Primary prediction is 'sprouted' with high sprouting probability (>= 60.0%), OR
  ///   * Healthy prediction with low confidence (< 50.0%), OR
  ///   * Emerging rot defect (combined rot probability between 25.0% and 50.0%)
  ///
  /// - Grade D: Severe defect / Worst quality
  ///   * Primary prediction is active rot/disease: 'black_rot', 'soft_rot', or 'mold', OR
  ///   * Combined rot/pathological probability >= 50.0%, OR
  ///   * Severe mechanical damage ('damaged' with confidence >= 75.0% and healthy < 15.0%), OR
  ///   * Healthy probability is extremely low (< 20.0% with defects dominating)
  static QualityGrade evaluate({
    required String rawPrediction,
    required double confidence,
    required Map<String, double> probabilities,
  }) {
    final normPrediction = rawPrediction.toLowerCase().replaceAll(' ', '_').trim();

    // Extract individual probabilities (percentages 0.0 - 100.0)
    final healthyProb = _getProb(probabilities, ['healthy']);
    final blackRotProb = _getProb(probabilities, ['black_rot', 'blackrot']);
    final softRotProb = _getProb(probabilities, ['soft_rot', 'softrot']);
    final moldProb = _getProb(probabilities, ['mold']);
    final sproutedProb = _getProb(probabilities, ['sprouted']);
    final damagedProb = _getProb(probabilities, ['damaged']);

    final totalRotProb = blackRotProb + softRotProb + moldProb;
    final maxSingleRot = [blackRotProb, softRotProb, moldProb].reduce((a, b) => a > b ? a : b);

    // Rule 1: Severe defect / Worst Quality (Grade D)
    if (normPrediction == 'black_rot' ||
        normPrediction == 'soft_rot' ||
        normPrediction == 'mold' ||
        totalRotProb >= 50.0 ||
        (normPrediction == 'damaged' && confidence >= 75.0 && healthyProb < 15.0) ||
        (healthyProb < 20.0 && totalRotProb >= 35.0)) {
      return QualityGrade.D;
    }

    // Rule 2: Highest Quality / Healthy (Grade A)
    if (normPrediction == 'healthy' &&
        healthyProb >= 70.0 &&
        maxSingleRot < 20.0 &&
        totalRotProb < 25.0) {
      return QualityGrade.A;
    }

    // Rule 3: Good Quality / Minor Concerns (Grade B)
    if ((normPrediction == 'healthy' && healthyProb >= 50.0) ||
        (normPrediction == 'sprouted' && sproutedProb >= 40.0 && totalRotProb < 25.0) ||
        (healthyProb >= 50.0 && totalRotProb < 30.0)) {
      return QualityGrade.B;
    }

    // Rule 4: Noticeable Defects / Moderate Quality (Grade C)
    if (normPrediction == 'damaged' ||
        damagedProb >= 40.0 ||
        normPrediction == 'sprouted' ||
        totalRotProb >= 25.0 ||
        healthyProb < 50.0) {
      return QualityGrade.C;
    }

    // Default safe fallback based on top prediction status
    return normPrediction == 'healthy' ? QualityGrade.B : QualityGrade.C;
  }

  static double _getProb(Map<String, double> map, List<String> keys) {
    for (final k in keys) {
      if (map.containsKey(k)) return map[k]!;
      // Case-insensitive fallback
      for (final entry in map.entries) {
        if (entry.key.toLowerCase().replaceAll(' ', '_') == k) {
          return entry.value;
        }
      }
    }
    return 0.0;
  }
}
