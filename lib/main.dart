import 'package:flutter/material.dart';
import 'db/database.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:gal/gal.dart';
import 'api/wto_api.dart';
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final user = await AppDatabase.getCurrentUser();

  if (user != null) {
    currentUserId = user['id']?.toString() ?? 'USER_001';
    currentUserName =
        user['name']?.toString() ?? 'Użytkownik 1';
  }

  runApp(const WTOApp());
}

class WTOApp extends StatelessWidget {
  const WTOApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'WTO',
      theme: ThemeData(
        colorSchemeSeed: Colors.blue,
        useMaterial3: true,
      ),
      home: const LoginScreen(),
    );
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  List<Map<String, dynamic>> users = [];
  String? selectedUserId;
  final pinController = TextEditingController();

  @override
  void initState() {
    super.initState();
    loadUsers();
  }

  Future<void> loadUsers() async {
    final data = await AppDatabase.getUsers();

    if (!mounted) return;

    setState(() {
      users = data;
      if (data.isNotEmpty) {
        selectedUserId = data.first['id']?.toString();
      }
    });
  }

  Future<void> login() async {
    if (selectedUserId == null) return;

    final pin = pinController.text.trim();

    final selectedUser = users.firstWhere(
      (user) => user['id']?.toString() == selectedUserId,
    );

    final userId = selectedUser['id']?.toString() ?? 'USER_001';
    final userName = selectedUser['name']?.toString() ?? 'Użytkownik';

    final ok = await AppDatabase.checkUserPin(userId, pin);

    if (!ok) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nieprawidłowy PIN'),
        ),
      );
      return;
    }

    await AppDatabase.setCurrentUserId(userId);

    currentUserId = userId;
    currentUserName = userName;

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => const MainMenuScreen(),
      ),
    );
  }

  @override
  void dispose() {
    pinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blueGrey.shade900,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: Card(
              elevation: 8,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.lock,
                      size: 64,
                      color: Colors.blueGrey,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Logowanie WTO',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 24),

                    DropdownButtonFormField<String>(
                      value: selectedUserId,
                      decoration: const InputDecoration(
                        labelText: 'Użytkownik',
                        border: OutlineInputBorder(),
                      ),
                      items: users.map((user) {
                        final id = user['id']?.toString() ?? '';
                        final name = user['name']?.toString() ?? '';

                        return DropdownMenuItem<String>(
                          value: id,
                          child: Text(name),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedUserId = value;
                          pinController.clear();
                        });
                      },
                    ),

                    const SizedBox(height: 16),

                    TextField(
                      controller: pinController,
                      obscureText: true,
                      keyboardType: TextInputType.number,
                      maxLength: 4,
                      decoration: const InputDecoration(
                        labelText: 'PIN',
                        border: OutlineInputBorder(),
                        counterText: '',
                      ),
                      onSubmitted: (_) => login(),
                    ),

                    const SizedBox(height: 20),

                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton.icon(
                        onPressed: login,
                        icon: const Icon(Icons.login),
                        label: const Text(
                          'Wejdź',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    const Text(
                      'Domyślny PIN: 0000',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class MainMenuScreen extends StatefulWidget {
  const MainMenuScreen({super.key});

  @override
  State<MainMenuScreen> createState() => _MainMenuScreenState();
}

class _MainMenuScreenState extends State<MainMenuScreen> {
  int unreadMessagesCount = 0;
  bool isAdmin = false;

  @override
  void initState() {
    super.initState();

    loadCurrentUser();
    loadUnreadMessagesCount();
  }

  Future<void> loadCurrentUser() async {
    final user = await AppDatabase.getCurrentUser();

    if (user == null) return;

    if (!mounted) return;

    setState(() {
      currentUserId = user['id']?.toString() ?? 'USER_001';
      currentUserName = user['name']?.toString() ?? 'Użytkownik 1';
      isAdmin = user['role']?.toString() == 'ADMIN';
    });
  }

  Future<void> loadUnreadMessagesCount() async {
    final count = await AppDatabase.getUnreadMessagesCount();

    if (!mounted) return;

    setState(() {
      unreadMessagesCount = count;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.red.shade700,
        foregroundColor: Colors.white,
        onPressed: () async {
          await AppDatabase.logout();

          currentUserId = 'USER_001';
          currentUserName = 'Użytkownik 1';

          if (!context.mounted) return;

          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder: (_) => const LoginScreen(),
            ),
            (route) => false,
          );
        },
        icon: const Icon(Icons.logout),
        label: const Text('Wyloguj'),
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/images/wto_logo.jpg',
            fit: BoxFit.cover,
          ),
          Container(
            color: Colors.black.withOpacity(0.65),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const SizedBox(height: 40),
                  const Text(
                    'WTO',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 42,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 3,
                    ),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    currentUserName,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Spacer(),
                  _MainMenuButton(
                    title: 'ZADANIA',
                    icon: Icons.assignment,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const YearsScreen(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  _MainMenuButton(
                    title: 'FLOTA',
                    icon: Icons.directions_car,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const FleetScreen(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  _MainMenuButton(
                    title: unreadMessagesCount > 0
                        ? 'KOMUNIKATY ($unreadMessagesCount)'
                        : 'KOMUNIKATY',
                    icon: Icons.campaign,
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const MessagesScreen(),
                        ),
                      );

                      await loadUnreadMessagesCount();
                    },
                  ),
                  
                  if (isAdmin) ...[
                    const SizedBox(height: 16),
                    _MainMenuButton(
                      title: 'PANEL ADMINA',
                      icon: Icons.admin_panel_settings,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const AdminPanelScreen(),
                          ),
                        );
                      },
                    ),
                  ],
                  const SizedBox(height: 16),
                  _MainMenuButton(
                    title: 'INNE',
                    icon: Icons.more_horiz,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const OtherScreen(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 50),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MainMenuButton extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;

  const _MainMenuButton({
    required this.title,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 64,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 28),
        label: Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
        ),
      ),
    );
  }
}

class YearsScreen extends StatefulWidget {
  const YearsScreen({super.key});

  @override
  State<YearsScreen> createState() => _YearsScreenState();
}

class _YearsScreenState extends State<YearsScreen> {
  List<Map<String, dynamic>> years = [];
  bool canAddYears = false;

  @override
  void initState() {
    super.initState();
    loadYears();
  }

  Future<void> loadYears() async {
    final data = await AppDatabase.getYears();
    final expert = await AppDatabase.isCurrentUserExpert();

    if (!mounted) return;

    setState(() {
      years = data;
      canAddYears = expert;
    });
  }

  Future<void> _showAddYearDialog() async {
    final yearController = TextEditingController();

    final year = await showDialog<int>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Dodaj rok'),
        content: TextField(
          controller: yearController,
          autofocus: true,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            hintText: 'Np. 2027',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Anuluj'),
          ),
          ElevatedButton(
            onPressed: () {
              final value = int.tryParse(yearController.text.trim());

              if (value == null) return;

              Navigator.of(dialogContext).pop(value);
            },
            child: const Text('Dodaj'),
          ),
        ],
      ),
    );

    if (year == null) return;

    await AppDatabase.insertYear(year);
    await loadYears();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F5F7),
      appBar: AppBar(
        title: const Text('Zadania'),
        centerTitle: true,
      ),
      floatingActionButton: canAddYears
          ? FloatingActionButton.extended(
              onPressed: _showAddYearDialog,
              icon: const Icon(Icons.add),
              label: const Text('Dodaj rok'),
            )
          : null,
      body: years.isEmpty
          ? const Center(
              child: Text(
                'Brak lat.\nKliknij Dodaj rok.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: years.length,
              itemBuilder: (context, index) {
                final year = years[index]['year'] as int;

                return Card(
                  elevation: 3,
                  margin: const EdgeInsets.only(bottom: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(18),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => NumbersScreen(year: year),
                        ),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Row(
                        children: [
                          Container(
                            width: 54,
                            height: 54,
                            decoration: BoxDecoration(
                              color: Colors.blueGrey.shade900,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Icon(
                              Icons.calendar_month,
                              color: Colors.white,
                              size: 30,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              year.toString(),
                              style: const TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const Icon(Icons.arrow_forward_ios),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  List<Map<String, dynamic>> messages = [];
  bool canAddImportantMessages = false;

  @override
  void initState() {
    super.initState();
    loadMessages();
  }

  Future<void> loadMessages() async {
    await AppDatabase.syncMessagesFromServer();

    final data = await AppDatabase.getMessages();
    final important = await AppDatabase.canCurrentUserAddImportantMessages();

    if (!mounted) return;

    setState(() {
      messages = data;
      canAddImportantMessages = important;
    });
  }

  Color messageColor(String level) {
    switch (level) {
      case 'WAŻNE':
        return Colors.red.shade800;
      case 'ISTOTNE':
        return Colors.amber.shade800;
      default:
        return Colors.grey.shade700;
    }
  }

  IconData messageIcon(String level) {
    switch (level) {
      case 'WAŻNE':
        return Icons.priority_high;
      case 'ISTOTNE':
        return Icons.warning_amber;
      default:
        return Icons.campaign;
    }
  }

  Future<void> showAddMessageDialog() async {
    final titleController = TextEditingController();
    final textController = TextEditingController();
    String selectedLevel = canAddImportantMessages ? 'WAŻNE' : 'ISTOTNE';

    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Dodaj komunikat'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: titleController,
                      autofocus: true,
                      decoration: const InputDecoration(
                        labelText: 'Tytuł komunikatu',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: textController,
                      keyboardType: TextInputType.multiline,
                      minLines: 4,
                      maxLines: 8,
                      textInputAction: TextInputAction.newline,
                      decoration: const InputDecoration(
                        labelText: 'Treść komunikatu',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: selectedLevel,
                      decoration: const InputDecoration(
                        labelText: 'Ważność',
                        border: OutlineInputBorder(),
                      ),
                      items: [
                        if (canAddImportantMessages)
                          const DropdownMenuItem(
                            value: 'WAŻNE',
                            child: Text('Czerwony - ważne'),
                          ),
                        const DropdownMenuItem(
                          value: 'ISTOTNE',
                          child: Text('Żółty - istotne'),
                        ),
                        const DropdownMenuItem(
                          value: 'OGŁOSZENIE',
                          child: Text('Szary - ogłoszenie'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value == null) return;

                        setDialogState(() {
                          selectedLevel = value;
                        });
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Anuluj'),
                ),
                ElevatedButton(
                  onPressed: () {
                    final title = titleController.text.trim();
                    final text = textController.text.trim();

                    if (title.isEmpty || text.isEmpty) return;

                    Navigator.of(dialogContext).pop({
                      'title': title,
                      'text': text,
                      'level': selectedLevel,
                    });
                  },
                  child: const Text('Dodaj'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result == null) return;

    final now = DateTime.now();

    final time =
        '${now.day}.${now.month}.${now.year} '
        '${now.hour}:${now.minute.toString().padLeft(2, '0')}';

    final title = result['title'] ?? '';
    final text = result['text'] ?? '';
    final level = result['level'] ?? 'OGŁOSZENIE';

    await AppDatabase.insertMessage(
      title,
      text,
      level,
      time,
      currentUserId,
    );

    final sent = await WtoApi.sendMessage(
      title: title,
      text: text,
      level: level,
      dateTime: time,
      userId: currentUserId,
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          sent
              ? 'Komunikat zapisany lokalnie i wysłany na serwer.'
              : 'Komunikat zapisany lokalnie. Brak połączenia z serwerem.',
        ),
      ),
    );

    await loadMessages();
  }

  Future<void> deleteMessage(Map<String, dynamic> message) async {
    final ownerId = message['userId']?.toString() ?? '';

    final canEdit = await AppDatabase.canCurrentUserEditItem(ownerId);

    if (!canEdit) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Możesz usuwać tylko swoje komunikaty.'),
        ),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Usuń komunikat'),
        content: const Text('Czy na pewno chcesz usunąć ten komunikat?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Anuluj'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Usuń'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    await AppDatabase.deleteMessage(message['id'] as int);
    await loadMessages();
  }

  Future<void> editMessage(Map<String, dynamic> message) async {
    final ownerId = message['userId']?.toString() ?? '';

    final canEdit = await AppDatabase.canCurrentUserEditItem(ownerId);

    if (!canEdit) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Możesz edytować tylko swoje komunikaty.'),
        ),
      );
      return;
    }

    final titleController = TextEditingController(
      text: message['title']?.toString() ?? '',
    );

    final textController = TextEditingController(
      text: message['text']?.toString() ?? '',
    );

    String selectedLevel = message['level']?.toString() ?? 'OGŁOSZENIE';

    if (selectedLevel == 'WAŻNE' && !canAddImportantMessages) {
      selectedLevel = 'ISTOTNE';
    }

    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Edytuj komunikat'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: titleController,
                      autofocus: true,
                      decoration: const InputDecoration(
                        labelText: 'Tytuł komunikatu',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: textController,
                      keyboardType: TextInputType.multiline,
                      minLines: 4,
                      maxLines: 8,
                      textInputAction: TextInputAction.newline,
                      decoration: const InputDecoration(
                        labelText: 'Treść komunikatu',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: selectedLevel,
                      decoration: const InputDecoration(
                        labelText: 'Ważność',
                        border: OutlineInputBorder(),
                      ),
                      items: [
                        if (canAddImportantMessages)
                          const DropdownMenuItem(
                            value: 'WAŻNE',
                            child: Text('Czerwony - ważne'),
                          ),
                        const DropdownMenuItem(
                          value: 'ISTOTNE',
                          child: Text('Żółty - istotne'),
                        ),
                        const DropdownMenuItem(
                          value: 'OGŁOSZENIE',
                          child: Text('Szary - ogłoszenie'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value == null) return;

                        setDialogState(() {
                          selectedLevel = value;
                        });
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Anuluj'),
                ),
                ElevatedButton(
                  onPressed: () {
                    final title = titleController.text.trim();
                    final text = textController.text.trim();

                    if (title.isEmpty || text.isEmpty) return;

                    Navigator.of(dialogContext).pop({
                      'title': title,
                      'text': text,
                      'level': selectedLevel,
                    });
                  },
                  child: const Text('Zapisz'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result == null) return;

    final id = message['id'] as int;
    final title = result['title'] ?? '';
    final text = result['text'] ?? '';
    final level = result['level'] ?? 'OGŁOSZENIE';

    await AppDatabase.updateMessage(
      id,
      title,
      text,
      level,
    );

    await WtoApi.updateMessage(
      id: id,
      title: title,
      text: text,
      level: level,
      dateTime: message['dateTime']?.toString() ?? '',
      userId: message['userId']?.toString() ?? currentUserId,
    );

    await loadMessages();
  }

  Future<void> openMessage(Map<String, dynamic> message) async {
    if (message['isRead'] != 1) {
      await AppDatabase.markMessageAsRead(message['id'] as int);
      await loadMessages();
    }
    final title = message['title']?.toString() ?? '';
    final text = message['text']?.toString() ?? '';
    final level = message['level']?.toString() ?? 'OGŁOSZENIE';
    final dateTime = message['dateTime']?.toString() ?? '';
    final userId = message['userId']?.toString() ?? '';
    final userName = await userNameById(userId);
    final color = messageColor(level);
    final isRead = message['isRead'] == 1;

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Row(
          children: [
            Icon(messageIcon(level), color: color),
            const SizedBox(width: 8),
            Expanded(child: Text(title)),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: color),
                ),
                child: Text(
                  level,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                text,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 18),
              Text(
                '$dateTime\n$userName',
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Zamknij'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        title: const Text('Komunikaty'),
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: showAddMessageDialog,
        icon: const Icon(Icons.add),
        label: const Text('Dodaj'),
      ),
      body: messages.isEmpty
          ? const Center(
              child: Text(
                'Brak komunikatów.\nKliknij Dodaj.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final message = messages[index];
                final title = message['title']?.toString() ?? '';
                final level = message['level']?.toString() ?? 'OGŁOSZENIE';
                final dateTime = message['dateTime']?.toString() ?? '';
                final color = messageColor(level);
                final isRead = message['isRead'] == 1;

                return Card(
                  color: isRead ? Colors.white : color.withOpacity(0.10),
                  elevation: isRead ? 2 : 6,
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(
                      color: color,
                      width: isRead ? 2 : 3,
                    ),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(14),
                    leading: CircleAvatar(
                      backgroundColor: color,
                      child: Icon(
                        isRead ? Icons.mark_email_read : messageIcon(level),
                        color: Colors.white,
                      ),
                    ),
                    title: Text(
                      title,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: isRead ? FontWeight.bold : FontWeight.w900,
                      ),
                    ),
                    subtitle: Text(
                      isRead
                          ? '$level • $dateTime'
                          : 'NIEPRZECZYTANE • $level • $dateTime',
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: () => openMessage(message),
                    onLongPress: () {
                      showModalBottomSheet(
                        context: context,
                        builder: (sheetContext) => SafeArea(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ListTile(
                                leading: const Icon(Icons.edit),
                                title: const Text('Edytuj'),
                                onTap: () {
                                  Navigator.pop(sheetContext);
                                  editMessage(message);
                                },
                              ),
                              ListTile(
                                leading: const Icon(Icons.delete),
                                title: const Text('Usuń'),
                                onTap: () {
                                  Navigator.pop(sheetContext);
                                  deleteMessage(message);
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
    );
  }
}

class OtherScreen extends StatelessWidget {
  const OtherScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        title: const Text('Inne'),
        centerTitle: true,
      ),
      body: Center(
        child: Card(
          elevation: 6,
          margin: const EdgeInsets.all(24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: Padding(
            padding: const EdgeInsets.all(26),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 82,
                  height: 82,
                  decoration: BoxDecoration(
                    color: Colors.blueGrey.shade900,
                    borderRadius: BorderRadius.circular(26),
                  ),
                  child: const Icon(
                    Icons.apps,
                    color: Colors.white,
                    size: 44,
                  ),
                ),
                const SizedBox(height: 22),
                const Text(
                  'WTOApp',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'System organizacji pracy WTO',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.grey.shade700,
                  ),
                ),
                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 16),
                const Text(
                  'Twórca aplikacji',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Jarosław Nowinowski',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 22),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blueGrey.shade900,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: const Text(
                    'wersja v0.69',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'internal build',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class UsersScreen extends StatefulWidget {
  const UsersScreen({super.key});

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  List<Map<String, dynamic>> users = [];
  bool isAdmin = false;

  @override
  void initState() {
    super.initState();
    loadUsers();
  }

  Future<void> loadUsers() async {
    final data = await AppDatabase.getUsers();
    final admin = await AppDatabase.isCurrentUserAdmin();

    if (!mounted) return;

    setState(() {
      users = data;
      isAdmin = admin;
    });
  }

  Future<void> addUser() async {
    final controller = TextEditingController();

    final name = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Dodaj użytkownika'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Imię / nazwa użytkownika',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Anuluj'),
          ),
          ElevatedButton(
            onPressed: () {
              final value = controller.text.trim();
              if (value.isEmpty) return;
              Navigator.of(dialogContext).pop(value);
            },
            child: const Text('Dodaj'),
          ),
        ],
      ),
    );

    if (name == null || name.isEmpty) return;

    final id = 'USER_${DateTime.now().millisecondsSinceEpoch}';

    await AppDatabase.insertUser(id, name);
    await loadUsers();
  }

  Future<void> selectUser(Map<String, dynamic> user) async {
    final id = user['id']?.toString() ?? 'USER_001';
    final name = user['name']?.toString() ?? 'Użytkownik';

    await AppDatabase.setCurrentUserId(id);

    currentUserId = id;
    currentUserName = name;

    if (!mounted) return;

    Navigator.pop(context, true);
  }

  Future<void> editUser(Map<String, dynamic> user) async {
    if (!isAdmin) return;

    final controller = TextEditingController(
      text: user['name']?.toString() ?? '',
    );

    final name = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Edytuj użytkownika'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Nazwa użytkownika',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Anuluj'),
          ),
          ElevatedButton(
            onPressed: () {
              final value = controller.text.trim();
              if (value.isEmpty) return;
              Navigator.of(dialogContext).pop(value);
            },
            child: const Text('Zapisz'),
          ),
        ],
      ),
    );

    if (name == null || name.isEmpty) return;

    await AppDatabase.updateUserName(
      user['id']?.toString() ?? '',
      name,
    );

    if (user['id'] == currentUserId) {
      currentUserName = name;
    }

    await loadUsers();
  }

  Future<void> deleteUser(Map<String, dynamic> user) async {
    if (!isAdmin) return;

    final id = user['id']?.toString() ?? '';
    final name = user['name']?.toString() ?? '';

    if (id == currentUserId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nie możesz usunąć aktywnego użytkownika.'),
        ),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Usuń użytkownika'),
        content: Text('Czy na pewno usunąć użytkownika $name?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Anuluj'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Usuń'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    await AppDatabase.deleteUser(id);
    await loadUsers();
  }

  Future<void> changeUserPin(Map<String, dynamic> user) async {
    if (!isAdmin) return;

    final controller = TextEditingController();
    final id = user['id']?.toString() ?? '';
    final name = user['name']?.toString() ?? '';

    final pin = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Zmień PIN: $name'),
        content: TextField(
          controller: controller,
          autofocus: true,
          obscureText: true,
          keyboardType: TextInputType.number,
          maxLength: 4,
          decoration: const InputDecoration(
            labelText: 'Nowy PIN',
            border: OutlineInputBorder(),
            counterText: '',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Anuluj'),
          ),
          ElevatedButton(
            onPressed: () {
              final value = controller.text.trim();

              if (value.length != 4) return;

              Navigator.of(dialogContext).pop(value);
            },
            child: const Text('Zapisz'),
          ),
        ],
      ),
    );

    if (pin == null || pin.length != 4) return;

    await AppDatabase.updateUserPin(id, pin);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('PIN użytkownika $name został zmieniony.'),
      ),
    );
  }

  Future<void> changeUserRole(Map<String, dynamic> user) async {
    if (!isAdmin) return;

    final id = user['id']?.toString() ?? '';
    final name = user['name']?.toString() ?? '';
    String selectedRole = user['role']?.toString() ?? 'USER';

    final role = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text('Uprawnienia: $name'),
              content: DropdownButtonFormField<String>(
                value: selectedRole,
                decoration: const InputDecoration(
                  labelText: 'Rola użytkownika',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'ADMIN',
                    child: Text('Administrator'),
                  ),
                  DropdownMenuItem(
                    value: 'EKSPERT',
                    child: Text('Ekspert'),
                  ),
                  DropdownMenuItem(
                    value: 'USER',
                    child: Text('Użytkownik'),
                  ),
                ],
                onChanged: (value) {
                  if (value == null) return;

                  setDialogState(() {
                    selectedRole = value;
                  });
                },
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Anuluj'),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(dialogContext).pop(selectedRole);
                  },
                  child: const Text('Zapisz'),
                ),
              ],
            );
          },
        );
      },
    );

    if (role == null) return;

    await AppDatabase.updateUserRole(id, role);

    await loadUsers();
  }

  Future<void> resetUserPin(Map<String, dynamic> user) async {
    if (!isAdmin) return;

    final id = user['id']?.toString() ?? '';
    final name = user['name']?.toString() ?? '';

    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Reset PIN'),
        content: Text('Zresetować PIN użytkownika $name do 0000?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Anuluj'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Resetuj'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    await AppDatabase.resetUserPin(id);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('PIN użytkownika $name zresetowany do 0000.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        title: const Text('Użytkownicy'),
        centerTitle: true,
      ),
      floatingActionButton: isAdmin
          ? FloatingActionButton.extended(
              onPressed: addUser,
              icon: const Icon(Icons.add),
              label: const Text('Dodaj'),
            )
          : null,
      body: users.isEmpty
          ? const Center(
              child: Text(
                'Brak użytkowników.',
                style: TextStyle(fontSize: 18),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: users.length,
              itemBuilder: (context, index) {
                final user = users[index];
                final id = user['id']?.toString() ?? '';
                final name = user['name']?.toString() ?? '';
                final isSelected = id == currentUserId;
                final role = user['role']?.toString() ?? 'USER';
                final userIsAdmin = role == 'ADMIN';
                final userIsExpert = role == 'EKSPERT';

                return Card(
                  color: isSelected ? Colors.green.shade50 : Colors.white,
                  elevation: isSelected ? 5 : 2,
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(
                      color: isSelected ? Colors.green : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor:
                          isSelected ? Colors.green : Colors.blueGrey,
                      child: Icon(
                        userIsAdmin
                            ? Icons.admin_panel_settings
                            : userIsExpert
                                ? Icons.verified_user
                                : Icons.person,
                        color: Colors.white,
                      ),
                    ),
                    title: Text(
                      name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Text(
                      role == 'ADMIN'
                          ? '$id • ADMINISTRATOR'
                          : role == 'EKSPERT'
                              ? '$id • EKSPERT'
                              : '$id • UŻYTKOWNIK',
                    ),
                    trailing: isAdmin
                        ? PopupMenuButton<String>(
                            onSelected: (value) {
                              if (value == 'edit') {
                                editUser(user);
                              }

                              if (value == 'role') {
                                changeUserRole(user);
                              }

                              if (value == 'pin') {
                                changeUserPin(user);
                              }

                              if (value == 'reset_pin') {
                                resetUserPin(user);
                              }

                              if (value == 'delete') {
                                deleteUser(user);
                              }
                            },
                            itemBuilder: (context) => [
                              const PopupMenuItem(
                                value: 'edit',
                                child: Text('Edytuj nazwę'),
                              ),
                              const PopupMenuItem(
                                value: 'role',
                                child: Text('Uprawnienia'),
                              ),
                              const PopupMenuItem(
                                value: 'pin',
                                child: Text('Zmień PIN'),
                              ),
                              const PopupMenuItem(
                                value: 'reset_pin',
                                child: Text('Reset PIN do 0000'),
                              ),
                              const PopupMenuDivider(),
                              const PopupMenuItem(
                                value: 'delete',
                                child: Text('Usuń'),
                              ),
                            ],
                          )
                        : isSelected
                            ? const Icon(Icons.check_circle, color: Colors.green)
                            : const Icon(Icons.arrow_forward_ios),                   
                  ),
                );
              },
            ),
    );
  }
}

class NumberStatus {
  final int count;
  final String? imagePath;

  NumberStatus({
    required this.count,
    required this.imagePath,
  });
}

class NumbersScreen extends StatefulWidget {
  final int year;

  const NumbersScreen({super.key, required this.year});

  @override
  State<NumbersScreen> createState() => _NumbersScreenState();
}

class _NumbersScreenState extends State<NumbersScreen> {
  List<Map<String, dynamic>> tasks = [];

  @override
  void initState() {
    super.initState();
    loadTasks();
  }

  Future<void> loadTasks() async {
    final data = await AppDatabase.getTasks(widget.year);

    if (!mounted) return;

    setState(() {
      tasks = data;
    });
  }

  Future<NumberStatus> getNumberStatus(String number) async {
    final count = await AppDatabase.getEntriesCount(number);
    final imagePath = await AppDatabase.getLastImagePath(number);

    return NumberStatus(
      count: count,
      imagePath: imagePath,
    );
  }

  Future<void> _showAddTaskDialog() async {
    final taskController = TextEditingController();

    final number = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Dodaj zadanie'),
        content: TextField(
          controller: taskController,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Np. 301/26',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Anuluj'),
          ),
          ElevatedButton(
            onPressed: () {
              final value = taskController.text.trim();

              if (value.isEmpty) return;

              Navigator.of(dialogContext).pop(value);
            },
            child: const Text('Dodaj'),
          ),
        ],
      ),
    );

    if (number == null || number.isEmpty) return;

    await AppDatabase.insertTask(widget.year, number);

    await loadTasks();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Rok ${widget.year}'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddTaskDialog,
        child: const Icon(Icons.add),
      ),
      body: tasks.isEmpty
          ? const Center(
              child: Text(
                'Brak zadań.\nKliknij + żeby dodać pierwsze.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18),
              ),
            )
          : ListView.builder(
              itemCount: tasks.length,
              itemBuilder: (context, index) {
                final number = tasks[index]['number'] as String;

                return FutureBuilder<NumberStatus>(
                  future: getNumberStatus(number),
                  builder: (context, snapshot) {
                    final status = snapshot.data;
                    final count = status?.count ?? 0;
                    final imagePath = status?.imagePath;

                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      child: ListTile(
                        leading: imagePath != null && imagePath.isNotEmpty
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.file(
                                  File(imagePath),
                                  width: 46,
                                  height: 46,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return const Icon(Icons.broken_image);
                                  },
                                ),
                              )
                            : Container(
                                width: 16,
                                height: 16,
                                decoration: BoxDecoration(
                                  color: count > 0 ? Colors.green : Colors.red,
                                  shape: BoxShape.circle,
                                ),
                              ),
                        title: Text(number),
                        subtitle: Text(
                          count > 0 ? 'Liczba wpisów: $count' : 'Brak wpisów',
                        ),
                        trailing: const Icon(Icons.arrow_forward_ios),
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                             builder: (_) => EntryScreen(number: number),
                            ),
                          );

                          loadTasks();
                        },
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}

