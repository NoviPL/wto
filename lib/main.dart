import 'package:flutter/material.dart';
import 'db/database.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
void main() {
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
      home: const YearsScreen(),
    );
  }
}

class YearsScreen extends StatelessWidget {
  const YearsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final years = [2025, 2026];

    return Scaffold(
      appBar: AppBar(
        title: const Text('WTO'),
      ),
      body: ListView.builder(
        itemCount: years.length,
        itemBuilder: (context, index) {
          return Card(
            margin: const EdgeInsets.all(8),
            child: ListTile(
              title: Text(
                years[index].toString(),
                style: const TextStyle(fontSize: 24),
              ),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => NumbersScreen(year: years[index]),
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

class NumbersScreen extends StatelessWidget {
  final int year;

  const NumbersScreen({super.key, required this.year});

  @override
  Widget build(BuildContext context) {
    final suffix = year.toString().substring(2);

    final numbers = [
      ...List.generate(99, (i) => '${301 + i}/$suffix'),
      ...List.generate(99, (i) => 'A${301 + i}/$suffix'),
      ...List.generate(20, (i) => 'KOORDYNACJA${i + 1}/$suffix'),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text('Rok $year'),
      ),
      body: ListView.builder(
        itemCount: numbers.length,
        itemBuilder: (context, index) {
          final number = numbers[index];

          return FutureBuilder<int>(
            future: AppDatabase.getEntriesCount(number),
            builder: (context, snapshot) {
              final count = snapshot.data ?? 0;

              return Card(
                margin: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                child: ListTile(
                  leading: Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: count > 0 ? Colors.green : Colors.red,
                      shape: BoxShape.circle,
                    ),
                  ),
                  title: Text(number),
                  subtitle: Text(
                    count > 0
                        ? 'Liczba wpisów: $count'
                        : 'Brak wpisów',
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => EntryScreen(number: number),
                      ),
                    );
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

  File? selectedImage;
  final picker = ImagePicker();

  List<Map<String, dynamic>> entries = [];

  @override
  void initState() {
    super.initState();
    loadEntries();
  }

Future<void> pickImage() async {
  final image = await picker.pickImage(
    source: ImageSource.gallery,
  );

  if (image == null) return;

  setState(() {
    selectedImage = File(image.path);
  });
}
void _editEntry(Map<String, dynamic> entry) {
  final editController = TextEditingController(text: entry['text']);

  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Edytuj notatkę'),
      content: TextField(
        controller: editController,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Anuluj'),
        ),
        ElevatedButton(
          onPressed: () async {
            final newText = editController.text.trim();
            if (newText.isEmpty) return;

            final db = await AppDatabase.database;

            await db.update(
              'entries',
              {'text': newText},
              where: 'id = ?',
              whereArgs: [entry['id']],
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
void _deleteEntry(Map<String, dynamic> entry) {
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
            await AppDatabase.deleteEntry(entry['id']);

            Navigator.pop(context);
            loadEntries();
          },
          child: const Text('Usuń'),
        ),
      ],
    ),
  );
}

  Future<void> loadEntries() async {
    final data = await AppDatabase.getEntries(widget.number);

    setState(() {
      entries = data;
    });
  }

  void addEntry() async {
    final text = controller.text.trim();
    if (text.isEmpty) return;

    final now = DateTime.now();
    final time =
        '${now.day}.${now.month}.${now.year} ${now.hour}:${now.minute.toString().padLeft(2, '0')}';

    await AppDatabase.insertEntry(widget.number, text, time);

    controller.clear();
    loadEntries();
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

        if (selectedImage != null)
          Padding(
            padding: const EdgeInsets.all(8),
            child: Image.file(File(entry['imagePath']))
              selectedImage!,
              height: 120,
            ),
          ),
        Expanded(
          child: ListView.builder(
            itemCount: entries.length,
            itemBuilder: (context, index) {
              final entry = entries[index];

              return ListTile(
                title: Text(entry['text'] ?? ''),
                subtitle: Text(entry['dateTime'] ?? ''),
                onTap: () {
                  _editEntry(entry);
                },
                onLongPress: () {
                  _deleteEntry(entry);
                },
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
                  decoration: const InputDecoration(
                    hintText: 'Nowy wpis...',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Column(
                children: [
                  IconButton(
                    onPressed: pickImage,
                    icon: const Icon(Icons.photo),
                  ),
                  ElevatedButton(
                    onPressed: addEntry,
                    child: const Text('Dodaj'),
                  ),
                ],
              ),
            ],
          )
        )
      ],
    ),
  );
}
}