import 'dart:io';

import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';

import '../api/wto_api.dart';

class AppVersionScreen extends StatefulWidget {
  const AppVersionScreen({super.key});

  @override
  State<AppVersionScreen> createState() => _AppVersionScreenState();
}

class _AppVersionScreenState extends State<AppVersionScreen> {
  Map<String, dynamic>? version;
  bool loading = true;
  bool downloading = false;

  @override
  void initState() {
    super.initState();
    loadVersion();
  }

  Future<void> loadVersion() async {
    setState(() {
      loading = true;
    });

    final result = await WtoApi.getAppVersion();

    if (!mounted) return;

    setState(() {
      version = result;
      loading = false;
    });
  }

  Future<void> downloadAndInstallApk() async {
    if (downloading) return;

    setState(() {
      downloading = true;
    });

    try {
      final dir = await getApplicationDocumentsDirectory();
      final filePath = '${dir.path}/WTO_latest.apk';

      final ok = await WtoApi.downloadLatestApk(filePath);

      if (!mounted) return;

      if (!ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Nie udało się pobrać APK.'),
          ),
        );
        return;
      }

      final file = File(filePath);

      if (!await file.exists()) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Plik APK nie istnieje po pobraniu.'),
          ),
        );
        return;
      }

      await OpenFilex.open(filePath);
    } finally {
      if (mounted) {
        setState(() {
          downloading = false;
        });
      }
    }
  }

  String valueText(dynamic value) {
    if (value == null) return '-';
    return value.toString();
  }

  Widget infoTile(String title, String value, IconData icon) {
    return Card(
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(14),
        leading: CircleAvatar(
          backgroundColor: Colors.blueGrey.shade900,
          child: Icon(icon, color: Colors.white),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(value),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final data = version;

    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        title: const Text('Wersja aplikacji'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: loadVersion,
          ),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : data == null
              ? const Center(
                  child: Text(
                    'Nie udało się pobrać informacji o wersji.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 18),
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.all(12),
                  children: [
                    infoTile(
                      'Dostępna wersja',
                      'v${valueText(data['version'])}',
                      Icons.system_update,
                    ),
                    infoTile(
                      'Build',
                      valueText(data['build']),
                      Icons.numbers,
                    ),
                    infoTile(
                      'Plik APK',
                      valueText(data['apk']),
                      Icons.android,
                    ),
                    infoTile(
                      'Aktualizacja obowiązkowa',
                      valueText(data['mandatory']),
                      Icons.warning_amber,
                    ),
                    infoTile(
                      'Opis zmian',
                      valueText(data['description']),
                      Icons.description,
                    ),
                    infoTile(
                      'Data wydania',
                      valueText(data['release_date']),
                      Icons.calendar_month,
                    ),
                    infoTile(
                      'Minimalna wersja serwera',
                      valueText(data['min_server_version']),
                      Icons.dns,
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton.icon(
                        onPressed:
                            downloading ? null : downloadAndInstallApk,
                        icon: downloading
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.download),
                        label: Text(
                          downloading
                              ? 'Pobieranie...'
                              : 'Pobierz i zainstaluj APK',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 80),
                  ],
                ),
    );
  }
}