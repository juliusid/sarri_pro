import 'package:get/get.dart';
import 'package:sarri_ride/config/api_config.dart';
import 'package:sarri_ride/core/services/http_service.dart';

class ShareService extends GetxService {
  static ShareService get instance => Get.find();
  final HttpService _httpService = HttpService.instance;

  /// Creates a shareable link for the given trip.
  /// Returns the share token string on success, or null on failure.
  Future<String?> createShareLink(String tripId) async {
    try {
      // Endpoint: POST /api/share/createSharelink
      // We don't send specific recipients, we just want a generic link to share manually.
      final body = {
        'tripId': tripId,
        'recipients': [
          {"name": "Mom", "phoneNumber": "+2348012345678"},
          {"name": "Alex Smith", "email": "alex.smith@example.com"},
          {
            "name": "Work Colleague",
            "phoneNumber": "+442079460001",
            "email": "colleague@work.com",
          },
        ],
        'settings': {
          'showDriverDetails': true,
          'showClientDetails': true,
          'showEstimatedArrival': true,
          'updateInterval': 5000,
        },
      };

      final response = await _httpService.post(ApiConfig.shareLink, body: body);
      print("ShareService Response: $body");

      final responseData = _httpService.handleResponse(response);

      if (responseData['status'] == 'success' && responseData['data'] != null) {
        // We just need the token to construct the URL
        return responseData['data']['shareToken'];
      }
      return null;
    } catch (e) {
      print("ShareService Error: $e");
      return null;
    }
  }
}
