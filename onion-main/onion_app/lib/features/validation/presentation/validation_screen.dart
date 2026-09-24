import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../models/inspection.dart';
import '../../../models/validation_record.dart';
import '../../grading/grading_engine.dart';
import '../../grading/presentation/final_result_screen.dart';

class ValidationScreen extends StatefulWidget {
  final Inspection inspection;

  const ValidationScreen({super.key, required this.inspection});

  @override
  State<ValidationScreen> createState() => _ValidationScreenState();
}

class _ValidationScreenState extends State<ValidationScreen> {
  late List<ValidationRecord> _validations;

  final List<String> _standardReasons = [
    'Visual inspection shows defect differing from AI',
    'Neck rot or internal softness visible on closer inspection',
    'Surface skin blemished but bulb tissue healthy',
    'Early sprout emerging beneath dry outer scale',
    'Under 45mm diameter (Undersized standard)',
    'Shadow or lighting artifact caused AI misclassification',
    'Other (Inspector physical evaluation)',
  ];

  @override
  void initState() {
    super.initState();
    _validations = List<ValidationRecord>.from(widget.inspection.validations);

    // If fresh and uncorrected, pre-seed a couple of realistic corrections for demo (e.g. 4 corrections)
    if (_validations.length >= 42 && !_validations.any((v) => v.isCorrected)) {
      // Onion #12: AI predicted Damaged (87%), Inspector overrides to Healthy
      if (_validations.length > 11) {
        final v = _validations[11];
        _validations[11] = ValidationRecord(
          id: v.id,
          inspectionId: v.inspectionId,
          detectionId: v.detectionId,
          originalAiClass: v.originalAiClass,
          aiConfidence: v.aiConfidence,
          inspectorClass: OnionClass.healthy,
          correctionReason: 'Surface skin blemished but bulb tissue healthy',
          finalClass: OnionClass.healthy,
          isCorrected: true,
          validatedBy: widget.inspection.inspectorName,
          validatedAt: DateTime.now(),
        );
      }
    }
  }

  void _acceptValidation(int index) {
    final v = _validations[index];
    setState(() {
      _validations[index] = ValidationRecord(
        id: v.id,
        inspectionId: v.inspectionId,
        detectionId: v.detectionId,
        originalAiClass: v.originalAiClass,
        aiConfidence: v.aiConfidence,
        inspectorClass: v.originalAiClass,
        correctionReason: null,
        finalClass: v.originalAiClass,
        isCorrected: false,
        validatedBy: widget.inspection.inspectorName,
        validatedAt: DateTime.now(),
      );
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Onion #${index + 1} accepted as ${AppConstants.formatOnionClass(v.originalAiClass)}'),
        duration: const Duration(milliseconds: 900),
      ),
    );
  }

