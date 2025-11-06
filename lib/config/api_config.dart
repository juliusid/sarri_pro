// lib/config/api_config.dart
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
  // static String get driverUploadImagesEndpoint => '$baseUrl/driverAuth/driver/upload-images'; // Confirm path

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
}