class EntryScreen extends StatefulWidget {
  final String number;

  const EntryScreen({super.key, required this.number});

  @override
  State<EntryScreen> createState() => _EntryScreenState();
}

class _EntryScreenState extends State<EntryScreen> {
  final TextEditingController controller = TextEditingController();

  List<File> selectedImages = [];
  final picker = ImagePicker();

  List<Map<String, dynamic>> entries = [];

  @override
  void initState() {
    super.initState();
    loadEntries();
  }

  Future<void> loadEntries() async {
    final data = await AppDatabase.getEntries(widget.number);

    setState(() {
      entries = data;
    });
  }
  
  List<Map<String, dynamic>> get imageEntries {
  return entries
      .where((entry) =>
          entry['imagePath'] != null &&
          entry['imagePath'].toString().isNotEmpty)
      .toList();
  }

  List<Map<String, dynamic>> get noteEntries {
    return entries
        .where((entry) =>
            entry['imagePath'] == null ||
            entry['imagePath'].toString().isEmpty)
        .toList();
  }

  void addEntryWithCategory(String category) async {
    final alreadyExists = entries.any(
      (entry) => entry['category']?.toString() == category,
    );

    if (alreadyExists) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$category już istnieje'),
        ),
      );
      return;
    }

    final now = DateTime.now();

    final time =
        '${now.day}.${now.month}.${now.year} '
        '${now.hour}:${now.minute.toString().padLeft(2, '0')}';

    await AppDatabase.insertEntry(
      widget.number,
      category,
      '',
      time,
      null,
      currentUserId,
    );

    await loadEntries();
  }

  Future<void> pickImage() async {
    final images = await picker.pickMultiImage();

    if (images.isEmpty) return;

    String caption = '';

    if (images.length == 1) {
      final captionController = TextEditingController();

      final result = await showDialog<String>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Podpis zdjęcia'),
          content: TextField(
            controller: captionController,
            autofocus: true,
            keyboardType: TextInputType.multiline,
            minLines: 3,
            maxLines: 7,
            textInputAction: TextInputAction.newline,
            decoration: const InputDecoration(
              hintText: 'Wpisz podpis zdjęcia...',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(''),
              child: const Text('Bez podpisu'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(
                  captionController.text.trim(),
                );
              },
              child: const Text('Zapisz'),
            ),
          ],
        ),
      );

      caption = result ?? '';
    }

    final appDir = await getApplicationDocumentsDirectory();

    final now = DateTime.now();

    final time =
        '${now.day}.${now.month}.${now.year} '
        '${now.hour}:${now.minute.toString().padLeft(2, '0')}';

    final photoCount = imageEntries.length;

    for (int i = 0; i < images.length; i++) {
      final image = images[i];

      final fileName =
          '${DateTime.now().millisecondsSinceEpoch}_${i}_${p.basename(image.path)}';

      final savedImage = await File(image.path).copy(
        '${appDir.path}/$fileName',
      );

      await AppDatabase.insertEntry(
        widget.number,
        'WPIS',
        images.length == 1
            ? (caption.isEmpty ? 'Zdjęcie' : caption)
            : 'Zdjęcie ${photoCount + i + 1}',
        time,
        savedImage.path,
        currentUserId,
      );
    }

    await loadEntries();

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          images.length == 1
              ? 'Zdjęcie dodane'
              : 'Dodano zdjęcia: ${images.length}',
        ),
      ),
    );
  }

  void addEntry() async {
    final text = controller.text.trim();

    if (text.isEmpty && selectedImages.isEmpty) return;

    final now = DateTime.now();

    final time =
        '${now.day}.${now.month}.${now.year} '
        '${now.hour}:${now.minute.toString().padLeft(2, '0')}';

    print('ZAPISYWANE ZDJECIE: ${selectedImages.length}');

    if (selectedImages.isEmpty) {
      await AppDatabase.insertEntry(
        widget.number,
        'WPIS',
        text,
        time,
        null,
        currentUserId,
      );
    } else {
      for (int i = 0; i < selectedImages.length; i++) {
        await AppDatabase.insertEntry(
          widget.number,
          'WPIS',
          i == 0 && text.isNotEmpty ? text : 'Zdjecie',
          time,
          selectedImages[i].path,
          currentUserId,
        );
      }
    }

    controller.clear();

    setState(() {
      selectedImages.clear();
    });

    loadEntries();
  }

  void _editEntry(Map<String, dynamic> entry) async {
    final ownerId = entry['userId']?.toString() ?? '';

    final canEdit = await AppDatabase.canCurrentUserEditItem(ownerId);

    if (!canEdit) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Możesz edytować tylko swoje wpisy.'),
        ),
      );
      return;
    }

    final editController =
        TextEditingController(text: entry['text']);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edytuj notatkę'),
        content: TextField(
          controller: editController,
          keyboardType: TextInputType.multiline,
          minLines: 3,
          maxLines: 8,
          textInputAction: TextInputAction.newline,
          decoration: const InputDecoration(
            hintText: 'Treść notatki...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Anuluj'),
          ),
          ElevatedButton(
            onPressed: () async {
              final newText =
                  editController.text.trim();

              if (newText.isEmpty) return;

              await AppDatabase.updateEntryText(
                entry['id'] as int,
                newText,
              );

              Navigator.pop(context);

              loadEntries();
            },
            child: const Text('Zapisz'),
          ),
        ],
      ),
    );
  }

  void _deleteEntry(Map<String, dynamic> entry) async {
    final ownerId = entry['userId']?.toString() ?? '';

    final canEdit = await AppDatabase.canCurrentUserEditItem(ownerId);

    if (!canEdit) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Możesz usuwać tylko swoje wpisy.'),
        ),
      );
      return;
    }
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Usuń notatkę'),
        content: const Text(
          'Czy na pewno chcesz usunąć tę notatkę?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Anuluj'),
          ),
          ElevatedButton(
            onPressed: () async {
              await AppDatabase.deleteEntry(
                entry['id'],
              );

              Navigator.pop(context);

              loadEntries();
            },
            child: const Text('Usuń'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.number),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _CategoryTile(
                  title: '01.',
                  subtitle: 'DANE',
                  icon: Icons.description,
                  isDone: entries.any((e) => e['category']?.toString() == 'DANE'),
                  onTap: () => addEntryWithCategory('DANE'),
                ),
                _CategoryTile(
                  title: '05.',
                  subtitle: 'ADRES',
                  icon: Icons.location_on,
                  isDone: entries.any((e) => e['category']?.toString() == 'ADRES'),
                  onTap: () => addEntryWithCategory('ADRES'),
                ),
                _CategoryTile(
                  title: '57.',
                  subtitle: 'AUTA',
                  icon: Icons.directions_car,
                  isDone: entries.any((e) => e['category']?.toString() == 'AUTA'),
                  onTap: () => addEntryWithCategory('AUTA'),
                ),
                _CategoryTile(
                  title: '08.',
                  subtitle: 'KONT.',
                  icon: Icons.contacts,
                  isDone: entries.any((e) => e['category']?.toString() == 'KONT.'),
                  onTap: () => addEntryWithCategory('KONT.'),
                ),
              ],
            ),
          ),
          if (selectedImages.isNotEmpty)
            SizedBox(
              height: 120,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.all(8),
                itemCount: selectedImages.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.file(
                        selectedImages[index],
                        width: 120,
                        height: 120,
                        fit: BoxFit.cover,
                      ),
                    ),
                  );
                },
              ),
            ),

          Expanded(
  child: ListView(
    padding: const EdgeInsets.all(8),
    children: [
      if (imageEntries.isNotEmpty) ...[
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 4, 4, 10),
          child: Row(
            children: [
              const Icon(Icons.photo_library, size: 20),
              const SizedBox(width: 8),
              Text(
                'Zdjęcia (${imageEntries.length})',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),

        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: imageEntries.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 0.72,
          ),
          itemBuilder: (context, index) {
            final entry = imageEntries[index];
            final imagePath = entry['imagePath'] as String?;
            final caption = entry['text']?.toString() ?? '';

            return GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => FullScreenImage(
                      photos: imageEntries,
                      initialIndex: index,
                    ),
                  ),
                );
              },
              onLongPress: () {
                _deleteEntry(entry);
              },
              child: Card(
                color: Colors.white,
                elevation: 5,
                clipBehavior: Clip.antiAlias,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(12),
                        ),
                        child: Image.file(
                          File(imagePath ?? ''),
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(Icons.broken_image);
                          },
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(6, 4, 2, 4),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              caption,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          IconButton(
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            icon: const Icon(Icons.edit, size: 17),
                            onPressed: () {
                              _editEntry(entry);
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
  ],

  if (noteEntries.isNotEmpty) ...[
    const SizedBox(height: 14),
    Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 4, 6),
      child: Row(
        children: [
          const Icon(Icons.article, size: 20),
          const SizedBox(width: 8),
          Text(
            'Dane sprawy (${noteEntries.length})',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    ),
  ],

  ...noteEntries.map((entry) {
        final category = entry['category']?.toString() ?? 'WPIS';
        final isMainCategory = category != 'WPIS';

        Color categoryColor(String category) {
          switch (category) {
            case 'DANE':
              return Colors.grey.shade300;
            case 'ADRES':
              return Colors.grey.shade400;
            case 'AUTA':
              return Colors.grey.shade500;
            case 'KONT.':
              return Colors.grey.shade600;
            default:
              return Colors.grey.shade200;
          }
        }

        return Card(
          color: isMainCategory ? Colors.grey.shade300 : Colors.white,
          elevation: 2,
          margin: const EdgeInsets.symmetric(vertical: 6),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.all(10),
            leading: Container(
              width: 60,
              height: 60,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: categoryColor(category),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                category,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: category == 'KONT.' ? Colors.white : Colors.black,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Text(
              entry['text'] ?? '',
              maxLines: 8,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
            subtitle: FutureBuilder<String>(
              future: userNameById(
                entry['userId']?.toString() ?? 'USER_001',
              ),
              builder: (context, snapshot) {
                final userName = snapshot.data ?? 'Użytkownik';

                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    '${entry['dateTime'] ?? ''}\n$userName',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                );
              },
            ),
            onTap: () {
              _editEntry(entry);
            },
            onLongPress: () {
              _deleteEntry(entry);
            },
          ),
        );
      }),
    ],
  ),
),

          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controller,
                    keyboardType: TextInputType.multiline,
                    minLines: 1,
                    maxLines: 5,
                    textInputAction: TextInputAction.newline,
                    decoration: const InputDecoration(
                      hintText: 'Nowy wpis...',
                      border:
                          OutlineInputBorder(),
                    ),
                  ),
                ),

                const SizedBox(width: 8),

                Column(
                  children: [
                    IconButton(
                      onPressed: pickImage,
                      icon: const Icon(
                        Icons.photo,
                      ),
                    ),
                    ElevatedButton(
                      onPressed: addEntry,
                      child: const Text(
                        'Dodaj',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

String currentUserId = 'USER_001';
String currentUserName = 'Użytkownik 1';

Future<String> userNameById(String userId) async {
  return AppDatabase.getUserNameById(userId);
}

Color carColor(int index) {
  final colors = [
    Colors.blueGrey.shade900,
    Colors.teal.shade800,
    Colors.indigo.shade800,
    Colors.deepPurple.shade700,
    Colors.brown.shade700,
    Colors.green.shade800,
    Colors.orange.shade800,
    Colors.red.shade800,
  ];

  return colors[index % colors.length];
}

class FleetScreen extends StatefulWidget {
  const FleetScreen({super.key});

  @override
  State<FleetScreen> createState() => _FleetScreenState();
}

class _FleetScreenState extends State<FleetScreen> {
  List<Map<String, dynamic>> cars = [];
  bool canManageFleet = false;

  @override
  void initState() {
    super.initState();
    loadCars();
  }

  Future<void> loadCars() async {
    final data = await AppDatabase.getCars();
    final expert = await AppDatabase.isCurrentUserExpert();

    if (!mounted) return;

    setState(() {
      cars = data;
      canManageFleet = expert;
    });
  }

  Future<void> _showCarDialog({Map<String, dynamic>? car}) async {
    final nameController = TextEditingController(
      text: car?['name']?.toString() ?? '',
    );
    final plateController = TextEditingController(
      text: car?['plate']?.toString() ?? '',
    );

    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(car == null ? 'Dodaj samochód' : 'Edytuj samochód'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Nazwa auta',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: plateController,
              decoration: const InputDecoration(
                labelText: 'Rejestracja',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Anuluj'),
          ),
          ElevatedButton(
            onPressed: () {
              final name = nameController.text.trim();
              final plate = plateController.text.trim();

              if (name.isEmpty) return;

              Navigator.of(dialogContext).pop({
                'name': name,
                'plate': plate,
              });
            },
            child: const Text('Zapisz'),
          ),
        ],
      ),
    );

    if (result == null) return;

    if (car == null) {
      final now = DateTime.now();

      final time =
          '${now.day}.${now.month}.${now.year} '
          '${now.hour}:${now.minute.toString().padLeft(2, '0')}';

      await AppDatabase.insertCar(
        result['name'] ?? '',
        result['plate'] ?? '',
        time,
        cars.length,
      );
    } else {
      await AppDatabase.updateCar(
        car['id'] as int,
        result['name'] ?? '',
        result['plate'] ?? '',
      );
    }

    await loadCars();
  }

  Future<void> _deleteCar(Map<String, dynamic> car) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Usuń samochód'),
        content: Text(
          'Czy na pewno chcesz usunąć samochód ${car['name']}?\n\nUsunięte zostaną też jego notatki.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Anuluj'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Usuń'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    await AppDatabase.deleteCar(car['id'] as int);
    await loadCars();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        title: const Text('Flota'),
        centerTitle: true,
      ),
      floatingActionButton: canManageFleet
          ? FloatingActionButton.extended(
              onPressed: () => _showCarDialog(),
              icon: const Icon(Icons.add),
              label: const Text('Dodaj auto'),
            )
          : null,
      body: cars.isEmpty
          ? const Center(
              child: Text(
                'Brak samochodów.\nKliknij Dodaj auto.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: cars.length,
              itemBuilder: (context, index) {
                final car = cars[index];
                final name = car['name']?.toString() ?? '';
                final plate = car['plate']?.toString() ?? '';
                final createdAt = car['createdAt']?.toString() ?? '';
                final colorIndex = car['colorIndex'] as int? ?? index;

                return Card(
                  color: carColor(colorIndex),
                  elevation: 4,
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(14),
                    leading: const Icon(
                      Icons.directions_car,
                      color: Colors.white,
                      size: 36,
                    ),
                    title: Text(
                      name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Text(
                      plate.isEmpty
                          ? 'Dodano: $createdAt'
                          : '$plate\nDodano: $createdAt',
                      style: const TextStyle(color: Colors.white70),
                    ),
                    isThreeLine: plate.isNotEmpty,
                    trailing: canManageFleet
                        ? PopupMenuButton<String>(
                            icon: const Icon(Icons.more_vert, color: Colors.white),
                            onSelected: (value) {
                              if (value == 'edit') {
                                _showCarDialog(car: car);
                              }

                              if (value == 'delete') {
                                _deleteCar(car);
                              }
                            },
                            itemBuilder: (context) => const [
                              PopupMenuItem(
                                value: 'edit',
                                child: Text('Edytuj'),
                              ),
                              PopupMenuItem(
                                value: 'delete',
                                child: Text('Usuń'),
                              ),
                            ],
                          )
                        : const Icon(Icons.arrow_forward_ios, color: Colors.white),
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => CarDetailsScreen(car: car),
                        ),
                      );

                      loadCars();
                    },
                  ),
                );
              },
            ),
    );
  }
}

class CarDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> car;

  const CarDetailsScreen({
    super.key,
    required this.car,
  });

  @override
  State<CarDetailsScreen> createState() => _CarDetailsScreenState();
}

class _CarDetailsScreenState extends State<CarDetailsScreen> {
  @override
  Widget build(BuildContext context) {
    final name = widget.car['name']?.toString() ?? '';
    final plate = widget.car['plate']?.toString() ?? '';
    final colorIndex = widget.car['colorIndex'] as int? ?? 0;

    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        title: Text(name),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            color: carColor(colorIndex),
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Row(
                children: [
                  const Icon(
                    Icons.directions_car,
                    color: Colors.white,
                    size: 42,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (plate.isNotEmpty)
                          Text(
                            plate,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 16,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 18),

          FutureBuilder<Map<String, int>>(
            future: AppDatabase.getCarSectionCounts(widget.car['id'] as int),
            builder: (context, snapshot) {
              final counts = snapshot.data ?? {};

              return Column(
                children: [
                  _CarOptionTile(
                    title: 'Zgłoś usterkę',
                    subtitle: 'Usterki: ${counts['USTERKI'] ?? 0}',
                    icon: Icons.report_problem,
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => CarNotesScreen(
                            car: widget.car,
                            section: 'USTERKI',
                            title: 'Zgłoś usterkę',
                            allowImages: true,
                          ),
                        ),
                      );

                      setState(() {});
                    },
                  ),

                  _CarOptionTile(
                    title: 'OC / AC / BT',
                    subtitle: 'Terminy dokumentów',
                    icon: Icons.verified_user,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => CarTermsScreen(car: widget.car),
                        ),
                      );
                    },
                  ),

                  _CarOptionTile(
                    title: 'Konspiracja',
                    subtitle: 'Notatki: ${counts['KONSPIRACJA'] ?? 0}',
                    icon: Icons.lock,
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => CarNotesScreen(
                            car: widget.car,
                            section: 'KONSPIRACJA',
                            title: 'Konspiracja',
                            allowImages: false,
                          ),
                        ),
                      );

                      setState(() {});
                    },
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class CarNotesScreen extends StatefulWidget {
  final Map<String, dynamic> car;
  final String section;
  final String title;
  final bool allowImages;

  const CarNotesScreen({
    super.key,
    required this.car,
    required this.section,
    required this.title,
    required this.allowImages,
  });

  @override
  State<CarNotesScreen> createState() => _CarNotesScreenState();
}

class _CarNotesScreenState extends State<CarNotesScreen> {
  final TextEditingController controller = TextEditingController();
  final picker = ImagePicker();

