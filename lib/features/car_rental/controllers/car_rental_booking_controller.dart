import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sarri_ride/core/services/http_service.dart';
import 'package:sarri_ride/features/payment/screens/paystack_webview_screen.dart';

class CarRentalBookingController extends GetxController {
  static CarRentalBookingController get instance => Get.find();

  final HttpService _httpService = HttpService.instance;

  final selectedCategory = 'All'.obs;
  final RxList<Map<String, dynamic>> vehicles = <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> filteredVehicles = <Map<String, dynamic>>[].obs;
  final RxBool isLoading = true.obs;
  final RxString error = ''.obs;

  // Booking State
  final Rx<Map<String, dynamic>?> selectedVehicle = Rx<Map<String, dynamic>?>(null);
  final Rx<DateTime?> pickupDate = Rx<DateTime?>(null);
  final Rx<DateTime?> returnDate = Rx<DateTime?>(null);
  final Rx<TimeOfDay?> pickupTime = Rx<TimeOfDay?>(null);
  final Rx<TimeOfDay?> returnTime = Rx<TimeOfDay?>(null);
  final RxString rentalMode = 'chauffeur'.obs; // Always chauffeur since self_drive is commented out
  
  final RxDouble estimatedPrice = 0.0.obs;
  final RxBool isSubmitting = false.obs;

  final List<String> categories = ['All', 'Economy', 'Comfort', 'Luxury', 'SUV', 'Chauffeur'];

  @override
  void onInit() {
    super.onInit();
    fetchVehicles();
  }

  Future<void> fetchVehicles() async {
    isLoading.value = true;
    error.value = '';
    try {
      final response = await _httpService.get('/api/car-rental/vehicles');
      final data = _httpService.handleResponse(response);
      if (data['status'] == 'success') {
        final list = List<Map<String, dynamic>>.from(data['data']);
        vehicles.value = list;
        filterVehicles();
      } else {
        error.value = 'Failed to load vehicles';
      }
    } catch (e) {
      print('Error fetching car rentals: $e');
      error.value = 'Failed to load vehicles. Please try again.';
    } finally {
      isLoading.value = false;
    }
  }

  void selectCategory(String category) {
    selectedCategory.value = category;
    filterVehicles();
  }

  void filterVehicles() {
    if (selectedCategory.value == 'All') {
      filteredVehicles.value = vehicles;
    } else if (selectedCategory.value == 'Chauffeur') {
      filteredVehicles.value = vehicles.where((v) => v['rentalType'] == 'chauffeur' || v['rentalType'] == 'both').toList();
    } else {
      filteredVehicles.value = vehicles.where((v) => v['category'].toString().toLowerCase() == selectedCategory.value.toLowerCase()).toList();
    }
  }

  void proceedToDetail(String vehicleId) {
    selectedVehicle.value = vehicles.firstWhere((v) => v['_id'] == vehicleId);
    pickupDate.value = null;
    returnDate.value = null;
    pickupTime.value = null;
    returnTime.value = null;
    estimatedPrice.value = 0.0;
    
    // Always default to chauffeur since self drive is disabled
    rentalMode.value = 'chauffeur';

    Get.toNamed('/car-rental/detail');
  }

