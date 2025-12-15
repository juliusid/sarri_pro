import 'package:get/get.dart';
import 'package:sarri_ride/config/api_config.dart';
import 'package:sarri_ride/core/services/http_service.dart';

class EmergencyService extends GetxService {
  static EmergencyService get instance => Get.find();
  final HttpService _httpService = HttpService.instance;

  /// 1. Create Emergency
  Future<Map<String, dynamic>?> createEmergency({
    required String description,
    required String category,
    String title = 'Emergency',
    String? tripId,
  }) async {
    try {
      final body = {
        'title': title,
        'description': description,
        'category': category,
        if (tripId != null)
          'relatedEntity': {'entityId': tripId, 'entityModel': 'Trip'},
      };

      // Using the endpoint from your guide: POST /api/emergencies/create-emergency
      // Note: You'll need to add createEmergencyEndpoint to ApiConfig or use the full path
      final response = await _httpService.post(
        ApiConfig.createEmergency,
        body: body,
      );

      final responseData = _httpService.handleResponse(response);

      if (responseData['status'] == 'queued' ||
          responseData['status'] == 'success') {
        return responseData['data'];
      }
      return null;
    } catch (e) {
      print("EmergencyService Error (create): $e");
      return null;
    }
  }

  /// 2. Get Emergency Details (with pagination for messages)
  Future<Map<String, dynamic>?> getEmergencyDetails(
    String emergencyId, {
    int page = 1,
  }) async {
    try {
      final response = await _httpService.get(
        ApiConfig.getEmergencyDetailsEndpoint(emergencyId),
        queryParameters: {'page': page.toString(), 'limit': '25'},
      );

      final responseData = _httpService.handleResponse(response);

      if (responseData['status'] == 'success') {
        return responseData['data'];
      }
      return null;
    } catch (e) {
      print("EmergencyService Error (getDetails): $e");
      return null;
    }
  }

  /// 3. Send Message to Emergency
  Future<bool> sendMessage(String emergencyId, String message) async {
    try {
      final response = await _httpService.post(
        ApiConfig.sendMessageEndpoint(emergencyId),
        headers: {'Content-Type': 'application/json'},
        body: {'message': message},
      );

      final responseData = _httpService.handleResponse(response);
      return responseData['status'] == 'success';
    } catch (e) {
      print("EmergencyService Error (sendMessage): $e");
      return false;
    }
  }

  /// 4. Get My Emergencies (History)
  Future<List<dynamic>> getMyEmergencies({int page = 1}) async {
    try {
      final response = await _httpService.get(
        '${ApiConfig.baseUrl}/emergencies/my',
        queryParameters: {'page': page.toString()},
      );

      final responseData = _httpService.handleResponse(response);

      if (responseData['status'] == 'success') {
        return responseData['data']['emergencies'] ?? [];
      }
      return [];
    } catch (e) {
      print("EmergencyService Error (getMy): $e");
      return [];
    }
  }
}
