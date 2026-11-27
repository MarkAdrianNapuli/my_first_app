import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Student {
  final String id;
  final String name;
  final String course;
  final double grade;
  final String email;
  final String yearLevel;
  final String contactNumber;

  const Student({
    required this.id,
    required this.name,
    required this.course,
    required this.grade,
    required this.email,
    required this.yearLevel,
    required this.contactNumber,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'course': course,
    'grade': grade,
    'email': email,
    'yearLevel': yearLevel,
    'contactNumber': contactNumber,
  };

  factory Student.fromJson(Map<String, dynamic> json) => Student(
    id: json['id']?.toString() ?? '',
    name: json['name']?.toString() ?? '',
    course: json['course']?.toString() ?? 'BSIT',
    grade: (json['grade'] as num?)?.toDouble() ?? 0,
    email: json['email']?.toString() ?? '',
    yearLevel: json['yearLevel']?.toString() ?? '1st Year',
    contactNumber: json['contactNumber']?.toString() ?? '',
  );
}

class StudentStorage {
  static const String storageKey = 'week4_students';

  static Future<List<Student>> loadStudents() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(storageKey);
    if (raw == null || raw.isEmpty) return [];
    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded
          .map((item) => Student.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('Unable to read saved student records: $e');
      return [];
    }
  }

  static Future<void> saveStudents(List<Student> students) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(students.map((student) => student.toJson()).toList());
    await prefs.setString(storageKey, encoded);
  }

  static Future<void> clearStudents() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(storageKey);
  }
}

