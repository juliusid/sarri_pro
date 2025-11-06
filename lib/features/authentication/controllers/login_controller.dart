// lib/features/authentication/controllers/login_controller.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:sarri_ride/core/services/websocket_service.dart';
import 'package:sarri_ride/features/driver/screens/driver_dashboard_screen.dart';
import 'package:sarri_ride/features/ride/widgets/map_screen_getx.dart';
import 'package:sarri_ride/features/authentication/services/auth_service.dart';
import 'package:sarri_ride/utils/constants/enums.dart';
import 'package:sarri_ride/utils/helpers/helper_functions.dart';
import 'package:sarri_ride/features/authentication/models/auth_model.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sarri_ride/core/services/http_service.dart';
import 'package:sarri_ride/utils/validators/validation.dart';
import 'package:sarri_ride/utils/constants/text_strings.dart';
import 'package:sarri_ride/features/authentication/screens/forgot_password/forgot_password_screen.dart';

class LoginController extends GetxController {
  static LoginController get instance => Get.find();

  // Text Controllers
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  // Form Key
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  // Reactive variables
  final RxBool obscurePassword = true.obs;
  final RxBool isLoading = false.obs;
  final selectedRole = UserType.rider.obs;

  @override
  void onReady() {
    super.onReady();
  }

  @override
  void onClose() {
    emailController.dispose();
    passwordController.dispose();
    super.onClose();
  }

  // Toggle password visibility
  void togglePasswordVisibility() {
    obscurePassword.value = !obscurePassword.value;
  }

  void setSelectedRole(UserType role) {
    selectedRole.value = role;
  }

  Future<void> handleLogin() async {
    if (!formKey.currentState!.validate()) return;

    isLoading.value = true;
    AuthResult loginResult;
    final email = emailController.text.trim();
    final password = passwordController.text.trim();
    final bool isDriverLogin = selectedRole.value == UserType.driver;

    try {
      // --- Call API based on selectedRole ---
      if (isDriverLogin) {
        print("LOGIN_CONTROLLER: Attempting login as Driver...");
        loginResult = await AuthService.instance.loginDriver(email, password);
      } else {
        // Rider
        print("LOGIN_CONTROLLER: Attempting login as Client...");
        loginResult = await AuthService.instance.login(email, password);
      }
      // --- END Role-based API Call ---

      // --- Process Result ---
      if (loginResult.success && loginResult.client != null) {
        print(
          "LOGIN_CONTROLLER: Initial login successful. Storing user data...",
        );
        if (Get.isRegistered<ClientData>(tag: 'currentUser')) {
          Get.delete<ClientData>(tag: 'currentUser', force: true);
          print("LOGIN_CONTROLLER: Removed existing ClientData instance.");
        }
        Get.put<ClientData>(
          loginResult.client!,
          tag: 'currentUser',
          permanent: true,
        );

        final storage = GetStorage();
        storage.write('user_role', loginResult.client!.role);
        print(
          "LOGIN_CONTROLLER: Stored user role: ${loginResult.client!.role}",
        );

        // --- IMMEDIATELY REFRESH TOKEN ---
        print("LOGIN_CONTROLLER: Attempting immediate token refresh...");
        final String userId = loginResult.client!.id;

        bool refreshSuccess = await HttpService.instance
            .refreshTokenImmediately(isDriver: isDriverLogin, userId: userId);
        // --- END ---

        if (!refreshSuccess) {
          print(
            "LOGIN_CONTROLLER: Immediate token refresh failed after login. Logout initiated by HttpService.",
          );
          isLoading.value = false;
          return; // Stop execution
        }

        print(
          "LOGIN_CONTROLLER: Immediate token refresh successful. Navigating...",
        );

        // Connect WebSocket
        print(
          "LOGIN_CONTROLLER: Connecting WebSocket for '${loginResult.client!.role}'...",
        );
        WebSocketService.instance.connect();

        // Navigate based on actual role from response
        if (loginResult.client!.role == "client") {
          // Client (Rider) flow
          Get.offAll(() => const MapScreenGetX());
          // --- MODIFIED ---
          THelperFunctions.showSuccessSnackBar(
            'Success',
            'Welcome back, Rider!',
          );
          // --- END MODIFIED ---
        } else if (loginResult.client!.role == "driver") {
          // Driver flow
          Get.offAll(() => const DriverDashboardScreen());
          // --- MODIFIED ---
          THelperFunctions.showSuccessSnackBar(
            'Success',
            'Welcome back, Driver!',
          );
          // --- END MODIFIED ---
        } else {
          THelperFunctions.showSnackBar(
            'Login successful, but role is unknown.',
          );
          Get.offAll(() => const MapScreenGetX()); // Default navigation
        }
      } else {
        // --- MODIFIED ---
        THelperFunctions.showErrorSnackBar(
          'Login Failed',
          loginResult.error ??
              'Please check your credentials and selected role.',
        );
        // --- END MODIFIED ---
      }
    } catch (e) {
      print("LOGIN_CONTROLLER: Error during login process: $e");
      // --- MODIFIED ---
      THelperFunctions.showErrorSnackBar(
        'Login Failed',
        'An unexpected error occurred. Please try again.',
      );
      // --- END MODIFIED ---
      if (HttpService.instance.isAuthenticated) {
        print("LOGIN_CONTROLLER: Clearing tokens due to error during login...");
        await HttpService.instance.clearTokens();
        WebSocketService.instance.disconnect();
      }
    } finally {
      if (!isClosed) {
        isLoading.value = false;
      }
    }
  }

