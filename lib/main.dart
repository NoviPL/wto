import 'package:flutter/material.dart';
import 'db/database.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:gal/gal.dart';
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
      home: const MainMenuScreen(),
    );
  }
}

class MainMenuScreen extends StatelessWidget {
  const MainMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                    title: 'KOMUNIKATY',
                    icon: Icons.campaign,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const MessagesScreen(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  _MainMenuButton(
                    title: 'INNE',
                    icon: Icons.more_horiz,
                    onTap: () {},
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

  @override
  void initState() {
    super.initState();
    loadYears();
  }

  Future<void> loadYears() async {
    final data = await AppDatabase.getYears();

    if (!mounted) return;

    setState(() {
      years = data;
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddYearDialog,
        icon: const Icon(Icons.add),
        label: const Text('Dodaj rok'),
      ),
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
                              borderRadius: BorderRadius.circular(16),
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

class MessagesScreen extends StatelessWidget {
  const MessagesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Komunikaty'),
      ),
      body: const Center(
        child: Text(
          'Tu będą komunikaty jak Jaroslaw ogarnie',
          style: TextStyle(fontSize: 22),
        ),
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
            : 'Zdjęcie ${i + 1}',
        time,
        savedImage.path,
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
      );
    } else {
      for (int i = 0; i < selectedImages.length; i++) {
        await AppDatabase.insertEntry(
          widget.number,
          'WPIS',
          i == 0 && text.isNotEmpty ? text : 'Zdjecie',
          time,
          selectedImages[i].path,
        );
      }
    }

    controller.clear();

    setState(() {
      selectedImages.clear();
    });

    loadEntries();
  }

  void _editEntry(Map<String, dynamic> entry) {
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

              final db = await AppDatabase.database;

              await db.update(
                'entries',
                {
                  'text': newText,
                },
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
            child: ListView.builder(
              itemCount: entries.length,
              itemBuilder: (context, index) {
                final entry = entries[index];
                final imagePath = entry['imagePath'] as String?;
                final category = entry['category']?.toString() ?? 'WPIS';
                final isMainCategory = category != 'WPIS';

                Color categoryColor(String category) {
                  switch (category) {
                    case 'DANE':
                      return Colors.grey.shade300;
                    case 'ADRES':
                      return Colors.grey.shade400;
                    case 'KOŁA':
                      return Colors.grey.shade500;
                    case 'KONT.':
                      return Colors.grey.shade600;
                    case 'ZADANIA':
                      return Colors.grey.shade700;
                    default:
                      return Colors.grey.shade200;
                  }
                }
                return Card(
                  color: isMainCategory ? Colors.grey.shade500 : Colors.white,
                  elevation: 2,
                  margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(10),
                    leading: imagePath != null && imagePath.isNotEmpty
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.file(
                              File(imagePath),
                              width: 60,
                              height: 60,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return const Icon(Icons.broken_image);
                              },
                            ),
                          )
                        : Container(
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
                                color: category == 'ZADANIA' || category == 'KONTAKTY'
                                    ? Colors.white
                                    : Colors.black,
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
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        entry['dateTime'] ?? '',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                    
                    trailing: imagePath != null && imagePath.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.edit),
                            onPressed: () {
                              _editEntry(entry);
                            },
                          )
                        : null,

                    onTap: () {
                      if (imagePath != null && imagePath.isNotEmpty) {
                        final photos = imageEntries;

                        final initialIndex = photos.indexWhere(
                          (photo) => photo['id'] == entry['id'],
                        );

                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => FullScreenImage(
                              photos: photos,
                              initialIndex: initialIndex < 0 ? 0 : initialIndex,
                            ),
                          ),
                        );
                      } else {
                        _editEntry(entry);
                      }
                    },
                  onLongPress: () {
                    _deleteEntry(entry);
                  },
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
      width: 155,
      height: 82,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: isDone ? Colors.grey.shade700 : Colors.grey.shade300,
            borderRadius: BorderRadius.circular(16),
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