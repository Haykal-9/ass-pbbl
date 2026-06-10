import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/destination.dart';
import '../models/destination_photo.dart';
import '../services/app_locale.dart';
import '../services/database_helper.dart';
import '../widgets/polaroid_deck_gallery.dart';

class GalleryScreen extends StatefulWidget {
  final Destination destination;

  const GalleryScreen({super.key, required this.destination});

  @override
  State<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends State<GalleryScreen> {
  final dbHelper = DatabaseHelper();
  List<DestinationPhoto> _photos = [];
  bool _isLoading = true;
  String _bgType = 'wood';
  String _decoType = 'tape';

  @override
  void initState() {
    super.initState();
    _loadPrefs();
    _loadPhotos();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _bgType = prefs.getString('gallery_bg_type') ?? 'wood';
      _decoType = prefs.getString('gallery_deco_type') ?? 'tape';
    });
  }

  Future<void> _changeBgType(String type) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('gallery_bg_type', type);
    setState(() => _bgType = type);
  }

  Future<void> _changeDecoType(String type) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('gallery_deco_type', type);
    setState(() => _decoType = type);
  }

  Future<void> _loadPhotos() async {
    setState(() => _isLoading = true);
    final photos = await dbHelper.getDestinationPhotos(widget.destination.id!);
    setState(() {
      _photos = photos;
      _isLoading = false;
    });
  }

  Future<void> _addPhoto() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    
    if (pickedFile != null) {
      // Tampilkan dialog untuk mengisi caption
      if (!mounted) return;
      final captionController = TextEditingController();
      
      final result = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Tambah Memori'),
          content: TextField(
            controller: captionController,
            decoration: const InputDecoration(
              hintText: 'Tulis kenangan di balik foto ini...',
              border: OutlineInputBorder(),
            ),
            maxLength: 50,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, captionController.text),
              child: const Text('Simpan'),
            ),
          ],
        ),
      );

      if (result != null) {
        final newPhoto = DestinationPhoto(
          destinationId: widget.destination.id!,
          photoPath: pickedFile.path,
          caption: result.isEmpty ? 'Memori Indah' : result,
          createdAt: DateTime.now().toIso8601String(),
        );
        
        await dbHelper.insertDestinationPhoto(newPhoto);
        _loadPhotos();
      }
    }
  }

  void _onDeckEmpty() {
    // Dipanggil saat kartu terakhir dilempar
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Semua memori telah dilihat!'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Galeri ${trName(widget.destination.name)}',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        foregroundColor: Theme.of(context).colorScheme.primary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadPhotos,
            tooltip: 'Ulangi Tumpukan',
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.settings),
            tooltip: 'Pengaturan Tampilan',
            onSelected: (value) {
              if (value.startsWith('bg_')) _changeBgType(value.substring(3));
              if (value.startsWith('deco_')) _changeDecoType(value.substring(5));
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                enabled: false,
                child: Text('Latar Belakang', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              PopupMenuItem(
                value: 'bg_wood',
                child: Row(
                  children: [
                    Icon(Icons.check, color: _bgType == 'wood' ? Colors.green : Colors.transparent),
                    const SizedBox(width: 8),
                    const Text('Meja Kayu'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'bg_corkboard',
                child: Row(
                  children: [
                    Icon(Icons.check, color: _bgType == 'corkboard' ? Colors.green : Colors.transparent),
                    const SizedBox(width: 8),
                    const Text('Papan Gabus (Cork)'),
                  ],
                ),
              ),
              const PopupMenuItem(
                enabled: false,
                child: Text('Dekorasi Kartu', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              PopupMenuItem(
                value: 'deco_tape',
                child: Row(
                  children: [
                    Icon(Icons.check, color: _decoType == 'tape' ? Colors.green : Colors.transparent),
                    const SizedBox(width: 8),
                    const Text('Selotip (Washi Tape)'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'deco_pin',
                child: Row(
                  children: [
                    Icon(Icons.check, color: _decoType == 'pin' ? Colors.green : Colors.transparent),
                    const SizedBox(width: 8),
                    const Text('Jarum Pin (Push Pin)'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Container(
        // Background dengan pola kayu atau meja untuk menonjolkan polaroid
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          image: DecorationImage(
            image: NetworkImage(
              _bgType == 'wood' 
                ? 'https://www.transparenttextures.com/patterns/wood-pattern.png'
                : 'https://www.transparenttextures.com/patterns/cork-board.png'
            ),
            repeat: ImageRepeat.repeat,
            colorFilter: ColorFilter.mode(
              Theme.of(context).colorScheme.surface.withValues(alpha: _bgType == 'wood' ? 0.9 : 0.8), 
              BlendMode.dstATop,
            ),
          ),
        ),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : PolaroidDeckGallery(
                photos: _photos,
                onDeckEmpty: _onDeckEmpty,
                decoType: _decoType,
              ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addPhoto,
        icon: const Icon(Icons.add_a_photo),
        label: const Text('Tambah Memori'),
      ),
    );
  }
}
