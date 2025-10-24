import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sarri_ride/core/services/websocket_service.dart';
import 'package:sarri_ride/features/driver/screens/driver_dashboard_screen.dart';
import 'package:sarri_ride/features/ride/widgets/map_screen_getx.dart';
// import 'package:sarri_ride/features/driver/screens/driver_dashboard_screen.dart';
import 'package:sarri_ride/features/authentication/services/auth_service.dart';
import 'package:sarri_ride/features/shared/models/user_model.dart';
import 'package:sarri_ride/utils/constants/enums.dart';
import 'package:sarri_ride/utils/helpers/helper_functions.dart';
import 'package:sarri_ride/features/authentication/models/auth_model.dart';
import 'package:google_sign_in/google_sign_in.dart';

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
  final selectedRole =
      UserType.rider.obs; // <-- NEW: Track selected role, default to rider

  @override
  void onReady() {
    super.onReady();
    // This is a safer place for any initial setup if needed.
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

    try {
      // --- Call API based on selectedRole ---
      if (selectedRole.value == UserType.rider) {
        print("Attempting login as Client...");
        loginResult = await AuthService.instance.login(email, password);
      } else {
        // UserType.driver
        print("Attempting login as Driver...");
        loginResult = await AuthService.instance.loginDriver(email, password);
      }
      // --- END Role-based API Call ---

      // --- Process Result ---
      if (loginResult.success && loginResult.client != null) {
        // Store current user in memory (Using ClientData as per AuthService)
        // Note: If you have a separate UserModel, map ClientData to UserModel here
        Get.put<ClientData>(loginResult.client!, tag: 'currentUser');

        // --- Connect WebSocket AFTER storing user data ---
        WebSocketService.instance.connect();
        // --- END WebSocket Connect ---

        // Navigate based on actual role from response
        if (loginResult.client!.role == "client") {
          Get.offAll(() => const MapScreenGetX());
          THelperFunctions.showSnackBar(
            'Welcome back, Rider ${loginResult.client!.email}!',
          );
        } else if (loginResult.client!.role == "driver") {
          Get.offAll(() => const DriverDashboardScreen());
          THelperFunctions.showSnackBar(
            'Welcome back, Driver ${loginResult.client!.email}!',
          );
        } else {
          THelperFunctions.showSnackBar(
            'Login successful, but role is unknown.',
          );
          Get.offAll(() => const MapScreenGetX()); // Default navigation
        }
      } else {
        // Show specific error
        THelperFunctions.showSnackBar(
          loginResult.error ??
              'Login failed. Please check your credentials and selected role.',
        );
      }
    } catch (e) {
      // Catch any unexpected errors
      THelperFunctions.showSnackBar('Login failed: ${e.toString()}');
    } finally {
      isLoading.value = false;
    }
  }

  // Handle social login (fake/demo)
  void handleSocialLogin(String provider) {
    if (provider.toLowerCase() == 'google') {
      handleGoogleLogin();
    } else {
      // Handle other social logins like Facebook here
      THelperFunctions.showSnackBar('$provider login is not implemented yet.');
    }
  }

  Future<void> handleGoogleLogin() async {
    isLoading.value = true;
    try {
      final googleSignIn = GoogleSignIn();
      final googleUser = await googleSignIn.signIn();

      if (googleUser != null) {
        final googleAuth = await googleUser.authentication;
        // Use idToken as it's generally preferred for backend verification
        final googleToken = googleAuth.idToken;

        if (googleToken != null) {
          print("Attempting Google Sign-In with token...");
          final loginResult = await AuthService.instance.loginWithGoogle(
            googleToken,
          );

          if (loginResult.success && loginResult.client != null) {
            Get.put<ClientData>(loginResult.client!, tag: 'currentUser');

            // --- Connect WebSocket AFTER storing user data ---
            WebSocketService.instance.connect();
            // --- END WebSocket Connect ---

            // Navigate based on role (assuming Google login is only for riders for now)
            if (loginResult.client!.role == "client") {
              Get.offAll(() => const MapScreenGetX());
              THelperFunctions.showSnackBar(
                'Welcome, ${loginResult.client!.email}!',
              );
            } else {
              // Handle case where Google Sign-In returns a driver? Or show error?
              await googleSignIn.signOut(); // Sign out if role mismatch
              WebSocketService.instance.disconnect(); // Disconnect socket
              THelperFunctions.showSnackBar(
                'Google Sign-In is currently only for Riders.',
              );
            }
          } else {
            await googleSignIn.signOut(); // Sign out if backend login fails
            THelperFunctions.showSnackBar(
              loginResult.error ?? 'Google login failed on our server.',
            );
          }
        } else {
          THelperFunctions.showSnackBar('Could not get Google ID token.');
        }
      } else {
        print("Google Sign-In cancelled by user."); // Optional logging
      }
    } catch (e) {
      THelperFunctions.showSnackBar('Google login failed: ${e.toString()}');
      print("Google Sign-In Error: $e"); // Log error
    } finally {
      // Ensure isLoading is always set to false, even on errors or cancellations
      // Check if controller is still mounted before setting state
      if (!isClosed) {
        isLoading.value = false;
      }
    }
  }
}
