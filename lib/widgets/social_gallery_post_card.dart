import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../models/destination.dart';
import '../models/destination_photo.dart';
import '../services/app_locale.dart';
import 'category_chip.dart';
import 'polaroid_painters.dart'; // Impor custom painter

class SocialGalleryPostCard extends StatelessWidget {
  final Destination destination;
  final DestinationPhoto photo;
  final String authorDisplayName;
  final String authorUsername;
  final String? authorAvatarPath;
  final String locationLabel;
  final bool isLiked;
  final int likeCount;
  final List<String> comments;
  final VoidCallback onLike;
  final VoidCallback onComment;
  final VoidCallback onShare;
  final VoidCallback onEditCaption;
  final VoidCallback onDelete;
  final VoidCallback onOpenDetail;

  const SocialGalleryPostCard({
    super.key,
    required this.destination,
    required this.photo,
    required this.authorDisplayName,
    required this.authorUsername,
    required this.authorAvatarPath,
    required this.locationLabel,
    required this.isLiked,
    required this.likeCount,
    required this.comments,
    required this.onLike,
    required this.onComment,
    required this.onShare,
    required this.onEditCaption,
    required this.onDelete,
    required this.onOpenDetail,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Author row — DI ATAS foto, bukan overlay
          _buildAuthorRow(context),
          AspectRatio(
            aspectRatio: 1,
            child: Stack(
              fit: StackFit.expand,
              children: [
                _DoubleTapLikeOverlay(
                  isLiked: isLiked,
                  onLike: onLike,
                  child: _photoImage(context),
                ),
                // Custom Drawing: Washi Tape di atas gambar
                Positioned(
                  top: -10,
                  left: 0,
                  right: 0,
                  child: IgnorePointer(
                    child: SizedBox(
                      height: 40,
                      child: CustomPaint(
                        painter: WashiTapePainter(),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 12,
                  right: 12,
                  bottom: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.32),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.place, color: Colors.white.withValues(alpha: 0.95), size: 18),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            locationLabel,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 6),
            child: Wrap(
              spacing: 14,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                _customLikeAction(
                  isLiked: isLiked,
                  label: '$likeCount',
                  color: isLiked ? Colors.red : colorScheme.onSurface,
                  onPressed: onLike,
                ),
                const SizedBox(width: 14),
                _iconAction(
                  icon: Icons.chat_bubble_outline,
                  label: '${comments.length}',
                  color: colorScheme.onSurface,
                  onPressed: onComment,
                ),
                const SizedBox(width: 14),
                _iconAction(
                  icon: Icons.ios_share,
                  label: 'Share',
                  color: colorScheme.onSurface,
                  onPressed: onShare,
                ),
                CategoryChip(destination.category),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 4, 14, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if ((photo.caption ?? '').trim().isNotEmpty)
                  RichText(
                    text: TextSpan(
                      style: Theme.of(context).textTheme.bodyMedium,
                      children: [
                        TextSpan(
                          text: '${trName(destination.name)} ',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        TextSpan(text: photo.caption!.trim()),
                      ],
                    ),
                  ),
                if (comments.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    comments.length == 1
                        ? '1 komentar'
                        : 'Lihat ${comments.length} komentar',
                    style: TextStyle(
                      color: colorScheme.onSurface.withValues(alpha: 0.58),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  for (final comment in comments.take(2))
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        comment,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
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

  Widget _photoImage(BuildContext context) {
    final path = photo.photoPath;
    if (path.startsWith('http')) {
      return Image.network(
        path,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _imagePlaceholder(context),
      );
    }

    if (!kIsWeb) {
      final file = File(path);
      if (file.existsSync()) {
        return Image.file(
          file,
          fit: BoxFit.cover,
          cacheWidth: 800, // Mengatasi lag dengan me-resize decoding gambar besar
          errorBuilder: (_, __, ___) => _imagePlaceholder(context),
        );
      }
    }

    return _imagePlaceholder(context);
  }

  Widget _buildAuthorRow(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final avatarPath = authorAvatarPath;
    final hasAvatar = avatarPath != null && avatarPath.isNotEmpty && !kIsWeb && File(avatarPath).existsSync();

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 4, 10),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: colorScheme.primary.withValues(alpha: 0.15),
            backgroundImage: hasAvatar ? ResizeImage(FileImage(File(avatarPath!)), width: 100) : null,
            child: hasAvatar
                ? null
                : Text(
                    authorDisplayName.isNotEmpty ? authorDisplayName[0].toUpperCase() : 'W',
                    style: TextStyle(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              authorUsername,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: colorScheme.onSurface,
              ),
            ),
          ),
          // Popup menu pindah ke author row
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'detail') onOpenDetail();
              if (value == 'edit') onEditCaption();
              if (value == 'delete') onDelete();
            },
            icon: Icon(
              Icons.more_vert,
              color: colorScheme.onSurface.withValues(alpha: 0.6),
            ),
            color: Theme.of(context).colorScheme.surface,
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'detail',
                child: ListTile(
                  dense: true,
                  leading: Icon(Icons.open_in_new),
                  title: Text('Buka Detail'),
                ),
              ),
              const PopupMenuItem(
                value: 'edit',
                child: ListTile(
                  dense: true,
                  leading: Icon(Icons.edit),
                  title: Text('Edit Caption'),
                ),
              ),
              PopupMenuItem(
                value: 'delete',
                child: ListTile(
                  dense: true,
                  leading: Icon(Icons.delete_outline, color: colorScheme.error),
                  title: Text(
                    'Hapus Foto',
                    style: TextStyle(color: colorScheme.error),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _imagePlaceholder(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      color: colorScheme.primary.withValues(alpha: 0.08),
      child: Icon(
        Icons.image_not_supported_outlined,
        color: colorScheme.onSurface.withValues(alpha: 0.35),
        size: 52,
      ),
    );
  }

  Widget _customLikeAction({
    required bool isLiked,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onPressed,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 24,
              height: 24,
              child: CustomPaint(
                painter: HeartPainter(isFilled: isLiked, color: color),
              ),
            ),
            const SizedBox(width: 5),
            Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Widget _iconAction({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onPressed,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(width: 5),
            Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

class _DoubleTapLikeOverlay extends StatefulWidget {
  final Widget child;
  final bool isLiked;
  final VoidCallback onLike;

  const _DoubleTapLikeOverlay({
    required this.child,
    required this.isLiked,
    required this.onLike,
  });

  @override
  State<_DoubleTapLikeOverlay> createState() => _DoubleTapLikeOverlayState();
}

class _DoubleTapLikeOverlayState extends State<_DoubleTapLikeOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;
  bool _showHeart = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    // Animasi goyang / membesar lalu mengecil sedikit (Bouncy)
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.2).chain(CurveTween(curve: Curves.elasticOut)), weight: 60),
      TweenSequenceItem(tween: Tween(begin: 1.2, end: 1.0).chain(CurveTween(curve: Curves.easeInOut)), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.0), weight: 20), // Tahan sebentar
    ]).animate(_controller);

    // Animasi muncul lalu memudar
    _opacityAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0).chain(CurveTween(curve: Curves.easeIn)), weight: 10),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.0), weight: 60), // Tahan opasitas penuh
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0).chain(CurveTween(curve: Curves.easeOut)), weight: 30),
    ]).animate(_controller);

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() => _showHeart = false);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleDoubleTap() {
    // Jalankan callback like kalau belum dilike
    if (!widget.isLiked) {
      widget.onLike();
    }
    
    // Tampilkan animasi goyang hati (kalau di-spam akan restart animasinya)
    setState(() {
      _showHeart = true;
    });
    _controller.forward(from: 0.0);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onDoubleTap: _handleDoubleTap,
      child: Stack(
        fit: StackFit.expand,
        alignment: Alignment.center,
        children: [
          widget.child,
          if (_showHeart)
            Center(
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return Opacity(
                    opacity: _opacityAnimation.value,
                    child: Transform.scale(
                      scale: _scaleAnimation.value,
                      child: child,
                    ),
                  );
                },
                child: SizedBox(
                  width: 120,
                  height: 120,
                  child: CustomPaint(
                    painter: HeartPainter(isFilled: true, color: Colors.white.withValues(alpha: 0.85)),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