  List<Map<String, dynamic>> notes = [];

  @override
  void initState() {
    super.initState();
    loadNotes();
  }

  Future<void> addPhotoNote() async {
    final images = await picker.pickMultiImage();

    if (images.isEmpty) return;

    String caption = '';

    if (images.length == 1) {
      final captionController = TextEditingController();

      final result = await showDialog<String>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Podpis zdjęcia'),
          content: TextField(
            controller: captionController,
            autofocus: true,
            keyboardType: TextInputType.multiline,
            minLines: 3,
            maxLines: 7,
            textInputAction: TextInputAction.newline,
            decoration: const InputDecoration(
              hintText: 'Wpisz podpis usterki...',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(''),
              child: const Text('Bez podpisu'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(
                  captionController.text.trim(),
                );
              },
              child: const Text('Zapisz'),
            ),
          ],
        ),
      );

      caption = result ?? '';
    }

    final appDir = await getApplicationDocumentsDirectory();

    final now = DateTime.now();

    final time =
        '${now.day}.${now.month}.${now.year} '
        '${now.hour}:${now.minute.toString().padLeft(2, '0')}';

    for (int i = 0; i < images.length; i++) {
      final image = images[i];

      final fileName =
          '${DateTime.now().millisecondsSinceEpoch}_${i}_${p.basename(image.path)}';

      final savedImage = await File(image.path).copy(
        '${appDir.path}/$fileName',
      );

      await AppDatabase.insertCarNote(
        widget.car['id'] as int,
        widget.section,
        images.length == 1
            ? (caption.isEmpty ? 'Zdjęcie usterki' : caption)
            : 'Zdjęcie usterki ${i + 1}',
        time,
        currentUserId,
        imagePath: savedImage.path,
      );
    }

