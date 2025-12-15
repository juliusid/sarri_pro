import 'dart:io';

import 'package:get/get.dart';
import 'package:sarri_ride/config/api_config.dart';
import 'package:sarri_ride/core/services/http_service.dart';
import 'package:sarri_ride/features/authentication/models/auth_model.dart';
import 'package:sarri_ride/features/authentication/models/driver_auth_model.dart';
import 'package:sarri_ride/utils/helpers/helper_functions.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart'; // Required for MediaType
import 'package:mime/mime.dart'; // Recommended to detect mime type, or hardcode if you convert

class AuthService extends GetxService {
  static AuthService get instance => Get.find();

  final HttpService _httpService = HttpService.instance;

  // ---------- SIGNUP ----------
  Future<AuthResult> signup(
    String email,
    String password,
    String firstName,
    String lastName,
  ) async {
    try {
      final request = SignupRequest(
        email: email,
        password: password,
        firstName: firstName,
        lastName: lastName,
      );

      final response = await _httpService.post(
        ApiConfig.signupEndpoint,
        body: request.toJson(),
      );
      final responseData = _httpService.handleResponse(response);
      final signupResponse = SignupResponse.fromJson(responseData);

      if (signupResponse.status == "success") {
        return AuthResult.success(
          message: signupResponse.message,
          client: signupResponse.client,
        );
      } else {
        return AuthResult.error(signupResponse.message);
      }
    } catch (e) {
      return AuthResult.error("Signup failed: ${e.toString()}");
    }
  }

  Future<AuthResult> sendPhoneOtp(String phoneNumber, String userType) async {
    try {
      final response = await _httpService.post(
        ApiConfig.sendPhoneOtpEndpoint,
        body: {'phoneNumber': phoneNumber, 'userType': userType},
      );
      final responseData = _httpService.handleResponse(response);
      if (response.statusCode == 200 || response.statusCode == 201) {
        return AuthResult.success(
          message: responseData['message'] ?? 'OTP sent successfully',
        );
      } else {
        return AuthResult.error(
          responseData['message'] ?? 'Failed to send OTP',
        );
      }
    } catch (e) {
      if (e is ApiException) {
        return AuthResult.error(e.message);
      }
      return AuthResult.error("An unknown error occurred: ${e.toString()}");
    }
  }

  /// Verifies a phone number OTP.
  Future<AuthResult> verifyPhoneOtp(
    String phoneNumber,
    String code,
    String userType,
  ) async {
    try {
      final response = await _httpService.post(
        ApiConfig.verifyPhoneOtpEndpoint,
        body: {'phoneNumber': phoneNumber, 'code': code, 'userType': userType},
      );
      final responseData = _httpService.handleResponse(response);
      if (responseData['status'] == 'success') {
        return AuthResult.success(message: responseData['message']);
      } else {
        return AuthResult.error(responseData['message'] ?? 'Invalid OTP');
      }
    } catch (e) {
      if (e is ApiException) {
        return AuthResult.error(e.message);
      }
      return AuthResult.error("An unknown error occurred: ${e.toString()}");
    }
  }

  /// Resends a verification OTP to a phone number.
  Future<AuthResult> resendPhoneOtp(String phoneNumber, String userType) async {
    try {
      final response = await _httpService.post(
        ApiConfig.resendPhoneOtpEndpoint,
        body: {'phoneNumber': phoneNumber, 'userType': userType},
      );
      final responseData = _httpService.handleResponse(response);
      if (response.statusCode == 200 || response.statusCode == 201) {
        return AuthResult.success(
          message: responseData['message'] ?? 'OTP resent successfully',
        );
      } else {
        return AuthResult.error(
          responseData['message'] ?? 'Failed to resend OTP',
        );
      }
    } catch (e) {
      if (e is ApiException) {
        return AuthResult.error(e.message);
      }
      return AuthResult.error("An unknown error occurred: ${e.toString()}");
    }
  }

