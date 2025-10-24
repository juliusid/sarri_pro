import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:get/get.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:sarri_ride/config/api_config.dart';
import 'package:sarri_ride/features/authentication/screens/login/login_screen_getx.dart';
import 'package:sarri_ride/utils/helpers/helper_functions.dart';

class HttpService extends GetxService {
  static HttpService get instance => Get.find();

  late http.Client _client;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';

  String? _cachedAccessToken;
  String? _cachedRefreshToken;

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
  }

  String? get accessToken => _cachedAccessToken;
  String? get refreshToken => _cachedRefreshToken;

  Future<void> storeTokens(String accessToken, String? refreshToken) async {
    await _storage.write(key: _accessTokenKey, value: accessToken);
    if (refreshToken != null) {
      await _storage.write(key: _refreshTokenKey, value: refreshToken);
    }
    _cachedAccessToken = accessToken;
    _cachedRefreshToken = refreshToken;
  }

  Future<void> clearTokens() async {
    await _storage.delete(key: _accessTokenKey);
    await _storage.delete(key: _refreshTokenKey);
    _cachedAccessToken = null;
    _cachedRefreshToken = null;
  }

  Map<String, String> _getHeaders({Map<String, String>? additionalHeaders}) {
    final headers = Map<String, String>.from(ApiConfig.defaultHeaders);
    if (accessToken != null) {
      headers['Authorization'] = 'Bearer $accessToken';
    }
    if (additionalHeaders != null) {
      headers.addAll(additionalHeaders);
    }
    return headers;
  }

  Future<http.Response> get(
    String endpoint, {
    Map<String, String>? headers,
    Map<String, dynamic>? queryParameters,
  }) async {
    final uri = Uri.parse(endpoint).replace(queryParameters: queryParameters);
    return await _client
        .get(uri, headers: _getHeaders(additionalHeaders: headers))
        .timeout(ApiConfig.receiveTimeout);
  }

  Future<http.Response> post(
    String endpoint, {
    Map<String, String>? headers,
    Map<String, dynamic>? body,
    Map<String, dynamic>? queryParameters,
  }) async {
    final uri = Uri.parse(endpoint).replace(queryParameters: queryParameters);
    return await _client
        .post(
          uri,
          headers: _getHeaders(additionalHeaders: headers),
          body: body != null ? json.encode(body) : null,
        )
        .timeout(ApiConfig.receiveTimeout);
  }

  Future<http.Response> put(
    String endpoint, {
    Map<String, String>? headers,
    Map<String, dynamic>? body,
    Map<String, dynamic>? queryParameters,
  }) async {
    final uri = Uri.parse(endpoint).replace(queryParameters: queryParameters);
    return await _client
        .put(
          uri,
          headers: _getHeaders(additionalHeaders: headers),
          body: body != null ? json.encode(body) : null,
        )
        .timeout(ApiConfig.receiveTimeout);
  }

  Future<http.Response> delete(
    String endpoint, {
    Map<String, String>? headers,
    Map<String, dynamic>? queryParameters,
  }) async {
    final uri = Uri.parse(endpoint).replace(queryParameters: queryParameters);
    return await _client
        .delete(uri, headers: _getHeaders(additionalHeaders: headers))
        .timeout(ApiConfig.receiveTimeout);
  }

  // MODIFIED METHOD WITH GLOBAL 401 HANDLING
  Map<String, dynamic> handleResponse(http.Response response) {
    // --- NEW: HANDLE 401 UNAUTHORIZED GLOBALLY ---
    if (response.statusCode == 401) {
      // Clear tokens from storage
      clearTokens();
      // Redirect to login screen, clearing all previous screens
      Get.offAll(() => const LoginScreenGetX());
      // Show an informative snackbar
      THelperFunctions.showSnackBar("Session expired. Please log in again.");
      // Throw a specific exception to stop further processing in the controller
      throw ApiException(message: "Session expired", statusCode: 401);
    }
    // --- END NEW ---

    try {
      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (response.body.isEmpty) return {'success': true};
        return json.decode(response.body);
      } else {
        Map<String, dynamic> errorData = {};
        try {
          if (response.body.isNotEmpty) errorData = json.decode(response.body);
        } catch (e) {
          errorData = {
            'message': 'An unexpected error occurred',
            'status': response.statusCode,
          };
        }
        if (!errorData.containsKey('status'))
          errorData['status'] = response.statusCode;
        throw ApiException(
          message: errorData['message'] ?? 'Request failed',
          statusCode: response.statusCode,
          data: errorData,
        );
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(
        message: 'Invalid response format',
        statusCode: response.statusCode,
        data: {'raw_response': response.body},
      );
    }
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
