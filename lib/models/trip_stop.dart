class TripStop {
  final int? id;
  final int destinationId;
  final int dayNumber;
  final int orderIndex;
  final String placeName;
  final String? placeAddress;
  final double? latitude;
  final double? longitude;
  final String? photoUrl;
  final String? openingHours;
  final String? description;
  final String? otmXid;
  final String? visitTime;
  final int estimatedDurationMinutes;
  final String transportMode;
  final double? distanceMeters;
  final int? travelMinutes;
  final String createdAt;

  const TripStop({
    this.id,
    required this.destinationId,
    this.dayNumber = 1,
    this.orderIndex = 0,
    required this.placeName,
    this.placeAddress,
    this.latitude,
    this.longitude,
    this.photoUrl,
    this.openingHours,
    this.description,
    this.otmXid,
    this.visitTime,
    this.estimatedDurationMinutes = 60,
    this.transportMode = 'walk',
    this.distanceMeters,
    this.travelMinutes,
    required this.createdAt,
  });

  factory TripStop.fromMap(Map<String, dynamic> map) => TripStop(
        id: map['id'] as int?,
        destinationId: map['destination_id'] as int,
        dayNumber: map['day_number'] as int? ?? 1,
        orderIndex: map['order_index'] as int? ?? 0,
        placeName: map['place_name'] as String,
        placeAddress: map['place_address'] as String?,
        latitude: (map['latitude'] as num?)?.toDouble(),
        longitude: (map['longitude'] as num?)?.toDouble(),
        photoUrl: map['photo_url'] as String?,
        openingHours: map['opening_hours'] as String?,
        description: map['description'] as String?,
        otmXid: map['otm_xid'] as String?,
        visitTime: map['visit_time'] as String?,
        estimatedDurationMinutes:
            map['estimated_duration_minutes'] as int? ?? 60,
        transportMode: map['transport_mode'] as String? ?? 'walk',
        distanceMeters: (map['distance_meters'] as num?)?.toDouble(),
        travelMinutes: map['travel_minutes'] as int?,
        createdAt: map['created_at'] as String,
      );

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'destination_id': destinationId,
        'day_number': dayNumber,
        'order_index': orderIndex,
        'place_name': placeName,
        'place_address': placeAddress,
        'latitude': latitude,
        'longitude': longitude,
        'photo_url': photoUrl,
        'opening_hours': openingHours,
        'description': description,
        'otm_xid': otmXid,
        'visit_time': visitTime,
        'estimated_duration_minutes': estimatedDurationMinutes,
        'transport_mode': transportMode,
        'distance_meters': distanceMeters,
        'travel_minutes': travelMinutes,
        'created_at': createdAt,
      };

  TripStop copyWith({
    int? id,
    int? destinationId,
    int? dayNumber,
    int? orderIndex,
    String? placeName,
    String? placeAddress,
    double? latitude,
    double? longitude,
    String? photoUrl,
    String? openingHours,
    String? description,
    String? otmXid,
    String? visitTime,
    int? estimatedDurationMinutes,
    String? transportMode,
    double? distanceMeters,
    int? travelMinutes,
    String? createdAt,
  }) =>
      TripStop(
        id: id ?? this.id,
        destinationId: destinationId ?? this.destinationId,
        dayNumber: dayNumber ?? this.dayNumber,
        orderIndex: orderIndex ?? this.orderIndex,
        placeName: placeName ?? this.placeName,
        placeAddress: placeAddress ?? this.placeAddress,
        latitude: latitude ?? this.latitude,
        longitude: longitude ?? this.longitude,
        photoUrl: photoUrl ?? this.photoUrl,
        openingHours: openingHours ?? this.openingHours,
        description: description ?? this.description,
        otmXid: otmXid ?? this.otmXid,
        visitTime: visitTime ?? this.visitTime,
        estimatedDurationMinutes:
            estimatedDurationMinutes ?? this.estimatedDurationMinutes,
        transportMode: transportMode ?? this.transportMode,
        distanceMeters: distanceMeters ?? this.distanceMeters,
        travelMinutes: travelMinutes ?? this.travelMinutes,
        createdAt: createdAt ?? this.createdAt,
      );
}
