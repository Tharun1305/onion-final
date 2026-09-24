import 'dart:math';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/primary_button.dart';
import '../../models/inspection.dart';
import '../auth/auth_provider.dart';
import 'add_onion_image_screen.dart';

class CreateInspectionScreen extends StatefulWidget {
  const CreateInspectionScreen({super.key});

  @override
  State<CreateInspectionScreen> createState() => _CreateInspectionScreenState();
}

class _CreateInspectionScreenState extends State<CreateInspectionScreen> {
  final _formKey = GlobalKey<FormState>();
  late String _inspectionCode;
  final _batchIdController = TextEditingController(text: 'ON-2026-0042');
  final _quantityController = TextEditingController(text: '850');
  final _sourceController = TextEditingController(text: 'Local Procurement');
  final _notesController = TextEditingController(text: 'Morning arrival lot #12. High bulb density, uniform sizing.');

  String _selectedVariety = 'Red Onion';
  late String _selectedCenterId;
  late String _selectedCenterName;

  @override
  void initState() {
    super.initState();
    final randomNum = (10000 + Random().nextInt(90000)).toString();
    _inspectionCode = 'INS-2026-00$randomNum'.substring(0, 14);

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final user = auth.currentUser;
    _selectedCenterId = user?.centerId ?? 'center-erode-01';
    _selectedCenterName = user?.centerName ?? 'Erode Onion Procurement Center';
  }

  @override
  void dispose() {
    _batchIdController.dispose();
    _quantityController.dispose();
    _sourceController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _proceedToCapture() {
    if (!_formKey.currentState!.validate()) return;

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final user = auth.currentUser;
    final uuid = const Uuid().v4();

    final inspection = Inspection(
      id: uuid,
      inspectionCode: _inspectionCode,
      batchId: _batchIdController.text.trim(),
      centerId: _selectedCenterId,
      centerName: _selectedCenterName,
      inspectorId: user?.inspectorId ?? user?.id ?? 'INS1024',
      inspectorName: user?.fullName ?? 'Arun Kumar',
      sampleCount: 42,
      quantity: double.tryParse(_quantityController.text) ?? 850.0,
      source: _sourceController.text.trim(),
      variety: _selectedVariety,
      status: InspectionStatus.capturing,
      syncStatus: SyncStatus.localOnly,
      notes: _notesController.text.trim(),
      inspectedAt: DateTime.now(),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AddOnionImageScreen(inspection: inspection),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final user = auth.currentUser;
    final inspectorName = user?.fullName ?? 'Arun Kumar';
    final procurementCenter = user?.centerName ?? 'Erode Onion Procurement Center';
    final nowFormatted = DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now());

    return Scaffold(
      backgroundColor: AppTheme.bgSlate,
      appBar: AppBar(
        title: const Text('Create Inspection'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Step indicator
              Container(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.borderGray),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: const BoxDecoration(
                        color: AppTheme.primaryTeal,
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Text(
                          '1',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Step 1 of 5: Batch Details',
                          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppTheme.darkSlate),
                        ),
                        Text(
                          'Enter consignment details before capturing samples',
                          style: TextStyle(fontSize: 11, color: AppTheme.textMuted),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Automatically generated details card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'AUTOMATICALLY GENERATED',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textMuted,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildReadonlyRow('Inspection ID', _inspectionCode, highlight: true),
                      const Divider(height: 16),
                      _buildReadonlyRow('Date / Time', nowFormatted),
                      const Divider(height: 16),
                      _buildReadonlyRow('Inspector', '$inspectorName (${user?.inspectorId ?? "INS1024"})'),
                      const Divider(height: 16),
                      _buildReadonlyRow('Procurement Center', procurementCenter),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Officer entry fields card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'BATCH DETAILS',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textMuted,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Batch ID *
                      TextFormField(
                        controller: _batchIdController,
                        decoration: const InputDecoration(
                          labelText: 'Batch ID *',
                          hintText: 'e.g. ON-2026-0042',
                          prefixIcon: Icon(Icons.qr_code, size: 20),
                        ),
                        textCapitalization: TextCapitalization.characters,
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Batch ID is required' : null,
                      ),
                      const SizedBox(height: 16),

                      // Quantity in kg (numeric keyboard)
                      TextFormField(
                        controller: _quantityController,
                        decoration: const InputDecoration(
                          labelText: 'Quantity (kg) *',
                          hintText: 'e.g. 850',
                          suffixText: 'kg',
                          prefixIcon: Icon(Icons.scale, size: 20),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Please enter quantity in kg';
                          if (double.tryParse(v) == null) return 'Enter a valid number';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Source / Supplier
                      TextFormField(
                        controller: _sourceController,
                        decoration: const InputDecoration(
                          labelText: 'Source / Supplier',
                          hintText: 'e.g. Local Procurement',
                          prefixIcon: Icon(Icons.storefront, size: 20),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Variety Dropdown
                      DropdownButtonFormField<String>(
                        initialValue: _selectedVariety,
                        decoration: const InputDecoration(
                          labelText: 'Variety *',
                          prefixIcon: Icon(Icons.grass, size: 20),
                        ),
                        items: AppConstants.onionVarieties.map((variety) {
                          return DropdownMenuItem<String>(
                            value: variety,
                            child: Text(variety),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _selectedVariety = val);
                        },
                      ),
                      const SizedBox(height: 16),

                      // Notes [Optional]
                      TextFormField(
                        controller: _notesController,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          labelText: 'Notes (Optional)',
                          hintText: 'Visual remarks, moisture conditions, truck number...',
                          prefixIcon: Icon(Icons.notes, size: 20),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Button: Continue to Capture
              PrimaryButton(
                label: 'Continue to Capture',
                icon: Icons.camera_alt,
                height: 52,
                onPressed: _proceedToCapture,
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReadonlyRow(String label, String value, {bool highlight = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: highlight ? FontWeight.w800 : FontWeight.w600,
            color: highlight ? AppTheme.primaryTeal : AppTheme.darkSlate,
          ),
        ),
      ],
    );
  }
}
