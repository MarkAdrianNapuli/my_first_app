import 'package:flutter/material.dart';

import '../constants.dart';

class SensorChip extends StatelessWidget {
  final String label;
  final bool active;
  const SensorChip({super.key, required this.label, required this.active});

  @override
  Widget build(BuildContext context) {
    final color = active ? Colors.green : Colors.red;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.10), borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.circle, color: color, size: 9),
          const SizedBox(width: 6),
          Text('$label: ${active ? 'Active' : 'No data'}', style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 11)),
        ],
      ),
    );
  }
}

class SectionHeading extends StatelessWidget {
  final String title;
  final String subtitle;
  const SectionHeading({super.key, required this.title, required this.subtitle});
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      if (subtitle.isNotEmpty) ...[
        const SizedBox(height: 2),
        Text(subtitle, style: const TextStyle(color: Colors.black54, fontSize: 11)),
      ],
    ],
  );
}

class MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final String? subtitle;
  final IconData icon;
  final Color color;
  const MetricCard({super.key, required this.title, required this.value, required this.icon, required this.color, this.subtitle});
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(11),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 7),
          Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold)),
          Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 10, color: Colors.black54)),
          if (subtitle != null) Text(subtitle!, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 9, color: Colors.black45)),
        ],
      ),
    ),
  );
}

class StatusPill extends StatelessWidget {
  final String status;
  const StatusPill({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final good = status == 'Online' || status == 'Sync Successful';
    final bad = status == 'Offline' || status == 'Sync Failed';
    final color = good ? Colors.green : bad ? Colors.red : Colors.orange;
    final icon = status == 'Sync Successful'
        ? Icons.check_circle
        : status == 'Sync Failed'
        ? Icons.error
        : status == 'Offline'
        ? Icons.wifi_off
        : status == 'Online'
        ? Icons.wifi
        : Icons.sync;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.10), borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 13),
          const SizedBox(width: 6),
          Text(status, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 11)),
        ],
      ),
    );
  }
}

class FacultyDirectorySection extends StatelessWidget {
  const FacultyDirectorySection({super.key});
  static const faculty = [
    ('Faculty Member 1', 'faculty1@lpucavite.edu.ph', 'College of Computer Studies'),
    ('Faculty Member 2', 'faculty2@lpucavite.edu.ph', 'College of Computer Studies'),
    ('Faculty Member 3', 'faculty3@lpucavite.edu.ph', 'College of Computer Studies'),
  ];
  @override
  Widget build(BuildContext context) => Column(
    children: faculty
        .map((f) => Card(
      margin: const EdgeInsets.only(bottom: 7),
      child: ListTile(
        dense: true,
        leading: const CircleAvatar(child: Icon(Icons.person_outline)),
        title: Text(f.$1, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        subtitle: Text('${f.$2}\n${f.$3}', style: const TextStyle(fontSize: 10)),
        isThreeLine: true,
      ),
    ))
        .toList(),
  );
}

class ProgrammeGrid extends StatelessWidget {
  const ProgrammeGrid({super.key});
  static const programmes = [
    ('BSIT-NS', 'Network and Security', 120),
    ('BSIT-WM', 'Web and Mobile Development', 150),
    ('BSCS-DS', 'Data Science', 100),
    ('BSCS-SE', 'Software Engineering', 90),
  ];
  @override
  Widget build(BuildContext context) => GridView.count(
    crossAxisCount: 2,
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    crossAxisSpacing: 8,
    mainAxisSpacing: 8,
    childAspectRatio: 1.65,
    children: programmes
        .map((p) => Card(
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.school, color: navy),
            const SizedBox(height: 4),
            Text(p.$1, style: const TextStyle(fontWeight: FontWeight.bold)),
            Text('${p.$3} Students', style: const TextStyle(fontSize: 11)),
            Text(p.$2, textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 9, color: Colors.black54)),
          ],
        ),
      ),
    ))
        .toList(),
  );
}


class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  const EmptyState({super.key, required this.icon, required this.title, required this.message});
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 45, color: Colors.black38),
          const SizedBox(height: 10),
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(message, textAlign: TextAlign.center, style: const TextStyle(color: Colors.black54, fontSize: 12)),
        ],
      ),
    ),
  );
}
