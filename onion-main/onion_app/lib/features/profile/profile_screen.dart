import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/network/network_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/primary_button.dart';
import '../../core/widgets/section_header.dart';
import '../auth/auth_provider.dart';
import '../auth/login_screen.dart';
import '../sync/sync_queue_service.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final network = Provider.of<NetworkService>(context);
    final syncService = Provider.of<SyncQueueService>(context);
    final user = auth.currentUser;

    return Scaffold(
      backgroundColor: AppTheme.bgSlate,
      appBar: AppBar(
        title: const Text('Inspector Profile'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Officer Profile Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 36,
                      backgroundColor: AppTheme.primaryTeal.withValues(alpha: 0.1),
                      child: const Icon(Icons.person, size: 40, color: AppTheme.primaryTeal),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      user?.fullName ?? 'Arun Kumar',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.darkSlate,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user?.role ?? 'Quality Inspector',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppTheme.textMuted,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryTeal.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppTheme.primaryTeal.withValues(alpha: 0.3)),
                      ),
                      child: Text(
                        'ID: ${user?.inspectorId ?? 'INS1024'}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryTeal,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Official Procurement Center Details
            const SectionHeader(title: 'Procurement Center Assignment'),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildProfileRow('Procurement Center', user?.centerName ?? 'Erode Onion Procurement Center'),
                    const Divider(height: 20),
                    _buildProfileRow('Center Code', user?.centerCode ?? 'ERO-01'),
                    const Divider(height: 20),
                    _buildProfileRow('District', user?.district ?? 'Erode'),
                    const Divider(height: 20),
                    _buildProfileRow('State', user?.state ?? 'Tamil Nadu'),
                    const Divider(height: 20),
                    _buildProfileRow('Authority', 'Govt APMC Agricultural Marketing Dept'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Connectivity & Offline Control
            const SectionHeader(title: 'Network & Synchronization'),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              network.isOnline ? Icons.wifi : Icons.wifi_off,
                              color: network.isOnline ? AppTheme.successGreen : AppTheme.warningAmber,
                              size: 20,
                            ),
                            const SizedBox(width: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  network.isOnline ? 'Online Mode' : 'Offline Mode Active',
                                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  network.isOnline ? 'Connected to APMC Server' : 'All records saved locally',
                                  style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                                ),
                              ],
                            ),
                          ],
                        ),
                        Switch(
                          value: !network.forceOfflineMode,
                          activeThumbColor: AppTheme.primaryTeal,
                          onChanged: (val) {
                            network.toggleForceOfflineMode();
                          },
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.sync, size: 20, color: AppTheme.textMuted),
                            const SizedBox(width: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Pending Queue', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                                Text(
                                  '${syncService.pendingCount} inspections waiting to sync',
                                  style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                                ),
                              ],
                            ),
                          ],
                        ),
                        TextButton(
                          onPressed: syncService.isSyncing
                              ? null
                              : () async {
                                  await syncService.processQueue();
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Synchronization completed.')),
                                    );
                                  }
                                },
                          child: syncService.isSyncing
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Text('Sync Now'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Logout Button
            SecondaryButton(
              label: 'Sign Out',
              icon: Icons.logout,
              borderColor: AppTheme.errorRed,
              textColor: AppTheme.errorRed,
              onPressed: () async {
                await auth.logout();
                if (context.mounted) {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (route) => false,
                  );
                }
              },
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 13, color: AppTheme.textMuted),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppTheme.darkSlate,
          ),
        ),
      ],
    );
  }
}
