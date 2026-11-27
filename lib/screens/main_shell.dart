import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../constants.dart';
import '../models/api_user.dart';
import '../models/student.dart';
import '../services/api_service.dart';
import '../services/device_controller.dart';
import '../services/txt_exporter.dart';
import '../utils/format.dart';
import '../widgets/common_widgets.dart';
import 'device_page.dart';
import 'online_directory_page.dart';
import 'settings_page.dart';
import 'students_page.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int selectedTab = 0;
  List<Student> students = [];
  List<ApiUser> apiUsers = [];
  bool isLoadingStudents = true;
  bool isSyncing = false;
  String syncStatus = 'Connecting';
  String connection = 'Checking';
  DateTime? lastSynced;
  String? apiError;
  Timer? syncTimer;
  int unreadNotifications = 0;
  final List<String> activityLog = [];
  final DeviceController device = DeviceController();

  @override
  void initState() {
    super.initState();
    _loadStudents();
    device.init();
    _syncApiData(showMessage: false);
    syncTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      _syncApiData(showMessage: false);
    });
  }

  @override
  void dispose() {
    syncTimer?.cancel();
    device.dispose();
    super.dispose();
  }

  Future<void> _loadStudents() async {
    final saved = await StudentStorage.loadStudents();
    if (!mounted) return;
    setState(() {
      students = saved;
      isLoadingStudents = false;
    });
  }

  Future<void> _saveStudents() async {
    await StudentStorage.saveStudents(students);
  }

  Future<void> _refreshDashboard({bool showMessage = true}) async {
    await _loadStudents();
    if (!mounted) return;
    if (showMessage) _showSnack('Dashboard refreshed. ${students.length} student record(s) loaded.');
  }

  bool _isOffline(Object e) {
    final text = e.toString();
    return e is SocketException ||
        e is TimeoutException ||
        e is http.ClientException ||
        text.contains('SocketException') ||
        text.contains('Failed host lookup');
  }

  Future<void> _syncApiData({bool showMessage = true}) async {
    if (isSyncing) return;
    setState(() {
      isSyncing = true;
      syncStatus = 'Syncing';
      apiError = null;
    });
    try {
      final users = await ApiService.getUsers();
      if (!mounted) return;
      setState(() {
        apiUsers = users;
        lastSynced = DateTime.now();
        connection = 'Online';
        syncStatus = 'Sync Successful';
        apiError = null;
        activityLog.insert(0, '${_time(lastSynced!)} • API data synchronized');
        if (activityLog.length > 12) activityLog.removeLast();
      });
      if (showMessage) _showSnack('Sync successful. ${apiUsers.length} online users retrieved.');
    } catch (e) {
      if (!mounted) return;
      final offline = _isOffline(e);
      setState(() {
        connection = offline ? 'Offline' : 'Online';
        syncStatus = offline ? 'Offline' : 'Sync Failed';
        apiError = e.toString();
        activityLog.insert(0, '${_time(DateTime.now())} • ${offline ? 'Offline - API unreachable' : 'API synchronization failed'}');
        if (activityLog.length > 12) activityLog.removeLast();
      });
      if (showMessage) {
        _showSnack(offline ? 'You are offline.  PALOAD KA MUNA TOL.' : 'Sync failed. Please try again.');
      }
    } finally {
      if (mounted) setState(() => isSyncing = false);
    }
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message), behavior: SnackBarBehavior.floating));
  }

  void _recordActivity(String message) {
    setState(() {
      activityLog.insert(0, '${_time(DateTime.now())} • $message');
      if (activityLog.length > 12) activityLog.removeLast();
      unreadNotifications++;
    });
  }

  Future<void> _addOrEditStudent({Student? existing}) async {
    final result = await showDialog<Student>(
      context: context,
      builder: (_) => StudentFormDialog(student: existing),
    );
    if (result == null || !mounted) return;
    final duplicateId = students.any((s) => s.id.toLowerCase() == result.id.toLowerCase() && s.id != existing?.id);
    if (duplicateId) {
      _showSnack('A student with this ID already exists.');
      return;
    }
    setState(() {
      if (existing == null) {
        students.add(result);
      } else {
        final index = students.indexWhere((s) => s.id == existing.id);
        if (index >= 0) students[index] = result;
      }
    });
    await _saveStudents();
    _recordActivity(existing == null ? 'Added ${result.name}' : 'Updated ${result.name}');
    _showSnack(existing == null ? 'Student added successfully.' : 'Student updated successfully.');
  }

  Future<void> _deleteStudent(Student student) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete student?'),
        content: Text('Are you sure you want to delete ${student.name}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    setState(() => students.removeWhere((s) => s.id == student.id));
    await _saveStudents();
    _recordActivity('Deleted ${student.name}');
    _showSnack('Student deleted.');
  }

  Future<void> _resetDatabase() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset student database?'),
        content: const Text('This will permanently remove all locally saved student records.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Reset')),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    await StudentStorage.clearStudents();
    if (!mounted) return;
    setState(() => students.clear());
    _recordActivity('Reset local student database');
    _showSnack('Student database has been cleared.');
  }

  // ---- TXT export ----------------------------------------------------------

  String _two(int n) => n.toString().padLeft(2, '0');

  String _buildExportText(DateTime now) {
    final b = StringBuffer()
      ..writeln('LPU SMART CAMPUS - STUDENT RECORDS')
      ..writeln('Exported: ${now.year}-${_two(now.month)}-${_two(now.day)} ${_time(now)}')
      ..writeln('=' * 50)
      ..writeln('Total Students : ${students.length}')
      ..writeln('Average Grade  : ${averageGrade.toStringAsFixed(1)}')
      ..writeln('Highest Grade  : ${highestGrade.toStringAsFixed(1)}')
      ..writeln('Top Performer  : ${topPerformer?.name ?? '-'}')
      ..writeln('=' * 50)
      ..writeln();
    for (var i = 0; i < students.length; i++) {
      final s = students[i];
      b
        ..writeln('${i + 1}. ${s.name}')
        ..writeln('   Student ID : ${s.id}')
        ..writeln('   Course     : ${s.course}')
        ..writeln('   Year Level : ${s.yearLevel}')
        ..writeln('   Grade      : ${s.grade.toStringAsFixed(1)}')
        ..writeln('   Email      : ${s.email}')
        ..writeln('   Contact    : ${s.contactNumber.isEmpty ? 'N/A' : s.contactNumber}')
        ..writeln();
    }
    return b.toString();
  }

  Future<void> _exportStudents() async {
    if (students.isEmpty) {
      _showSnack('No student records to export.');
      return;
    }
    try {
      final now = DateTime.now();
      final stamp = '${now.year}${_two(now.month)}${_two(now.day)}_${_two(now.hour)}${_two(now.minute)}${_two(now.second)}';
      final fileName = 'lpu_students_$stamp.txt';
      final location = await TxtExporter.save(fileName: fileName, content: _buildExportText(now));
      if (!mounted) return;
      _recordActivity('Exported ${students.length} students to $fileName');
      _showSnack('Saved to $location');
    } catch (e) {
      _showSnack('Unable to save the file: $e');
    }
  }

  double get averageGrade => students.isEmpty ? 0 : students.map((s) => s.grade).reduce((a, b) => a + b) / students.length;
  double get highestGrade => students.isEmpty ? 0 : students.map((s) => s.grade).reduce((a, b) => a > b ? a : b);
  Student? get topPerformer {
    if (students.isEmpty) return null;
    return students.reduce((a, b) => a.grade >= b.grade ? a : b);
  }

  String _time(DateTime date) => fmtClock(date);

  @override
  Widget build(BuildContext context) {
    final pages = [
      _buildDashboard(),
      StudentsPage(
        students: students,
        onAdd: () => _addOrEditStudent(),
        onEdit: (s) => _addOrEditStudent(existing: s),
        onDelete: _deleteStudent,
        onExport: _exportStudents,
      ),
      OnlineDirectoryPage(users: apiUsers, isSyncing: isSyncing, error: apiError, onRefresh: () => _syncApiData()),
      SettingsPage(
        status: syncStatus,
        lastSynced: lastSynced,
        isSyncing: isSyncing,
        onSync: () => _syncApiData(),
        onReset: _resetDatabase,
        onRefreshDashboard: () => _refreshDashboard(),
        onExport: _exportStudents,
      ),
      DevicePage(controller: device, onActivity: _recordActivity),
    ];

    return PopScope(
      canPop: selectedTab == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) setState(() => selectedTab = 0);
      },
      child: Scaffold(
        body: IndexedStack(index: selectedTab, children: pages),
        bottomNavigationBar: NavigationBar(
          selectedIndex: selectedTab,
          onDestinationSelected: (index) => setState(() {
            selectedTab = index;
            if (index == 3) unreadNotifications = 0;
          }),
          destinations: const [
            NavigationDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard), label: 'Dashboard'),
            NavigationDestination(icon: Icon(Icons.people_outline), selectedIcon: Icon(Icons.people), label: 'Students'),
            NavigationDestination(icon: Icon(Icons.cloud_outlined), selectedIcon: Icon(Icons.cloud), label: 'Online'),
            NavigationDestination(icon: Icon(Icons.settings_outlined), selectedIcon: Icon(Icons.settings), label: 'Settings'),
            NavigationDestination(icon: Icon(Icons.sensors_outlined), selectedIcon: Icon(Icons.sensors), label: 'Device'),
          ],
        ),
        floatingActionButton: selectedTab == 1
            ? FloatingActionButton.extended(
          onPressed: () => _addOrEditStudent(),
          backgroundColor: lpuRed,
          foregroundColor: Colors.white,
          icon: const Icon(Icons.person_add),
          label: const Text('Add Student'),
        )
            : selectedTab == 0
            ? FloatingActionButton.small(
          onPressed: () => _syncApiData(),
          backgroundColor: lpuRed,
          foregroundColor: Colors.white,
          child: isSyncing
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Icon(Icons.sync),
        )
            : null,
      ),
    );
  }

  Widget _quickAccessTile(IconData icon, String title, String subtitle, int tab) => ListTile(
    dense: true,
    leading: Icon(icon, color: lpuRed),
    title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
    subtitle: Text(subtitle, style: const TextStyle(fontSize: 11)),
    trailing: const Icon(Icons.chevron_right),
    onTap: () => setState(() => selectedTab = tab),
  );

  /// Compact Week 5 summary shown on the Home dashboard.
  Widget _deviceSummaryCard() {
    return ListenableBuilder(
      listenable: device,
      builder: (context, _) {
        final latest = device.latestPhoto;
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text('Device Monitor', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    ),
                    TextButton(
                      onPressed: () => setState(() => selectedTab = 4),
                      child: const Text('Open'),
                    ),
                  ],
                ),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    SensorChip(label: 'Accelerometer', active: device.accelActive),
                    SensorChip(label: 'Gyroscope', active: device.gyroActive),
                    SensorChip(label: 'Compass', active: device.compassActive),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Accel  X ${fmtNum(device.accel[0])}  Y ${fmtNum(device.accel[1])}  Z ${fmtNum(device.accel[2])}',
                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                ),
                Text(
                  'Heading  ${device.direction}  ${device.heading.toStringAsFixed(0)}°',
                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                ),
                if (latest != null) ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(
                          File(latest.path),
                          width: 56,
                          height: 56,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, size: 40),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Latest image', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                            Text(fmtDateTime(latest.time), style: const TextStyle(fontSize: 11, color: Colors.black54)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDashboard() {
    final top = topPerformer;
    return SafeArea(
      child: RefreshIndicator(
        onRefresh: () async {
          await _refreshDashboard(showMessage: false);
          await _syncApiData();
        },
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 90),
          children: [
            Row(
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('LPU Smart App', style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold)),
                      Text('LPU Student Management Dashboard', style: TextStyle(color: Colors.black54, fontSize: 12)),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => _refreshDashboard(),
                  icon: const Icon(Icons.refresh, size: 26),
                  tooltip: 'Refresh Dashboard',
                ),
                Stack(
                  children: [
                    IconButton(
                      onPressed: () => setState(() {
                        selectedTab = 3;
                        unreadNotifications = 0;
                      }),
                      icon: const Icon(Icons.notifications_outlined, size: 27),
                    ),
                    if (unreadNotifications > 0)
                      Positioned(
                        right: 7,
                        top: 6,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                          child: Text(
                            unreadNotifications > 9 ? '9+' : '$unreadNotifications',
                            style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [lpuRed, Color(0xFF790B12)]),
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.school, color: Colors.white, size: 30),
                  SizedBox(height: 10),
                  Text('Welcome to LPU Cavite Smart App', style: TextStyle(color: Colors.white, fontSize: 21, fontWeight: FontWeight.bold)),
                  SizedBox(height: 4),
                ],
              ),
            ),
            const SizedBox(height: 18),
            const SectionHeading(title: 'Dashboard Overview', subtitle: ''),
            const SizedBox(height: 10),
            LayoutBuilder(builder: (context, constraints) {
              final columns = constraints.maxWidth >= 650 ? 3 : 2;
              return GridView.count(
                crossAxisCount: columns,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 9,
                mainAxisSpacing: 9,
                childAspectRatio: columns == 3 ? 1.45 : 1.55,
                children: [
                  MetricCard(title: 'Total Students', value: '${students.length}', icon: Icons.people, color: Colors.blue),
                  MetricCard(title: 'Average Grade', value: students.isEmpty ? '—' : averageGrade.toStringAsFixed(1), icon: Icons.analytics, color: Colors.orange),
                  MetricCard(title: 'Highest Grade', value: students.isEmpty ? '—' : highestGrade.toStringAsFixed(1), icon: Icons.trending_up, color: Colors.deepPurple),
                  MetricCard(
                    title: 'Top Performer',
                    value: top == null ? '—' : top.name,
                    subtitle: top == null ? 'No records' : '${top.grade.toStringAsFixed(1)} grade',
                    icon: Icons.emoji_events,
                    color: Colors.amber,
                  ),
                  MetricCard(title: 'Online Users', value: '${apiUsers.length}', icon: Icons.cloud_done, color: Colors.green),
                  MetricCard(
                    title: 'Passing Rate',
                    value: students.isEmpty ? '—' : '${(students.where((s) => s.grade >= 75).length / students.length * 100).toStringAsFixed(0)}%',
                    subtitle: students.isEmpty ? 'No records' : '${students.where((s) => s.grade >= 75).length} of ${students.length} passed',
                    icon: Icons.verified,
                    color: Colors.teal,
                  ),
                ],
              );
            }),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('API Synchronization Status', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    const SizedBox(height: 9),
                    Row(
                      children: [
                        Expanded(
                          child: Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: [StatusPill(status: connection), StatusPill(status: syncStatus)],
                          ),
                        ),
                        if (isSyncing) const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                      ],
                    ),
                    const SizedBox(height: 7),
                    Text('Last updated: ${lastSynced == null ? 'Not synchronized yet' : _time(lastSynced!)}', style: const TextStyle(fontSize: 12, color: Colors.black54)),
                    Text('Users retrieved: ${apiUsers.length}', style: const TextStyle(fontSize: 12, color: Colors.black54)),
                    if (apiError != null)
                      const Padding(
                        padding: EdgeInsets.only(top: 5),
                        child: Text('Offline: API data is currently unavailable.', style: TextStyle(color: Colors.red, fontSize: 11)),
                      ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        onPressed: isSyncing ? null : () => _syncApiData(),
                        icon: const Icon(Icons.sync),
                        label: const Text('Sync Now'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            _deviceSummaryCard(),
            const SizedBox(height: 16),
            const SectionHeading(title: 'Quick Access', subtitle: 'Open the other modules of the system'),
            const SizedBox(height: 8),
            Card(
              child: Column(
                children: [
                  _quickAccessTile(Icons.people, 'Student Records', 'View, add, edit and delete students', 1),
                  const Divider(height: 1),
                  _quickAccessTile(Icons.cloud, 'Online Directory', 'Users retrieved from the REST API', 2),
                  const Divider(height: 1),
                  _quickAccessTile(Icons.settings, 'Settings', 'Refresh, sync, export and reset data', 3),
                  const Divider(height: 1),
                  _quickAccessTile(Icons.sensors, 'Device Monitor', 'Camera, gallery and motion sensors', 4),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const SectionHeading(title: 'Top Performer', subtitle: 'Highest grade in the local student list'),
            const SizedBox(height: 8),
            Card(
              child: ListTile(
                leading: const CircleAvatar(backgroundColor: Color(0xFFFFF0C2), child: Icon(Icons.emoji_events, color: Colors.orange)),
                title: Text(top?.name ?? 'No student records yet', style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(top == null ? 'Add a student with a grade to see the top performer.' : '${top.id} • ${top.course}'),
                trailing: Text(top == null ? '—' : top.grade.toStringAsFixed(1), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
              ),
            ),
            const SizedBox(height: 16),
            const SectionHeading(title: 'CCS Programme Dashboard', subtitle: 'Programme information from the Week 2 activity'),
            const SizedBox(height: 8),
            const ProgrammeGrid(),
            const SizedBox(height: 16),
            const SectionHeading(title: 'Faculty Directory', subtitle: 'Sample faculty contact information'),
            const SizedBox(height: 8),
            const FacultyDirectorySection(),
            const SizedBox(height: 16),
            const SectionHeading(title: 'Recent Activity', subtitle: 'Latest changes and synchronization events'),
            const SizedBox(height: 8),
            Card(
              child: activityLog.isEmpty
                  ? const ListTile(leading: Icon(Icons.history), title: Text('No recent activity yet'))
                  : Column(
                children: activityLog
                    .take(5)
                    .map((item) => ListTile(
                  dense: true,
                  leading: const Icon(Icons.history, color: lpuRed, size: 19),
                  title: Text(item, style: const TextStyle(fontSize: 12)),
                ))
                    .toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

