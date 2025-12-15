// lib/core/services/http_service.dart

import 'dart:convert';
import 'dart:io';
import 'dart:math'; // For min function
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:get/get.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:sarri_ride/config/api_config.dart';
import 'package:sarri_ride/features/authentication/screens/login/login_screen_getx.dart';
import 'package:sarri_ride/utils/helpers/helper_functions.dart';
import 'package:sarri_ride/features/authentication/models/auth_model.dart'; // Needed for ClientData

class HttpService extends GetxService {
  static HttpService get instance => Get.find();

  late http.Client _client;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';

  String? _cachedAccessToken;
  String? _cachedRefreshToken;
  bool _isRefreshing = false; // Flag to prevent concurrent refresh attempts

  Future<HttpService> init() async {
    _client = http.Client();
    await _loadCachedTokens();
    return this;
    print("HttpService onInit (client and tokens loaded via init())");
  }

  @override
  void onInit() {
    super.onInit();
    _client = http.Client();
    _loadCachedTokens();
  }

  @override
  void onClose() {
    _client.close();
    super.onClose();
  }

  Future<void> _loadCachedTokens() async {
    _cachedAccessToken = await _storage.read(key: _accessTokenKey);
    _cachedRefreshToken = await _storage.read(key: _refreshTokenKey);
    if (_cachedAccessToken != null) {
      print(
        "=================================================================",
      );
      print("USER ACCESS TOKEN (Copy for Postman):");
      print(_cachedAccessToken);
      print(
        "=================================================================",
      );
    }
    print(
      "HTTP_SERVICE: Loaded cached tokens - Access: ${_cachedAccessToken != null}, Refresh: ${_cachedRefreshToken != null}",
    );
  }

  String? get accessToken => _cachedAccessToken;
  String? get refreshToken => _cachedRefreshToken;

  Future<void> storeTokens(String accessToken, String? refreshToken) async {
    print("HTTP_SERVICE: Attempting to store tokens...");
    await _storage.write(key: _accessTokenKey, value: accessToken);
    _cachedAccessToken = accessToken; // Update cache immediately
    print("HTTP_SERVICE: Access token stored & cached.");

    if (refreshToken != null && refreshToken.isNotEmpty) {
      // Check not empty
      await _storage.write(key: _refreshTokenKey, value: refreshToken);
      _cachedRefreshToken = refreshToken; // Update cache immediately
      print("HTTP_SERVICE: Refresh token stored & cached.");
    } else {
      // Ensure refresh token cache and storage are cleared if none provided or empty
      await _storage.delete(key: _refreshTokenKey);
      _cachedRefreshToken = null;
      print(
        "HTTP_SERVICE: No valid refresh token provided, cleared stored/cached one.",
      );
    }
  }

  Future<void> clearTokens() async {
    print("HTTP_SERVICE: Clearing stored tokens...");
    await _storage.delete(key: _accessTokenKey);
    await _storage.delete(key: _refreshTokenKey);
    _cachedAccessToken = null;
    _cachedRefreshToken = null;
    print("HTTP_SERVICE: Tokens cleared.");
  }

  Map<String, String> _getHeaders({
    Map<String, String>? additionalHeaders,
    bool requiresAuth = true,
  }) {
    final headers = Map<String, String>.from(ApiConfig.defaultHeaders);
    if (requiresAuth) {
      // Only add Auth header if required
      final currentAccessToken =
          accessToken; // Use the getter which reads from cache
      if (currentAccessToken != null) {
        print("HTTP_SERVICE: Adding Auth Header...");
        headers['Authorization'] = 'Bearer $currentAccessToken';
      } else {
        print(
          "HTTP_SERVICE: No access token found in cache for authenticated header.",
        );
      }
    } else {
      print("HTTP_SERVICE: Auth header not required for this request.");
    }
    if (additionalHeaders != null) {
      headers.addAll(additionalHeaders);
    }
    return headers;
  }

