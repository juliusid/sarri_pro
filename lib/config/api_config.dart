// lib/config/api_config.dart
class ApiConfig {
  // Base URLs for different environments
  static const String apiKey = "the_sarriride_2025@development_Backend";
  static const String _devBaseUrl =
      'https://sarriride.onrender.com'; // Replace with your dev API URL
  static const String _stagingBaseUrl =
      'https://sarriride.onrender.com'; // Replace with your staging API URL
  static const String _prodBaseUrl =
      'https://sarriride.onrender.com'; // Replace with your production API URL

  // Timeouts
  static const Duration _connectionTimeout = Duration(seconds: 30);
  static const Duration _receiveTimeout = Duration(seconds: 30);

  // Headers
  static const Map<String, String> _defaultHeaders = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    'User-Agent': 'SarriRide/1.0.0',
    'x-api-key': apiKey,
  };

  // Get base URL based on environment
  static String get baseUrl {
    // TODO: Replace this with proper environment detection
    // For now, using dev. You can use build flavors or environment variables
    const bool isProduction = bool.fromEnvironment('dart.vm.product');
    const bool isStaging = bool.fromEnvironment('dart.vm.staging');

    if (isProduction) {
      return _prodBaseUrl;
    } else if (isStaging) {
      return _stagingBaseUrl;
    } else {
      return _devBaseUrl;
    }
  }

  // Get connection timeout
  static Duration get connectionTimeout => _connectionTimeout;

  // Get receive timeout
  static Duration get receiveTimeout => _receiveTimeout;

  // Get default headers
  static Map<String, String> get defaultHeaders => Map.from(_defaultHeaders);

  /// Returns the base URL for the WebSocket connection.
  static String get webSocketUrl => baseUrl;

  // Auth endpoints
  static String get loginEndpoint => '$baseUrl/auth/client/login';
  static String get signupEndpoint => '$baseUrl/auth/client/register';
  // Removed verifyEndpoint as verifyOtpEndpoint covers it
  static String get googleAuthEndpoint =>
      '$baseUrl/client/google'; // Assuming correct path
  static String get logoutEndpoint =>
      '$baseUrl/auth/logout'; // Assuming correct path

  // -- UNIFIED REGISTRATION ENDPOINTS --
  static String get verifyUserEmailEndpoint =>
      '$baseUrl/auth/user/verifyUserEmail';
  static String get verifyOtpEndpoint => '$baseUrl/auth/user/verify-otp';
  static String get reconnectEndpoint => '$baseUrl/reconnect/reconnectToTrip';
  static String get sendPhoneOtpEndpoint =>
      '$baseUrl/phonenumber/send-OTP-phonenumber';
  static String get verifyPhoneOtpEndpoint =>
      '$baseUrl/phonenumber/verify-OTP-phonenumber';
  static String get resendPhoneOtpEndpoint =>
      '$baseUrl/phonenumber/resend-OTP-phonenumber';
  static String getChatMessagesEndpoint(String chatId) =>
      '$baseUrl/chatRoutes/chat/$chatId/messages';
  static String get sendChatEndpoint => '$baseUrl/chatRoutes/chat/message';

  static String sendMessageEndpoint(String emergencyId) =>
      '$baseUrl/emergency/$emergencyId/messages';
  // Call Endpoints
  static String get initiateCallEndpoint => '$baseUrl/call/initiate';
  static String get acceptCallEndpoint => '$baseUrl/call/answer';
  static String get rejectCallEndpoint => '$baseUrl/call/reject';
  static String get endCallEndpoint => '$baseUrl/call/end';
  static String getCallHistoryEndpoint(String tripId) =>
      '$baseUrl/call/history/$tripId'; // Added
  static String get createEmergency => '$baseUrl/emergency/create-emergency';
  static String getEmergencyDetailsEndpoint(String emergencyId) =>
      '$baseUrl/emergency/$emergencyId';

  // --- REFRESH TOKEN ENDPOINTS (FROM USER) ---
  static String get clientRefreshEndpoint =>
      '$baseUrl/auth/client/refresh-Token'; // Corrected path
  static String get driverRefreshEndpoint =>
      '$baseUrl/driverAuth/driver/refresh-token'; // Corrected path
  // --- END REFRESH ENDPOINTS ---

  // Driver Endpoints
  static String get driverRegisterEndpoint =>
      '$baseUrl/driverAuth/driver/register';
  static String get driverLoginEndpoint => '$baseUrl/driverAuth/driver/login';
  static String get driverProfileEndpoint =>
      '$baseUrl/driverRides/driver/profile'; // Added profile endpoint
  static String get driverStatusEndpoint => '$baseUrl/driverRides/getStatus';
  static String get startBreakEndpoint => '$baseUrl/driverRides/break/start';
  static String get endBreakEndpoint => '$baseUrl/driverRides/break/end';
  static String get acceptRideEndpoint => '$baseUrl/driverRides/acceptRide';
  static String get startTripEndpoint => '$baseUrl/driverRides/startTrip';
  static String get endTripEndpoint => '$baseUrl/driverRides/endTrip';
  static String get driverUpdateBankEndpoint =>
      '$baseUrl/driverAuth/driver/updateBankdetails';
  static String get driverBankListEndpoint =>
      '$baseUrl/driverAuth/driver/banklist';
  static String get driverTripHistoryEndpoint =>
      '$baseUrl/driverRides/driverTripHistory';
  // Driver Payment & Wallet Endpoints
  static String get cashPaymentConfirmEndpoint =>
      '$baseUrl/payment/cash/confirm';
  static String get initiateCashPaymentEndpoint =>
      '$baseUrl/payment/trip/cash/initialize';
  static String get driverDebtStatusEndpoint => '$baseUrl/payment/debt/status';
  static String get driverPayDebtEndpoint => '$baseUrl/payment/debt/pay';
  static String get driverWalletBalanceEndpoint =>
      '$baseUrl/payment/wallet/balance';
  static String get driverWalletTransactionsEndpoint =>
      '$baseUrl/payment/wallet/transactions';
  static String get driverWalletWithdrawEndpoint =>
      '$baseUrl/payment/wallet/withdraw';
  static String get driverWalletPendingEarningsEndpoint =>
      '$baseUrl/payment/wallet/pending-earnings';
  static String get driverWalletStatisticsEndpoint =>
      '$baseUrl/payment/wallet/statistics';
  static String get driverWalletVerifyBankEndpoint =>
      '$baseUrl/payment/wallet/verify-bank';
  static String get driverWalletWithdrawalsEndpoint =>
      '$baseUrl/payment/wallet/withdrawals';
  // static String get driverUploadImagesEndpoint => '$baseUrl/driverAuth/driver/upload-images'; // Confirm path
  static String get driverUploadImagesEndpoint =>
      '$baseUrl/driverAuth/driver/upload-images';

  // Password Reset Endpoints
  static String get forgotPasswordEndpoint =>
      '$baseUrl/auth/user/forgot-password';
  static String get resetPasswordEndpoint =>
      '$baseUrl/auth/user/reset-password';

  // Client Ride Endpoints
  static String get calculatePriceEndpoint =>
      '$baseUrl/clientRide/calculate-price';
  static String get bookRideEndpoint => '$baseUrl/clientRide/bookRide';
  static String get checkAvailableDriversEndpoint =>
      '$baseUrl/clientRide/checkingAvailableDrivers';
  static String get cancelRideEndpoint => '$baseUrl/clientRide/cancel-ride';
  static String get checkRideStatusEndpoint =>
      '$baseUrl/clientRide/checkRideStatus';

  // Client endpoints
  static String get clientProfileEndpoint => '$baseUrl/auth/client/profile';
  static String get updateProfilePictureEndpoint =>
      '$baseUrl/auth/client/update-profilePicture';
  static String get clientTripHistoryEndpoint =>
      '$baseUrl/clientRide/client/triphistory';
  static String get savePlaceEndpoint => '$baseUrl/saved/save-place';
  static String get getPlacesEndpoint => '$baseUrl/saved/get-place';
  static String updatePlaceEndpoint(String id) => '$baseUrl/saved/$id';
  static String deletePlaceEndpoint(String id) => '$baseUrl/saved/$id';

  static String get shareLink => '$baseUrl/sharelocation/createSharelink';

  // Payment Endpoints
  static String get addPaymentCardEndpoint => '$baseUrl/payment/card/add';
  static String get listPaymentCardsEndpoint => '$baseUrl/payment/cards';
  static String get initiateTripPaymentEndpoint => '$baseUrl/payment/trip/init';
  static String get switchPaymentMethodEndpoint =>
      '$baseUrl/payment/switch-method';
  // Note: The callback endpoints are for backend/webview use, not direct app calls.

  // Rating Endpoints
  static String get rateDriverEndpoint => '$baseUrl/rating/rate-driver';
  static String updateRatingEndpoint(String ratingId) =>
      '$baseUrl/rating/update-rating/$ratingId';
  static String getTripRatingEndpoint(String tripId) =>
      '$baseUrl/rating/trip/$tripId';
  static String get clientRatingsEndpoint =>
      '$baseUrl/rating/my-ratings'; // Assuming "fair" was a typo for "rating" or "for"
  static String deleteRatingEndpoint(String ratingId) =>
      '$baseUrl/rating/$ratingId';
  static String get driverRatingsEndpoint =>
      '$baseUrl/rating/my-driver-ratings';
}
