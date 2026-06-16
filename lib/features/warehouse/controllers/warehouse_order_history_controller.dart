import 'package:get/get.dart';
import 'package:sarri_ride/core/services/http_service.dart';
import 'package:sarri_ride/utils/helpers/helper_functions.dart';

class WarehouseOrderHistoryController extends GetxController {
  final HttpService _httpService = HttpService.instance;

  final RxList<Map<String, dynamic>> orders = <Map<String, dynamic>>[].obs;
  final RxBool isLoading = true.obs;

  @override
  void onInit() {
    super.onInit();
    fetchOrders();
  }

  Future<void> fetchOrders() async {
    isLoading.value = true;
    try {
      final response = await _httpService.get('/api/warehouse/orders/history');
      final data = _httpService.handleResponse(response);
      if (data['status'] == 'success') {
        orders.value = List<Map<String, dynamic>>.from(data['data']);
      }
    } catch (e) {
      print('Error fetching warehouse orders: $e');
      THelperFunctions.showErrorSnackBar('Error', 'Failed to load order history.');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> cancelOrder(String shipmentId) async {
    try {
      final response = await _httpService.patch('/api/warehouse/orders/$shipmentId/cancel');
      final data = _httpService.handleResponse(response);
      if (data['status'] == 'success') {
        THelperFunctions.showSuccessSnackBar('Success', 'Order cancelled successfully.');
        fetchOrders();
      }
    } catch (e) {
      THelperFunctions.showErrorSnackBar('Error', 'Failed to cancel order.');
    }
  }
}
