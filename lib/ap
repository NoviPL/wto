import 'dart:convert';
import 'package:http/http.dart' as http;

class WtoApi {
  static String serverUrl = 'http://10.119.82.46:8000';

  static Future<bool> sendMessage({
    required String title,
    required String text,
    required String level,
    required String dateTime,
    required String userId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$serverUrl/messages'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'title': title,
          'text': text,
          'level': level,
          'dateTime': dateTime,
          'userId': userId,
        }),
      ).timeout(const Duration(seconds: 5));

      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (_) {
      return false;
    }
  }

  static Future<List<Map<String, dynamic>>> getMessages() async {
    try {
      final response = await http
          .get(Uri.parse('$serverUrl/messages'))
          .timeout(const Duration(seconds: 5));

      if (response.statusCode < 200 || response.statusCode >= 300) {
        return [];
      }

      final decoded = jsonDecode(response.body);

      if (decoded is! List) return [];

      return decoded
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
    } catch (_) {
      return [];
    }
  }
}
