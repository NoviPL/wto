import 'package:flutter/material.dart';

import '../db/database.dart';
import '../widgets/main_menu_button.dart';
import '../main.dart';

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
                  MainMenuButton(
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
                  MainMenuButton(
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
                  MainMenuButton(
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
                    MainMenuButton(
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
                  MainMenuButton(
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