    await loadNotes();
  }

  Future<void> loadNotes() async {
    final data = await AppDatabase.getCarNotes(
      widget.car['id'] as int,
      widget.section,
    );

    if (!mounted) return;

    setState(() {
      notes = data;
    });
  }

  Future<void> addNote() async {
    final text = controller.text.trim();

    if (text.isEmpty) return;

    final now = DateTime.now();

    final time =
        '${now.day}.${now.month}.${now.year} '
        '${now.hour}:${now.minute.toString().padLeft(2, '0')}';

    await AppDatabase.insertCarNote(
      widget.car['id'] as int,
      widget.section,
      text,
      time,
      currentUserId,
    );

    controller.clear();
    await loadNotes();
  }

  Future<void> editNote(Map<String, dynamic> note) async {
    final ownerId = note['userId']?.toString() ?? '';

    final canEdit = await AppDatabase.canCurrentUserEditItem(ownerId);

    if (!canEdit) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Możesz edytować tylko swoje notatki.'),
        ),
      );
      return;
    }

    final editController = TextEditingController(
      text: note['text']?.toString() ?? '',
    );

    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Edytuj notatkę'),
        content: TextField(
          controller: editController,
          autofocus: true,
          keyboardType: TextInputType.multiline,
          minLines: 3,
          maxLines: 8,
          textInputAction: TextInputAction.newline,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            hintText: 'Treść notatki...',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Anuluj'),
          ),
          ElevatedButton(
            onPressed: () {
              final value = editController.text.trim();

              if (value.isEmpty) return;

              Navigator.of(dialogContext).pop(value);
            },
            child: const Text('Zapisz'),
          ),
        ],
      ),
    );

    if (result == null) return;

    await AppDatabase.updateCarNote(
      note['id'] as int,
      result,
    );

    await loadNotes();
  }

  Future<void> deleteNote(Map<String, dynamic> note) async {
    final ownerId = note['userId']?.toString() ?? '';

    final canEdit = await AppDatabase.canCurrentUserEditItem(ownerId);

    if (!canEdit) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Możesz usuwać tylko swoje notatki.'),
        ),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Usuń notatkę'),
        content: const Text('Czy na pewno chcesz usunąć tę notatkę?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Anuluj'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Usuń'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    await AppDatabase.deleteCarNote(note['id'] as int);
    await loadNotes();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final carName = widget.car['name']?.toString() ?? '';
    final plate = widget.car['plate']?.toString() ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        title: Text(widget.title),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.blueGrey.shade900,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              plate.isEmpty ? carName : '$carName\n$plate',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: notes.isEmpty
                ? const Center(
                    child: Text(
                      'Brak notatek.',
                      style: TextStyle(fontSize: 18),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: notes.length,
                    itemBuilder: (context, index) {
                      final note = notes[index];
                      final text = note['text']?.toString() ?? '';
                      final dateTime = note['dateTime']?.toString() ?? '';
                      final userId = note['userId']?.toString() ?? '';
                      final imagePath = note['imagePath']?.toString() ?? '';
                      final hasImage = imagePath.isNotEmpty;
                      final userNameFuture = userNameById(userId);

                      final photoNotes = notes
                          .where((n) =>
                              n['imagePath'] != null &&
                              n['imagePath'].toString().isNotEmpty)
                          .toList();

                      final photoIndex = photoNotes.indexWhere(
                        (n) => n['id'] == note['id'],
                      );

                      if (hasImage) {
                        return Card(
                          elevation: 4,
                          margin: const EdgeInsets.only(bottom: 12),
                          clipBehavior: Clip.antiAlias,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => FullScreenImage(
                                        photos: photoNotes,
                                        initialIndex: photoIndex < 0 ? 0 : photoIndex,
                                      ),
                                    ),
                                  );
                                },
                                child: Image.file(
                                  File(imagePath),
                                  width: double.infinity,
                                  height: 220,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      height: 220,
                                      alignment: Alignment.center,
                                      child: const Icon(Icons.broken_image, size: 60),
                                    );
                                  },
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(12),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Icon(Icons.photo, size: 22),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            text,
                                            maxLines: 6,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          FutureBuilder<String>(
                                            future: userNameFuture,
                                            builder: (context, snapshot) {
                                              return Text(
                                                '$dateTime\n${snapshot.data ?? userId}',
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey,
                                                ),
                                              );
                                            },
                                          ),
                                        ],
                                      ),
                                    ),
                                    PopupMenuButton<String>(
                                      onSelected: (value) {
                                        if (value == 'edit') {
                                          editNote(note);
                                        }

                                        if (value == 'delete') {
                                          deleteNote(note);
                                        }
                                      },
                                      itemBuilder: (context) => const [
                                        PopupMenuItem(
                                          value: 'edit',
                                          child: Text('Edytuj'),
                                        ),
                                        PopupMenuItem(
                                          value: 'delete',
                                          child: Text('Usuń'),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      return Card(
                        elevation: 2,
                        margin: const EdgeInsets.only(bottom: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(12),
                          title: Text(
                            text,
                            maxLines: 8,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: FutureBuilder<String>(
                              future: userNameFuture,
                              builder: (context, snapshot) {
                                return Text(
                                  '$dateTime\n${snapshot.data ?? userId}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                );
                              },
                            ),
                          ),
                          trailing: PopupMenuButton<String>(
                            onSelected: (value) {
                              if (value == 'edit') {
                                editNote(note);
                              }

                              if (value == 'delete') {
                                deleteNote(note);
                              }
                            },
                            itemBuilder: (context) => const [
                              PopupMenuItem(
                                value: 'edit',
                                child: Text('Edytuj'),
                              ),
                              PopupMenuItem(
                                value: 'delete',
                                child: Text('Usuń'),
                              ),
                            ],
                          ),
                          onTap: () => editNote(note),
                          onLongPress: () => deleteNote(note),
                        ),
                      );
                    },
                  ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controller,
                    keyboardType: TextInputType.multiline,
                    minLines: 1,
                    maxLines: 5,
                    textInputAction: TextInputAction.newline,
                    decoration: const InputDecoration(
                      hintText: 'Nowa notatka...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),

                if (widget.allowImages) ...[
                  const SizedBox(width: 6),
                  IconButton(
                    onPressed: addPhotoNote,
                    icon: const Icon(Icons.photo),
                  ),
                ],

                const SizedBox(width: 6),

                ElevatedButton(
                  onPressed: addNote,
                  child: const Text('Dodaj'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class CarTermsScreen extends StatefulWidget {
  final Map<String, dynamic> car;

  const CarTermsScreen({
    super.key,
    required this.car,
  });

  @override
  State<CarTermsScreen> createState() => _CarTermsScreenState();
}

class _CarTermsScreenState extends State<CarTermsScreen> {
  String? ocDate;
  String? acDate;
  String? btDate;

  bool canManageTerms = false;

  @override
  void initState() {
    super.initState();
    loadTerms();
    loadPermissions();
  }

  Future<void> loadTerms() async {
    final data = await AppDatabase.getCarTerms(widget.car['id'] as int);

    if (!mounted) return;

    setState(() {
      ocDate = data?['ocDate']?.toString();
      acDate = data?['acDate']?.toString();
      btDate = data?['btDate']?.toString();
    });
  }

  Future<void> loadPermissions() async {
    final expert = await AppDatabase.isCurrentUserExpert();

    if (!mounted) return;

    setState(() {
      canManageTerms = expert;
    });
  }

  Future<void> pickTerm(String type) async {
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2040),
      initialDate: DateTime.now(),
    );

    if (picked == null) return;

    final value =
        '${picked.day}.${picked.month}.${picked.year}';

    if (type == 'OC') ocDate = value;
    if (type == 'AC') acDate = value;
    if (type == 'BT') btDate = value;

    await AppDatabase.saveCarTerms(
      widget.car['id'] as int,
      ocDate,
      acDate,
      btDate,
    );

    await loadTerms();
  }

  DateTime? parseDate(String? value) {
    if (value == null || value.isEmpty) return null;

    final parts = value.split('.');

    if (parts.length != 3) return null;

    final day = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    final year = int.tryParse(parts[2]);

    if (day == null || month == null || year == null) return null;

    return DateTime(year, month, day);
  }

  Color termColor(String? value) {
    final date = parseDate(value);

    if (date == null) return Colors.grey.shade700;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final daysLeft = date.difference(today).inDays;

    if (daysLeft < 0) return Colors.red.shade800;
    if (daysLeft <= 30) return Colors.orange.shade800;

    return Colors.green.shade800;
  }

  String termStatus(String? value) {
    final date = parseDate(value);

    if (date == null) return 'Brak ustawionej daty';

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final daysLeft = date.difference(today).inDays;

    if (daysLeft < 0) return 'Po terminie';
    if (daysLeft == 0) return 'Termin dzisiaj';
    if (daysLeft <= 30) return 'Zostało dni: $daysLeft';

    return 'Zostało dni: $daysLeft';
  }

  Widget termTile(String title, String? date, String type) {
    return Card(
      color: termColor(date),
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 14),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: const Icon(
          Icons.event_available,
          color: Colors.white,
          size: 34,
        ),
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 21,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          date == null || date.isEmpty
              ? 'Brak daty\n${termStatus(date)}'
              : '$date\n${termStatus(date)}',
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 14,
          ),
        ),
        trailing: Icon(
          canManageTerms ? Icons.edit_calendar : Icons.lock,
          color: Colors.white,
        ),
        onTap: canManageTerms ? () => pickTerm(type) : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final name = widget.car['name']?.toString() ?? '';
    final plate = widget.car['plate']?.toString() ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        title: const Text('OC / AC / BT'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            margin: const EdgeInsets.only(bottom: 14),
            decoration: BoxDecoration(
              color: Colors.blueGrey.shade900,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              plate.isEmpty ? name : '$name\n$plate',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          termTile('OC', ocDate, 'OC'),
          termTile('AC', acDate, 'AC'),
          termTile('BT', btDate, 'BT'),
        ],
      ),
    );
  }
}

class _CarOptionTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  const _CarOptionTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 14),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          width: 54,
          height: 54,
          decoration: BoxDecoration(
            color: Colors.grey.shade800,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(
            icon,
            color: Colors.white,
            size: 30,
          ),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: onTap,
      ),
    );
  }
}

