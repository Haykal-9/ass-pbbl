class DestinationPhoto {
  final int? id;
  final int destinationId;
  final String photoPath;
  final String? caption;
  final String createdAt;

  DestinationPhoto({
    this.id,
    required this.destinationId,
    required this.photoPath,
    this.caption,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'destination_id': destinationId,
      'photo_path': photoPath,
      'caption': caption,
      'created_at': createdAt,
    };
  }

  factory DestinationPhoto.fromMap(Map<String, dynamic> map) {
    return DestinationPhoto(
      id: map['id'] as int?,
      destinationId: map['destination_id'] as int,
      photoPath: map['photo_path'] as String,
      caption: map['caption'] as String?,
      createdAt: map['created_at'] as String,
    );
  }
}
