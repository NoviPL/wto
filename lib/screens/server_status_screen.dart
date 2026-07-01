import 'package:flutter/material.dart';
import '../api/wto_api.dart';

class ServerStatusScreen extends StatefulWidget {
  const ServerStatusScreen({super.key});

  @override
  State<ServerStatusScreen> createState() => _ServerStatusScreenState();
}

class _ServerStatusScreenState extends State<ServerStatusScreen> {
  Map<String, dynamic>? status;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadStatus();
  }

  Future<void> loadStatus() async {
    setState(() {
      loading = true;
    });

    final result = await WtoApi.getServerStatus();

    if (!mounted) return;

    setState(() {
      status = result;
      loading = false;
    });
  }

  String valueText(dynamic value) {
    if (value == null) return '-';
    return value.toString();
  }

  String uptimeText(dynamic secondsValue) {
    final seconds = int.tryParse(secondsValue?.toString() ?? '') ?? 0;

    final days = seconds ~/ 86400;
    final hours = (seconds % 86400) ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;

    if (days > 0) {
      return '${days}d ${hours}h ${minutes}min';
    }

    if (hours > 0) {
      return '${hours}h ${minutes}min';
    }

    return '${minutes}min';
  }

  Color statusColor(String value) {
    if (value == 'ok') return Colors.green;
    if (value == 'not_installed') return Colors.orange;
    if (value == 'not_found') return Colors.orange;
    if (value == 'empty') return Colors.orange;

    return Colors.red;
  }

  IconData statusIcon(String value) {
    if (value == 'ok') return Icons.check_circle;
    if (value == 'not_installed') return Icons.warning_amber;
    if (value == 'not_found') return Icons.warning_amber;
    if (value == 'empty') return Icons.warning_amber;

    return Icons.error;
  }

  Widget statusTile({
    required String title,
    required String value,
    required IconData icon,
    bool isStatus = false,
  }) {
    final color = isStatus ? statusColor(value) : Colors.blueGrey.shade900;
    final finalIcon = isStatus ? statusIcon(value) : icon;

    return Card(
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(14),
        leading: CircleAvatar(
          backgroundColor: color,
          child: Icon(
            finalIcon,
            color: Colors.white,
          ),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(value),
      ),
    );
  }

  Widget percentTile({
    required String title,
    required double percent,
    required IconData icon,
  }) {
    final normalized = (percent / 100).clamp(0.0, 1.0);

    return Card(
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: Colors.blueGrey.shade900,
              child: Icon(
                icon,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: normalized,
                    minHeight: 8,
                  ),
                  const SizedBox(height: 6),
                  Text('${percent.toStringAsFixed(1)}%'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  double doubleValue(String key) {
    final value = status?[key];
    return double.tryParse(value?.toString() ?? '') ?? 0.0;
  }

  @override
  Widget build(BuildContext context) {
    final data = status;

    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        title: const Text('Stan serwera'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Odśwież',
            onPressed: loadStatus,
          ),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : data == null
              ? RefreshIndicator(
                  onRefresh: loadStatus,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: const [
                      SizedBox(height: 80),
                      Icon(
                        Icons.cloud_off,
                        size: 70,
                        color: Colors.red,
                      ),
                      SizedBox(height: 18),
                      Text(
                        'Brak połączenia z serwerem.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Sprawdź adres serwera, Wi-Fi/WireGuard albo czy FastAPI działa.',
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: loadStatus,
                  child: ListView(
                    padding: const EdgeInsets.all(12),
                    children: [
                      statusTile(
                        title: 'FastAPI',
                        value: valueText(data['fastapi']),
                        icon: Icons.api,
                        isStatus: true,
                      ),
                      statusTile(
                        title: 'PostgreSQL',
                        value: valueText(data['postgresql']),
                        icon: Icons.storage,
                        isStatus: true,
                      ),
                      statusTile(
                        title: 'Backup',
                        value: valueText(data['backup_status']),
                        icon: Icons.backup,
                        isStatus: true,
                      ),
                      statusTile(
                        title: 'WireGuard',
                        value:
                            '${valueText(data['wireguard_status'])} • peerów: ${valueText(data['wireguard_peers'])}',
                        icon: Icons.vpn_lock,
                        isStatus: false,
                      ),
                      percentTile(
                        title: 'CPU',
                        percent: doubleValue('cpu_percent'),
                        icon: Icons.memory,
                      ),
                      percentTile(
                        title: 'RAM',
                        percent: doubleValue('ram_percent'),
                        icon: Icons.developer_board,
                      ),
                      percentTile(
                        title: 'Dysk',
                        percent: doubleValue('disk_percent'),
                        icon: Icons.sd_storage,
                      ),
                      statusTile(
                        title: 'RAM użyte / całość',
                        value:
                            '${valueText(data['ram_used_mb'])} MB / ${valueText(data['ram_total_mb'])} MB',
                        icon: Icons.developer_board,
                      ),
                      statusTile(
                        title: 'Dysk wolny',
                        value:
                            '${valueText(data['disk_free_gb'])} GB wolne z ${valueText(data['disk_total_gb'])} GB',
                        icon: Icons.storage,
                      ),
                      statusTile(
                        title: 'Uptime',
                        value: uptimeText(data['uptime_seconds']),
                        icon: Icons.timer,
                      ),
                      statusTile(
                        title: 'Ostatni backup',
                        value:
                            '${valueText(data['backup_last_file'])}\n${valueText(data['backup_last_time'])}',
                        icon: Icons.cloud_done,
                      ),
                      statusTile(
                        title: 'Liczba backupów',
                        value: valueText(data['backup_count']),
                        icon: Icons.folder_zip,
                      ),
                      const SizedBox(height: 80),
                    ],
                  ),
                ),
    );
  }
}
