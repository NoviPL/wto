import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import '../api/wto_api.dart';

class UploadManager {
  static Future<String?> uploadFile(String filePath) async {
    try {
      final file = File(filePath);

      if (!await file.exists()) return null;

      final request = http.MultipartRequest(
        'POST',
        Uri.parse('${WtoApi.serverUrl}/upload'),
      );

      request.files.add(
        await http.MultipartFile.fromPath(
          'file',
          file.path,
          filename: p.basename(file.path),
        ),
      );

      final response = await request.send().timeout(
            const Duration(seconds: 20),
          );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        return null;
      }

      final body = await response.stream.bytesToString();

      final pathMatch = RegExp(r'"path"\s*:\s*"([^"]+)"').firstMatch(body);

      if (pathMatch == null) return null;

      return pathMatch.group(1);
    } catch (_) {
      return null;
    }
  }
}