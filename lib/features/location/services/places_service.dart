import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:google_maps_flutter/google_maps_flutter.dart';

class PlacesService {
  static const String _baseUrl = 'https://maps.googleapis.com/maps/api/place';
  static const String _geocodingUrl = 'https://maps.googleapis.com/maps/api/geocode';
  // TODO: Replace with your actual Google Places API key
  static const String _apiKey = 'AIzaSyChNPec0LnXwnWRon4-fT0SsjrPW0mroPE';
  
  // Get place autocomplete suggestions
  static Future<List<PlaceSuggestion>> getPlaceSuggestions(String query, {LatLng? location}) async {
    if (query.length < 3) return [];
    
    try {
      String locationBias = '';
      if (location != null) {
        // Bias results to current location
        locationBias = '&location=${location.latitude},${location.longitude}&radius=50000';
      } else {
        // Default to Lagos, Nigeria
        locationBias = '&location=6.5244,3.3792&radius=50000';
      }
      
      final String url = '$_baseUrl/autocomplete/json'
          '?input=${Uri.encodeComponent(query)}'
          '&key=$_apiKey'
          '&components=country:ng' // Restrict to Nigeria
          '$locationBias'
          '&types=establishment|geocode'; // Include places and addresses
      
      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['status'] == 'OK') {
          List<PlaceSuggestion> suggestions = [];
          
          for (var prediction in data['predictions']) {
            suggestions.add(PlaceSuggestion(
              placeId: prediction['place_id'],
              description: prediction['description'],
              mainText: prediction['structured_formatting']['main_text'],
              secondaryText: prediction['structured_formatting']['secondary_text'] ?? '',
            ));
          }
          
          return suggestions;
        } else {
          print('Places API Error: ${data['status']} - ${data['error_message'] ?? 'Unknown error'}');
          return [];
        }
      } else {
        print('HTTP Error: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('Places Service Error: $e');
      return [];
    }
  }
  
  // Get place details including coordinates
  static Future<PlaceDetails?> getPlaceDetails(String placeId) async {
    try {
      final String url = '$_baseUrl/details/json'
          '?place_id=$placeId'
          '&fields=name,formatted_address,geometry'
          '&key=$_apiKey';
      
      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['status'] == 'OK') {
          final result = data['result'];
          final geometry = result['geometry']['location'];
          
          return PlaceDetails(
            name: result['name'] ?? '',
            formattedAddress: result['formatted_address'],
            location: LatLng(
              geometry['lat'].toDouble(),
              geometry['lng'].toDouble(),
            ),
          );
        } else {
          print('Place Details API Error: ${data['status']} - ${data['error_message'] ?? 'Unknown error'}');
          return null;
        }
      } else {
        print('HTTP Error: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Place Details Error: $e');
      return null;
    }
  }

  // Get address from coordinates (reverse geocoding)
  static Future<String?> getAddressFromCoordinates(double latitude, double longitude) async {
    try {
      final String url = '$_geocodingUrl/json'
          '?latlng=$latitude,$longitude'
          '&key=$_apiKey'
          '&result_type=street_address|route|neighborhood|political';
      
      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['status'] == 'OK' && data['results'].isNotEmpty) {
          // Return the most specific address (first result)
          return data['results'][0]['formatted_address'];
        } else {
          print('Geocoding API Error: ${data['status']} - ${data['error_message'] ?? 'Unknown error'}');
          return 'Unknown location';
        }
      } else {
        print('HTTP Error: ${response.statusCode}');
        return 'Unable to get address';
      }
    } catch (e) {
      print('Reverse Geocoding Error: $e');
      return 'Error getting address';
    }
  }

  // Get detailed place information from coordinates
  static Future<PlaceDetails?> getPlaceDetailsFromCoordinates(double latitude, double longitude) async {
    try {
      final String url = '$_geocodingUrl/json'
          '?latlng=$latitude,$longitude'
          '&key=$_apiKey'
          '&result_type=establishment|street_address|route';
      
      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['status'] == 'OK' && data['results'].isNotEmpty) {
          final result = data['results'][0];
          final geometry = result['geometry']['location'];
          
          // Extract name from address components or use formatted address
          String name = result['formatted_address'];
          if (result['address_components'] != null && result['address_components'].isNotEmpty) {
            // Try to get establishment name or street name
            for (var component in result['address_components']) {
              final types = List<String>.from(component['types']);
              if (types.contains('establishment') || types.contains('point_of_interest')) {
                name = component['long_name'];
                break;
              } else if (types.contains('route')) {
                name = component['long_name'];
              }
            }
          }
          
          return PlaceDetails(
            name: name,
            formattedAddress: result['formatted_address'],
            location: LatLng(
              geometry['lat'].toDouble(),
              geometry['lng'].toDouble(),
            ),
          );
        } else {
          print('Geocoding API Error: ${data['status']} - ${data['error_message'] ?? 'Unknown error'}');
          return null;
        }
      } else {
        print('HTTP Error: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Reverse Geocoding Error: $e');
      return null;
    }
  }
}

class PlaceSuggestion {
  final String placeId;
  final String description;
  final String mainText;
  final String secondaryText;
  
  PlaceSuggestion({
    required this.placeId,
    required this.description,
    required this.mainText,
    required this.secondaryText,
  });
}

class PlaceDetails {
  final String name;
  final String formattedAddress;
  final LatLng location;
  
  PlaceDetails({
    required this.name,
    required this.formattedAddress,
    required this.location,
  });
} 