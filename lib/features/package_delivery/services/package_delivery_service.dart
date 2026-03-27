import 'package:get/get.dart';

import 'package:sarri_ride/core/services/http_service.dart';
import 'package:sarri_ride/config/api_config.dart';
import 'package:sarri_ride/features/package_delivery/models/package_delivery_model.dart';
import 'package:sarri_ride/utils/helpers/helper_functions.dart';

class PackageDeliveryService extends GetxService {
  static PackageDeliveryService get instance => Get.find();

  final HttpService _httpService = HttpService.instance;

  Future<BookPackageResponse> bookPackageDelivery(BookPackageRequest request) async {
    final response = await _httpService.post(
      ApiConfig.packageDeliveryBookEndpoint,
      body: request.toJson(),
    );

    final responseData = _httpService.handleResponse(response);
    if (responseData['status'] != 'success' || responseData['data'] == null) {
      throw Exception(responseData['message'] ?? 'Failed to book package delivery');
    }

    return BookPackageResponse.fromJson(responseData['data'] as Map<String, dynamic>);
  }

  Future<bool> cancelPackageDelivery(String rideId) async {
    final response = await _httpService.post(
      ApiConfig.packageDeliveryCancelEndpoint,
      body: {'rideId': rideId},
    );
    final responseData = _httpService.handleResponse(response);

    if (responseData['status'] == 'success') return true;
    THelperFunctions.showErrorSnackBar(
      'Error',
      responseData['message'] ?? 'Failed to cancel package delivery',
    );
    return false;
  }

  // --- DRIVER ACTIONS (package delivery) ---

  Future<bool> acceptPackageDeliveryRequest(String rideId) async {
    final response = await _httpService.post(
      ApiConfig.packageDeliveryAcceptEndpoint,
      body: {'rideId': rideId},
    );
    final responseData = _httpService.handleResponse(response);
    return responseData['status'] == 'success';
  }

  Future<bool> rejectPackageDeliveryRequest(String rideId) async {
    final response = await _httpService.post(
      ApiConfig.packageDeliveryRejectEndpoint,
      body: {'rideId': rideId},
    );
    final responseData = _httpService.handleResponse(response);
    return responseData['status'] == 'success';
  }

  Future<bool> confirmPickupWithCode({
    required String tripId,
    required String pickupCode,
  }) async {
    final response = await _httpService.post(
      ApiConfig.packageDeliveryConfirmPickupEndpoint,
      body: {
        'tripId': tripId,
        'pickupCode': pickupCode,
      },
    );
    final responseData = _httpService.handleResponse(response);
    return responseData['status'] == 'success';
  }

  Future<bool> startPackageDeliveryTrip({
    required String tripId,
    required double lat,
    required double lng,
  }) async {
    final response = await _httpService.post(
      ApiConfig.packageDeliveryStartTripEndpoint,
      body: {
        'tripId': tripId,
        'coordinates': [lng, lat], // backend expects [longitude, latitude]
      },
    );
    final responseData = _httpService.handleResponse(response);
    return responseData['status'] == 'success';
  }

  Future<bool> arriveAtPackageDropoff({
    required String tripId,
    required double lat,
    required double lng,
  }) async {
    final response = await _httpService.post(
      ApiConfig.packageDeliveryArriveAtDropoffEndpoint,
      body: {
        'tripId': tripId,
        'coordinates': [lng, lat],
      },
    );
    final responseData = _httpService.handleResponse(response);
    return responseData['status'] == 'success';
  }

  Future<bool> confirmPackageDeliveryWithCode({
    required String tripId,
    required String deliveryCode,
  }) async {
    final response = await _httpService.post(
      ApiConfig.packageDeliveryConfirmDeliveryWithCodeEndpoint,
      body: {
        'tripId': tripId,
        'deliveryCode': deliveryCode,
      },
    );
    final responseData = _httpService.handleResponse(response);
    return responseData['status'] == 'success';
  }

  Future<bool> confirmDeliveryBySender({
    required String tripId,
    required bool confirm,
  }) async {
    final response = await _httpService.post(
      ApiConfig.packageDeliveryConfirmDeliveryBySenderEndpoint,
      body: {
        'tripId': tripId,
        'confirm': confirm,
      },
    );
    final responseData = _httpService.handleResponse(response);
    return responseData['status'] == 'success';
  }

  // --- DISPUTES ---

  Future<PackageDisputeResponse> raiseDispute(PackageDisputeRequest request) async {
    final response = await _httpService.post(
      ApiConfig.packageDeliveryRaiseDisputeEndpoint,
      body: request.toJson(),
    );
    final responseData = _httpService.handleResponse(response);
    return PackageDisputeResponse.fromJson(responseData);
  }

  // --- PAYMENTS ---

  Future<PackagePaymentInitResponse> initializePayment(PackagePaymentInitRequest request) async {
    final response = await _httpService.post(
      ApiConfig.packagePaymentInitEndpoint,
      body: request.toJson(),
    );
    final responseData = _httpService.handleResponse(response);
    return PackagePaymentInitResponse.fromJson(responseData);
  }

  Future<bool> switchPaymentMethod({
    required String tripId,
    required String newPaymentMethod,
  }) async {
    final response = await _httpService.post(
      ApiConfig.packagePaymentSwitchMethodEndpoint,
      body: {
        'tripId': tripId,
        'newPaymentMethod': newPaymentMethod,
      },
    );
    final responseData = _httpService.handleResponse(response);
    return responseData['status'] == 'success';
  }

  Future<bool> confirmCashPayment({
    required String tripId,
    bool useReduction = false,
  }) async {
    final response = await _httpService.post(
      ApiConfig.packagePaymentCashConfirmEndpoint,
      body: {
        'tripId': tripId,
        'useReduction': useReduction,
      },
    );
    final responseData = _httpService.handleResponse(response);
    return responseData['status'] == 'success';
  }

  Future<PackageDebtStatusResponse> getDebtStatus() async {
    final response = await _httpService.get(ApiConfig.packagePaymentDebtStatusEndpoint);
    final responseData = _httpService.handleResponse(response);
    return PackageDebtStatusResponse.fromJson(responseData);
  }

  Future<PackagePaymentInitResponse> payDebt({
    required double amount,
    required String paymentMethod,
  }) async {
    final response = await _httpService.post(
      ApiConfig.packagePaymentPayDebtEndpoint,
      body: {
        'amount': amount,
        'paymentMethod': paymentMethod,
      },
    );
    final responseData = _httpService.handleResponse(response);
    return PackagePaymentInitResponse.fromJson(responseData);
  }

  Future<Map<String, dynamic>> previewPayment(String tripId) async {
    final response = await _httpService.post(
      ApiConfig.packagePaymentPreviewEndpoint,
      body: {'tripId': tripId},
    );
    return _httpService.handleResponse(response);
  }
}

