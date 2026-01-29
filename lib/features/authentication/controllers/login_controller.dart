import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sarri_ride/core/services/http_service.dart';
import 'package:sarri_ride/core/services/websocket_service.dart';
import 'package:sarri_ride/features/authentication/models/auth_model.dart';
import 'package:sarri_ride/features/authentication/screens/phone_verification/phone_number_screen.dart';
import 'package:sarri_ride/features/authentication/services/auth_service.dart';
import 'package:sarri_ride/features/driver/screens/driver_dashboard_screen.dart';
import 'package:sarri_ride/features/ride/controllers/drawer_controller.dart';
import 'package:sarri_ride/features/ride/widgets/map_screen_getx.dart';
import 'package:sarri_ride/utils/constants/enums.dart';
import 'package:sarri_ride/utils/helpers/helper_functions.dart';

class LoginController extends GetxController {
  static LoginController get instance => Get.find();

  // Text Controllers
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  // Form Key
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  // Reactive variables
  final RxBool obscurePassword = true.obs;
  final RxBool isEmailLoading = false.obs;
  final RxBool isGoogleLoading = false.obs;
  final RxBool isFacebookLoading = false.obs;
  final selectedRole = UserType.rider.obs;

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

    isEmailLoading.value = true;
    AuthResult loginResult;
    final email = emailController.text.trim();
    final password = passwordController.text.trim();
    final bool isDriverLogin = selectedRole.value == UserType.driver;

