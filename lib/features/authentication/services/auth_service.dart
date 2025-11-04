import 'package:get/get.dart';
import 'package:sarri_ride/config/api_config.dart';
import 'package:sarri_ride/core/services/http_service.dart';
import 'package:sarri_ride/features/authentication/models/auth_model.dart';
import 'package:sarri_ride/features/authentication/models/driver_auth_model.dart';

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
      return AuthResult.error("Google login failed: ${e.toString()}");
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
      return AuthResult.error("Verification failed: ${e.toString()}");
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
      return AuthResult.error("Login failed: ${e.toString()}");
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
      return AuthResult.error("Login failed: ${e.toString()}");
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
      return AuthResult.error("Email verification failed: ${e.toString()}");
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
      return AuthResult.error("OTP verification failed: ${e.toString()}");
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
      return AuthResult.error("Driver registration failed: ${e.toString()}");
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
      return AuthResult.error('Failed to reset password: ${e.toString()}');
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