  Future<AuthResult> uploadDriverDocuments({
    required File frontsideImage,
    required File backsideImage,
    required File insuranceCertificate,
    required File vehicleRegistration,
    File? picture,
  }) async {
    try {
      final uri = Uri.parse(ApiConfig.driverUploadImagesEndpoint);
      final request = http.MultipartRequest('POST', uri);

      // Add Headers (Authorization)
      final token = _httpService.accessToken;
      if (token != null) {
        request.headers['Authorization'] = 'Bearer $token';
      }
      request.headers['Content-Type'] = 'multipart/form-data';

      // Helper to add file safely
      Future<void> addFile(String key, File file) async {
        final mimeTypeData = lookupMimeType(file.path)?.split('/');

        // Default to jpeg if lookup fails, or ensure your picker only picks jpg/png
        final type = mimeTypeData != null ? mimeTypeData[0] : 'image';
        final subtype = mimeTypeData != null ? mimeTypeData[1] : 'jpeg';

        request.files.add(
          await http.MultipartFile.fromPath(
            key,
            file.path,
            contentType: MediaType(type, subtype),
          ),
        );
      }

      // Add Required Files
      await addFile('frontsideImage', frontsideImage);
      await addFile('backsideImage', backsideImage);
      await addFile('insuranceCertificate', insuranceCertificate);
      await addFile('vehicleRegistration', vehicleRegistration);

      // Add Optional Profile Picture
      if (picture != null) {
        await addFile('picture', picture);
      }

      // Send Request
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      final responseData = _httpService.handleResponse(response);

      if (responseData['status'] == 'success') {
        return AuthResult.success(
          message: responseData['message'] ?? 'Documents uploaded successfully',
        );
      } else {
        return AuthResult.error(responseData['message'] ?? 'Upload failed');
      }
    } catch (e) {
      if (e is ApiException) {
        return AuthResult.error(e.message);
      }
      return AuthResult.error("An unknown error occurred: ${e.toString()}");
    }
  }

