import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/destination.dart';
import '../models/destination_photo.dart';
import '../models/gallery_feed_item.dart';
import '../services/app_locale.dart';
import '../services/database_helper.dart';
import '../services/session_service.dart';
import '../widgets/custom_snackbar.dart';
import '../widgets/social_gallery_post_card.dart';
import 'detail_screen.dart';

class SocialGalleryScreen extends StatefulWidget {
  const SocialGalleryScreen({super.key});

  @override
  State<SocialGalleryScreen> createState() => _SocialGalleryScreenState();
}

class _SocialGalleryScreenState extends State<SocialGalleryScreen> {
  final DatabaseHelper _db = DatabaseHelper();
  final ImagePicker _picker = ImagePicker();
  final SessionService _session = SessionService();

  List<GalleryFeedItem> _items = [];
  List<Destination> _destinations = [];
  Set<int> _likedPhotoIds = {};
  Map<int, int> _likeCounts = {};
  Map<int, List<String>> _comments = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadGallery();
  }

  Future<void> _loadGallery() async {
    setState(() => _isLoading = true);
    final items = await _db.getGalleryFeedItems();
    final destinations = await _db.getDestinations(sortBy: 'az');
    final prefs = await SharedPreferences.getInstance();

    final likedIds = <int>{};
    final likeCounts = <int, int>{};
    final comments = <int, List<String>>{};

    for (final item in items) {
      final id = item.photo.id;
      if (id == null) continue;

      if (prefs.getBool(_likedKey(id)) ?? false) likedIds.add(id);
      likeCounts[id] = prefs.getInt(_likeKey(id)) ?? _defaultLikeCount(id);
      comments[id] = prefs.getStringList(_commentsKey(id)) ?? _defaultComments(item);
    }

    if (mounted) {
      setState(() {
        _items = items;
        _destinations = destinations;
        _likedPhotoIds = likedIds;
        _likeCounts = likeCounts;
        _comments = comments;
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleLike(GalleryFeedItem item) async {
    final id = item.photo.id;
    if (id == null) return;

    final prefs = await SharedPreferences.getInstance();
    final isLiked = _likedPhotoIds.contains(id);
    final currentCount = _likeCounts[id] ?? _defaultLikeCount(id);
    final nextCount = isLiked
        ? (currentCount - 1).clamp(0, 999999).toInt()
        : currentCount + 1;

    setState(() {
      if (isLiked) {
        _likedPhotoIds.remove(id);
      } else {
        _likedPhotoIds.add(id);
      }
      _likeCounts[id] = nextCount;
    });

    await prefs.setBool(_likedKey(id), !isLiked);
    await prefs.setInt(_likeKey(id), nextCount);
  }

  Future<void> _addComment(GalleryFeedItem item) async {
    final id = item.photo.id;
    if (id == null) return;

    final controller = TextEditingController();
    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Tambah Komentar',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: controller,
                autofocus: true,
                maxLines: 3,
                maxLength: 120,
                decoration: const InputDecoration(
                  labelText: 'Komentar',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton.icon(
                  onPressed: () => Navigator.pop(context, controller.text.trim()),
                  icon: const Icon(Icons.send),
                  label: const Text('Kirim'),
                ),
              ),
            ],
          ),
        );
      },
    );

    if (result == null || result.isEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    final nextComments = [
      ...(_comments[id] ?? _defaultComments(item)),
      'Ray: $result',
    ];

    setState(() => _comments[id] = nextComments);
    await prefs.setStringList(_commentsKey(id), nextComments);
  }

  Future<void> _sharePost(GalleryFeedItem item) async {
    final caption = (item.photo.caption ?? '').trim();
    final text = [
      'WanderList Memory',
      trName(item.destination.name),
      if (caption.isNotEmpty) caption,
      item.photo.photoPath,
    ].join('\n');

    await Clipboard.setData(ClipboardData(text: text));
    if (mounted) {
      showSuccessSnackbar(
        context,
        'Konten share disalin ke clipboard',
        icon: Icons.ios_share,
      );
    }
  }

  Future<void> _editCaption(GalleryFeedItem item) async {
    final controller = TextEditingController(text: item.photo.caption ?? '');
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Caption'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLines: 3,
          maxLength: 80,
          decoration: const InputDecoration(
            labelText: 'Caption',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(tr('cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: Text(tr('save')),
          ),
        ],
      ),
    );

    if (result == null) return;
    await _db.updateDestinationPhoto(
      item.photo.copyWith(caption: result.isEmpty ? 'Memori perjalanan' : result),
    );
    await _loadGallery();
  }

  Future<void> _deletePhoto(GalleryFeedItem item) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Foto'),
        content: Text(
          'Hapus foto dari ${trName(item.destination.name)}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(tr('cancel')),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: Text(tr('delete')),
          ),
        ],
      ),
    );

    if (confirm != true || item.photo.id == null) return;
    await _db.deleteDestinationPhoto(item.photo.id!);
    await _loadGallery();
  }

  Future<void> _openDetail(GalleryFeedItem item) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DetailScreen(destination: item.destination),
      ),
    );
    await _loadGallery();
  }

  Future<void> _addPhoto() async {
    if (_destinations.isEmpty) {
      showErrorSnackbar(context, 'Belum ada destinasi untuk diberi foto');
      return;
    }

    Destination selectedDestination = _destinations.first;
    final captionController = TextEditingController();

    final result = await showModalBottomSheet<_NewPhotoDraft>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tambah Foto ke Feed',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<int>(
                    value: selectedDestination.id,
                    decoration: const InputDecoration(
                      labelText: 'Destinasi',
                      border: OutlineInputBorder(),
                    ),
                    items: _destinations
                        .where((destination) => destination.id != null)
                        .map(
                          (destination) => DropdownMenuItem<int>(
                            value: destination.id,
                            child: Text(
                              trName(destination.name),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (id) {
                      if (id == null) return;
                      setModalState(() {
                        selectedDestination = _destinations.firstWhere(
                          (destination) => destination.id == id,
                        );
                      });
                    },
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: captionController,
                    maxLines: 2,
                    maxLength: 80,
                    decoration: const InputDecoration(
                      labelText: 'Caption',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () async {
                        final picked = await _picker.pickImage(
                          source: ImageSource.gallery,
                        );
                        if (picked == null || !context.mounted) return;
                        final photoPath = await _persistPickedPhoto(picked);
                        if (!context.mounted) return;
                        Navigator.pop(
                          context,
                          _NewPhotoDraft(
                            destination: selectedDestination,
                            photoPath: photoPath,
                            caption: captionController.text.trim(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.add_photo_alternate_outlined),
                      label: const Text('Pilih Foto & Simpan'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    if (result == null || result.destination.id == null) return;
    final currentUserId = await _session.getCurrentUserId() ?? 1;

    await _db.insertDestinationPhoto(
      DestinationPhoto(
        destinationId: result.destination.id!,
        photoPath: result.photoPath,
        authorUserId: currentUserId,
        caption: result.caption.isEmpty ? 'Memori perjalanan' : result.caption,
        createdAt: DateTime.now().toIso8601String(),
      ),
    );
    await _loadGallery();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Stack(
      children: [
        RefreshIndicator(
          onRefresh: _loadGallery,
          child: _items.isEmpty ? _emptyState() : _feedList(),
        ),
        Positioned(
          right: 16,
          bottom: 16,
          child: FloatingActionButton.extended(
            onPressed: _addPhoto,
            icon: const Icon(Icons.add_a_photo_outlined),
            label: const Text('Tambah Foto'),
          ),
        ),
      ],
    );
  }

  Widget _feedList() {
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 96),
      itemCount: _items.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) return _header();

        final item = _items[index - 1];
        final id = item.photo.id ?? -1;
        return SocialGalleryPostCard(
          destination: item.destination,
          photo: item.photo,
          authorDisplayName: item.authorDisplayName,
          authorUsername: item.authorUsername,
          authorAvatarPath: item.authorAvatarPath,
          isLiked: _likedPhotoIds.contains(id),
          likeCount: _likeCounts[id] ?? _defaultLikeCount(id),
          comments: _comments[id] ?? _defaultComments(item),
          locationLabel: trCountry(item.destination.country),
          onLike: () => _toggleLike(item),
          onComment: () => _addComment(item),
          onShare: () => _sharePost(item),
          onEditCaption: () => _editCaption(item),
          onDelete: () => _deletePhoto(item),
          onOpenDetail: () => _openDetail(item),
        );
      },
    );
  }

  Widget _header() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Memori dari semua destinasi',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
          TextButton.icon(
            onPressed: _loadGallery,
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('Refresh'),
          ),
        ],
      ),
    );
  }

  Widget _emptyState() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 80, 24, 120),
      children: [
        Icon(
          Icons.photo_library_outlined,
          size: 76,
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.45),
        ),
        const SizedBox(height: 18),
        Text(
          'Belum ada foto di galeri',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          'Tambahkan foto dari destinasi untuk membuat feed memori perjalanan.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.62),
          ),
        ),
      ],
    );
  }

  int _defaultLikeCount(int photoId) => 8 + (photoId.abs() % 31);

  Future<String> _persistPickedPhoto(XFile picked) async {
    if (kIsWeb) return picked.path;

    final appDir = await getApplicationDocumentsDirectory();
    final photosDir = Directory(p.join(appDir.path, 'gallery_photos'));
    await photosDir.create(recursive: true);

    final extension = p.extension(picked.path);
    final fileName =
        'gallery_${DateTime.now().microsecondsSinceEpoch}${extension.isEmpty ? '.jpg' : extension}';
    final destinationPath = p.join(photosDir.path, fileName);
    await File(picked.path).copy(destinationPath);
    return destinationPath;
  }

  List<String> _defaultComments(GalleryFeedItem item) {
    return [
      'WanderBot: Tempat ini masuk bucket list!',
      'Traveler: Caption-nya bikin pengen berangkat.',
    ];
  }

  String _likedKey(int id) => 'gallery_social_liked_$id';
  String _likeKey(int id) => 'gallery_social_likes_$id';
  String _commentsKey(int id) => 'gallery_social_comments_$id';
}

class _NewPhotoDraft {
  final Destination destination;
  final String photoPath;
  final String caption;

  const _NewPhotoDraft({
    required this.destination,
    required this.photoPath,
    required this.caption,
  });
}
