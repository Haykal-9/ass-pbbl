import 'destination.dart';
import 'destination_photo.dart';

class GalleryFeedItem {
  final DestinationPhoto photo;
  final Destination destination;

  const GalleryFeedItem({
    required this.photo,
    required this.destination,
  });

  factory GalleryFeedItem.fromMap(Map<String, dynamic> map) {
    return GalleryFeedItem(
      photo: DestinationPhoto(
        id: map['gallery_photo_id'] as int?,
        destinationId: map['gallery_destination_id'] as int,
        photoPath: map['gallery_photo_path'] as String,
        caption: map['gallery_caption'] as String?,
        createdAt: map['gallery_created_at'] as String,
      ),
      destination: Destination.fromMap(map),
    );
  }
}
