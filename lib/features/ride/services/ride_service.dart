// lib/features/ride/services/ride_service.dart

import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:sarri_ride/config/api_config.dart';
import 'package:sarri_ride/core/services/http_service.dart';
import 'package:sarri_ride/features/ride/models/ride_model.dart';
import 'package:sarri_ride/utils/helpers/helper_functions.dart';

class RideService extends GetxService {
  static RideService get instance => Get.find();

  final HttpService _httpService = HttpService.instance;

  /// Calls the reconnect API and returns a parsed response.
  Future<ReconnectResponse> reconnectToTrip(
    String tripId,
    String userRole,
  ) async {
    try {
      final response = await _httpService.post(
        ApiConfig.reconnectEndpoint,
        body: {"tripId": tripId},
      );
      // We pass the role to help the factory constructor parse the right data
      return ReconnectResponse.fromJson(
        _httpService.handleResponse(response),
        userRole,
      );
    } catch (e) {
      String errorMessage;
      if (e is ApiException) {
        errorMessage = e.message;
      } else {
        errorMessage = e.toString();
      }
      return ReconnectResponse(
        status: 'error',
        message: 'Reconnect failed: $errorMessage',
        userRole: userRole,
      );
    }
  }

  /// Calculates the ride prices for different categories
  Future<CalculatePriceResponse> calculatePrice(
    LatLng pickup,
    LatLng destination,
  ) async {
    try {
      final request = CalculatePriceRequest(
        currentLocation: pickup,
        destination: destination,
      );
      final response = await _httpService.post(
        ApiConfig.calculatePriceEndpoint,
        body: request.toJson(),
      );
      final responseData = _httpService.handleResponse(response);
      return CalculatePriceResponse.fromJson(responseData);
    } catch (e) {
      // --- MODIFIED ERROR HANDLING ---
      String errorMessage;
      if (e is ApiException) {
        errorMessage = e.message; // Use the clean message from the API
      } else {
        errorMessage = e.toString(); // Fallback for unexpected errors
      }
      return CalculatePriceResponse(
        status: 'error',
        message: 'Could not calculate prices: $errorMessage',
      );
      // --- END MODIFICATION ---
    }
  }

  /// Books a ride for the client
  Future<BookRideResponse> bookRide({
    required String pickupName,
    required String destinationName,
    required LatLng pickupCoords,
    required LatLng destinationCoords,
    required String category,
    required String state,
  }) async {
    try {
      final request = BookRideRequest(
        currentLocationName: pickupName,
        destinationName: destinationName,
        currentLocation: pickupCoords,
        destination: destinationCoords,
        category: category,
        state: state,
      );
      final response = await _httpService.post(
        ApiConfig.bookRideEndpoint,
        body: request.toJson(),
      );
      // handleResponse will throw an ApiException for 404/500 errors
      final responseData = _httpService.handleResponse(response);
      // This line is reached only on 2xx status
      return BookRideResponse.fromJson(responseData);
    } catch (e) {
      // --- MODIFIED ERROR HANDLING ---
      // This catch block handles network errors, timeouts, and API errors (like 404)
      String errorMessage;
      if (e is ApiException) {
        errorMessage = e
            .message; // Use the clean message from the API (e.g., "No available drivers...")
      } else {
        errorMessage =
            'An unexpected error occurred. Please try again.'; // Generic fallback
        print("BookRide Unhandled Error: ${e.toString()}");
      }
      return BookRideResponse(
        status: 'error',
        message: errorMessage, // Pass the clean (or generic) message
      );
      // --- END MODIFICATION ---
    }
  }

  Future<CheckRideStatusResponse> checkRideStatus(String rideId) async {
    try {
      final request = CheckRideStatusRequest(rideId: rideId);
      final response = await _httpService.post(
        ApiConfig.checkRideStatusEndpoint,
        body: request.toJson(),
      );
      final responseData = _httpService.handleResponse(response);
      return CheckRideStatusResponse.fromJson(responseData);
    } catch (e) {
      // --- MODIFIED ERROR HANDLING ---
      String errorMessage;
      if (e is ApiException) {
        errorMessage = e.message;
      } else {
        errorMessage = e.toString();
      }
      return CheckRideStatusResponse(
        status: 'error',
        message: 'Could not check ride status: $errorMessage',
      );
      // --- END MODIFICATION ---
    }
  }

  /// Cancels a ride for the client
  Future<bool> cancelRide(String rideId) async {
    try {
      final request = CancelRideRequest(rideId: rideId);
      final response = await _httpService.post(
        ApiConfig.cancelRideEndpoint,
        body: request.toJson(),
      );
      final responseData = _httpService.handleResponse(response);

      if (responseData['status'] == 'success') {
        // --- MODIFIED SNACKBAR ---
        THelperFunctions.showSuccessSnackBar(
          'Cancelled',
          responseData['message'] ?? 'Ride cancelled successfully',
        );
        // --- END MODIFICATION ---
        return true;
      } else {
        // --- MODIFIED SNACKBAR ---
        THelperFunctions.showErrorSnackBar(
          'Error',
          responseData['message'] ?? 'Failed to cancel ride',
        );
        // --- END MODIFICATION ---
        return false;
      }
    } catch (e) {
      // --- MODIFIED SNACKBAR ---
      String errorMessage = "An error occurred";
      if (e is ApiException) errorMessage = e.message;
      THelperFunctions.showErrorSnackBar('Error', errorMessage);
      // --- END MODIFICATION ---
      return false;
    }
  }
}
