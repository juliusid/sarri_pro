import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:sarri_ride/core/services/http_service.dart';
import 'package:sarri_ride/utils/helpers/helper_functions.dart';
import 'dart:async';
import 'package:sarri_ride/features/payment/screens/paystack_webview_screen.dart';
import 'package:sarri_ride/features/warehouse/screens/warehouse_qr_code_screen.dart';
import 'package:sarri_ride/utils/constants/colors.dart';

class WarehouseBookingController extends GetxController {
  final HttpService _httpService = HttpService.instance;

  // Data from backend
  final RxList<Map<String, dynamic>> warehouses = <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> pricingRoutes = <Map<String, dynamic>>[].obs;
  final RxList<String> prohibitedItems = <String>[].obs;

  // Maintenance Mode
  final RxBool isMaintenanceMode = false.obs;

  // Form selections
  final RxString selectedWarehouseId = ''.obs;
  final RxString selectedDestinationState = ''.obs;
  final RxBool prohibitedItemsAcknowledged = false.obs;
  final RxSet<String> checkedProhibitedItems = <String>{}.obs;
  DateTime? prohibitedItemsAcknowledgedAt;
  bool _isCheckingPayment = false;

  // Sender Details
  final senderName = TextEditingController();
  final senderPhone = TextEditingController();
  final senderAddress = TextEditingController();

  // Recipient Details
  final recipientName = TextEditingController();
  final recipientPhone = TextEditingController();
  final recipientAddress = TextEditingController();

  // Item details (Assuming 1 item for now to simplify UI, can expand later)
  final itemDescription = TextEditingController();
  final itemDeclaredWeight = TextEditingController();
  final itemDeclaredValue = TextEditingController();
  final itemLength = TextEditingController();
  final itemWidth = TextEditingController();
  final itemHeight = TextEditingController();

  // Price estimate
  final RxDouble estimatedPrice = 0.0.obs;
  final RxBool isLoadingPrice = false.obs;

  @override
  void onInit() {
    super.onInit();
    _fetchWarehouses();
    _fetchProhibitedItems();
  }

  Future<void> _fetchWarehouses() async {
    isMaintenanceMode.value = false;
    try {
      final response = await _httpService.get('/api/warehouse/warehouses');
      final data = _httpService.handleResponse(response);
      if (data['status'] == 'success') {
        final list = List<Map<String, dynamic>>.from(data['data']);
        if (list.isEmpty) {
          isMaintenanceMode.value = true;
        } else {
          warehouses.value = list;
        }
      } else {
        isMaintenanceMode.value = true;
      }
    } catch (e) {
      print('Error fetching warehouses: $e');
      isMaintenanceMode.value = true;
    }
  }

  void retryFetchWarehouses() {
    _fetchWarehouses();
    _fetchProhibitedItems();
  }

  void toggleProhibitedItemChecked(String item, bool? checked) {
    if (checked == true) {
      checkedProhibitedItems.add(item);
    } else {
      checkedProhibitedItems.remove(item);
      prohibitedItemsAcknowledged.value = false;
      prohibitedItemsAcknowledgedAt = null;
    }
  }

  Future<void> _fetchProhibitedItems() async {
    try {
      final response = await _httpService.get('/api/warehouse/prohibited-items');
      final data = _httpService.handleResponse(response);
      if (data['status'] == 'success') {
        prohibitedItems.value = List<String>.from(data['data']);
      }
    } catch (e) {
      print('Error fetching prohibited items: $e');
    }
  }

  Future<void> fetchPricingRoutes(String warehouseId) async {
    selectedWarehouseId.value = warehouseId;
    selectedDestinationState.value = '';
    estimatedPrice.value = 0.0;
    
    try {
      final response = await _httpService.get('/api/warehouse/pricing/routes?warehouseId=$warehouseId');
      final data = _httpService.handleResponse(response);
      if (data['status'] == 'success') {
        pricingRoutes.value = List<Map<String, dynamic>>.from(data['data']);
      }
    } catch (e) {
      print('Error fetching pricing routes: $e');
      pricingRoutes.clear();
    }
  }

