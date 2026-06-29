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

  static Future<bool> updateMessage({
    required int id,
    required String title,
    required String text,
    required String level,
    required String dateTime,
    required String userId,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('$serverUrl/messages/$id'),
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

  static Future<List<Map<String, dynamic>>> getUsers() async {
    try {
      final response = await http
          .get(Uri.parse('$serverUrl/users'))
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

  static Future<bool> sendUser({
    required String id,
    required String name,
    required String role,
    required String pin,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$serverUrl/users'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'id': id,
          'name': name,
          'role': role,
          'pin': pin,
        }),
      ).timeout(const Duration(seconds: 5));

      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (_) {
      return false;
    }
  }
  static Future<bool> deleteUser(String id) async {
    try {
      final response = await http.delete(
        Uri.parse('$serverUrl/users/$id'),
      ).timeout(const Duration(seconds: 5));

      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (_) {
      return false;
    }
  }
  static Future<List<Map<String, dynamic>>> getYears() async {
    try {
      final response = await http
          .get(Uri.parse('$serverUrl/years'))
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

  static Future<bool> sendYear({
    required int year,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$serverUrl/years'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'year': year,
          'deleted': 0,
        }),
      ).timeout(const Duration(seconds: 5));

      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (_) {
      return false;
    }
  }

  static Future<List<Map<String, dynamic>>> getTasks() async {
    try {
      final response = await http
          .get(Uri.parse('$serverUrl/tasks'))
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

  static Future<bool> sendTask({
    required int year,
    required String number,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$serverUrl/tasks'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'year': year,
          'number': number,
          'deleted': 0,
        }),
      ).timeout(const Duration(seconds: 5));

      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> deleteTask({
    required int year,
    required String number,
  }) async {
    try {
      final response = await http.delete(
        Uri.parse('$serverUrl/tasks/$year/$number'),
      ).timeout(const Duration(seconds: 5));

      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (_) {
      return false;
    }
  }
  static Future<List<Map<String, dynamic>>> getEntries() async {
    try {
      final response = await http
          .get(Uri.parse('$serverUrl/entries'))
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

  static Future<bool> sendEntry({
    required String entryUuid,
    required String number,
    required String category,
    required String text,
    required String dateTime,
    required String userId,
    String? serverImagePath,
    bool deleted = false,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$serverUrl/entries'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'entry_uuid': entryUuid,
          'number': number,
          'category': category,
          'text': text,
          'dateTime': dateTime,
          'imagePath': serverImagePath,
          'userId': userId,
          'deleted': deleted,
        }),
      ).timeout(const Duration(seconds: 5));

      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (_) {
      return false;
    }
  }
  static Future<List<Map<String, dynamic>>> getCars() async {
    try {
      final response = await http
          .get(Uri.parse('$serverUrl/cars'))
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

  static Future<bool> sendCar({
    required String carUuid,
    required String name,
    required String plate,
    required String createdAt,
    required int colorIndex,
    bool deleted = false,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$serverUrl/cars'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'car_uuid': carUuid,
          'name': name,
          'plate': plate,
          'createdAt': createdAt,
          'colorIndex': colorIndex,
          'deleted': deleted,
        }),
      ).timeout(const Duration(seconds: 5));

      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (_) {
      return false;
    }
  }
}
