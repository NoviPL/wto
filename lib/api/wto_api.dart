import 'dart:convert';
import 'package:http/http.dart' as http;

class WtoApi {
  static String serverUrl = 'http://10.119.82.46:8000';

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

  static Future<bool> sendMessage({
    required String messageUuid,
    required String title,
    required String text,
    required String level,
    required String dateTime,
    required String userId,
    String? serverImagePath,
    bool deleted = false,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$serverUrl/messages'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'message_uuid': messageUuid,
          'title': title,
          'text': text,
          'level': level,
          'dateTime': dateTime,
          'userId': userId,
          'imagePath': serverImagePath,
          'deleted': deleted,
        }),
      ).timeout(const Duration(seconds: 5));

      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (_) {
      return false;
    }
  }

  static Future<List<Map<String, dynamic>>> getMessageReads() async {
    try {
      final response = await http
          .get(Uri.parse('$serverUrl/message_reads'))
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

  static Future<bool> markMessageRead({
    required String messageUuid,
    required String userId,
    required String readAt,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$serverUrl/message_reads'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'message_uuid': messageUuid,
          'userId': userId,
          'readAt': readAt,
        }),
      ).timeout(const Duration(seconds: 5));

      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (_) {
      return false;
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
  static Future<List<Map<String, dynamic>>> getCarTerms() async {
    try {
      final response = await http
          .get(Uri.parse('$serverUrl/car_terms'))
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

  static Future<bool> sendCarTerms({
    required String carUuid,
    String? ocDate,
    String? acDate,
    String? btDate,
    bool deleted = false,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$serverUrl/car_terms'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'car_uuid': carUuid,
          'ocDate': ocDate,
          'acDate': acDate,
          'btDate': btDate,
          'deleted': deleted,
        }),
      ).timeout(const Duration(seconds: 5));

      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (_) {
      return false;
    }
  }
  static Future<List<Map<String, dynamic>>> getCarNotes() async {
    try {
      final response = await http
          .get(Uri.parse('$serverUrl/car_notes'))
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

  static Future<bool> sendCarNote({
    required String carNoteUuid,
    required String carUuid,
    required String section,
    required String text,
    required String dateTime,
    required String userId,
    String? serverImagePath,
    bool deleted = false,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$serverUrl/car_notes'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'car_note_uuid': carNoteUuid,
          'car_uuid': carUuid,
          'section': section,
          'text': text,
          'dateTime': dateTime,
          'userId': userId,
          'imagePath': serverImagePath,
          'deleted': deleted,
        }),
      ).timeout(const Duration(seconds: 5));

      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (_) {
      return false;
    }
  }
  static Future<List<Map<String, dynamic>>> getMessageImages() async {
    try {
      final response = await http
          .get(Uri.parse('$serverUrl/message_images'))
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

  static Future<bool> sendMessageImage({
    required String imageUuid,
    required String messageUuid,
    String? serverImagePath,
    String caption = '',
    bool deleted = false,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$serverUrl/message_images'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'image_uuid': imageUuid,
          'message_uuid': messageUuid,
          'imagePath': serverImagePath,
          'caption': caption,
          'deleted': deleted,
        }),
      ).timeout(const Duration(seconds: 5));

      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (_) {
      return false;
    }
  }
}
