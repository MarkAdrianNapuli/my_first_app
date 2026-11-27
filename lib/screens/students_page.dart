import 'package:flutter/material.dart';

import '../constants.dart';
import '../models/student.dart';
import '../utils/student_id_formatter.dart';
import '../widgets/common_widgets.dart';

class StudentsPage extends StatefulWidget {
  final List<Student> students;
  final VoidCallback onAdd;
  final ValueChanged<Student> onEdit;
  final ValueChanged<Student> onDelete;
  final VoidCallback onExport;
  const StudentsPage({
    super.key,
    required this.students,
    required this.onAdd,
    required this.onEdit,
    required this.onDelete,
    required this.onExport,
  });

  @override
  State<StudentsPage> createState() => _StudentsPageState();
}

class _StudentsPageState extends State<StudentsPage> {
  final searchController = TextEditingController();
  String selectedFilter = 'All Students';

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  List<Student> get filteredStudents {
    final query = searchController.text.trim().toLowerCase();
    return widget.students.where((student) {
      final matchesQuery = student.name.toLowerCase().contains(query) || student.id.toLowerCase().contains(query);
      final course = student.course.toUpperCase();
      final matchesFilter = selectedFilter == 'All Students' ||
          (selectedFilter == 'BSIT' && course.startsWith('BSIT')) ||
          (selectedFilter == 'BSCS' && course.startsWith('BSCS')) ||
          (selectedFilter == 'BSIS' && course.startsWith('BSIS'));
      return matchesQuery && matchesFilter;
    }).toList();
  }

