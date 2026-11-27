import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/photo_record.dart';
import '../utils/format.dart';

class DeviceController extends ChangeNotifier {
  static const String _kPhotos = 'week5_photos';
  static const String _kAccelLog = 'week5_accel_log';
  static const String _kGyroLog = 'week5_gyro_log';
  static const String _kCompassLog = 'week5_compass_log';
  static const String _kPeaks = 'week5_peaks';
  static const int _maxLog = 30;
  static const Duration _sampling = Duration(milliseconds: 300);
  static const Duration _logEvery = Duration(seconds: 2);
  static const List<String> _dirs = ['N', 'NE', 'E', 'SE', 'S', 'SW', 'W', 'NW'];

  final ImagePicker _picker = ImagePicker();

  // Images
  final List<PhotoRecord> photos = [];

  // Sensor values
  List<double> accel = [0, 0, 0];
  List<double> accelPeak = [0, 0, 0];
  List<double> gyro = [0, 0, 0];
  List<double> prevGyro = [0, 0, 0];
  List<double> gyroPeak = [0, 0, 0];
  List<double> mag = [0, 0, 0];
  double heading = 0;
  String direction = '—';

  // Sensor status
  bool accelActive = false;
  bool gyroActive = false;
  bool compassActive = false;

  // Logs (newest first)
  final List<String> accelLog = [];
  final List<String> gyroLog = [];
  final List<String> compassLog = [];

  DateTime? _lastAccelLog;
  DateTime? _lastGyroLog;
  DateTime? _lastCompassLog;
  String _lastDirectionLogged = '';

  StreamSubscription<AccelerometerEvent>? _accelSub;
  StreamSubscription<GyroscopeEvent>? _gyroSub;
  StreamSubscription<MagnetometerEvent>? _magSub;
  Timer? _saveTimer;
  bool _dirty = false;
  bool _disposed = false;

  List<PhotoRecord> get cameraPhotos => photos.where((p) => p.source == 'camera').toList();
  List<PhotoRecord> get galleryPhotos => photos.where((p) => p.source == 'gallery').toList();
  PhotoRecord? get latestPhoto => photos.isEmpty ? null : photos.first;

