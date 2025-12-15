class SavedPlace {
  final String id; // Maps to _id
  final String label; // home, work, other
  final String displayName; // e.g. "Home" or "My Gym"
  final String address;
  final double lat;
  final double lng;
  final String? icon; // e.g. "🏠"
  final String? city;
  final String? state;

  SavedPlace({
    required this.id,
    required this.label,
    required this.displayName,
    required this.address,
    required this.lat,
    required this.lng,
    this.icon,
    this.city,
    this.state,
  });

  // For sending to API (Update)
  Map<String, dynamic> toUpdateJson() => {
    'label': label,
    'address': address,
    'coordinates': [lng, lat], // Note: API expects [lng, lat]
    'city': city,
    'state': state,
    // Add customName if label is 'other' (logic handled in controller)
  };

  factory SavedPlace.fromJson(Map<String, dynamic> json) {
    // Parse coordinates: [longitude, latitude]
    double parsedLat = 0.0;
    double parsedLng = 0.0;

    if (json['coordinates'] is List && json['coordinates'].length >= 2) {
      parsedLng = (json['coordinates'][0] as num).toDouble();
      parsedLat = (json['coordinates'][1] as num).toDouble();
    }

    return SavedPlace(
      id: json['_id'] ?? '',
      label: json['label'] ?? 'other',
      displayName: json['displayName'] ?? json['label'] ?? 'Place',
      address: json['address'] ?? '',
      lat: parsedLat,
      lng: parsedLng,
      icon: json['icon'],
      city: json['city'],
      state: json['state'],
    );
  }
}
