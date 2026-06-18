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
      final response = await _httpService.get(
        '/api/warehouse/orders',
        queryParameters: {'page': '1', 'limit': '50'},
      );
      final data = _httpService.handleResponse(response);
      if (data['status'] == 'success') {
        orders.value = List<Map<String, dynamic>>.from(data['data']);
      }
    } catch (e) {
      print('Error fetching warehouse orders: $e');
      String errMsg = 'Failed to load order history.';
      if (e is ApiException) {
        errMsg = e.message;
      }
      THelperFunctions.showErrorSnackBar('Error', errMsg);
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> cancelOrder(String shipmentId) async {
    try {
      final response = await _httpService.delete('/api/warehouse/orders/$shipmentId');
      final data = _httpService.handleResponse(response);
      if (data['status'] == 'success') {
        THelperFunctions.showSuccessSnackBar('Success', 'Order cancelled successfully.');
        fetchOrders();
        return true;
      }
      return false;
    } catch (e) {
      String errMsg = 'Failed to cancel order.';
      if (e is ApiException) {
        errMsg = e.message;
      }
      THelperFunctions.showErrorSnackBar('Error', errMsg);
      return false;
    }
  }
}