  void _showChangeModal(int index) {
    final v = _validations[index];
    OnionClass selectedClass = v.isCorrected ? v.finalClass : v.originalAiClass;
    String selectedReason = v.correctionReason ?? _standardReasons.first;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Onion #${index + 1}',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.darkSlate),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppTheme.bgSlate,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: AppTheme.borderGray),
                          ),
                          child: Text(
                            'AI: ${AppConstants.formatOnionClass(v.originalAiClass)} (${(v.aiConfidence * 100).toInt()}%)',
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.textMuted),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    const Text(
                      'Select Final Classification',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.darkSlate),
                    ),
                    const SizedBox(height: 8),

                    // Radio list for classifications: Healthy, Damaged, Rotten, Sprouted, Undersized, Unknown
                    Column(
                      children: OnionClass.values.map((cls) {
                        final title = AppConstants.formatOnionClass(cls);
                        final isSelected = selectedClass == cls;
                        final color = AppConstants.getClassColor(cls);

                        return InkWell(
                          onTap: () => setModalState(() => selectedClass = cls),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              children: [
                                Container(
                                  width: 20,
                                  height: 20,
                                  margin: const EdgeInsets.only(right: 10, left: 4),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: isSelected ? AppTheme.primaryTeal : AppTheme.borderGray,
                                      width: isSelected ? 6 : 2,
                                    ),
                                  ),
                                ),
                                Container(
                                  width: 10,
                                  height: 10,
                                  decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  title,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                    color: isSelected ? AppTheme.darkSlate : AppTheme.textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 12),

                    const Text(
                      'Correction reason',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.darkSlate),
                    ),
                    const SizedBox(height: 6),

                    DropdownButtonFormField<String>(
                      initialValue: _standardReasons.contains(selectedReason) ? selectedReason : _standardReasons.first,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                      items: _standardReasons.map((r) {
                        return DropdownMenuItem(
                          value: r,
                          child: Text(r, style: const TextStyle(fontSize: 12), overflow: TextOverflow.ellipsis),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setModalState(() => selectedReason = val);
                      },
                    ),
                    const SizedBox(height: 20),

                    // Save Button
                    PrimaryButton(
                      label: 'Save Correction',
                      icon: Icons.check,
                      height: 48,
                      onPressed: () {
                        final isModified = selectedClass != v.originalAiClass;
                        setState(() {
                          _validations[index] = ValidationRecord(
                            id: v.id,
                            inspectionId: v.inspectionId,
                            detectionId: v.detectionId,
                            originalAiClass: v.originalAiClass,
                            aiConfidence: v.aiConfidence,
                            inspectorClass: selectedClass,
                            correctionReason: isModified ? selectedReason : null,
                            finalClass: selectedClass,
                            isCorrected: isModified,
                            validatedBy: widget.inspection.inspectorName,
                            validatedAt: DateTime.now(),
                          );
                        });
                        Navigator.of(ctx).pop();
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _finalizeAndCalculateGrade() {
    // Run grading engine on final inspector-verified observations
    final finalGrading = GradingEngine.evaluate(
      inspectionId: widget.inspection.id,
      validations: _validations,
    );

    final updated = widget.inspection.copyWith(
      status: InspectionStatus.validated,
      validations: _validations,
      gradingResult: finalGrading,
    );

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => FinalResultScreen(inspection: updated),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final total = _validations.length;
    final correctionsCount = _validations.where((v) => v.isCorrected).length;

    return Scaffold(
      backgroundColor: AppTheme.bgSlate,
      appBar: AppBar(
        title: const Text('Review AI Assessment'),
      ),
      body: Column(
        children: [
          // Header (Section 18)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: Colors.white,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Review AI Assessment',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppTheme.darkSlate),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$total onions analyzed • $correctionsCount corrections required',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.primaryTeal),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDCFCE7),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'INSPECTOR VERIFIED',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.successGreen),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Detection review list
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _validations.length,
              itemBuilder: (context, index) {
                final v = _validations[index];
                final isCorr = v.isCorrected;

                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: BorderSide(
                      color: isCorr ? AppTheme.warningAmber : AppTheme.borderGray,
                      width: isCorr ? 1.5 : 1.0,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Onion # Index & Tag
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Onion #${index + 1}',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.darkSlate,
                              ),
                            ),
                            if (isCorr)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFEF3C7),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  'OVERRIDDEN',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.warningAmber,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 10),

                        // AI vs Verified UI (Section 19: crystal clear difference)
                        Row(
                          children: [
                            // AI Prediction Block
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: AppTheme.bgSlate,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: AppTheme.borderGray),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'AI Prediction',
                                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.textMuted),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      AppConstants.formatOnionClass(v.originalAiClass),
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: AppConstants.getClassColor(v.originalAiClass),
                                      ),
                                    ),
                                    Text(
                                      '${(v.aiConfidence * 100).toInt()}% confidence',
                                      style: const TextStyle(fontSize: 10, color: AppTheme.textMuted),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),

                            // Inspector Verified Block
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: isCorr ? const Color(0xFFFEF3C7).withValues(alpha: 0.5) : const Color(0xFFDCFCE7).withValues(alpha: 0.5),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: isCorr ? const Color(0xFFFCD34D) : const Color(0xFF86EFAC),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Inspector Verified',
                                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.darkSlate),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      AppConstants.formatOnionClass(v.finalClass),
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: isCorr ? AppTheme.warningAmber : AppTheme.successGreen,
                                      ),
                                    ),
                                    Text(
                                      isCorr ? 'Corrected' : 'Accepted',
                                      style: const TextStyle(fontSize: 10, color: AppTheme.textMuted),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),

                        // Show reason if corrected
                        if (isCorr && v.correctionReason != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            'Reason: ${v.correctionReason}',
                            style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: AppTheme.textMuted),
                          ),
                        ],
                        const SizedBox(height: 12),

                        // Actions: [ Accept ] [ Change ]
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                style: OutlinedButton.styleFrom(
                                  minimumSize: const Size.fromHeight(36),
                                  side: const BorderSide(color: AppTheme.borderGray),
                                ),
                                onPressed: () => _acceptValidation(index),
                                child: const Text('Accept', style: TextStyle(fontSize: 12, color: AppTheme.darkSlate)),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  minimumSize: const Size.fromHeight(36),
                                  backgroundColor: isCorr ? AppTheme.warningAmber : AppTheme.primaryTeal,
                                  foregroundColor: Colors.white,
                                ),
                                onPressed: () => _showChangeModal(index),
                                child: const Text('Change', style: TextStyle(fontSize: 12)),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // Bottom Action
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: PrimaryButton(
              label: 'Finalize & Calculate Grade',
              icon: Icons.military_tech,
              height: 52,
              onPressed: _finalizeAndCalculateGrade,
            ),
          ),
        ],
      ),
    );
  }
}