  Widget _studentCard(Student student) => Card(
    margin: const EdgeInsets.only(bottom: 9),
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: const Color(0xFFFFE6E7),
                child: Text(
                  student.name.isEmpty ? '?' : student.name[0].toUpperCase(),
                  style: const TextStyle(color: lpuRed, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(student.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    Text('ID: ${student.id} • ${student.course}', style: const TextStyle(fontSize: 11, color: Colors.black54)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(student.grade.toStringAsFixed(1), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: lpuRed)),
            ],
          ),
          const Divider(height: 18),
          _studentDetail(Icons.email_outlined, student.email),
          _studentDetail(Icons.school_outlined, '${student.yearLevel} • Grade ${student.grade.toStringAsFixed(1)}'),
          _studentDetail(Icons.phone_outlined, student.contactNumber.isEmpty ? 'No contact number' : student.contactNumber),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                onPressed: () => widget.onEdit(student),
                icon: const Icon(Icons.edit_outlined, size: 17),
                label: const Text('Edit'),
              ),
              TextButton.icon(
                onPressed: () => widget.onDelete(student),
                icon: const Icon(Icons.delete_outline, size: 17, color: Colors.red),
                label: const Text('Delete', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        ],
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final list = filteredStudents;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Records'),
        actions: [
          IconButton(
            onPressed: widget.onExport,
            icon: const Icon(Icons.download_outlined),
            tooltip: 'Export to .txt',
          ),
          IconButton(
            onPressed: widget.onAdd,
            icon: const Icon(Icons.person_add_alt_1),
            tooltip: 'Add student',
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
            child: TextField(
              controller: searchController,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Search by student ID or name',
              ),
            ),
          ),
          SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: ['All Students', 'BSIT', 'BSCS', 'BSIS']
                  .map((filter) => Padding(
                padding: const EdgeInsets.only(right: 7),
                child: ChoiceChip(
                  label: Text(filter),
                  selected: selectedFilter == filter,
                  onSelected: (_) => setState(() => selectedFilter = filter),
                ),
              ))
                  .toList(),
            ),
          ),
          Expanded(
            child: widget.students.isEmpty
                ? const EmptyState(icon: Icons.people_outline, title: 'No student records', message: 'Tap Add Student to create your first record.')
                : list.isEmpty
                ? const EmptyState(icon: Icons.search_off, title: 'No matching students', message: 'Try another search term or filter.')
                : ListView.builder(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 90),
              itemCount: list.length,
              itemBuilder: (context, index) => _studentCard(list[index]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _studentDetail(IconData icon, String value) => Padding(
    padding: const EdgeInsets.only(bottom: 5),
    child: Row(
      children: [
        Icon(icon, size: 15, color: Colors.black54),
        const SizedBox(width: 7),
        Expanded(child: Text(value, style: const TextStyle(fontSize: 11))),
      ],
    ),
  );
}


class StudentFormDialog extends StatefulWidget {
  final Student? student;
  const StudentFormDialog({super.key, this.student});
  @override
  State<StudentFormDialog> createState() => _StudentFormDialogState();
}

class _StudentFormDialogState extends State<StudentFormDialog> {
  final formKey = GlobalKey<FormState>();
  late final TextEditingController idController;
  late final TextEditingController nameController;
  late final TextEditingController emailController;
  late final TextEditingController gradeController;
  late final TextEditingController contactController;
  String? course;
  String? year;

  static const courses = ['BSIT-NS', 'BSIT-WM', 'BSCS-DS', 'BSCS-SE', 'BSIS'];
  static const years = ['1st Year', '2nd Year', '3rd Year', '4th Year'];

  @override
  void initState() {
    super.initState();
    final s = widget.student;
    idController = TextEditingController(text: s?.id ?? '');
    nameController = TextEditingController(text: s?.name ?? '');
    emailController = TextEditingController(text: s?.email ?? '');
    gradeController = TextEditingController(text: s == null ? '' : s.grade.toString());
    contactController = TextEditingController(text: s?.contactNumber ?? '');
    course = s?.course;
    year = s?.yearLevel;
  }

  @override
  void dispose() {
    idController.dispose();
    nameController.dispose();
    emailController.dispose();
    gradeController.dispose();
    contactController.dispose();
    super.dispose();
  }

  String? requiredText(String? value) => value == null || value.trim().isEmpty ? 'This field is required' : null;

  void save() {
    if (!formKey.currentState!.validate()) return;
    final grade = double.tryParse(gradeController.text.trim());
    if (grade == null || grade < 0 || grade > 100) return;
    Navigator.pop(
      context,
      Student(
        id: idController.text.trim(),
        name: nameController.text.trim(),
        email: emailController.text.trim(),
        course: course!,
        yearLevel: year!,
        grade: grade,
        contactNumber: contactController.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final courseItems = [...courses, if (course != null && !courses.contains(course)) course!];
    final yearItems = [...years, if (year != null && !years.contains(year)) year!];

    return AlertDialog(
      title: Text(widget.student == null ? 'Add Student' : 'Edit Student'),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: idController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [StudentIdFormatter()],
                  decoration: const InputDecoration(
                    labelText: 'Student ID',
                    hintText: '202*-2-*****',
                  ),
                  validator: (v) {
                    final value = v?.trim() ?? '';
                    if (value.isEmpty) return 'This field is required';
                    if (!RegExp(r'^\d{4}-\d-\d{5}$').hasMatch(value)) {
                      return 'Format: 202*-2-*****';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 9),
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Student Name'),
                  validator: requiredText,
                ),
                const SizedBox(height: 9),
                TextFormField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(labelText: 'Email Address'),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Email is required';
                    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v.trim())) return 'Enter a valid email';
                    return null;
                  },
                ),
                const SizedBox(height: 9),
                DropdownButtonFormField<String>(
                  initialValue: course,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Course / Programme'),
                  items: courseItems.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                  validator: (v) => v == null ? 'Select a course' : null,
                  onChanged: (v) => setState(() => course = v),
                ),
                const SizedBox(height: 9),
                DropdownButtonFormField<String>(
                  initialValue: year,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Year Level'),
                  items: yearItems.map((y) => DropdownMenuItem(value: y, child: Text(y))).toList(),
                  validator: (v) => v == null ? 'Select year level' : null,
                  onChanged: (v) => setState(() => year = v),
                ),
                const SizedBox(height: 9),
                TextFormField(
                  controller: gradeController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Grade (0–100)'),
                  validator: (v) {
                    final n = double.tryParse(v ?? '');
                    if (n == null || n < 0 || n > 100) return 'Enter a grade from 0 to 100';
                    return null;
                  },
                ),
                const SizedBox(height: 9),
                TextFormField(
                  controller: contactController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(labelText: 'Contact Number (optional)'),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(
          onPressed: save,
          style: FilledButton.styleFrom(backgroundColor: lpuRed),
          child: const Text('Save Student'),
        ),
      ],
    );
  }
}

