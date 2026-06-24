import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../models/destination.dart';
import '../models/destination_photo.dart';
import '../services/app_locale.dart';
import 'category_chip.dart';

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
                _photoImage(context),
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
                _iconAction(
                  icon: isLiked ? Icons.favorite : Icons.favorite_border,
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
            backgroundImage: hasAvatar ? FileImage(File(avatarPath!)) : null,
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
