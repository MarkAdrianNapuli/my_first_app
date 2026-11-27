class PhotoRecord {
  final String path;
  final String name;
  final int sizeBytes;
  final DateTime time;
  final String source; // 'camera' or 'gallery'

  const PhotoRecord({
    required this.path,
    required this.name,
    required this.sizeBytes,
    required this.time,
    required this.source,
  });

  Map<String, dynamic> toJson() => {
    'path': path,
    'name': name,
    'size': sizeBytes,
    'time': time.toIso8601String(),
    'source': source,
  };

  factory PhotoRecord.fromJson(Map<String, dynamic> j) => PhotoRecord(
    path: j['path']?.toString() ?? '',
    name: j['name']?.toString() ?? 'image',
    sizeBytes: (j['size'] as num?)?.toInt() ?? 0,
    time: DateTime.tryParse(j['time']?.toString() ?? '') ?? DateTime.now(),
    source: j['source']?.toString() ?? 'gallery',
  );
}

