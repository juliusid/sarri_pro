class ApiConfig {
  // Base URLs for different environments
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
  static String get webSocketUrl => '$baseUrl/driver/websocket';

  // Auth endpoints
  static String get loginEndpoint => '$baseUrl/auth/client/login'; // Corrected
  static String get signupEndpoint =>
      '$baseUrl/auth/client/register'; // Corrected
  static String get verifyEndpoint =>
      '$baseUrl/auth/client/verify-otp'; // Corrected
  static String get googleAuthEndpoint => '$baseUrl/client/google'; // New
  static String get logoutEndpoint => '$baseUrl/auth/logout';

  // -- NEW UNIFIED REGISTRATION ENDPOINTS --
  static String get verifyUserEmailEndpoint =>
      '$baseUrl/auth/user/verifyUserEmail';
  static String get verifyOtpEndpoint => '$baseUrl/auth/user/verify-otp';

  // New Driver Endpoints
  // static String get driverVerifyEmailEndpoint =>
  //     '$baseUrl/driverAuth/driver/verifyDriverEmail';
  // static String get driverVerifyOtpEndpoint =>
  //     '$baseUrl/driverAuth/driver/verifyDriverOtp';
  static String get driverRegisterEndpoint =>
      '$baseUrl/driverAuth/driver/register';
  static String get driverLoginEndpoint => '$baseUrl/driverAuth/driver/login';
  static String get driverUploadImagesEndpoint =>
      '$baseUrl/driverAuth/driver/upload-images';

  // New Password Reset Endpoints
  static String get forgotPasswordEndpoint =>
      '$baseUrl/auth/user/forgot-password';
  static String get resetPasswordEndpoint =>
      '$baseUrl/auth/user/reset-password';

  // New Client Ride Endpoints
  static String get calculatePriceEndpoint =>
      '$baseUrl/clientRide/calculate-price';
  static String get bookRideEndpoint => '$baseUrl/clientRide/bookRide';
  static String get checkAvailableDriversEndpoint =>
      '$baseUrl/clientRide/checkingAvailableDrivers';
  static String get cancelRideEndpoint => '$baseUrl/clientRide/cancel-ride';
  static String get checkRideStatusEndpoint =>
      '$baseUrl/clientRide/checkRideStatus';

  //   // User endpoints
  //   static String get userProfileEndpoint => '$baseUrl/user/profile';
  //   static String get updateProfileEndpoint => '$baseUrl/user/profile';

  //   // Ride endpoints
  //   static String get rideRequestEndpoint => '$baseUrl/rides/request';
  //   static String get rideStatusEndpoint => '$baseUrl/rides';
  //   static String get rideHistoryEndpoint => '$baseUrl/rides/history';

  //   // Payment endpoints
  //   static String get paymentMethodsEndpoint => '$baseUrl/payments/methods';
  //   static String get walletEndpoint => '$baseUrl/payments/wallet';

  //   // Driver endpoints
  //   static String get nearbyDriversEndpoint => '$baseUrl/drivers/nearby';
  //   static String get driverLocationEndpoint => '$baseUrl/drivers/location';
  //
}
