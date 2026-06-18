import 'package:get/get.dart';
import 'package:sarri_ride/core/services/http_service.dart';
import 'package:sarri_ride/utils/helpers/helper_functions.dart';

class DriverManifestController extends GetxController {
  final HttpService _httpService = HttpService.instance;

  final RxList<Map<String, dynamic>> batches = <Map<String, dynamic>>[].obs;
  final RxBool isLoading = true.obs;

  @override
  void onInit() {
    super.onInit();
    fetchManifest();
  }

  Future<void> fetchManifest() async {
    isLoading.value = true;
    try {
      final response = await _httpService.get('/api/warehouse/delivery/manifest');
      final data = _httpService.handleResponse(response);
      if (data['status'] == 'success' && data['data'] != null && data['data']['batches'] != null) {
        batches.value = List<Map<String, dynamic>>.from(data['data']['batches']);
      } else {
        batches.clear();
      }
    } catch (e) {
      print('Error fetching manifest: $e');
      String errMsg = 'Failed to load manifest.';
      if (e is ApiException) {
        errMsg = e.message;
      }
      THelperFunctions.showErrorSnackBar('Error', errMsg);
      batches.clear();
    } finally {
      isLoading.value = false;
    }
  }

  // Scan QR at delivery point
  Future<Map<String, dynamic>?> scanDelivery(String qrPayload, double? lat, double? lng) async {
    try {
      final response = await _httpService.post(
        '/api/warehouse/delivery/scan',
        body: {
          'payload': qrPayload,
          'latitude': lat,
          'longitude': lng,
        },
      );
      final data = _httpService.handleResponse(response);
      if (data['status'] == 'success') {
        return data['data'];
      }
      return null;
    } catch (e) {
      String errMsg = 'Delivery scan failed.';
      if (e is ApiException) {
        errMsg = e.message;
      }
      THelperFunctions.showErrorSnackBar('Scan Error', errMsg);
      return null;
    }
  }

  // Confirm delivery with PIN
  Future<bool> confirmDeliveryPIN({
    required String shipmentId,
    required int itemIndex,
    required String pin,
    required String receivedByName,
    required String receivedByIdType,
  }) async {
    try {
      final response = await _httpService.post(
        '/api/warehouse/delivery/$shipmentId/items/$itemIndex/confirm',
        body: {
          'pin': pin,
          'receivedByName': receivedByName,
          'receivedByIdType': receivedByIdType,
        },
      );
      final data = _httpService.handleResponse(response);
      if (data['status'] == 'success') {
        THelperFunctions.showSuccessSnackBar('Delivered', 'Delivery confirmed successfully.');
        fetchManifest(); // Refresh manifest list
        return true;
      }
      return false;
    } catch (e) {
      String errMsg = 'Failed to confirm delivery.';
      if (e is ApiException) {
        errMsg = e.message;
      }
      THelperFunctions.showErrorSnackBar('Delivery Confirmation Error', errMsg);
      return false;
    }
  }

  // Report failed delivery
  Future<bool> reportFailure({
    required String shipmentId,
    required int itemIndex,
    String? reason,
  }) async {
    try {
      final response = await _httpService.post(
        '/api/warehouse/delivery/$shipmentId/items/$itemIndex/failed',
        body: {
          if (reason != null && reason.trim().isNotEmpty) 'reason': reason,
        },
      );
      final data = _httpService.handleResponse(response);
      if (data['status'] == 'success') {
        THelperFunctions.showSuccessSnackBar('Logged', 'Delivery issue logged successfully.');
        fetchManifest(); // Refresh manifest list
        return true;
      }
      return false;
    } catch (e) {
      String errMsg = 'Failed to log delivery failure.';
      if (e is ApiException) {
        errMsg = e.message;
      }
      THelperFunctions.showErrorSnackBar('Failure Report Error', errMsg);
      return false;
    }
  }
}

