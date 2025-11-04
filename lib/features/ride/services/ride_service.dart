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
      // Return a response object with an error message
      return CalculatePriceResponse(
        status: 'error',
        message: 'Could not calculate prices: ${e.toString()}',
      );
    }
  }

  /// Books a ride for the client
  // --- MODIFIED SIGNATURE ---
  Future<BookRideResponse> bookRide({
    required String pickupName,
    required String destinationName,
    required LatLng pickupCoords,
    required LatLng destinationCoords,
    required String category,
    required String state, // --- ADDED ---
  }) async {
    // --- END MODIFICATION ---
    try {
      final request = BookRideRequest(
        currentLocationName: pickupName,
        destinationName: destinationName,
        currentLocation: pickupCoords,
        destination: destinationCoords,
        category: category,
        state: state, // --- ADDED ---
      );
      final response = await _httpService.post(
        ApiConfig.bookRideEndpoint,
        body: request.toJson(),
      );
      final responseData = _httpService.handleResponse(response);
      return BookRideResponse.fromJson(responseData);
    } catch (e) {
      return BookRideResponse(
        status: 'error',
        message: 'Could not book ride: ${e.toString()}',
      );
    }
  }

  /// Checks the status of an ongoing ride
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
      return CheckRideStatusResponse(
        status: 'error',
        message: 'Could not check ride status: ${e.toString()}',
      );
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
        THelperFunctions.showSnackBar(
          responseData['message'] ?? 'Ride cancelled successfully',
        );
        return true;
      } else {
        THelperFunctions.showSnackBar(
          responseData['message'] ?? 'Failed to cancel ride',
        );
        return false;
      }
    } catch (e) {
      THelperFunctions.showSnackBar('An error occurred: ${e.toString()}');
      return false;
    }
  }
}
