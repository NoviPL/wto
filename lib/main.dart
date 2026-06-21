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
  Future<NumberStatus> getNumberStatus(String number) async {
    final count = await AppDatabase.getEntriesCount(number);
    final imagePath = await AppDatabase.getLastImagePath(number);

    return NumberStatus(
      count: count,
      imagePath: imagePath,
    );
  }

  @override
  Widget build(BuildContext context) {
    final suffix = widget.year.toString().substring(2);

    final numbers = [
      ...List.generate(99, (i) => '${301 + i}/$suffix'),
      ...List.generate(99, (i) => 'A${301 + i}/$suffix'),
      ...List.generate(20, (i) => 'KOORDYNACJA${i + 1}/$suffix'),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text('Rok ${widget.year}'),
      ),
      body: ListView.builder(
        itemCount: numbers.length,
        itemBuilder: (context, index) {
          final number = numbers[index];

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

                    setState(() {});
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

  Future<void> pickImage() async {
    final image = await picker.pickImage(
      source: ImageSource.gallery,
    );

    if (image == null) return;

    final appDir = await getApplicationDocumentsDirectory();

    final fileName =
        '${DateTime.now().millisecondsSinceEpoch}_${p.basename(image.path)}';

    final savedImage = await File(image.path).copy(
      '${appDir.path}/$fileName',
    );

    setState(() {
      selectedImage = savedImage;
    });
  }

  void addEntry() async {
    final text = controller.text.trim();

    if (text.isEmpty && selectedImage == null) return;

    final now = DateTime.now();

    final time =
        '${now.day}.${now.month}.${now.year} '
        '${now.hour}:${now.minute.toString().padLeft(2, '0')}';

    print('ZAPISYWANE ZDJECIE: ${selectedImage?.path}');

    await AppDatabase.insertEntry(
      widget.number,
      text.isEmpty ? 'Zdjecie' : text,
      time,
      selectedImage?.path,
    );

    controller.clear();

    setState(() {
      selectedImage = null;
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
          if (selectedImage != null)
            Padding(
              padding: const EdgeInsets.all(8),
              child: Image.file(
                selectedImage!,
                height: 120,
              ),
            ),

          Expanded(
            child: ListView.builder(
              itemCount: entries.length,
              itemBuilder: (context, index) {
                final entry = entries[index];
                final imagePath = entry['imagePath'] as String?;

                return Card(
                  elevation: 2,
                  margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(10)
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
                        : const Icon(Icons.description),

                    title: Text(
                      entry['text'] ?? '',
                      maxLines: 4,
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
                    
                    onTap: () {
                      if (imagePath != null && imagePath.isNotEmpty) {
                        final photos = imageEntries;
                        final initialIndex = photos.indexWhere(
                          (photo) => photo['id'] == entry['id']
                        );
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => FullScreenImage(
                              photos: photos,
                              initialIndex: initialIndex <0 ? 0 : initialIndex
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