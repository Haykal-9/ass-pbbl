class Destination {
  final int? id;
  final String name;
  final String country;
  final String category; // pantai | kota | gunung | alam
  final String status; // wishlist | visited
  final String notes;
  final String? photoPath;
  final String? visitedAt;
  final String createdAt;

  const Destination({
    this.id,
    required this.name,
    required this.country,
    required this.category,
    required this.status,
    required this.notes,
    this.photoPath,
    this.visitedAt,
    required this.createdAt,
  });

  factory Destination.fromMap(Map<String, dynamic> map) => Destination(
        id: map['id'] as int?,
        name: map['name'] as String,
        country: map['country'] as String,
        category: map['category'] as String,
        status: map['status'] as String,
        notes: map['notes'] as String,
        photoPath: map['photo_path'] as String?,
        visitedAt: map['visited_at'] as String?,
        createdAt: map['created_at'] as String,
      );

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'name': name,
        'country': country,
        'category': category,
        'status': status,
        'notes': notes,
        'photo_path': photoPath,
        'visited_at': visitedAt,
        'created_at': createdAt,
      };

  Destination copyWith({
    int? id,
    String? name,
    String? country,
    String? category,
    String? status,
    String? notes,
    String? photoPath,
    String? visitedAt,
    String? createdAt,
  }) =>
      Destination(
        id: id ?? this.id,
        name: name ?? this.name,
        country: country ?? this.country,
        category: category ?? this.category,
        status: status ?? this.status,
        notes: notes ?? this.notes,
        photoPath: photoPath ?? this.photoPath,
        visitedAt: visitedAt ?? this.visitedAt,
        createdAt: createdAt ?? this.createdAt,
      );
}
