import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../api/wto_api.dart';

class DownloadManager {
  static Future<String?> downloadFile(String? serverImagePath) async {
    if (serverImagePath == null || serverImagePath.isEmpty) {
      return null;
    }

    try {
      final fileName = p.basename(serverImagePath);

      final dir = await getApplicationDocumentsDirectory();

      final imagesDir = Directory('${dir.path}/images');

      if (!await imagesDir.exists()) {
        await imagesDir.create(recursive: true);
      }

      final localFile = File('${imagesDir.path}/$fileName');

      if (await localFile.exists()) {
        return localFile.path;
      }

      final response = await http.get(
        Uri.parse(
          '${WtoApi.serverUrl}/files/$fileName',
        ),
      );

      if (response.statusCode != 200) {
        return null;
      }

      await localFile.writeAsBytes(response.bodyBytes);

      return localFile.path;
    } catch (_) {
      return null;
    }
  }
}