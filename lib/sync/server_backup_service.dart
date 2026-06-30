import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

class ServerBackupItem {
  final String filename;
  final int size;
  final DateTime created;

  ServerBackupItem({
    required this.filename,
    required this.size,
    required this.created,
  });

  factory ServerBackupItem.fromJson(Map<String, dynamic> json) {
    return ServerBackupItem(
      filename: json['filename'].toString(),
      size: int.tryParse(json['size'].toString()) ?? 0,
      created: DateTime.tryParse(json['created'].toString()) ?? DateTime.now(),
    );
  }
}

class ServerBackupService {
  static const String baseUrl = 'http://10.119.82.46:8000';

  static Future<void> uploadBackup(File backupFile) async {
    final uri = Uri.parse('$baseUrl/backups/upload');

    final request = http.MultipartRequest('POST', uri);

    request.files.add(
      await http.MultipartFile.fromPath(
        'file',
        backupFile.path,
        filename: backupFile.path.split('/').last,
      ),
    );

    final response = await request.send();

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final body = await response.stream.bytesToString();
      throw Exception('Błąd wysyłania backupu: ${response.statusCode} $body');
    }
  }

  static Future<List<ServerBackupItem>> getServerBackups() async {
    final uri = Uri.parse('$baseUrl/backups');

    final response = await http.get(uri);

    if (response.statusCode != 200) {
      throw Exception('Błąd pobierania listy backupów: ${response.statusCode}');
    }

    final List data = jsonDecode(response.body);

    return data
        .map((e) => ServerBackupItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  static Future<File> downloadBackup(String filename) async {
    final uri = Uri.parse('$baseUrl/backups/$filename');

    final response = await http.get(uri);

    if (response.statusCode != 200) {
      throw Exception('Błąd pobierania backupu: ${response.statusCode}');
    }

    final dir = await getApplicationDocumentsDirectory();
    final backupDir = Directory('${dir.path}/server_downloaded_backups');

    if (!await backupDir.exists()) {
      await backupDir.create(recursive: true);
    }

    final file = File('${backupDir.path}/$filename');
    await file.writeAsBytes(response.bodyBytes);

    return file;
  }

  static Future<void> deleteServerBackup(String filename) async {
    final uri = Uri.parse('$baseUrl/backups/$filename');

    final response = await http.delete(uri);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Błąd usuwania backupu: ${response.statusCode}');
    }
  }
}