  Future<Map<String, dynamic>?> updateProfilePicture(File imageFile) async {
    try {
      final response = await _httpService.putMultipart(
        ApiConfig.updateProfilePictureEndpoint,
        fileKey: 'picture', // This is the key from the API docs
        file: imageFile,
      );

      final responseData = _httpService.handleResponse(response);

      if (responseData['success'] == true && responseData['data'] is Map) {
        return responseData['data'] as Map<String, dynamic>;
      } else {
        // Handle API error message
        throw ApiException(
          message: responseData['message'] ?? 'Failed to update picture',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      print("Error in updateProfilePicture: $e");
      String errorMessage = "An error occurred. Please try again.";
      if (e is ApiException) {
        errorMessage = e.message;
      }
      THelperFunctions.showErrorSnackBar('Upload Failed', errorMessage);
      return null;
    }
  }

  // Add this new method for Google Sign-In
  Future<AuthResult> loginWithGoogle(String googleToken) async {
    try {
      // This will call your /auth/client/google endpoint
      final response = await _httpService.post(
        ApiConfig.googleAuthEndpoint,
        body: {
          'idToken': googleToken,
        }, // Body might differ based on backend spec
      );
      final responseData = _httpService.handleResponse(response);
      final loginResponse = LoginResponse.fromJson(
        responseData,
      ); // Reuse LoginResponse model

      if (loginResponse.status == "success" &&
          loginResponse.accessToken != null) {
        await _httpService.storeTokens(
          loginResponse.accessToken!,
          loginResponse.refreshToken,
        );
        return AuthResult.success(
          message: loginResponse.message,
          client: loginResponse.client,
        );
      } else {
        return AuthResult.error(loginResponse.message);
      }
    } catch (e) {
      if (e is ApiException) {
        return AuthResult.error(e.message);
      }
      return AuthResult.error("An unknown error occurred: ${e.toString()}");
    }
  }

  // ---------- VERIFY OTP ----------
  Future<AuthResult> verifyEmail(String email, String otp, String role) async {
    try {
      final request = VerifyRequest(email: email, otp: otp, role: role);

      final response = await _httpService.post(
        ApiConfig.verifyOtpEndpoint,
        body: request.toJson(),
      );
      final responseData = _httpService.handleResponse(response);
      final verifyResponse = VerifyResponse.fromJson(responseData);

      if (verifyResponse.status == "success" && verifyResponse.user != null) {
        return AuthResult.success(
          message: verifyResponse.message,
          client: verifyResponse.user,
        );
      } else {
        return AuthResult.error(verifyResponse.message);
      }
    } catch (e) {
      if (e is ApiException) {
        return AuthResult.error(e.message);
      }
      return AuthResult.error("An unknown error occurred: ${e.toString()}");
    }
  }

  // ---------- LOGIN ----------
  Future<AuthResult> login(String email, String password) async {
    try {
      final request = LoginRequest(email: email, password: password);

      final response = await _httpService.post(
        ApiConfig.loginEndpoint,
        body: request.toJson(),
      );
      final responseData = _httpService.handleResponse(response);
      final loginResponse = LoginResponse.fromJson(responseData);

      if (loginResponse.status == "success" &&
          loginResponse.accessToken != null) {
        await _httpService.storeTokens(
          loginResponse.accessToken!,
          loginResponse.refreshToken,
        );
        return AuthResult.success(
          message: loginResponse.message,
          client: loginResponse.client,
        );
      } else {
        return AuthResult.error(loginResponse.message);
      }
    } catch (e) {
      if (e is ApiException) {
        return AuthResult.error(e.message);
      }
      return AuthResult.error("An unknown error occurred: ${e.toString()}");
    }
  }

  // ---------- DRIVER LOGIN ----------
  Future<AuthResult> loginDriver(String email, String password) async {
    try {
      final request = LoginRequest(
        email: email,
        password: password,
      ); // Reuse the client LoginRequest model

      final response = await _httpService.post(
        ApiConfig.driverLoginEndpoint, // Use the driver login endpoint
        body: request.toJson(),
      );
      final responseData = _httpService.handleResponse(response);
      final driverLoginResponse = DriverLoginResponse.fromJson(responseData);

      if (driverLoginResponse.status == "success" &&
          driverLoginResponse.data != null) {
        await _httpService.storeTokens(
          driverLoginResponse.data!.accessToken,
          driverLoginResponse.data!.refreshToken,
        );
        // Convert DriverDetails to ClientData for consistency in AuthResult
        final clientData = ClientData(
          id: driverLoginResponse.data!.driver.id,
          email: driverLoginResponse.data!.driver.email,
          role: driverLoginResponse.data!.driver.role,
          isVerified: driverLoginResponse.data!.driver.isVerified,
        );
        return AuthResult.success(
          message: driverLoginResponse.message,
          client: clientData, // Return the consistent ClientData model
        );
      } else {
        return AuthResult.error(driverLoginResponse.message);
      }
    } on ApiException catch (e) {
      // Return specific error for incorrect credentials
      if (e.statusCode == 401) {
        return AuthResult.error("Incorrect email or password.");
      }
      return AuthResult.error("Login failed: ${e.message}");
    } catch (e) {
      if (e is ApiException) {
        return AuthResult.error(e.message);
      }
      return AuthResult.error("An unknown error occurred: ${e.toString()}");
    }
  }

  // ---------- LOGOUT (CORRECTED METHOD) ----------
  Future<AuthResult> logout() async {
    try {
      // Get the refresh token from HttpService
      final refreshToken = _httpService.refreshToken;
      if (refreshToken == null) {
        // If no token, just clear local storage and assume success
        _httpService.clearTokens();
        return AuthResult.success(
          message: "Logged out successfully (no token found)",
        );
      }

      final request = LogoutRequest(refreshToken: refreshToken);

      // Call the logout endpoint, but don't fail if it errors out
      try {
        await _httpService.post(
          ApiConfig.logoutEndpoint,
          body: request.toJson(),
        );
      } catch (e) {
        // Log the error but don't block the user from logging out locally
        print("API logout failed, proceeding with local logout: $e");
      }

      // Always clear local tokens
      await _httpService.clearTokens();

      return AuthResult.success(message: "Logged out successfully");
    } catch (e) {
      // Ensure tokens are cleared even if an unexpected error occurs
      await _httpService.clearTokens();
      return AuthResult.error("Logout failed: ${e.toString()}");
    }
  }

  // --- GET RIDER PROFILE ---
  /// Fetches the full profile for the currently logged-in rider.
  Future<RiderProfileData?> getRiderProfile() async {
    try {
      final response = await _httpService.get(
        ApiConfig.clientProfileEndpoint,
      ); // This is an authenticated GET request

      final responseData = _httpService.handleResponse(response);
      final profileResponse = RiderProfileResponse.fromJson(responseData);
      print("Rider profile fetched: ${profileResponse.data?.fullName}");

      if (profileResponse.status == "success" && profileResponse.data != null) {
        return profileResponse.data;
      } else {
        return null;
      }
    } catch (e) {
      print("Error fetching rider profile: $e");
      return null;
    }
  }

  // ---------- NEW: SEND REGISTRATION OTP (Unified) ----------
  Future<AuthResult> sendRegistrationOtp(String email, String role) async {
    try {
      final response = await _httpService.post(
        ApiConfig.verifyUserEmailEndpoint,
        body: {'email': email, 'role': role},
      );
      final responseData = _httpService.handleResponse(response);
      if (response.statusCode == 200) {
        return AuthResult.success(
          message: responseData['message'] ?? 'OTP sent successfully',
        );
      } else {
        return AuthResult.error(
          responseData['message'] ?? 'Failed to send OTP',
        );
      }
    } catch (e) {
      if (e is ApiException) {
        return AuthResult.error(e.message);
      }
      return AuthResult.error("An unknown error occurred: ${e.toString()}");
    }
  }

  // ---------- NEW: VERIFY REGISTRATION OTP (Unified) ----------
  Future<AuthResult> verifyRegistrationOtp(
    String email,
    String otp,
    String role,
  ) async {
    try {
      final response = await _httpService.post(
        ApiConfig.verifyOtpEndpoint,
        body: {'email': email, 'otp': otp, 'role': role},
      );
      final responseData = _httpService.handleResponse(response);
      if (responseData['status'] == 'success') {
        return AuthResult.success(message: responseData['message']);
      } else {
        return AuthResult.error(responseData['message'] ?? 'Invalid OTP');
      }
    } catch (e) {
      if (e is ApiException) {
        return AuthResult.error(e.message);
      }
      return AuthResult.error("An unknown error occurred: ${e.toString()}");
    }
  }

  // ---------- DRIVER: REGISTER ----------
  Future<AuthResult> registerDriver(DriverRegistrationRequest request) async {
    try {
      final response = await _httpService.post(
        ApiConfig.driverRegisterEndpoint,
        body: request.toJson(),
      );
      final responseData = _httpService.handleResponse(response);
      if (response.statusCode == 201) {
        return AuthResult.success(
          message: responseData['message'] ?? 'Registration successful',
        );
      } else {
        return AuthResult.error(
          responseData['message'] ?? 'Registration failed',
        );
      }
    } catch (e) {
      if (e is ApiException) {
        return AuthResult.error(e.message);
      }
      return AuthResult.error("An unknown error occurred: ${e.toString()}");
    }
  }

  // ---------- FORGOT PASSWORD ----------
  Future<ForgotPasswordResponse> forgotPassword(
    String email,
    String role,
  ) async {
    try {
      final request = ForgotPasswordRequest(email: email, role: role);
      final response = await _httpService.post(
        ApiConfig.forgotPasswordEndpoint,
        body: request.toJson(),
      );
      final responseData = _httpService.handleResponse(response);
      return ForgotPasswordResponse.fromJson(responseData);
    } catch (e) {
      throw 'Failed to send reset code: ${e.toString()}';
    }
  }

  // ---------- RESET PASSWORD ----------
  Future<AuthResult> resetPassword({
    required String resetTokenId,
    required String resetCode,
    required String password,
    required String role,
  }) async {
    try {
      final request = ResetPasswordRequest(
        resetTokenId: resetTokenId,
        resetCode: resetCode,
        password: password,
        role: role,
      );
      final response = await _httpService.post(
        ApiConfig.resetPasswordEndpoint,
        body: request.toJson(),
      );
      final responseData = _httpService.handleResponse(response);

      if (response.statusCode == 200 && responseData['status'] == 'success') {
        return AuthResult.success(
          message: responseData['message'] ?? 'Password reset successfully.',
        );
      } else {
        return AuthResult.error(
          responseData['message'] ?? 'Password reset failed.',
        );
      }
    } catch (e) {
      if (e is ApiException) {
        return AuthResult.error(e.message);
      }
      return AuthResult.error("An unknown error occurred: ${e.toString()}");
    }
  }

  bool get isAuthenticated => _httpService.isAuthenticated;
  String? get accessToken => _httpService.accessToken;
}

// ---------- RESULT WRAPPER ----------
class AuthResult {
  final bool success;
  final ClientData? client;
  final String? message;
  final String? error;

  AuthResult._({required this.success, this.client, this.message, this.error});

  factory AuthResult.success({ClientData? client, String? message}) {
    return AuthResult._(success: true, client: client, message: message);
  }

  factory AuthResult.error(String error) {
    return AuthResult._(success: false, error: error);
  }
}
