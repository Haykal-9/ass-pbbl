class Destination {
  final int? id;
  final String name;
  final String country;
  final String category; // Wisata Alam | Budaya & Sejarah | Kota & Urban
  final String status; // wishlist | in_trip | visited
  final String notes;
  final String? photoPath;
  final String? visitedAt;
  final String? startDate; // Trip start date (YYYY-MM-DD)
  final String? endDate; // Trip end date (YYYY-MM-DD)
  final double? latitude;
  final double? longitude;
  final String createdAt;
  final int checklistTotal;
  final int checklistDone;

  const Destination({
    this.id,
    required this.name,
    required this.country,
    required this.category,
    required this.status,
    required this.notes,
    this.photoPath,
    this.visitedAt,
    this.startDate,
    this.endDate,
    this.latitude,
    this.longitude,
    required this.createdAt,
    this.checklistTotal = 0,
    this.checklistDone = 0,
  });

  /// Number of days in the trip (derived from startDate/endDate).
  int get tripDays {
    if (startDate == null || endDate == null) return 0;
    try {
      final start = DateTime.parse(startDate!);
      final end = DateTime.parse(endDate!);
      return end.difference(start).inDays + 1;
    } catch (_) {
      return 0;
    }
  }

  factory Destination.fromMap(Map<String, dynamic> map) => Destination(
        id: map['id'] as int?,
        name: map['name'] as String,
        country: map['country'] as String,
        category: map['category'] as String,
        status: map['status'] as String,
        notes: map['notes'] as String,
        photoPath: map['photo_path'] as String?,
        visitedAt: map['visited_at'] as String?,
        startDate: map['start_date'] as String?,
        endDate: map['end_date'] as String?,
        latitude: (map['latitude'] as num?)?.toDouble(),
        longitude: (map['longitude'] as num?)?.toDouble(),
        createdAt: map['created_at'] as String,
        checklistTotal: map['checklist_total'] as int? ?? 0,
        checklistDone: map['checklist_done'] as int? ?? 0,
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
        'start_date': startDate,
        'end_date': endDate,
        'latitude': latitude,
        'longitude': longitude,
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
    String? startDate,
    String? endDate,
    double? latitude,
    double? longitude,
    String? createdAt,
    int? checklistTotal,
    int? checklistDone,
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
        startDate: startDate ?? this.startDate,
        endDate: endDate ?? this.endDate,
        latitude: latitude ?? this.latitude,
        longitude: longitude ?? this.longitude,
        createdAt: createdAt ?? this.createdAt,
        checklistTotal: checklistTotal ?? this.checklistTotal,
        checklistDone: checklistDone ?? this.checklistDone,
      );
}