  Future<void> init() async {
    await _load();

    _accelSub = accelerometerEventStream(samplingPeriod: _sampling).listen(
      _onAccel,
      onError: (_) {
        accelActive = false;
        _notify();
      },
    );
    _gyroSub = gyroscopeEventStream(samplingPeriod: _sampling).listen(
      _onGyro,
      onError: (_) {
        gyroActive = false;
        _notify();
      },
    );
    _magSub = magnetometerEventStream(samplingPeriod: _sampling).listen(
      _onMag,
      onError: (_) {
        compassActive = false;
        _notify();
      },
    );

    _saveTimer = Timer.periodic(const Duration(seconds: 5), (_) => _persist());
    _notify();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  // ---------------- Sensors ----------------

  void _addLog(List<String> log, String entry) {
    log.insert(0, entry);
    if (log.length > _maxLog) log.removeLast();
    _dirty = true;
  }

  void _onAccel(AccelerometerEvent e) {
    accel = [e.x, e.y, e.z];
    accelActive = true;
    for (var i = 0; i < 3; i++) {
      if (accel[i].abs() > accelPeak[i]) {
        accelPeak[i] = accel[i].abs();
        _dirty = true;
      }
    }
    final now = DateTime.now();
    if (_lastAccelLog == null || now.difference(_lastAccelLog!) >= _logEvery) {
      _lastAccelLog = now;
      _addLog(accelLog, '${fmtClock(now)}  X ${fmtNum(e.x)}  Y ${fmtNum(e.y)}  Z ${fmtNum(e.z)}');
    }
    _notify();
  }

  void _onGyro(GyroscopeEvent e) {
    prevGyro = List<double>.from(gyro);
    gyro = [e.x, e.y, e.z];
    gyroActive = true;
    for (var i = 0; i < 3; i++) {
      if (gyro[i].abs() > gyroPeak[i]) {
        gyroPeak[i] = gyro[i].abs();
        _dirty = true;
      }
    }
    final now = DateTime.now();
    if (_lastGyroLog == null || now.difference(_lastGyroLog!) >= _logEvery) {
      _lastGyroLog = now;
      _addLog(gyroLog, '${fmtClock(now)}  X ${fmtNum(e.x)}  Y ${fmtNum(e.y)}  Z ${fmtNum(e.z)} rad/s');
    }
    _notify();
  }

  void _onMag(MagnetometerEvent e) {
    mag = [e.x, e.y, e.z];
    // Heading with the phone held flat: 0 = North, 90 = East.
    var deg = math.atan2(-e.x, e.y) * 180 / math.pi;
    if (deg < 0) deg += 360;
    heading = deg;
    direction = _dirs[((deg + 22.5) / 45).floor() % 8];
    compassActive = true;

    final now = DateTime.now();
    final changedDirection = direction != _lastDirectionLogged;
    if (changedDirection ||
        _lastCompassLog == null ||
        now.difference(_lastCompassLog!) >= const Duration(seconds: 5)) {
      if (changedDirection || _lastCompassLog == null) {
        _lastCompassLog = now;
        _lastDirectionLogged = direction;
        _addLog(compassLog, '${fmtClock(now)}  $direction  ${deg.toStringAsFixed(0)}°');
      }
    }
    _notify();
  }

  void resetAccelPeaks() {
    accelPeak = [0, 0, 0];
    _dirty = true;
    _notify();
  }

  void resetGyroPeaks() {
    gyroPeak = [0, 0, 0];
    _dirty = true;
    _notify();
  }

  void clearLog(List<String> log) {
    log.clear();
    _dirty = true;
    _notify();
  }

  // ---------------- Images ----------------

  Future<PhotoRecord?> takePhoto() async {
    final x = await _picker.pickImage(source: ImageSource.camera, imageQuality: 90);
    if (x == null) return null;
    return _storePhoto(x, 'camera');
  }

  Future<List<PhotoRecord>> pickFromGallery() async {
    final files = await _picker.pickMultiImage(imageQuality: 90);
    final added = <PhotoRecord>[];
    for (final x in files) {
      added.add(await _storePhoto(x, 'gallery'));
    }
    return added;
  }

  Future<PhotoRecord> _storePhoto(XFile x, String source) async {
    // Copy into the app's own folder so the image survives cache cleanups.
    final dir = await getApplicationDocumentsDirectory();
    final folder = Directory('${dir.path}/week5_photos');
    if (!await folder.exists()) await folder.create(recursive: true);
    final now = DateTime.now();
    final dest = '${folder.path}/${now.millisecondsSinceEpoch}_${x.name}';
    await File(x.path).copy(dest);
    final size = await File(dest).length();
    final record = PhotoRecord(path: dest, name: x.name, sizeBytes: size, time: now, source: source);
    photos.insert(0, record);
    await _savePhotos();
    _notify();
    return record;
  }

  Future<void> removePhoto(PhotoRecord p) async {
    photos.removeWhere((e) => e.path == p.path);
    try {
      final f = File(p.path);
      if (await f.exists()) await f.delete();
    } catch (_) {}
    await _savePhotos();
    _notify();
  }

  // ---------------- Local storage ----------------

  Future<void> _savePhotos() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kPhotos, jsonEncode(photos.map((p) => p.toJson()).toList()));
  }

  Future<void> _persist() async {
    if (!_dirty) return;
    _dirty = false;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_kAccelLog, accelLog);
    await prefs.setStringList(_kGyroLog, gyroLog);
    await prefs.setStringList(_kCompassLog, compassLog);
    await prefs.setString(_kPeaks, jsonEncode({'a': accelPeak, 'g': gyroPeak}));
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();

    final rawPhotos = prefs.getString(_kPhotos);
    if (rawPhotos != null && rawPhotos.isNotEmpty) {
      try {
        final list = jsonDecode(rawPhotos) as List<dynamic>;
        photos
          ..clear()
          ..addAll(list
              .map((e) => PhotoRecord.fromJson(e as Map<String, dynamic>))
              .where((p) => File(p.path).existsSync()));
      } catch (e) {
        debugPrint('Unable to read saved photos: $e');
      }
    }

    accelLog
      ..clear()
      ..addAll(prefs.getStringList(_kAccelLog) ?? []);
    gyroLog
      ..clear()
      ..addAll(prefs.getStringList(_kGyroLog) ?? []);
    compassLog
      ..clear()
      ..addAll(prefs.getStringList(_kCompassLog) ?? []);

    final rawPeaks = prefs.getString(_kPeaks);
    if (rawPeaks != null) {
      try {
        final m = jsonDecode(rawPeaks) as Map<String, dynamic>;
        List<double> toList(dynamic v) =>
            (v as List<dynamic>).map((e) => (e as num).toDouble()).toList();
        accelPeak = toList(m['a']);
        gyroPeak = toList(m['g']);
      } catch (_) {}
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _accelSub?.cancel();
    _gyroSub?.cancel();
    _magSub?.cancel();
    _saveTimer?.cancel();
    _dirty = true;
    _persist();
    super.dispose();
  }
}

