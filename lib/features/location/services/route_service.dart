import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';

class RouteService {
  static const String _baseUrl =
      'https://maps.googleapis.com/maps/api/directions';
  // TODO: Replace with your actual Google Directions API key
  static const String _apiKey = 'AIzaSyAuzjqoVRhu70vqDQKFtDuOnZE6UE6kXVM';

  // For development, we'll use a more realistic fallback route

  static Future<List<LatLng>> getRoutePoints(
    LatLng origin,
    LatLng destination,
  ) async {
    try {
      final String url =
          '$_baseUrl/json'
          '?origin=${origin.latitude},${origin.longitude}'
          '&destination=${destination.latitude},${destination.longitude}'
          '&key=$_apiKey'
          '&mode=driving'
          '&alternatives=false';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['status'] == 'OK' && data['routes'].isNotEmpty) {
          final route = data['routes'][0];
          final polylinePoints = route['overview_polyline']['points'];

          // Decode polyline points
          PolylinePoints polylinePointsDecoder = PolylinePoints();
          List<PointLatLng> decodedPoints = polylinePointsDecoder
              .decodePolyline(polylinePoints);

          return decodedPoints
              .map((point) => LatLng(point.latitude, point.longitude))
              .toList();
        } else {
          print('Directions API Error: ${data['status']}');
          return _getFallbackRoute(origin, destination);
        }
      } else {
        print('HTTP Error: ${response.statusCode}');
        return _getFallbackRoute(origin, destination);
      }
    } catch (e) {
      print('Route Service Error: $e');
      return _getFallbackRoute(origin, destination);
    }
  }

  static Future<RouteInfo> getRouteInfo(
    LatLng origin,
    LatLng destination,
  ) async {
    try {
      final String url =
          '$_baseUrl/json'
          '?origin=${origin.latitude},${origin.longitude}'
          '&destination=${destination.latitude},${destination.longitude}'
          '&key=$_apiKey'
          '&mode=driving'
          '&alternatives=false';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['status'] == 'OK' && data['routes'].isNotEmpty) {
          final route = data['routes'][0];
          final leg = route['legs'][0];

          final polylinePoints = route['overview_polyline']['points'];
          PolylinePoints polylinePointsDecoder = PolylinePoints();
          List<PointLatLng> decodedPoints = polylinePointsDecoder
              .decodePolyline(polylinePoints);
          List<LatLng> routePoints = decodedPoints
              .map((point) => LatLng(point.latitude, point.longitude))
              .toList();

          return RouteInfo(
            points: routePoints,
            distance: leg['distance']['text'],
            duration: leg['duration']['text'],
            distanceValue: leg['distance']['value'],
            durationValue: leg['duration']['value'],
          );
        } else {
          print('Directions API Error: ${data['status']}');
          return _getFallbackRouteInfo(origin, destination);
        }
      } else {
        print('HTTP Error: ${response.statusCode}');
        return _getFallbackRouteInfo(origin, destination);
      }
    } catch (e) {
      print('Route Service Error: $e');
      return _getFallbackRouteInfo(origin, destination);
    }
  }

  // Fallback route that simulates road-like paths
  static List<LatLng> _getFallbackRoute(LatLng origin, LatLng destination) {
    List<LatLng> points = [];

    // Add origin
    points.add(origin);

    // Calculate distance and direction
    double latDiff = destination.latitude - origin.latitude;
    double lngDiff = destination.longitude - origin.longitude;
    double distance = sqrt(latDiff * latDiff + lngDiff * lngDiff);

    // Create more realistic road-like path with turns
    int numPoints = (distance * 100000).round().clamp(
      5,
      20,
    ); // More points for longer distances

    for (int i = 1; i < numPoints; i++) {
      double ratio = i / numPoints.toDouble();

      // Add road-like variations (simulate following streets)
      double roadVariation = 0;

      // Add some realistic turns every few points
      if (i % 3 == 0) {
        roadVariation = sin(ratio * pi * 4) * 0.0008; // Simulate street turns
      }

      // Follow a more realistic path (not perfectly straight)
      double currentLat = origin.latitude + (latDiff * ratio);
      double currentLng = origin.longitude + (lngDiff * ratio) + roadVariation;

      // Add slight randomness to simulate following actual roads
      double microVariation = (sin(ratio * pi * 8) * 0.0002);

      LatLng intermediatePoint = LatLng(
        currentLat + microVariation,
        currentLng,
      );
      points.add(intermediatePoint);
    }

    // Add destination
    points.add(destination);

    return points;
  }

  static RouteInfo _getFallbackRouteInfo(LatLng origin, LatLng destination) {
    // Calculate approximate distance and time
    double distance = _calculateDistance(origin, destination);
    int estimatedTime = (distance * 2)
        .round(); // Rough estimate: 2 minutes per km

    return RouteInfo(
      points: _getFallbackRoute(origin, destination),
      distance: '${distance.toStringAsFixed(1)} km',
      duration: '${estimatedTime} min',
      distanceValue: (distance * 1000).round(),
      durationValue: estimatedTime * 60,
    );
  }

  static double _calculateDistance(LatLng point1, LatLng point2) {
    // Haversine formula for distance calculation
    const double earthRadius = 6371.0; // Earth's radius in kilometers

    double lat1Rad = point1.latitude * (3.14159265359 / 180);
    double lat2Rad = point2.latitude * (3.14159265359 / 180);
    double deltaLatRad =
        (point2.latitude - point1.latitude) * (3.14159265359 / 180);
    double deltaLngRad =
        (point2.longitude - point1.longitude) * (3.14159265359 / 180);

    double a =
        sin(deltaLatRad / 2) * sin(deltaLatRad / 2) +
        cos(lat1Rad) *
            cos(lat2Rad) *
            sin(deltaLngRad / 2) *
            sin(deltaLngRad / 2);
    double c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return earthRadius * c;
  }
}

class RouteInfo {
  final List<LatLng> points;
  final String distance;
  final String duration;
  final int distanceValue; // in meters
  final int durationValue; // in seconds

  RouteInfo({
    required this.points,
    required this.distance,
    required this.duration,
    required this.distanceValue,
    required this.durationValue,
  });
}