  // --- MODIFIED: refreshTokenImmediately ---
  /// Attempts to refresh the access token using the stored refresh token and userId.
  /// Returns true if refresh was successful, false otherwise.
  Future<bool> refreshTokenImmediately({
    required bool isDriver,
    required String userId,
  }) async {
    if (_isRefreshing) {
      print("HTTP_SERVICE: Refresh already in progress, skipping call.");
      // Wait for the ongoing refresh to complete
      int waitAttempts = 0;
      while (_isRefreshing && waitAttempts < 10) {
        // Wait up to ~1 second
        await Future.delayed(Duration(milliseconds: 100));
        waitAttempts++;
      }
      if (_isRefreshing) {
        print("HTTP_SERVICE: Wait for ongoing refresh timed out.");
        return false;
      }
      print("HTTP_SERVICE: Ongoing refresh completed. Proceeding check.");
      return accessToken != null;
    }

    final currentRefreshToken = refreshToken;
    if (currentRefreshToken == null || currentRefreshToken.isEmpty) {
      print("HTTP_SERVICE: Cannot refresh token - Refresh token is missing.");
      await clearTokens();
      _handleLogoutRedirect("Session invalid. Please log in again.");
      return false;
    }

    // --- ADDED: Check for userId ---
    if (userId.isEmpty) {
      print("HTTP_SERVICE: Cannot refresh token - User ID is missing.");
      await clearTokens();
      _handleLogoutRedirect(
        "Session invalid (User ID missing). Please log in again.",
      );
      return false;
    }
    // --- END ADDED ---

    _isRefreshing = true;
    print(
      "HTTP_SERVICE: Attempting token refresh (Role: ${isDriver ? 'Driver' : 'Client'}, UserID: $userId)...",
    );

    try {
      final refreshEndpoint = isDriver
          ? ApiConfig.driverRefreshEndpoint
          : ApiConfig.clientRefreshEndpoint;

      // --- MODIFIED: Add userId to request body ---
      final requestBody = json.encode({
        'refreshToken': currentRefreshToken,
        'userId': userId,
      });
      // --- END MODIFIED ---

      final response = await _client
          .post(
            Uri.parse(refreshEndpoint),
            headers: _getHeaders(
              requiresAuth: false,
            ), // Refresh doesn't need Bearer token
            body: requestBody, // Use new request body
          )
          .timeout(ApiConfig.receiveTimeout);

      print("HTTP_SERVICE: Refresh Response Status: ${response.statusCode}");
      // print("HTTP_SERVICE: Refresh Response Body: ${response.body}"); // Optional: Log body

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = json.decode(response.body);

        // Parse based on the provided response structure
        final data = responseData['data'];
        final newAccessToken = data?['accessToken'] as String?;
        final newRefreshToken = data?['refreshToken'] as String?;

        if (newAccessToken != null && newAccessToken.isNotEmpty) {
          await storeTokens(
            newAccessToken,
            newRefreshToken ?? currentRefreshToken,
          );
          print("HTTP_SERVICE: Token refresh successful. New tokens stored.");
          return true; // Indicate success
        } else {
          print(
            "HTTP_SERVICE: Token refresh failed - New access token not found in response: ${response.body}",
          );
          await clearTokens();
          _handleLogoutRedirect(
            "Your session has expired (refresh error). Please log in again.",
          );
          return false;
        }
      } else {
        print(
          "HTTP_SERVICE: Token refresh API call failed with status ${response.statusCode}. Body: ${response.body}. Logging out.",
        );
        await clearTokens();
        _handleLogoutRedirect("Your session has expired. Please log in again.");
        return false;
      }
    } catch (e) {
      print("HTTP_SERVICE: Exception during token refresh: $e. Logging out.");
      await clearTokens();
      _handleLogoutRedirect(
        "An error occurred during session refresh. Please log in again.",
      );
      return false;
    } finally {
      _isRefreshing = false; // Ensure flag is always reset
      print("HTTP_SERVICE: Refresh process finished.");
    }
  }
  // --- END MODIFIED ---

  // --- Wrapper for making requests with potential retry on 401 ---
  Future<http.Response> _makeRequest(
    Future<http.Response> Function() requestFunction, {
    bool requiresAuth = true,
    // Details needed for retry
    required String method,
    required String endpoint,
    Map<String, String>? headers,
    Map<String, dynamic>? body,
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      http.Response response = await requestFunction();

      if (response.statusCode == 401 && requiresAuth) {
        print(
          "HTTP_SERVICE: Received 401 for $method $endpoint. Attempting token refresh...",
        );

        // --- MODIFIED: Get UserID for refresh ---
        ClientData? currentUser =
            Get.isRegistered<ClientData>(tag: 'currentUser')
            ? Get.find<ClientData>(tag: 'currentUser')
            : null;

        if (currentUser == null || currentUser.id.isEmpty) {
          print(
            "HTTP_SERVICE: 401 received, but no user data/ID found. Logging out.",
          );
          _handleLogoutRedirect("Session invalid. Please log in again.");
          return response; // Return original 401
        }
        bool isDriver = currentUser.role == 'driver';
        String userId = currentUser.id;
        // --- END MODIFIED ---

        bool refreshed = await refreshTokenImmediately(
          isDriver: isDriver,
          userId: userId,
        ); // <-- PASS userId

        if (refreshed) {
          print(
            "HTTP_SERVICE: Token refreshed. Retrying original request $method $endpoint...",
          );
          // --- RETRY LOGIC (unchanged) ---
          Future<http.Response> Function() retryFunction;
          final uri = Uri.parse(
            endpoint,
          ).replace(queryParameters: queryParameters);
          final retryHeaders = _getHeaders(
            additionalHeaders: headers,
            requiresAuth: true,
          );

          switch (method.toUpperCase()) {
            case 'GET':
              retryFunction = () => _client.get(uri, headers: retryHeaders);
              break;
            case 'POST':
              retryFunction = () => _client.post(
                uri,
                headers: retryHeaders,
                body: body != null ? json.encode(body) : null,
              );
              break;
            case 'PUT':
              retryFunction = () => _client.put(
                uri,
                headers: retryHeaders,
                body: body != null ? json.encode(body) : null,
              );
              break;
            case 'DELETE':
              retryFunction = () => _client.delete(uri, headers: retryHeaders);
              break;
            default:
              print("HTTP_SERVICE: Unknown method '$method' for retry.");
              return response;
          }
          http.Response retryResponse = await retryFunction().timeout(
            ApiConfig.receiveTimeout,
          );
          print(
            "HTTP_SERVICE: Retry request completed with status: ${retryResponse.statusCode}",
          );
          return retryResponse;
          // --- END RETRY LOGIC ---
        } else {
          print(
            "HTTP_SERVICE: Refresh failed. Returning original 401 response for $method $endpoint.",
          );
          return response;
        }
      }

      return response; // Return original response if not 401
    } catch (e) {
      print(
        "HTTP_SERVICE: Network or timeout error during request ($method $endpoint): $e",
      );
      return http.Response(
        json.encode({
          'status': 'error',
          'message': 'Network error: ${e.toString()}',
        }),
        503,
        headers: {'content-type': 'application/json'},
      );
    }
  }

  // --- Standard HTTP Methods (unchanged, they use the wrapper) ---
  Future<http.Response> get(
    String endpoint, {
    Map<String, String>? headers,
    Map<String, dynamic>? queryParameters,
    bool requiresAuth = true,
  }) async {
    return await _makeRequest(
      () => _client.get(
        Uri.parse(endpoint).replace(queryParameters: queryParameters),
        headers: _getHeaders(
          additionalHeaders: headers,
          requiresAuth: requiresAuth,
        ),
      ),
      method: 'GET',
      endpoint: endpoint,
      headers: headers,
      queryParameters: queryParameters,
      requiresAuth: requiresAuth,
    );
  }

  Future<http.Response> post(
    String endpoint, {
    Map<String, String>? headers,
    Map<String, dynamic>? body,
    Map<String, dynamic>? queryParameters,
    bool requiresAuth = true,
  }) async {
    return await _makeRequest(
      () => _client.post(
        Uri.parse(endpoint).replace(queryParameters: queryParameters),
        headers: _getHeaders(
          additionalHeaders: headers,
          requiresAuth: requiresAuth,
        ),
        body: body != null ? json.encode(body) : null,
      ),
      method: 'POST',
      endpoint: endpoint,
      headers: headers,
      body: body,
      queryParameters: queryParameters,
      requiresAuth: requiresAuth,
    );
  }

  Future<http.Response> put(
    String endpoint, {
    Map<String, String>? headers,
    Map<String, dynamic>? body,
    Map<String, dynamic>? queryParameters,
    bool requiresAuth = true,
  }) async {
    return await _makeRequest(
      () => _client.put(
        Uri.parse(endpoint).replace(queryParameters: queryParameters),
        headers: _getHeaders(
          additionalHeaders: headers,
          requiresAuth: requiresAuth,
        ),
        body: body != null ? json.encode(body) : null,
      ),
      method: 'PUT',
      endpoint: endpoint,
      headers: headers,
      body: body,
      queryParameters: queryParameters,
      requiresAuth: requiresAuth,
    );
  }

  Future<http.Response> putMultipart(
    String endpoint, {
    required String fileKey,
    required File file,
    Map<String, String>? fields,
    bool requiresAuth = true,
  }) async {
    // This method does not use the `_makeRequest` wrapper because
    // multipart request logic is different.
    // It will, however, handle a 401 and attempt a refresh manually.

    http.Response response;

    try {
      final uri = Uri.parse(endpoint);
      var request = http.MultipartRequest('PUT', uri);

      // Add headers
      final headers = _getHeaders(requiresAuth: requiresAuth);
      request.headers.addAll(headers);

      // Add text fields
      if (fields != null) {
        request.fields.addAll(fields);
      }

      // Add file
      request.files.add(await http.MultipartFile.fromPath(fileKey, file.path));

      // Send request
      var streamedResponse = await _client
          .send(request)
          .timeout(ApiConfig.receiveTimeout);
      response = await http.Response.fromStream(streamedResponse);
    } catch (e) {
      print(
        "HTTP_SERVICE: Network or timeout error during multipart request ($endpoint): $e",
      );
      return http.Response(
        json.encode({
          'status': 'error',
          'message': 'Network error: ${e.toString()}',
        }),
        503,
        headers: {'content-type': 'application/json'},
      );
    }

    // Handle 401 retry
    if (response.statusCode == 401 && requiresAuth) {
      print(
        "HTTP_SERVICE: Received 401 for PUT multipart. Attempting token refresh...",
      );

      ClientData? currentUser = Get.isRegistered<ClientData>(tag: 'currentUser')
          ? Get.find<ClientData>(tag: 'currentUser')
          : null;

      if (currentUser == null || currentUser.id.isEmpty) {
        _handleLogoutRedirect("Session invalid. Please log in again.");
        return response; // Return original 401
      }

      bool isDriver = currentUser.role == 'driver';
      String userId = currentUser.id;

      bool refreshed = await refreshTokenImmediately(
        isDriver: isDriver,
        userId: userId,
      );

      if (refreshed) {
        print(
          "HTTP_SERVICE: Token refreshed. Retrying PUT multipart request...",
        );
        // Retry the request
        try {
          final retryUri = Uri.parse(endpoint);
          var retryRequest = http.MultipartRequest('PUT', retryUri);

          final retryHeaders = _getHeaders(
            requiresAuth: true,
          ); // Now has new token
          retryRequest.headers.addAll(retryHeaders);

          if (fields != null) retryRequest.fields.addAll(fields);

          retryRequest.files.add(
            await http.MultipartFile.fromPath(fileKey, file.path),
          );

          var retryStreamedResponse = await _client
              .send(retryRequest)
              .timeout(ApiConfig.receiveTimeout);
          response = await http.Response.fromStream(retryStreamedResponse);

          print(
            "HTTP_SERVICE: Retry PUT multipart completed with status: ${response.statusCode}",
          );
        } catch (e) {
          print("HTTP_SERVICE: Error during multipart retry: $e");
          return http.Response(
            json.encode({
              'status': 'error',
              'message': 'Network error on retry: ${e.toString()}',
            }),
            503,
            headers: {'content-type': 'application/json'},
          );
        }
      }
    }

    return response;
  }

  Future<http.Response> delete(
    String endpoint, {
    Map<String, String>? headers,
    Map<String, dynamic>? queryParameters,
    bool requiresAuth = true,
  }) async {
    return await _makeRequest(
      () => _client.delete(
        Uri.parse(endpoint).replace(queryParameters: queryParameters),
        headers: _getHeaders(
          additionalHeaders: headers,
          requiresAuth: requiresAuth,
        ),
      ),
      method: 'DELETE',
      endpoint: endpoint,
      headers: headers,
      queryParameters: queryParameters,
      requiresAuth: requiresAuth,
    );
  }
  // --- END Standard Methods ---

  /// Parses the response, handles errors, and performs global 401 logout (if refresh fails).
  Map<String, dynamic> handleResponse(http.Response response) {
    if (response.statusCode == 401) {
      print(
        "HTTP_SERVICE: handleResponse definitively caught 401 Unauthorized for ${response.request?.method} ${response.request?.url}",
      );
      if (!_isRefreshing) {
        _handleLogoutRedirect("Session expired. Please log in again.");
      } else {
        print(
          "HTTP_SERVICE: 401 caught, refresh was already in progress (likely failed). Logout redirect pending.",
        );
      }
      throw ApiException(message: "Session expired", statusCode: 401);
    }

    if (response.statusCode == 503) {
      print(
        "HTTP_SERVICE: handleResponse caught 503 Network Error for ${response.request?.method} ${response.request?.url}",
      );
      Map<String, dynamic> errorData = {
        'message': 'Network error occurred',
        'status': 'error',
      };
      try {
        if (response.body.isNotEmpty) errorData = json.decode(response.body);
      } catch (e) {}
      throw ApiException(
        message: errorData['message'],
        statusCode: 503,
        data: errorData,
      );
    }

    try {
      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (response.body.isEmpty)
          return {'status': 'success', 'message': 'Operation successful'};
        final decodedBody = json.decode(response.body);
        if (decodedBody is Map<String, dynamic>) {
          if (!decodedBody.containsKey('status'))
            decodedBody['status'] = 'success';
          return decodedBody;
        } else {
          return {'status': 'success', 'data': decodedBody};
        }
      } else {
        Map<String, dynamic> errorData = {
          'message': 'An unknown error occurred',
          'status': 'error',
        };
        try {
          if (response.body.isNotEmpty) errorData = json.decode(response.body);
        } catch (e) {
          print(
            "HTTP_SERVICE: Failed to decode error response body: ${response.body}",
          );
          errorData['message'] = response.reasonPhrase ?? 'Request failed';
        }
        if (!errorData.containsKey('status')) errorData['status'] = 'error';
        if (!errorData.containsKey('message'))
          errorData['message'] = response.reasonPhrase ?? 'Request failed';

        throw ApiException(
          message: errorData['message'],
          statusCode: response.statusCode,
          data: errorData,
        );
      }
    } on ApiException {
      rethrow;
    } catch (e) {
      print(
        "HTTP_SERVICE: Error processing response: $e. Body: ${response.body}",
      );
      throw ApiException(
        message: 'Invalid response format from server',
        statusCode: response.statusCode,
        data: {'raw_response': response.body},
      );
    }
  }

  /// Handles clearing tokens and redirecting to login safely.
  void _handleLogoutRedirect(String message) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final currentRoute = Get.currentRoute;
      if (currentRoute != '/LoginScreenGetX') {
        print("HTTP_SERVICE: Redirecting to login. Reason: $message");
        clearTokens();
        Get.offAll(() => const LoginScreenGetX());
        THelperFunctions.showSnackBar(message);
      } else {
        print(
          "HTTP_SERVICE: Already on login screen, skipping redirect. Reason: $message",
        );
        THelperFunctions.showSnackBar(message);
      }
    });
  }

  bool get isAuthenticated => accessToken != null;
}

class ApiException implements Exception {
  final String message;
  final int statusCode;
  final Map<String, dynamic> data;

  ApiException({
    required this.message,
    required this.statusCode,
    this.data = const {},
  });

  @override
  String toString() => 'ApiException: $message (Status: $statusCode)';
}
