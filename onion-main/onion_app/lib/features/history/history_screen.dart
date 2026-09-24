import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/empty_state_view.dart';
import '../../core/widgets/inspection_card.dart';
import '../../data/repositories/inspection_repository.dart';
import '../../models/inspection.dart';
import '../inspection/create_inspection_screen.dart';
import '../sync/sync_queue_service.dart';
import 'inspection_detail_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final InspectionRepository _repository = InspectionRepository();
  List<Inspection> _inspections = [];
  bool _isLoading = true;
  String _selectedFilter = 'ALL'; // ALL, VERIFIED, PENDING_SYNC, SYNCED
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadInspections();
  }

  Future<void> _loadInspections() async {
    setState(() => _isLoading = true);
    final all = await _repository.getAllInspections();
    if (mounted) {
      setState(() {
        _inspections = all;
        _isLoading = false;
      });
    }
  }

  List<Inspection> get _filteredInspections {
    return _inspections.where((i) {
      // Filter tab
      if (_selectedFilter == 'VERIFIED') {
        if (i.status != InspectionStatus.completed && i.status != InspectionStatus.validated) {
          return false;
        }
      } else if (_selectedFilter == 'PENDING_SYNC') {
        if (i.syncStatus == SyncStatus.synced) {
          return false;
        }
      } else if (_selectedFilter == 'SYNCED') {
        if (i.syncStatus != SyncStatus.synced) {
          return false;
        }
      }

      // Search query
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final matchCode = i.inspectionCode.toLowerCase().contains(q);
        final matchBatch = i.batchId.toLowerCase().contains(q);
        if (!matchCode && !matchBatch) return false;
      }

      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final syncService = Provider.of<SyncQueueService>(context);
    final filtered = _filteredInspections;

    return Scaffold(
      backgroundColor: AppTheme.bgSlate,
      appBar: AppBar(
        title: const Text('Inspection History'),
        actions: [
          IconButton(
            tooltip: 'Sync Queue',
            icon: syncService.isSyncing
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.sync),
            onPressed: syncService.isSyncing
                ? null
                : () async {
                    await syncService.processQueue();
                    _loadInspections();
                  },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar (Section 24)
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search by Inspection ID / Batch ID',
                prefixIcon: const Icon(Icons.search, size: 20),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onChanged: (val) => setState(() => _searchQuery = val.trim()),
            ),
          ),

          // Filters (Section 24: All, Verified, Pending Sync, Synced)
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip('ALL', 'All (${_inspections.length})'),
                  const SizedBox(width: 8),
                  _buildFilterChip(
                    'VERIFIED',
                    'Verified (${_inspections.where((i) => i.status == InspectionStatus.completed || i.status == InspectionStatus.validated).length})',
                  ),
                  const SizedBox(width: 8),
                  _buildFilterChip(
                    'PENDING_SYNC',
                    'Pending Sync (${_inspections.where((i) => i.syncStatus != SyncStatus.synced).length})',
                  ),
                  const SizedBox(width: 8),
                  _buildFilterChip(
                    'SYNCED',
                    'Synced (${_inspections.where((i) => i.syncStatus == SyncStatus.synced).length})',
                  ),
                ],
              ),
            ),
          ),
          const Divider(height: 1),

          // List of Inspection Cards
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : filtered.isEmpty
                    ? EmptyStateView(
                        icon: Icons.history,
                        title: 'No inspections found',
                        description: _searchQuery.isNotEmpty
                            ? 'No matches for "$_searchQuery". Check spelling or reset filters.'
                            : 'No inspections registered under this category yet.',
                        actionLabel: '+ New Inspection',
                        onAction: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const CreateInspectionScreen()),
                          ).then((_) => _loadInspections());
                        },
                      )
                    : RefreshIndicator(
                        onRefresh: _loadInspections,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: filtered.length,
                          itemBuilder: (context, index) {
                            final insp = filtered[index];
                            return InspectionCard(
                              inspection: insp,
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => InspectionDetailScreen(inspectionId: insp.id),
                                  ),
                                ).then((_) => _loadInspections());
                              },
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String key, String label) {
    final isSelected = _selectedFilter == key;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: AppTheme.primaryTeal,
      backgroundColor: AppTheme.bgSlate,
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
        color: isSelected ? Colors.white : AppTheme.darkSlate,
      ),
      onSelected: (selected) {
        if (selected) setState(() => _selectedFilter = key);
      },
    );
  }
}