  // Handle social login (Google)
  Future<void> handleGoogleLogin() async {
    if (selectedRole.value != UserType.rider) {
      // --- MODIFIED ---
      THelperFunctions.showErrorSnackBar(
        'Error',
        "Google Sign-In is currently only available for Riders.",
      );
      // --- END MODIFIED ---
      return;
    }

    isLoading.value = true;
    try {
      final googleSignIn = GoogleSignIn();
      await googleSignIn.signOut();
      final googleUser = await googleSignIn.signIn();

      if (googleUser != null) {
        final googleAuth = await googleUser.authentication;
        final googleToken = googleAuth.idToken;

        if (googleToken != null) {
          print("LOGIN_CONTROLLER: Attempting Google Sign-In with token...");
          final loginResult = await AuthService.instance.loginWithGoogle(
            googleToken,
          );

          if (loginResult.success && loginResult.client != null) {
            print(
              "LOGIN_CONTROLLER: Google login successful via backend. Storing user data...",
            );
            if (Get.isRegistered<ClientData>(tag: 'currentUser')) {
              Get.delete<ClientData>(tag: 'currentUser', force: true);
            }
            Get.put<ClientData>(
              loginResult.client!,
              tag: 'currentUser',
              permanent: true,
            );

            final storage = GetStorage();
            storage.write('user_role', loginResult.client!.role);

            print(
              "LOGIN_CONTROLLER: Attempting immediate token refresh after Google login...",
            );
            final String userId = loginResult.client!.id;
            bool refreshSuccess = await HttpService.instance
                .refreshTokenImmediately(
                  isDriver: false, // Google login is for riders
                  userId: userId,
                );

            if (!refreshSuccess) {
              print(
                "LOGIN_CONTROLLER: Immediate refresh failed after Google login. Logout initiated.",
              );
              await googleSignIn.signOut();
              isLoading.value = false;
              return;
            }
            print(
              "LOGIN_CONTROLLER: Immediate token refresh successful after Google login.",
            );

            print("LOGIN_CONTROLLER: Connecting WebSocket for Rider...");
            WebSocketService.instance.connect();

            Get.offAll(() => const MapScreenGetX());
            // --- MODIFIED ---
            THelperFunctions.showSuccessSnackBar('Success', 'Welcome!');
            // --- END MODIFIED ---
          } else {
            await googleSignIn.signOut();
            // --- MODIFIED ---
            THelperFunctions.showErrorSnackBar(
              'Login Failed',
              loginResult.error ?? 'Google login failed on our server.',
            );
            // --- END MODIFIED ---
          }
        } else {
          await googleSignIn.signOut();
          // --- MODIFIED ---
          THelperFunctions.showErrorSnackBar(
            'Error',
            'Could not get Google ID token.',
          );
          // --- END MODIFIED ---
        }
      } else {
        print("LOGIN_CONTROLLER: Google Sign-In cancelled by user.");
      }
    } catch (e) {
      // --- MODIFIED ---
      THelperFunctions.showErrorSnackBar(
        'Error',
        'Google login failed: ${e.toString()}',
      );
      // --- END MODIFIED ---
      print("LOGIN_CONTROLLER: Google Sign-In Error: $e");
      try {
        await GoogleSignIn().signOut();
      } catch (_) {}
    } finally {
      if (!isClosed) {
        isLoading.value = false;
      }
    }
  }

  // Placeholder for other social logins
  void handleSocialLogin(String provider) {
    if (provider.toLowerCase() == 'google') {
      handleGoogleLogin();
    } else {
      THelperFunctions.showSnackBar('$provider login is not implemented yet.');
    }
  }
}
