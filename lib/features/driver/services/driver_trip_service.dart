import 'package:get/get.dart';
import 'package:sarri_ride/core/services/http_service.dart';
import 'package:sarri_ride/config/api_config.dart';

class DriverTripService extends GetxService {
  static DriverTripService get instance => Get.find();
  final HttpService _httpService = HttpService.instance;

  /// Accept a pending ride request
  Future<Map<String, dynamic>> acceptRide(String rideId) async {
    final response = await _httpService.post(
      ApiConfig.acceptRideEndpoint,
      body: {'rideId': rideId},
    );
    return _httpService.handleResponse(response);
  }

  /// Signal that driver has arrived at pickup/destination
  Future<void> updateTripStatus(String tripId, String status) async {
    // Implement if your API supports a generic status update,
    // otherwise rely on startTrip/endTrip specific endpoints.
  }

  /// Start the trip (Navigate to destination)
  Future<Map<String, dynamic>> startTrip(
    String tripId,
    double lat,
    double lng,
  ) async {
    final response = await _httpService.post(
      ApiConfig.startTripEndpoint,
      body: {
        "tripId": tripId,
        "coordinates": [lng, lat], // MongoDB usually expects [lng, lat]
      },
    );
    return _httpService.handleResponse(response);
  }

  /// End the trip (Arrived at destination)
  Future<Map<String, dynamic>> endTrip(
    String tripId,
    double lat,
    double lng,
  ) async {
    final response = await _httpService.post(
      ApiConfig.endTripEndpoint,
      body: {
        "tripId": tripId,
        "coordinates": [lng, lat],
      },
    );
    return _httpService.handleResponse(response);
  }

  /// Confirm cash payment received
  Future<Map<String, dynamic>> confirmCashPayment(String tripId) async {
    final response = await _httpService.post(
      ApiConfig.cashPaymentConfirmEndpoint,
      body: {"tripId": tripId},
    );
    return _httpService.handleResponse(response);
  }
}
