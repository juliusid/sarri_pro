import 'package:get/get.dart';
import 'package:sarri_ride/core/services/http_service.dart';

class CarRentalHistoryController extends GetxController {
  final HttpService _httpService = HttpService.instance;

  final RxList<Map<String, dynamic>> allBookings = <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> filteredBookings = <Map<String, dynamic>>[].obs;
  
  final RxBool isLoading = true.obs;
  final RxString error = ''.obs;

  final RxString selectedTab = 'All'.obs;
  final List<String> tabs = ['All', 'Active', 'Upcoming', 'Completed', 'Cancelled'];

  @override
  void onInit() {
    super.onInit();
    fetchBookings();
  }

  Future<void> fetchBookings() async {
    isLoading.value = true;
    error.value = '';
    try {
      final response = await _httpService.get('/api/car-rental/bookings/client');
      final data = _httpService.handleResponse(response);
      if (data['status'] == 'success') {
        final list = List<Map<String, dynamic>>.from(data['data']);
        allBookings.value = list;
        filterBookings();
      } else {
        error.value = 'Failed to load rentals';
      }
    } catch (e) {
      print('Error fetching car rentals history: $e');
      error.value = 'Failed to load your rentals. Please try again.';
    } finally {
      isLoading.value = false;
    }
  }

  void selectTab(String tab) {
    selectedTab.value = tab;
    filterBookings();
  }

  void filterBookings() {
    if (selectedTab.value == 'All') {
      filteredBookings.value = allBookings;
    } else {
      filteredBookings.value = allBookings.where((b) {
        final status = b['status'].toString().toLowerCase();
        if (selectedTab.value == 'Active') return status == 'active';
        if (selectedTab.value == 'Upcoming') return status == 'pending' || status == 'confirmed';
        if (selectedTab.value == 'Completed') return status == 'completed';
        if (selectedTab.value == 'Cancelled') return status == 'cancelled';
        return false;
      }).toList();
    }
  }

  Future<void> cancelBooking(String bookingId) async {
    try {
      final response = await _httpService.patch('/api/car-rental/bookings/$bookingId/cancel-client');
      final data = _httpService.handleResponse(response);
      if (data['status'] == 'success') {
        fetchBookings(); // Refresh list to reflect cancellation and refund
        Get.snackbar('Success', 'Booking cancelled successfully');
      } else {
        Get.snackbar('Error', data['message'] ?? 'Failed to cancel booking');
      }
    } catch (e) {
      Get.snackbar('Error', 'Connection failed');
    }
  }
}
