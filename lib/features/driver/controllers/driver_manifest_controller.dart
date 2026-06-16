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
      final response = await _httpService.get('/api/warehouse/batches/driver');
      final data = _httpService.handleResponse(response);
      if (data['status'] == 'success') {
        batches.value = List<Map<String, dynamic>>.from(data['data']);
      }
    } catch (e) {
      print('Error fetching manifest: $e');
      THelperFunctions.showErrorSnackBar('Error', 'Failed to load manifest.');
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> updateBatchStatus(String batchId, String newStatus, {String? qrData}) async {
    try {
      final response = await _httpService.patch(
        '/api/warehouse/batches/$batchId/status',
        body: {
          'status': newStatus,
          if (qrData != null) 'scannedQrData': qrData,
        },
      );
      final data = _httpService.handleResponse(response);
      if (data['status'] == 'success') {
        THelperFunctions.showSuccessSnackBar('Success', 'Batch updated to $newStatus');
        fetchManifest(); // Refresh
        return true;
      }
      return false;
    } catch (e) {
      THelperFunctions.showErrorSnackBar('Error', 'Failed to update batch status.');
      return false;
    }
  }
}
