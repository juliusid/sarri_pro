// TODO: Update these URLs with your actual API endpoints
class ApiEndpoints {
  // Replace these with your actual API base URLs
  static const String devBaseUrl = 'https://sarriride.onrender.com';
  static const String stagingBaseUrl = 'https://sarriride.onrender.com';
  static const String prodBaseUrl = 'https://sarriride.onrender.com';
  
  // API version (update if your API uses a different version)
  static const String apiVersion = 'v1';
  
  // Auth endpoints (update these to match your API)
  static const String login = '/auth/client/login';
  static const String register = '/auth/client/register';
  static const String refreshToken = '/auth/client/refresh';
  static const String logout = '/auth/client/logout';
  
  // User endpoints
  static const String userProfile = '/user/profile';
  static const String updateProfile = '/user/profile';
  
  // Ride endpoints
  static const String rideRequest = '/rides/request';
  static const String rideStatus = '/rides';
  static const String rideHistory = '/rides/history';
  
  // Payment endpoints
  static const String paymentMethods = '/payments/methods';
  static const String wallet = '/payments/wallet';
  
  // Driver endpoints
  static const String nearbyDrivers = '/drivers/nearby';
  static const String driverLocation = '/drivers/location';
  
  // Helper method to get full endpoint URL
  static String getEndpoint(String baseUrl, String endpoint) {
    return '$baseUrl/api/$apiVersion$endpoint';
  }
}