  void calculatePrice() {
    if (selectedDestinationState.isEmpty || itemDeclaredWeight.text.isEmpty) {
      estimatedPrice.value = 0.0;
      return;
    }

    final route = pricingRoutes.firstWhere(
      (r) => r['destinationState'] == selectedDestinationState.value,
      orElse: () => {},
    );

    if (route.isEmpty) return;

    final basePrice = (route['basePrice'] as num).toDouble();
    final pricePerKg = (route['pricePerKg'] as num).toDouble();
    final weight = double.tryParse(itemDeclaredWeight.text) ?? 0.0;

    estimatedPrice.value = basePrice + (weight * pricePerKg);
  }

  void acknowledgeProhibitedItems(bool? value) {
    if (checkedProhibitedItems.length < prohibitedItems.length) {
      THelperFunctions.showWarningSnackBar(
        'Checklist Required',
        'Please read and check all prohibited items individually first.',
      );
      return;
    }
    prohibitedItemsAcknowledged.value = value ?? false;
    if (prohibitedItemsAcknowledged.value) {
      prohibitedItemsAcknowledgedAt = DateTime.now();
    } else {
      prohibitedItemsAcknowledgedAt = null;
    }
  }

  bool validateForm() {
    if (selectedWarehouseId.isEmpty) {
      THelperFunctions.showErrorSnackBar('Error', 'Please select a drop-off warehouse.');
      return false;
    }
    if (selectedDestinationState.isEmpty) {
      THelperFunctions.showErrorSnackBar('Error', 'Please select a destination state.');
      return false;
    }
    if (checkedProhibitedItems.length < prohibitedItems.length) {
      THelperFunctions.showErrorSnackBar('Error', 'You must read and check all prohibited items.');
      return false;
    }
    if (!prohibitedItemsAcknowledged.value) {
      THelperFunctions.showErrorSnackBar('Error', 'You must acknowledge the prohibited items list.');
      return false;
    }
    if (senderName.text.isEmpty || senderPhone.text.isEmpty || senderAddress.text.isEmpty) {
      THelperFunctions.showErrorSnackBar('Error', 'Please fill in all sender details.');
      return false;
    }
    if (recipientName.text.isEmpty || recipientPhone.text.isEmpty || recipientAddress.text.isEmpty) {
      THelperFunctions.showErrorSnackBar('Error', 'Please fill in all recipient details.');
      return false;
    }
    if (itemDescription.text.isEmpty || itemDeclaredWeight.text.isEmpty || itemDeclaredValue.text.isEmpty ||
        itemLength.text.isEmpty || itemWidth.text.isEmpty || itemHeight.text.isEmpty) {
      THelperFunctions.showErrorSnackBar('Error', 'Please fill in all package details.');
      return false;
    }

    final route = pricingRoutes.firstWhere((r) => r['destinationState'] == selectedDestinationState.value, orElse: () => {});
    if (route.isNotEmpty) {
      final weight = double.tryParse(itemDeclaredWeight.text) ?? 0.0;
      final maxWeight = (route['maxWeightPerItem'] as num?)?.toDouble() ?? double.infinity;
      if (weight > maxWeight) {
        THelperFunctions.showErrorSnackBar('Error', 'Item exceeds maximum weight of ${maxWeight}kg for this route.');
        return false;
      }
    }

    return true;
  }