class FullScreenImage extends StatefulWidget {
  final List<Map<String, dynamic>> photos;
  final int initialIndex;

  const FullScreenImage({
    super.key,
    required this.photos,
    required this.initialIndex,
  });

  @override
  State<FullScreenImage> createState() => _FullScreenImageState();
}

class _CategoryTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool isDone;
  final VoidCallback onTap;

  const _CategoryTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.isDone,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 165,
      height: 76,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: isDone ? Colors.grey.shade700 : Colors.grey.shade300,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDone ? Colors.grey.shade900 : Colors.grey.shade500,
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                isDone ? Icons.check_circle : icon,
                color: isDone ? Colors.white : Colors.black87,
                size: 28,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: isDone ? Colors.white : Colors.black,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: isDone ? Colors.white70 : Colors.black87,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FullScreenImageState extends State<FullScreenImage> {
  late final PageController pageController;
  late int currentIndex;

  @override
  void initState() {
    super.initState();
    currentIndex = widget.initialIndex;
    pageController = PageController(initialPage: widget.initialIndex);
  }

  Future<void> saveImage(BuildContext context) async {
    final imagePath = widget.photos[currentIndex]['imagePath'] as String?;

    if (imagePath == null || imagePath.isEmpty) return;

    try {
      await Gal.putImage(imagePath);

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Zdjęcie zapisane w galerii'),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nie udało się zapisać zdjęcia'),
        ),
      );
    }
  }

  @override
  void dispose() {
    pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentPhoto = widget.photos[currentIndex];
    final caption = currentPhoto['text']?.toString() ?? '';
    final dateTime = currentPhoto['dateTime']?.toString() ?? '';

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(
          '${currentIndex + 1}/${widget.photos.length}',
        ),
        actions: [
          IconButton(
            onPressed: () => saveImage(context),
            icon: const Icon(Icons.download),
            tooltip: 'Zapisz do telefonu',
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: PageView.builder(
              controller: pageController,
              itemCount: widget.photos.length,
              onPageChanged: (index) {
                setState(() {
                  currentIndex = index;
                });
              },
              itemBuilder: (context, index) {
                final photo = widget.photos[index];
                final imagePath = photo['imagePath'] as String?;

                return Center(
                  child: InteractiveViewer(
                    minScale: 0.5,
                    maxScale: 5,
                    child: Image.file(
                      File(imagePath ?? ''),
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(
                          Icons.broken_image,
                          color: Colors.white,
                          size: 80,
                        );
                      },
                    ),
                  ),
                );
              },
            ),
          ),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: Colors.black87,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (caption.isNotEmpty)
                  Text(
                    caption,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                if (dateTime.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    dateTime,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ChangeLogsScreen extends StatefulWidget {
  const ChangeLogsScreen({super.key});

  @override
  State<ChangeLogsScreen> createState() => _ChangeLogsScreenState();
}

class _ChangeLogsScreenState extends State<ChangeLogsScreen> {
  List<Map<String, dynamic>> logs = [];
  bool isAdmin = false;

  @override
  void initState() {
    super.initState();
    loadLogs();
  }

  Future<void> loadLogs() async {
    final admin = await AppDatabase.isCurrentUserAdmin();

    if (!admin) {
      if (!mounted) return;

      setState(() {
        isAdmin = false;
      });

      return;
    }

    final data = await AppDatabase.getChangeLogs();

    if (!mounted) return;

    setState(() {
      isAdmin = true;
      logs = data;
    });
  }

  IconData iconForAction(String action) {
    if (action == 'Edycja') return Icons.edit;
    if (action == 'Usunięcie') return Icons.delete;
    return Icons.history;
  }

  Color colorForAction(String action) {
    if (action == 'Edycja') return Colors.orange;
    if (action == 'Usunięcie') return Colors.red;
    return Colors.blueGrey;
  }

  void openLog(Map<String, dynamic> log) {
    final action = log['action']?.toString() ?? '';
    final entityType = log['entityType']?.toString() ?? '';
    final userName = log['userName']?.toString() ?? '';
    final dateTime = log['dateTime']?.toString() ?? '';
    final oldValue = log['oldValue']?.toString() ?? '';
    final newValue = log['newValue']?.toString() ?? '';

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('$action - $entityType'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Użytkownik: $userName'),
              const SizedBox(height: 6),
              Text('Data: $dateTime'),
              const Divider(height: 24),
              const Text(
                'Przed zmianą:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Text(oldValue.isEmpty ? '-' : oldValue),
              const SizedBox(height: 18),
              const Text(
                'Po zmianie:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Text(newValue.isEmpty ? '-' : newValue),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Zamknij'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!isAdmin) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Historia zmian'),
          centerTitle: true,
        ),
        body: const Center(
          child: Text(
            'Tylko ADMIN ma dostęp do historii zmian.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 18),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        title: const Text('Historia zmian'),
        centerTitle: true,
      ),
      body: logs.isEmpty
          ? const Center(
              child: Text(
                'Brak historii zmian.',
                style: TextStyle(fontSize: 18),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: logs.length,
              itemBuilder: (context, index) {
                final log = logs[index];

                final action = log['action']?.toString() ?? '';
                final entityType = log['entityType']?.toString() ?? '';
                final userName = log['userName']?.toString() ?? '';
                final dateTime = log['dateTime']?.toString() ?? '';
                final color = colorForAction(action);

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
                        iconForAction(action),
                        color: Colors.white,
                      ),
                    ),
                    title: Text(
                      '$action - $entityType',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Text('$userName\n$dateTime'),
                    isThreeLine: true,
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: () => openLog(log),
                  ),
                );
              },
            ),
    );
  }
}

Future<T> runWithProgressDialog<T>({
  required BuildContext context,
  required String title,
  required String message,
  required Future<T> Function(ValueNotifier<double> progress) action,
}) async {
  final progress = ValueNotifier<double>(0);

  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) {
      return AlertDialog(
        title: Text(title),
        content: ValueListenableBuilder<double>(
          valueListenable: progress,
          builder: (context, value, _) {
            final percent = (value * 100).clamp(0, 100).round();

            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(message),
                const SizedBox(height: 18),
                LinearProgressIndicator(value: value),
                const SizedBox(height: 12),
                Text('$percent%'),
              ],
            );
          },
        ),
      );
    },
  );

  try {
    return await action(progress);
  } finally {
    progress.dispose();

    if (context.mounted) {
      Navigator.of(context, rootNavigator: true).pop();
    }
  }
}

