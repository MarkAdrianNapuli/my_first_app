import 'package:flutter/material.dart';

import '../constants.dart';
import '../widgets/common_widgets.dart';

class SettingsPage extends StatelessWidget {
  final String status;
  final DateTime? lastSynced;
  final bool isSyncing;
  final VoidCallback onSync;
  final VoidCallback onReset;
  final VoidCallback onRefreshDashboard;
  final VoidCallback onExport;
  const SettingsPage({
    super.key,
    required this.status,
    required this.lastSynced,
    required this.isSyncing,
    required this.onSync,
    required this.onReset,
    required this.onRefreshDashboard,
    required this.onExport,
  });

  String get formattedLastSync {
    if (lastSynced == null) return 'Not synchronized yet';
    final d = lastSynced!.toLocal();
    return '${d.month}/${d.day}/${d.year} ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}:${d.second.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Settings & Synchronization')),
    body: ListView(
      padding: const EdgeInsets.all(14),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('API Connection', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 12),
                Row(children: [const Text('Current status'), const Spacer(), StatusPill(status: status)]),
                const SizedBox(height: 8),
                Text('Last synchronization: $formattedLastSync', style: const TextStyle(fontSize: 12, color: Colors.black54)),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: isSyncing ? null : onSync,
                    style: FilledButton.styleFrom(backgroundColor: lpuRed),
                    icon: isSyncing
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.sync),
                    label: Text(isSyncing ? 'Synchronizing...' : 'Sync Data Now'),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Column(
            children: [
              const ListTile(
                leading: Icon(Icons.storage, color: navy),
                title: Text('Local Student Database', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.dashboard_customize, color: navy),
                title: const Text('Refresh Dashboard'),
                trailing: const Icon(Icons.chevron_right),
                onTap: onRefreshDashboard,
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.text_snippet_outlined, color: navy),
                title: const Text('Export Records to .txt'),
                trailing: const Icon(Icons.chevron_right),
                onTap: onExport,
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.delete_forever, color: Colors.red),
                title: const Text('Reset Student Database'),
                trailing: const Icon(Icons.chevron_right),
                onTap: onReset,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
      ],
    ),
  );
}