  Map<String, dynamic> buildOrderPayload() {
    return {
      "warehouseId": selectedWarehouseId.value,
      "senderDetails": {
        "name": senderName.text,
        "phone": senderPhone.text,
        "address": senderAddress.text
      },
      "recipientDetails": {
        "name": recipientName.text,
        "phone": recipientPhone.text,
        "address": recipientAddress.text,
        "state": selectedDestinationState.value,
      },
      "items": [
        {
          "description": itemDescription.text,
          "declaredWeight": double.tryParse(itemDeclaredWeight.text) ?? 0.0,
          "declaredValue": double.tryParse(itemDeclaredValue.text) ?? 0.0,
          "dimensions": {
            "lengthCm": double.tryParse(itemLength.text) ?? 0.0,
            "widthCm": double.tryParse(itemWidth.text) ?? 0.0,
            "heightCm": double.tryParse(itemHeight.text) ?? 0.0
          },
          "destinationState": selectedDestinationState.value
        }
      ],
      "prohibitedItemsAcknowledgedAt": prohibitedItemsAcknowledgedAt?.toUtc().toIso8601String()
    };
  }

  void _showCheckingPaymentDialog() {
    _isCheckingPayment = true;
    Get.dialog(
      PopScope(
        canPop: false,
        child: Center(
          child: Card(
            color: Get.isDarkMode ? TColors.dark : Colors.white,
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: TColors.primary),
                  const SizedBox(height: 16),
                  const Text(
                    'Checking payment...',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      barrierDismissible: false,
    ).then((_) {
      _isCheckingPayment = false;
    });
  }

  Future<void> createOrder() async {
    if (!validateForm()) return;
    
    try {
      final payload = buildOrderPayload();
      THelperFunctions.showSnackBar('Creating order...');
      final response = await _httpService.post('/api/warehouse/orders', body: payload);
      final data = _httpService.handleResponse(response);
      
      if (data['status'] == 'success') {
        final paymentUrl = data['data']['paymentUrl'];
        final shipmentId = data['data']['shipmentId'];
        
        // Open Paystack WebView
        final result = await Get.to(() => PaystackWebViewScreen(authorizationUrl: paymentUrl));
        
        if (result == 'success' || result == null) {
          _showCheckingPaymentDialog();
          _pollPaymentStatus(shipmentId);
        } else {
          THelperFunctions.showSnackBar('Payment cancelled.');
        }
      }
    } catch (e) {
      print('Error creating order: $e');
      if (e is ApiException) {
        if (e.statusCode == 400 && e.data.containsKey('errors')) {
          final errorsList = e.data['errors'] as List;
          final errorMessages = errorsList.map((err) => "${err['message']}").join('\n');
          THelperFunctions.showErrorSnackBar('Validation Error', errorMessages);
        } else {
          THelperFunctions.showErrorSnackBar('Error', e.message);
        }
      } else {
        THelperFunctions.showErrorSnackBar('Error', 'Failed to create order: $e');
      }
    }
  }

  void _pollPaymentStatus(String shipmentId) {
    int attempts = 0;
    Timer.periodic(const Duration(seconds: 3), (timer) async {
      attempts++;
      if (attempts > 10) {
        timer.cancel();
        if (_isCheckingPayment) {
          Get.back();
        }
        THelperFunctions.showErrorSnackBar('Timeout', 'Could not confirm payment. Check history.');
        return;
      }
      try {
        final response = await _httpService.get('/api/warehouse/orders/$shipmentId');
        final data = _httpService.handleResponse(response);
        if (data['data']['paymentStatus'] == 'paid') {
          timer.cancel();
          if (_isCheckingPayment) {
            Get.back();
          }
          THelperFunctions.showSuccessSnackBar('Success', 'Order confirmed!');
          Get.off(() => WarehouseQRCodeScreen(shipmentId: shipmentId));
        }
      } catch (e) {
        // Ignore until timeout
      }
    });
  }

  @override
  void onClose() {
    senderName.dispose();
    senderPhone.dispose();
    senderAddress.dispose();
    recipientName.dispose();
    recipientPhone.dispose();
    recipientAddress.dispose();
    itemDescription.dispose();
    itemDeclaredWeight.dispose();
    itemDeclaredValue.dispose();
    itemLength.dispose();
    itemWidth.dispose();
    itemHeight.dispose();
    super.onClose();
  }
}