  void calculatePrice() {
    if (selectedVehicle.value == null || pickupDate.value == null || returnDate.value == null || pickupTime.value == null || returnTime.value == null) {
      estimatedPrice.value = 0.0;
      return;
    }

    final pickup = DateTime(pickupDate.value!.year, pickupDate.value!.month, pickupDate.value!.day, pickupTime.value!.hour, pickupTime.value!.minute);
    final ret = DateTime(returnDate.value!.year, returnDate.value!.month, returnDate.value!.day, returnTime.value!.hour, returnTime.value!.minute);

    final durationHours = ret.difference(pickup).inMinutes / 60.0;
    if (durationHours <= 0) {
      estimatedPrice.value = 0.0;
      return;
    }

    final dailyObj = selectedVehicle.value!['dailyRate'];
    final dailyRate = dailyObj is Map ? double.tryParse(dailyObj['\$numberDecimal'].toString()) ?? 0 : double.tryParse(dailyObj.toString()) ?? 0;

    final hourlyObj = selectedVehicle.value!['hourlyRate'];
    final hourlyRate = hourlyObj is Map ? double.tryParse(hourlyObj['\$numberDecimal'].toString()) ?? 0 : (hourlyObj != null ? double.tryParse(hourlyObj.toString()) ?? 0 : 0);

    // Auto-switch logic
    if (hourlyRate > 0) {
      final days = (durationHours / 24).floor();
      final remainderHours = durationHours % 24;
      
      final costRemainderByHour = remainderHours * hourlyRate;
      // If remainder by hour exceeds daily rate, just charge a full day for the remainder
      final costRemainder = costRemainderByHour > dailyRate ? dailyRate : costRemainderByHour;
      
      estimatedPrice.value = (days * dailyRate) + costRemainder;
    } else {
      // Daily only
      final days = (durationHours / 24).ceil();
      estimatedPrice.value = days * dailyRate;
    }
  }

  void setDates(DateTime? start, DateTime? end) {
    pickupDate.value = start;
    returnDate.value = end;
    calculatePrice();
  }

  void setTimes(TimeOfDay? pickup, TimeOfDay? ret) {
    pickupTime.value = pickup;
    returnTime.value = ret;
    calculatePrice();
  }

  void proceedToConfirm() {
    if (estimatedPrice.value <= 0) return;
    Get.toNamed('/car-rental/confirm');
  }

  Future<void> submitBooking(String cardId) async {
    if (selectedVehicle.value == null) return;
    
    isSubmitting.value = true;
    error.value = '';

    final pickup = DateTime(pickupDate.value!.year, pickupDate.value!.month, pickupDate.value!.day, pickupTime.value!.hour, pickupTime.value!.minute);
    final ret = DateTime(returnDate.value!.year, returnDate.value!.month, returnDate.value!.day, returnTime.value!.hour, returnTime.value!.minute);

    try {
      // Step 1: Create the booking
      final createResponse = await _httpService.post('/api/car-rental/bookings', body: {
        'vehicleId': selectedVehicle.value!['_id'],
        'pickupDateTime': pickup.toIso8601String(),
        'returnDateTime': ret.toIso8601String(),
        'rentalMode': rentalMode.value,
        'paymentMethod': 'card', // Always card for now
        'paymentAmount': estimatedPrice.value,
      });
      
      final createData = _httpService.handleResponse(createResponse);
      if (createData['status'] != 'success') {
        error.value = createData['message'] ?? 'Booking failed';
        isSubmitting.value = false;
        return;
      }

      final bookingId = createData['data']['_id'];

      // Step 2: Initialize payment
      final payResponse = await _httpService.post('/api/car-rental/bookings/$bookingId/pay', body: {
        'cardId': cardId.isNotEmpty ? cardId : null,
      });

      final payData = _httpService.handleResponse(payResponse);
      if (payData['status'] == 'success') {
        if (payData['charged'] == true) {
          // Charged successfully via saved card
          Get.offAllNamed('/car-rental/success');
        } else if (payData['requiresOtp'] == true || payData['authorization_url'] != null) {
          // Route to WebView for 3DS or new card payment link
          final url = payData['authorization_url'] ?? payData['url'] ?? ''; 
          if (url.isNotEmpty) {
             final result = await Get.to(() => PaystackWebViewScreen(authorizationUrl: url));
             if (result == 'success') {
               Get.offAllNamed('/car-rental/success');
             } else {
               error.value = 'Payment was not completed';
             }
          } else {
            error.value = 'Payment authorization failed: URL missing';
          }
        } else {
           Get.offAllNamed('/car-rental/success');
        }
      } else {
        error.value = payData['message'] ?? 'Payment failed';
      }
    } catch (e) {
      print('Booking error: $e');
      error.value = 'Failed to submit booking. Check your connection.';
    } finally {
      isSubmitting.value = false;
    }
  }
}
