import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../constants.dart';
import '../models/photo_record.dart';
import '../services/device_controller.dart';
import '../utils/format.dart';
import '../widgets/common_widgets.dart';

class DevicePage extends StatelessWidget {
  final DeviceController controller;
  final void Function(String) onActivity;
  const DevicePage({super.key, required this.controller, required this.onActivity});

  DeviceController get c => controller;

  void _snack(BuildContext context, String msg) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating));
  }

  Future<void> _takePhoto(BuildContext context) async {
    try {
      final p = await c.takePhoto();
      if (p != null) {
        onActivity('Captured photo ${p.name}');
        _snack(context, 'Photo saved (${fmtSize(p.sizeBytes)}).');
      }
    } catch (e) {
      _snack(context, 'Camera error: $e');
    }
  }

  Future<void> _openGallery(BuildContext context) async {
    try {
      final list = await c.pickFromGallery();
      if (list.isNotEmpty) {
        onActivity('Selected ${list.length} image(s) from gallery');
        _snack(context, '${list.length} image(s) added to history.');
      }
    } catch (e) {
      _snack(context, 'Gallery error: $e');
    }
  }

  Future<void> _remove(BuildContext context, PhotoRecord p) async {
    await c.removePhoto(p);
    onActivity('Removed image ${p.name}');
    _snack(context, 'Image removed.');
  }

  // ---------- reusable pieces ----------

  Widget _title(String t, {String? sub}) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(t, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        if (sub != null) Text(sub, style: const TextStyle(color: Colors.black54, fontSize: 11)),
      ],
    ),
  );

  Widget _xyzRow(String axis, double value, {double? prev, double? peak}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          SizedBox(width: 22, child: Text(axis, style: const TextStyle(fontWeight: FontWeight.bold))),
          SizedBox(width: 70, child: Text(fmtNum(value))),
          if (prev != null)
            Expanded(
              child: Text(
                'prev ${fmtNum(prev)}  Δ ${fmtNum(value - prev)}',
                style: const TextStyle(fontSize: 11, color: Colors.black54),
              ),
            ),
          if (peak != null)
            Text('peak ${fmtNum(peak)}', style: const TextStyle(fontSize: 11, color: Colors.black54)),
        ],
      ),
    );
  }

  Widget _vectorCard(
      String title,
      List<double> v, {
        bool? live,
        List<double>? prev,
        List<double>? peak,
      }) {
    const axes = ['X', 'Y', 'Z'];
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15))),
                if (live != null) SensorChip(label: 'Live', active: live),
              ],
            ),
            const SizedBox(height: 6),
            for (var i = 0; i < 3; i++)
              _xyzRow(axes[i], v[i], prev: prev?[i], peak: peak?[i]),
          ],
        ),
      ),
    );
  }

  Widget _logCard(String title, List<String> log, VoidCallback onClear, {int show = 12}) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15))),
                if (log.isNotEmpty) TextButton(onPressed: onClear, child: const Text('Clear')),
              ],
            ),
            if (log.isEmpty)
              const Text('No entries yet.', style: TextStyle(fontSize: 12, color: Colors.black54))
            else
              ...log.take(show).map((e) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Text(e, style: const TextStyle(fontSize: 11, fontFamily: 'monospace')),
              )),
          ],
        ),
      ),
    );
  }

  Widget _photoCard(BuildContext context, PhotoRecord p, {double height = 220}) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Image.file(
            File(p.path),
            height: height,
            width: double.infinity,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => SizedBox(
              height: height,
              child: const Center(child: Icon(Icons.broken_image, size: 48)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(p.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 2),
                Text('${fmtSize(p.sizeBytes)} • ${fmtDateTime(p.time)}', style: const TextStyle(fontSize: 11, color: Colors.black54)),
                Text('Saved at: ${p.path}', maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 9, color: Colors.black45)),
              ],
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () => _remove(context, p),
              icon: const Icon(Icons.delete_outline, size: 17, color: Colors.red),
              label: const Text('Remove', style: TextStyle(color: Colors.red)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusRow(String label, bool active) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(
      children: [
        Icon(Icons.circle, size: 10, color: active ? Colors.green : Colors.red),
        const SizedBox(width: 8),
        Expanded(child: Text(label)),
        Text(active ? 'Active' : 'No data', style: TextStyle(color: active ? Colors.green : Colors.red, fontWeight: FontWeight.bold, fontSize: 12)),
      ],
    ),
  );

  // ---------- tabs ----------

  Widget _overviewTab(BuildContext context) {
    final latest = c.latestPhoto;
    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                onPressed: () => _takePhoto(context),
                style: FilledButton.styleFrom(backgroundColor: lpuRed),
                icon: const Icon(Icons.photo_camera),
                label: const Text('Take Photo'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _openGallery(context),
                icon: const Icon(Icons.photo_library),
                label: const Text('Select Photo'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _title('Latest Image'),
        if (latest == null)
          const Card(child: ListTile(leading: Icon(Icons.image_outlined), title: Text('No image yet')))
        else
          _photoCard(context, latest, height: 180),
        const SizedBox(height: 12),
        _vectorCard('Movement Data (Accelerometer)', c.accel, live: c.accelActive),
        const SizedBox(height: 10),
        _vectorCard('Gyroscope', c.gyro, live: c.gyroActive),
        const SizedBox(height: 10),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                const Expanded(child: Text('Compass', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15))),
                Text('Direction: ${c.direction}  ${c.heading.toStringAsFixed(0)}°', style: const TextStyle(fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Sensor Status', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                const SizedBox(height: 6),
                _statusRow('Camera', true),
                _statusRow('Accelerometer', c.accelActive),
                _statusRow('Gyroscope', c.gyroActive),
                _statusRow('Compass', c.compassActive),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Sensor Statistics', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                const SizedBox(height: 6),
                Text('Images captured: ${c.cameraPhotos.length}', style: const TextStyle(fontSize: 12)),
                Text('Images selected: ${c.galleryPhotos.length}', style: const TextStyle(fontSize: 12)),
                Text('Accel peaks  X ${fmtNum(c.accelPeak[0])}  Y ${fmtNum(c.accelPeak[1])}  Z ${fmtNum(c.accelPeak[2])}', style: const TextStyle(fontSize: 12)),
                Text('Gyro peaks  X ${fmtNum(c.gyroPeak[0])}  Y ${fmtNum(c.gyroPeak[1])}  Z ${fmtNum(c.gyroPeak[2])}', style: const TextStyle(fontSize: 12)),
                Text('Log entries: ${c.accelLog.length + c.gyroLog.length + c.compassLog.length}', style: const TextStyle(fontSize: 12)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        _logCard('Direction History', c.compassLog, () => c.clearLog(c.compassLog), show: 5),
      ],
    );
  }

  Widget _cameraTab(BuildContext context) {
    final shots = c.cameraPhotos;
    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        FilledButton.icon(
          onPressed: () => _takePhoto(context),
          style: FilledButton.styleFrom(backgroundColor: lpuRed, minimumSize: const Size.fromHeight(48)),
          icon: const Icon(Icons.photo_camera),
          label: const Text('Take Photo'),
        ),
        const SizedBox(height: 12),
        _title('Latest Captured Image', sub: '${shots.length} photo(s) captured'),
        if (shots.isEmpty)
          const Card(child: ListTile(leading: Icon(Icons.photo_camera_outlined), title: Text('No photos captured yet')))
        else ...[
          _photoCard(context, shots.first),
          if (shots.length > 1) ...[
            const SizedBox(height: 12),
            _title('Previous Photos'),
            ...shots.skip(1).map((p) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _photoCard(context, p, height: 150),
            )),
          ],
        ],
      ],
    );
  }

  Widget _galleryTab(BuildContext context) {
    final picks = c.galleryPhotos;
    final lastThree = picks.take(3).toList();
    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        FilledButton.icon(
          onPressed: () => _openGallery(context),
          style: FilledButton.styleFrom(backgroundColor: lpuRed, minimumSize: const Size.fromHeight(48)),
          icon: const Icon(Icons.photo_library),
          label: const Text('Select Image'),
        ),
        const SizedBox(height: 12),
        _title('Last 3 Selected Images', sub: '${picks.length} image(s) in dashboard history'),
        if (picks.isEmpty)
          const Card(child: ListTile(leading: Icon(Icons.photo_library_outlined), title: Text('No images selected yet')))
        else
          ...lastThree.map((p) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _photoCard(context, p, height: 180),
          )),
        if (picks.length > 3)
          Text('${picks.length - 3} older image(s) kept in history.', style: const TextStyle(fontSize: 11, color: Colors.black54)),
      ],
    );
  }

  Widget _accelTab(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        _vectorCard('Accelerometer (m/s²)', c.accel, live: c.accelActive, peak: c.accelPeak),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            onPressed: c.resetAccelPeaks,
            icon: const Icon(Icons.restart_alt),
            label: const Text('Reset peaks'),
          ),
        ),
        _logCard('Movement History', c.accelLog, () => c.clearLog(c.accelLog), show: 20),
      ],
    );
  }

  Widget _gyroTab(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        _vectorCard('Gyroscope (rad/s)', c.gyro, live: c.gyroActive, prev: c.prevGyro, peak: c.gyroPeak),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            onPressed: c.resetGyroPeaks,
            icon: const Icon(Icons.restart_alt),
            label: const Text('Reset peaks'),
          ),
        ),
        _logCard('Rotational Movement Log', c.gyroLog, () => c.clearLog(c.gyroLog), show: 20),
      ],
    );
  }

  Widget _compassTab(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              children: [
                SensorChip(label: 'Live', active: c.compassActive),
                const SizedBox(height: 14),
                Transform.rotate(
                  angle: -c.heading * math.pi / 180,
                  child: const Icon(Icons.navigation, size: 96, color: lpuRed),
                ),
                const SizedBox(height: 8),
                Text(c.direction, style: const TextStyle(fontSize: 34, fontWeight: FontWeight.bold)),
                Text('${c.heading.toStringAsFixed(0)}°', style: const TextStyle(fontSize: 18, color: Colors.black54)),
                const SizedBox(height: 6),
                const Text(
                  'Hold the phone flat. The arrow points to North.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 11, color: Colors.black45),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        _vectorCard('Magnetometer (µT)', c.mag, live: c.compassActive),
        const SizedBox(height: 10),
        _logCard('Direction History', c.compassLog, () => c.clearLog(c.compassLog), show: 20),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 6,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Device Monitor'),
          bottom: const TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.white,
            tabs: [
              Tab(icon: Icon(Icons.dashboard), text: 'Overview'),
              Tab(icon: Icon(Icons.photo_camera), text: 'Camera'),
              Tab(icon: Icon(Icons.photo_library), text: 'Gallery'),
              Tab(icon: Icon(Icons.speed), text: 'Accelerometer'),
              Tab(icon: Icon(Icons.threed_rotation), text: 'Gyroscope'),
              Tab(icon: Icon(Icons.explore), text: 'Compass'),
            ],
          ),
        ),
        body: ListenableBuilder(
          listenable: c,
          builder: (context, _) => TabBarView(
            children: [
              _overviewTab(context),
              _cameraTab(context),
              _galleryTab(context),
              _accelTab(context),
              _gyroTab(context),
              _compassTab(context),
            ],
          ),
        ),
      ),
    );
  }
}

