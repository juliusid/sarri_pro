class SavedPlace {
  final String id;
  final String label; // e.g., Home, Work
  final String address;
  final double lat;
  final double lng;

  SavedPlace({required this.id, required this.label, required this.address, required this.lat, required this.lng});

  Map<String, dynamic> toJson() => {
        'id': id,
        'label': label,
        'address': address,
        'lat': lat,
        'lng': lng,
      };

  factory SavedPlace.fromJson(Map<String, dynamic> json) => SavedPlace(
        id: json['id'],
        label: json['label'],
        address: json['address'],
        lat: (json['lat'] as num).toDouble(),
        lng: (json['lng'] as num).toDouble(),
      );
} 