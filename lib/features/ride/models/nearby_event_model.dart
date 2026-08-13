import 'package:google_maps_flutter/google_maps_flutter.dart';

/// A "Happening Nearby" partner event card shown on the home screen.
/// Tapping its CTA pre-fills the booking destination with [destination]
/// so the rider skips manual search.
class NearbyEvent {
  final String id;
  final String title;
  final String badgeLabel;
  final String eventDateLabel;
  final String subtitle;
  final String imageUrl;
  final String destinationName;
  final LatLng destination;
  final String ctaLabel;

  const NearbyEvent({
    required this.id,
    required this.title,
    required this.badgeLabel,
    required this.eventDateLabel,
    required this.subtitle,
    required this.imageUrl,
    required this.destinationName,
    required this.destination,
    required this.ctaLabel,
  });

  factory NearbyEvent.fromJson(Map<String, dynamic> json) {
    final coords = json['destinationCoordinates'] as Map<String, dynamic>?;
    return NearbyEvent(
      id: json['_id'] ?? '',
      title: json['title'] ?? '',
      badgeLabel: json['badgeLabel'] ?? '',
      eventDateLabel: json['eventDateLabel'] ?? '',
      subtitle: json['subtitle'] ?? '',
      imageUrl: json['imageUrl'] ?? '',
      destinationName: json['destinationName'] ?? '',
      destination: LatLng(
        (coords?['latitude'] as num?)?.toDouble() ?? 0.0,
        (coords?['longitude'] as num?)?.toDouble() ?? 0.0,
      ),
      ctaLabel: json['ctaLabel'] ?? 'Book event ride',
    );
  }
}
