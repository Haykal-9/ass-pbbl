import 'destination.dart';
import 'destination_photo.dart';

class GalleryFeedItem {
  final DestinationPhoto photo;
  final Destination destination;
  final int? authorId;
  final String authorDisplayName;
  final String authorUsername;
  final String? authorAvatarPath;

  const GalleryFeedItem({
    required this.photo,
    required this.destination,
    required this.authorId,
    required this.authorDisplayName,
    required this.authorUsername,
    required this.authorAvatarPath,
  });

  factory GalleryFeedItem.fromMap(Map<String, dynamic> map) {
    return GalleryFeedItem(
      photo: DestinationPhoto(
        id: map['gallery_photo_id'] as int?,
        destinationId: map['gallery_destination_id'] as int,
        photoPath: map['gallery_photo_path'] as String,
        authorUserId: map['gallery_author_user_id'] as int?,
        caption: map['gallery_caption'] as String?,
        createdAt: map['gallery_created_at'] as String,
      ),
      destination: Destination.fromMap(map),
      authorId: map['gallery_author_id'] as int?,
      authorDisplayName:
          map['gallery_author_display_name'] as String? ?? 'WanderList User',
      authorUsername:
          map['gallery_author_username'] as String? ?? 'wanderlist',
      authorAvatarPath: map['gallery_author_avatar_path'] as String?,
    );
  }
}