class AdminPanelScreen extends StatelessWidget {
  const AdminPanelScreen({super.key});

  Widget adminTile({
    required BuildContext context,
    required String title,
    required IconData icon,
    required VoidCallback onTap,
  }) {
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
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 17,
          ),
        ),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: onTap,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        title: const Text('Panel administratora'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          adminTile(
            context: context,
            title: 'Historia zmian',
            icon: Icons.history,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const ChangeLogsScreen(),
                ),
              );
            },
          ),
          adminTile(
            context: context,
            title: 'Użytkownicy',
            icon: Icons.people,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const UsersScreen(),
                ),
              );
            },
          ),
          adminTile(
            context: context,
            title: 'Statystyki',
            icon: Icons.bar_chart,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const AdminStatsScreen(),
                ),
              );
            },
          ),
          adminTile(
            context: context,
            title: 'Utwórz backup',
            icon: Icons.backup,
            onTap: () async {
              try {
                final path = await runWithProgressDialog<String>(
                  context: context,
                  title: 'Backup',
                  message: 'Trwa tworzenie backupu...',
                  action: (progress) {
                    return AppDatabase.createBackupZip(
                      onProgress: (value) {
                        progress.value = value;
                      },
                    );
                  },
                );

                if (!context.mounted) return;

                showDialog(
                  context: context,
                  builder: (dialogContext) => AlertDialog(
                    title: const Text('Backup utworzony'),
                    content: Text(
                      'Kopia zapasowa została zapisana:\n\n$path',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(dialogContext),
                        child: const Text('OK'),
                      ),
                    ],
                  ),
                );
              } catch (e) {
                if (!context.mounted) return;

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Błąd backupu: $e'),
                  ),
                );
              }
            },
          ),
          adminTile(
            context: context,
            title: 'Backupy',
            icon: Icons.folder_zip,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const BackupsScreen(),
                ),
              );
            },
          ),
          
          adminTile(
            context: context,
            title: 'Ustawienia aplikacji',
            icon: Icons.settings,
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Ustawienia dodamy później.'),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
class AdminStatsScreen extends StatefulWidget {
  const AdminStatsScreen({super.key});

  @override
  State<AdminStatsScreen> createState() => _AdminStatsScreenState();
}

class _AdminStatsScreenState extends State<AdminStatsScreen> {
  Map<String, int> stats = {};
  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadStats();
  }

  Future<void> loadStats() async {
    final data = await AppDatabase.getAdminStats();

    if (!mounted) return;

    setState(() {
      stats = data;
      loading = false;
    });
  }

  Widget statTile(String title, int value, IconData icon) {
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
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 17,
          ),
        ),
        trailing: Text(
          value.toString(),
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        title: const Text('Statystyki'),
        centerTitle: true,
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: loadStats,
              child: ListView(
                padding: const EdgeInsets.all(12),
                children: [
                  statTile('Użytkownicy', stats['users'] ?? 0, Icons.people),
                  statTile('Lata', stats['years'] ?? 0, Icons.calendar_month),
                  statTile('Zadania', stats['tasks'] ?? 0, Icons.assignment),
                  statTile('Wpisy w zadaniach', stats['entries'] ?? 0, Icons.article),
                  statTile('Zdjęcia w zadaniach', stats['photos'] ?? 0, Icons.photo),
                  statTile('Auta', stats['cars'] ?? 0, Icons.directions_car),
                  statTile('Notatki floty', stats['carNotes'] ?? 0, Icons.build),
                  statTile('Komunikaty', stats['messages'] ?? 0, Icons.campaign),
                  statTile('Historia zmian', stats['changeLogs'] ?? 0, Icons.history),
                ],
              ),
            ),
    );
  }
}
class BackupsScreen extends StatefulWidget {
  const BackupsScreen({super.key});

