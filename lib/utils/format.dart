String _pad2(int n) => n.toString().padLeft(2, '0');

String fmtClock(DateTime date) {
  final local = date.toLocal();
  final hour = local.hour % 12 == 0 ? 12 : local.hour % 12;
  final suffix = local.hour >= 12 ? 'PM' : 'AM';
  return '$hour:${_pad2(local.minute)}:${_pad2(local.second)} $suffix';
}

String fmtDateTime(DateTime date) {
  final l = date.toLocal();
  return '${l.year}-${_pad2(l.month)}-${_pad2(l.day)} ${fmtClock(l)}';
}

String fmtSize(int bytes) {
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
  return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
}

String fmtNum(double v) => v.toStringAsFixed(2);
