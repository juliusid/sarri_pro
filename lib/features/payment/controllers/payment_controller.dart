import 'package:get/get.dart';
import 'package:sarri_ride/config/api_config.dart';
import 'package:sarri_ride/core/services/http_service.dart';
import 'package:sarri_ride/utils/helpers/helper_functions.dart';
import 'package:sarri_ride/features/payment/screens/paystack_webview_screen.dart';
import 'package:get_storage/get_storage.dart';

/// Outcome of a payment initiation attempt.
enum PaymentResult {
  /// Payment completed and confirmed.
  success,

  /// Cash or transfer — request sent, waiting for driver/backend to confirm.
  awaitingConfirmation,

  /// Payment definitively failed.
  failed,

  /// WebView closed without a clear intercept; polling/socket will resolve it.
  unknown,
}

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

  final HttpService _httpService = HttpService.instance;

  final RxList<PaymentCardModel> savedCards = <PaymentCardModel>[].obs;
  final RxBool isLoading = false.obs;
  final RxBool isAddingCard = false.obs;
  final RxBool isPaying = false.obs;

  /// True while waiting for driver to confirm a cash/transfer payment.
  final RxBool isAwaitingCashConfirmation = false.obs;

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

  /// Initiates the "Add Card" flow via Paystack WebView.
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

        final result = await Get.to(
          () => PaystackWebViewScreen(authorizationUrl: authUrl),
        );

        if (result == 'success') {
          THelperFunctions.showSuccessSnackBar(
            'Success',
            'Your card has been added successfully!',
          );
        } else if (result == 'cancelled') {
          THelperFunctions.showSnackBar('Card verification was cancelled.');
        } else {
          THelperFunctions.showSnackBar('Verifying card status...');
        }

        await fetchSavedCards();

        if (savedCards.isNotEmpty && result != 'success') {
          THelperFunctions.showSuccessSnackBar(
            'Success',
            'Card verified and saved!',
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

  /// Initiates a trip payment.
  ///
  /// Returns a [PaymentResult] so the UI can react appropriately to each
  /// distinct outcome instead of guessing from a boolean.
  Future<PaymentResult> initiateTripPayment(
    String tripId, {
    String? cardId,
    required String paymentMethod, // 'card', 'cash', 'transfer'
  }) async {
    if (isPaying.value) return PaymentResult.failed;
    isPaying.value = true;

    try {
      final storage = GetStorage();
      final bool isPackageDelivery =
          storage.read('active_ride_mode') == 'package_delivery';

      final Map<String, dynamic> requestBody = {
        "tripId": tripId,
        "paymentMethod": paymentMethod.toLowerCase(),
      };

      if (paymentMethod.toLowerCase() == "card" && cardId != null) {
        requestBody["cardId"] = cardId;
      }

      final String endpoint = isPackageDelivery
          ? ApiConfig.packagePaymentInitEndpoint
          : ApiConfig.initiateTripPaymentEndpoint;

      final response = await _httpService.post(
        endpoint,
        body: requestBody,
      );

      final responseData = _httpService.handleResponse(response);

      if (responseData['status'] == 'success') {
        // --- Cash / Transfer: driver must confirm ---
        if (responseData['requiresDriverConfirmation'] == true) {
          isAwaitingCashConfirmation.value = true;
          return PaymentResult.awaitingConfirmation;
        }

        // --- Card: already charged via saved authorization ---
        if (responseData['charged'] == true) {
          return PaymentResult.success;
        }

        // --- Card OTP required (rare) ---
        if (responseData['requiresOtp'] == true) {
          THelperFunctions.showSnackBar(
            'Your card requires OTP. Please use a different card or pay with cash.',
          );
          return PaymentResult.failed;
        }

        // --- Card: Paystack authorization URL (new card charge) ---
        if (responseData['authorization_url'] != null) {
          final String authUrl = responseData['authorization_url'];

          // Close any stale dialogs before pushing the WebView
          if (Get.isDialogOpen ?? false) Get.back();

          final result = await Get.to(
            () => PaystackWebViewScreen(authorizationUrl: authUrl),
          );

          if (result == 'success') {
            return PaymentResult.success;
          } else if (result == 'cancelled') {
            THelperFunctions.showSnackBar('Payment was cancelled.');
            return PaymentResult.failed;
          } else {
            // WebView closed without a clean redirect intercept.
            // The payment may still have processed — socket/polling will confirm.
            THelperFunctions.showSnackBar(
              'Payment submitted. Confirming status automatically…',
            );
            return PaymentResult.unknown;
          }
        }

        // Fallback: generic success (e.g. wallet auto-debit)
        return PaymentResult.success;
      } else {
        throw Exception(
          responseData['message'] ?? 'Payment initialization failed',
        );
      }
    } catch (e) {
      String errorMsg = e is ApiException ? e.message : e.toString();
      THelperFunctions.showErrorSnackBar('Payment Failed', errorMsg);
      return PaymentResult.failed;
    } finally {
      isPaying.value = false;
    }
  }

  /// Called when the backend confirms payment (via socket or polling).
  void onPaymentConfirmedExternally() {
    isAwaitingCashConfirmation.value = false;
  }
}