  @override
  State<BackupsScreen> createState() => _BackupsScreenState();
}

class _BackupsScreenState extends State<BackupsScreen> {
  List<FileSystemEntity> backups = [];

  @override
  void initState() {
    super.initState();
    loadBackups();
  }

  Future<void> loadBackups() async {
    final list = await AppDatabase.getBackupFiles();

    if (!mounted) return;

    setState(() {
      backups = list;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Backupy'),
      ),
      body: backups.isEmpty
          ? const Center(
              child: Text('Brak backupów'),
            )
          : ListView.builder(
              itemCount: backups.length,
              itemBuilder: (context, index) {
                final file = backups[index];

                final name = file.path.split('/').last;

                return ListTile(
                  leading: const Icon(Icons.archive),
                  title: Text(name),
                  subtitle: Text(file.path),

                  onTap: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: const Text('Przywróć backup'),
                        content: Text(
                          'Przywrócić ten backup?\n\n$name\n\nAktualne dane zostaną podmienione.',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('Anuluj'),
                          ),
                          ElevatedButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text('Przywróć'),
                          ),
                        ],
                      ),
                    );

                    if (confirm != true) return;

                    try {
                      await runWithProgressDialog<void>(
                        context: context,
                        title: 'Przywracanie backupu',
                        message: 'Trwa przywracanie backupu...',
                        action: (progress) {
                          return AppDatabase.restoreBackupFromPath(
                            file.path,
                            onProgress: (value) {
                              progress.value = value;
                            },
                          );
                        },
                      );

                      if (!context.mounted) return;

                      showDialog(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: const Text('Backup przywrócony'),
                          content: const Text(
                            'Dane zostały przywrócone.\n\nZamknij aplikację całkowicie i uruchom ją ponownie.',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('OK'),
                            ),
                          ],
                        ),
                      );
                    } catch (e) {
                      if (!context.mounted) return;

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Błąd przywracania: $e'),
                        ),
                      );
                    }
                  },

                  onLongPress: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: const Text('Usuń backup'),
                        content: Text(name),
                        actions: [
                          TextButton(
                            onPressed: () =>
                                Navigator.pop(context, false),
                            child: const Text('Anuluj'),
                          ),
                          ElevatedButton(
                            onPressed: () =>
                                Navigator.pop(context, true),
                            child: const Text('Usuń'),
                          ),
                        ],
                      ),
                    );

                    if (confirm != true) return;

                    await AppDatabase.deleteBackup(file.path);

                    await loadBackups();
                  },
                );
              },
            ),
    );
  }
}



