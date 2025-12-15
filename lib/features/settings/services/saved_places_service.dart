import 'package:get/get.dart';
import 'package:sarri_ride/config/api_config.dart';
import 'package:sarri_ride/core/services/http_service.dart';
import 'package:sarri_ride/features/settings/models/saved_place.dart';

class SavedPlacesService extends GetxService {
  static SavedPlacesService get instance => Get.find();
  final HttpService _httpService = HttpService.instance;

  /// Get all saved places
  Future<List<SavedPlace>> getAllPlaces() async {
    try {
      final response = await _httpService.get(ApiConfig.getPlacesEndpoint);
      final responseData = _httpService.handleResponse(response);

      if (responseData['success'] == true && responseData['data'] != null) {
        final List placesList = responseData['data']['places'] ?? [];
        return placesList.map((e) => SavedPlace.fromJson(e)).toList();
      }
      return [];
    } catch (e) {
      print("SavedPlacesService Error (Get): $e");
      return []; // Return empty list on error
    }
  }

  /// Save a new place
  Future<bool> savePlace({
    required String label,
    required String address,
    required double lat,
    required double lng,
    String? city,
    String? state,
    String? country,
    String? postalCode,
    String? customName, // For 'other' label
  }) async {
    try {
      final body = {
        "label": label.toLowerCase(),
        "address": address,
        "coordinates": [lng, lat], // [Longitude, Latitude]
        "city": city ?? "",
        "state": state ?? "",
        "country": country ?? "Nigeria",
        "postalCode": postalCode ?? "",
      };

      if (label.toLowerCase() == 'other' && customName != null) {
        body["customName"] = customName;
      }

      final response = await _httpService.post(
        ApiConfig.savePlaceEndpoint,
        body: body,
      );
      final responseData = _httpService.handleResponse(response);
      return responseData['success'] == true;
    } catch (e) {
      print("SavedPlacesService Error (Save): $e");
      return false;
    }
  }

  /// Update a place
  Future<bool> updatePlace(String id, Map<String, dynamic> updateData) async {
    try {
      final response = await _httpService.put(
        ApiConfig.updatePlaceEndpoint(id),
        body: updateData,
      );
      final responseData = _httpService.handleResponse(response);
      return responseData['success'] == true;
    } catch (e) {
      print("SavedPlacesService Error (Update): $e");
      return false;
    }
  }

  /// Delete a place
  Future<bool> deletePlace(String id) async {
    try {
      final response = await _httpService.delete(
        ApiConfig.deletePlaceEndpoint(id),
      );
      // API might return success: true or just 200 OK
      // Assuming handleResponse checks status code 200-299
      // If delete returns void or different shape, adjust here.
      // Based on screenshot, it's a DELETE method.
      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (e) {
      print("SavedPlacesService Error (Delete): $e");
      return false;
    }
  }
}
