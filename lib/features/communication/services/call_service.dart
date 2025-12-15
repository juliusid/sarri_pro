import 'package:get/get.dart';
import 'package:sarri_ride/config/api_config.dart';
import 'package:sarri_ride/core/services/http_service.dart';

class CallService extends GetxService {
  static CallService get instance => Get.find();
  final HttpService _httpService = HttpService.instance;

  // --- Initiate Call (Updated to match your API docs) ---
  Future<Map<String, dynamic>?> initiateCall(String tripId) async {
    try {
      final response = await _httpService.post(
        ApiConfig.initiateCallEndpoint,
        body: {'tripId': tripId}, // <-- API requires tripId
      );
      final data = _httpService.handleResponse(response);

      if (data['status'] == 'success') {
        return data['data']; // Contains callId, peerConfig, etc.
      }
      return null;
    } catch (e) {
      print("CallService Error (Initiate): $e");
      return null;
    }
  }

  Future<bool> answerCall(String callId) async {
    try {
      final response = await _httpService.post(
        ApiConfig.acceptCallEndpoint,
        body: {'callId': callId},
      );
      final data = _httpService.handleResponse(response);
      return data['status'] == 'success';
    } catch (e) {
      print("CallService Error (Answer): $e");
      return false;
    }
  }

  Future<bool> rejectCall(String callId) async {
    try {
      final response = await _httpService.post(
        ApiConfig.rejectCallEndpoint,
        body: {'callId': callId, 'reason': 'declined'},
      );
      final data = _httpService.handleResponse(response);
      return data['status'] == 'success';
    } catch (e) {
      print("CallService Error (Reject): $e");
      return false;
    }
  }

  Future<bool> endCall(String callId) async {
    try {
      final response = await _httpService.post(
        ApiConfig.endCallEndpoint,
        body: {'callId': callId},
      );
      final data = _httpService.handleResponse(response);
      return data['status'] == 'success';
    } catch (e) {
      print("CallService Error (End): $e");
      return false;
    }
  }
}
