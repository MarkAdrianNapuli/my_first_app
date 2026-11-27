import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/api_user.dart';

class ApiService {
  static const String usersUrl = 'https://jsonplaceholder.typicode.com/users';

  static Future<List<ApiUser>> getUsers() async {
    final response = await http.get(Uri.parse(usersUrl)).timeout(const Duration(seconds: 20));
    debugPrint('USERS STATUS CODE: ${response.statusCode}');
    if (response.statusCode != 200) throw Exception('Users API error: HTTP ${response.statusCode}');
    final decoded = jsonDecode(response.body);
    if (decoded is! List) throw const FormatException('Invalid users API response.');
    return decoded.map((item) => ApiUser.fromJson(item as Map<String, dynamic>)).toList();
  }
}

// -----------------------------------------------------------------------------
