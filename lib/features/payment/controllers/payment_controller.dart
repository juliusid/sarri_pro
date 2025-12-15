import 'package:get/get.dart';
import 'package:sarri_ride/config/api_config.dart';
import 'package:sarri_ride/core/services/http_service.dart';
import 'package:sarri_ride/features/ride/controllers/ride_controller.dart';
import 'package:sarri_ride/utils/helpers/helper_functions.dart';
import 'package:sarri_ride/features/payment/screens/paystack_webview_screen.dart';

/// Model for a saved payment card
class PaymentCardModel {
  final String cardId;
  final String last4;
  final String brand;
  final String cardType;
  final String bank;
  final bool isDefault;
  final String expiry;

  PaymentCardModel({
    required this.cardId,
    required this.last4,
    required this.brand,
    required this.cardType,
    required this.bank,
    required this.isDefault,
    required this.expiry,
  });

  factory PaymentCardModel.fromJson(Map<String, dynamic> json) {
    return PaymentCardModel(
      cardId: json['cardId'] as String,
      last4: json['last4'] as String,
      brand: (json['brand'] as String?)?.capitalizeFirst ?? 'Card',
      cardType: json['cardType'] as String,
      bank: json['bank'] as String,
      isDefault: json['isDefault'] as bool,
      expiry: json['expiry'] as String,
    );
  }

  String get displayName => '$brand **** $last4';
  String get displayDetails => '$bank • Expires $expiry';
}

class PaymentController extends GetxController {
  static PaymentController get instance => Get.find();

  // --- FIX: Use a getter so it doesn't crash on app start ---
  // RideController is not available in main(), only on the map screen.
  RideController get _rideController => Get.find<RideController>();
  // ----------------------------------------------------------

  final HttpService _httpService = HttpService.instance;

  final RxList<PaymentCardModel> savedCards = <PaymentCardModel>[].obs;
  final RxBool isLoading = false.obs;
  final RxBool isAddingCard = false.obs;
  final RxBool isPaying = false.obs;

  @override
  void onInit() {
    super.onInit();
  }

  /// Fetches the list of saved payment cards from the API
  Future<void> fetchSavedCards() async {
    isLoading.value = true;
    try {
      final response = await _httpService.get(
        ApiConfig.listPaymentCardsEndpoint,
      );
      final responseData = _httpService.handleResponse(response);

      if (responseData['status'] == 'success' && responseData['data'] is List) {
        final List<dynamic> cardList = responseData['data'];
        savedCards.value = cardList
            .map((json) => PaymentCardModel.fromJson(json))
            .toList();

        print("Fetched ${savedCards.length} saved cards.");
      } else {
        throw Exception(responseData['message'] ?? 'Failed to load cards');
      }
    } catch (e) {
      String errorMsg = e is ApiException ? e.message : e.toString();
      THelperFunctions.showErrorSnackBar(
        'Error',
        'Could not load saved cards: $errorMsg',
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// Initiates the "Add Card" flow
  Future<void> addNewCard() async {
    isAddingCard.value = true;
    THelperFunctions.showSnackBar('Initializing secure payment...');

    try {
      final response = await _httpService.post(
        ApiConfig.addPaymentCardEndpoint,
      );
      final responseData = _httpService.handleResponse(response);

      if (responseData['status'] == 'success' &&
          responseData['authorization_url'] != null) {
        final String authUrl = responseData['authorization_url'];

        print("PAYMENT CONTROLLER: Opening WebView. Waiting for result...");
        final result = await Get.to(
          () => PaystackWebViewScreen(authorizationUrl: authUrl),
        );

        print("PAYMENT CONTROLLER: WebView closed. Received result: '$result'");

        if (result == 'success') {
          THelperFunctions.showSuccessSnackBar(
            'Success',
            'Your card has been added successfully!',
          );
          await fetchSavedCards();
        } else if (result == 'cancelled') {
          THelperFunctions.showSnackBar('Card verification was cancelled.');
        } else {
          THelperFunctions.showErrorSnackBar(
            'Error',
            'Card verification failed. Please try again.',
          );
        }
      } else {
        throw Exception(
          responseData['message'] ?? 'Failed to initialize card verification',
        );
      }
    } catch (e) {
      String errorMsg = e is ApiException ? e.message : e.toString();
      THelperFunctions.showErrorSnackBar(
        'Error',
        'Could not add card: $errorMsg',
      );
    } finally {
      isAddingCard.value = false;
    }
  }

  /// Initiates a trip payment
  Future<bool> initiateTripPayment(
    String tripId, {
    String? cardId,
    required String paymentMethod, // 'card', 'cash', 'transfer'
  }) async {
    if (isPaying.value) return false;
    isPaying.value = true;

    try {
      // Construct body based on documentation
      // req: { "tripId": "...", "paymentMethod": "card", "cardId": "..." }
      final Map<String, dynamic> requestBody = {
        "tripId": tripId,
        "paymentMethod": paymentMethod.toLowerCase(),
      };

      // Add cardId only if method is card
      if (paymentMethod.toLowerCase() == "card" && cardId != null) {
        requestBody["cardId"] = cardId;
      }

      // Use the correct endpoint: /payment/trip/init
      final response = await _httpService.post(
        ApiConfig.initiateTripPaymentEndpoint,
        body: requestBody,
      );

      final responseData = _httpService.handleResponse(response);

      if (responseData['status'] == 'success') {
        // 1. Handle Cash / Transfer (Driver Confirmation Required)
        if (responseData['requiresDriverConfirmation'] == true) {
          THelperFunctions.showSnackBar(
            'Waiting for driver to confirm payment...',
          );
          return true; // Request sent successfully
        }

        // 2. Handle Card (Authorization URL)
        if (responseData['authorization_url'] != null) {
          final String authUrl = responseData['authorization_url'];
          final result = await Get.to(
            () => PaystackWebViewScreen(authorizationUrl: authUrl),
          );

          if (result == 'success') {
            THelperFunctions.showSuccessSnackBar(
              'Success',
              'Payment processing...',
            );
            return true;
          } else if (result == 'cancelled') {
            THelperFunctions.showSnackBar('Payment was cancelled.');
            return false;
          } else {
            throw Exception('Card payment verification failed.');
          }
        }

        // 3. Fallback Success (e.g. Wallet auto-debit if supported)
        THelperFunctions.showSuccessSnackBar('Success', 'Payment initiated!');
        return true;
      } else {
        throw Exception(
          responseData['message'] ?? 'Payment initialization failed',
        );
      }
    } catch (e) {
      String errorMsg = e is ApiException ? e.message : e.toString();
      THelperFunctions.showErrorSnackBar('Payment Failed', errorMsg);
      return false;
    } finally {
      isPaying.value = false;
    }
  }
}
