import 'package:flutter/material.dart';

import '../constants.dart';
import '../models/api_user.dart';
import '../widgets/common_widgets.dart';

class OnlineDirectoryPage extends StatefulWidget {
  final List<ApiUser> users;
  final bool isSyncing;
  final String? error;
  final VoidCallback onRefresh;
  const OnlineDirectoryPage({super.key, required this.users, required this.isSyncing, required this.error, required this.onRefresh});
  @override
  State<OnlineDirectoryPage> createState() => _OnlineDirectoryPageState();
}

class _OnlineDirectoryPageState extends State<OnlineDirectoryPage> {
  final searchController = TextEditingController();

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Widget _apiSummaryCards(List<ApiUser> users) {
    final companies = users.map((u) => u.company).where((v) => v.isNotEmpty && v != 'No company').toSet().length;
    final emails = users.where((u) => u.email.trim().isNotEmpty).length;
    final phones = users.where((u) => u.phone.trim().isNotEmpty).length;
    final stats = [
      ('Total Users', users.length, Icons.people),
      ('Companies', companies, Icons.business),
      ('Emails', emails, Icons.email),
      ('Contact Numbers', phones, Icons.phone),
    ];
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 8,
      mainAxisSpacing: 8,
      childAspectRatio: 1.8,
      children: stats.map((s) => MetricCard(title: s.$1, value: '${s.$2}', icon: s.$3, color: navy)).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final query = searchController.text.toLowerCase();
    final filtered = widget.users
        .where((u) => u.name.toLowerCase().contains(query) || u.email.toLowerCase().contains(query) || u.company.toLowerCase().contains(query))
        .toList();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Online Directory'),
        actions: [
          IconButton(
            onPressed: widget.isSyncing ? null : widget.onRefresh,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh API',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(14),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(13),
              child: Row(
                children: [
                  const Icon(Icons.cloud_done, color: Colors.green),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      '${widget.users.length} online users retrieved from JSONPlaceholder',
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                    ),
                  ),
                  if (widget.isSyncing) const SizedBox(width: 17, height: 17, child: CircularProgressIndicator(strokeWidth: 2)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: searchController,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Search name, email, or company'),
          ),
          const SizedBox(height: 12),
          if (widget.error != null && widget.users.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Icon(Icons.cloud_off, color: Colors.red, size: 30),
                    const SizedBox(height: 7),
                    const Text('Unable to connect to API'),
                    Text(widget.error!, maxLines: 3, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11)),
                    TextButton.icon(onPressed: widget.onRefresh, icon: const Icon(Icons.refresh), label: const Text('Try Again')),
                  ],
                ),
              ),
            ),
          if (filtered.isEmpty && widget.users.isNotEmpty)
            const EmptyState(icon: Icons.search_off, title: 'No matching API users', message: 'Try a different search term.'),
          ...filtered.map((u) => Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: CircleAvatar(backgroundColor: const Color(0xFFE6EDF5), child: Text('${u.id}')),
              title: Text(u.name, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('${u.email}\n${u.phone}\n${u.company} • ${u.city}', style: const TextStyle(fontSize: 11)),
              isThreeLine: true,
              trailing: const Icon(Icons.cloud_done, color: Colors.green),
            ),
          )),
          const SizedBox(height: 12),
          const SectionHeading(title: 'API Summary Statistics', subtitle: ''),
          const SizedBox(height: 8),
          _apiSummaryCards(widget.users),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