    try {
      // Call API based on selectedRole
      if (isDriverLogin) {
        print("LOGIN_CONTROLLER: Attempting login as Driver...");
        loginResult = await AuthService.instance.loginDriver(email, password);
      } else {
        print("LOGIN_CONTROLLER: Attempting login as Client...");
        loginResult = await AuthService.instance.login(email, password);
      }

      // Process Result
      if (loginResult.success && loginResult.client != null) {
        print(
          "LOGIN_CONTROLLER: Initial login successful. Storing user data...",
        );
        print("GOOGLE LOGIN SUCCESS! FULL DATA:");
        print(jsonEncode(loginResult.client!.toJson()));

        // -------------------------------

        if (Get.isRegistered<ClientData>(tag: 'currentUser')) {
          Get.delete<ClientData>(tag: 'currentUser', force: true);
        }

        Get.put<ClientData>(
          loginResult.client!,
          tag: 'currentUser',
          permanent: true,
        );

        // Refresh user data in the drawer controller
        final drawerController = Get.find<MapDrawerController>();
        await drawerController.refreshUserData();

        final storage = GetStorage();
        storage.write('user_role', loginResult.client!.role);
        storage.write('current_user_data', loginResult.client!.toJson());

        print(
          "LOGIN_CONTROLLER: Stored user role: ${loginResult.client!.role}",
        );

        // IMMEDIATELY REFRESH TOKEN
        print("LOGIN_CONTROLLER: Attempting immediate token refresh...");
        final String userId = loginResult.client!.id;

        bool refreshSuccess = await HttpService.instance
            .refreshTokenImmediately(isDriver: isDriverLogin, userId: userId);

        if (!refreshSuccess) {
          print(
            "LOGIN_CONTROLLER: Immediate token refresh failed. Logout initiated.",
          );
          isEmailLoading.value = false;
          return;
        }

        print(
          "LOGIN_CONTROLLER: Immediate token refresh successful. Navigating...",
        );

        // CHECK FOR PHONE NUMBER (Rider Only)
        final profile = drawerController.fullProfile.value;

        // Connect WebSocket
        if (loginResult.client!.role == "client" ||
            loginResult.client!.role == "driver") {
          WebSocketService.instance.connect();
        }

        if (loginResult.client!.role == "client") {
          // --- FIXED: Uncommented Phone Number Verification Logic ---

          // Check if profile exists and phone number is missing OR not verified
          if (profile == null || profile.phoneNumberVerified == false) {
            print(
              "LOGIN_CONTROLLER: Phone number missing or not verified. Forcing verification.",
            );

            // 1. Uncommented verification screen
            Get.offAll(() => const PhoneNumberScreen());

            // 2. Removed bypass to MapScreen
            // Get.offAll(() => const MapScreenGetX());

            THelperFunctions.showSnackBar(
              'Please verify your phone number to continue.',
            );
          } else {
            // Phone number exists and is verified
            Get.offAll(() => const MapScreenGetX());
            THelperFunctions.showSuccessSnackBar(
              'Success',
              'Welcome back, Rider!',
            );
          }
        } else if (loginResult.client!.role == "driver") {
          // Driver flow
          Get.offAll(() => const DriverDashboardScreen());
          THelperFunctions.showSuccessSnackBar(
            'Success',
            'Welcome back, Driver!',
          );
        } else {
          THelperFunctions.showSnackBar(
            'Login successful, but role is unknown.',
          );
          Get.offAll(() => const MapScreenGetX());
        }
      } else {
        THelperFunctions.showErrorSnackBar(
          'Login Failed',
          loginResult.error ??
              'Please check your credentials and selected role.',
        );
      }
    } catch (e) {
      print("LOGIN_CONTROLLER: Error during login process: $e");
      THelperFunctions.showErrorSnackBar(
        'Login Failed',
        'An unexpected error occurred. Please try again.',
      );
      if (HttpService.instance.isAuthenticated) {
        await HttpService.instance.clearTokens();
        WebSocketService.instance.disconnect();
      }
    } finally {
      if (!isClosed) {
        isEmailLoading.value = false;
      }
    }
  }

  // Handle social login (Google)
  Future<void> handleGoogleLogin() async {
    // 1. Check User Role (Google Sign-In is usually for Riders)
    if (selectedRole.value != UserType.rider) {
      THelperFunctions.showErrorSnackBar(
        'Error',
        "Google Sign-In is currently only available for Riders.",
      );
      return;
    }

    isGoogleLoading.value = true;

    try {
      // 2. Configure Google Sign In
      // I extracted this ID from the google-services.json you sent me.
      // It is the "Web client (auto created by Google Service)"
      final googleSignIn = GoogleSignIn(
        serverClientId:
            '566802818676-kuc13au4v6ifp3oe6qimcdp78s84fnnd.apps.googleusercontent.com',
        scopes: ['email', 'profile'],
      );

      // 3. Start the Sign-In Process
      await googleSignIn.signOut(); // Ensure we are starting fresh
      final googleUser = await googleSignIn.signIn();

      if (googleUser != null) {
        // 4. Get the Token
        final googleAuth = await googleUser.authentication;
        final googleToken = googleAuth.idToken;

        if (googleToken != null) {
          print(
            "LOGIN_CONTROLLER: Got Token from Google. Sending to Backend...",
          );

          // 5. Send the Token to YOUR Backend
          // This calls the 'loginWithGoogle' method in your AuthService
          final loginResult = await AuthService.instance.loginWithGoogle(
            googleToken,
          );

          if (loginResult.success && loginResult.client != null) {
            print("LOGIN_CONTROLLER: Backend accepted the login!");

            // --- SAVE DATA & NAVIGATE (Standard Login Flow) ---

            // Clear old data
            if (Get.isRegistered<ClientData>(tag: 'currentUser')) {
              Get.delete<ClientData>(tag: 'currentUser', force: true);
            }

            // Save new user data
            Get.put<ClientData>(
              loginResult.client!,
              tag: 'currentUser',
              permanent: true,
            );

            // Save to local storage
            final storage = GetStorage();
            storage.write('user_role', loginResult.client!.role);
            storage.write('current_user_data', loginResult.client!.toJson());

            // Connect to Realtime features
            WebSocketService.instance.connect();

            // Navigate
            final drawerController = Get.find<MapDrawerController>();
            await drawerController
                .refreshUserData(); // Ensure profile is loaded

            // Check if phone number needs verification
            final profile = drawerController.fullProfile.value;
            if (profile != null && profile.phoneNumberVerified == false) {
              Get.offAll(() => const PhoneNumberScreen());
            } else {
              Get.offAll(() => const MapScreenGetX());
              THelperFunctions.showSuccessSnackBar('Success', 'Welcome!');
            }
          } else {
            // Backend rejected the token
            await googleSignIn.signOut();
            THelperFunctions.showErrorSnackBar(
              'Login Failed',
              loginResult.error ?? 'Server rejected the login.',
            );
          }
        } else {
          THelperFunctions.showErrorSnackBar(
            'Error',
            'Google did not return a token.',
          );
        }
      }
    } catch (e) {
      THelperFunctions.showErrorSnackBar(
        'Error',
        'Google login failed: ${e.toString()}',
      );
      print("Google Sign-In Error: $e");
    } finally {
      isGoogleLoading.value = false;
    }
  }

  // Placeholder for other social logins
  void handleSocialLogin(String provider) async {
    if (provider.toLowerCase() == 'google') {
      await handleGoogleLogin();
    } else if (provider.toLowerCase() == 'facebook') {
      isFacebookLoading.value = true;
      await Future.delayed(const Duration(seconds: 2));
      THelperFunctions.showSnackBar('Facebook login is not implemented yet.');
      isFacebookLoading.value = false;
    } else {
      THelperFunctions.showSnackBar('$provider login is not implemented yet.');
    }
  }
}
