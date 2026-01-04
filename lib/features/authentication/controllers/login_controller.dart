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
    if (selectedRole.value != UserType.rider) {
      THelperFunctions.showErrorSnackBar(
        'Error',
        "Google Sign-In is currently only available for Riders.",
      );
      return;
    }

    isGoogleLoading.value = true;
    try {
      // --- CONFIGURE GOOGLE SIGN IN ---
      final googleSignIn = GoogleSignIn(
        serverClientId:
            '189458277367-bnqmk6rsrtnh7no8u05vltkmsch4n6ig.apps.googleusercontent.com',
      );

      await googleSignIn.signOut(); // Force account picker
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

            // Refresh user data
            final drawerController = Get.find<MapDrawerController>();
            await drawerController.refreshUserData();

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
              isGoogleLoading.value = false;
              return;
            }
            print("LOGIN_CONTROLLER: Immediate token refresh successful.");

            print("LOGIN_CONTROLLER: Connecting WebSocket for Rider...");
            WebSocketService.instance.connect();

            // CHECK FOR PHONE NUMBER
            final profile = drawerController.fullProfile.value;

            // --- FIXED: Uncommented Phone Number Verification Logic for Google ---

            // Check if profile exists and phone number is missing OR not verified
            if (profile != null && profile.phoneNumberVerified == false) {
              print(
                "LOGIN_CONTROLLER: Phone number missing. Forcing verification.",
              );

              // 1. Uncommented verification screen
              Get.offAll(() => const PhoneNumberScreen());

              // 2. Removed bypass to MapScreen
              // Get.offAll(() => const MapScreenGetX());

              THelperFunctions.showSnackBar(
                'Please verify your phone number to continue.',
              );
            } else {
              // Phone number exists, proceed to map
              Get.offAll(() => const MapScreenGetX());
              THelperFunctions.showSuccessSnackBar('Success', 'Welcome!');
            }
          } else {
            await googleSignIn.signOut();
            THelperFunctions.showErrorSnackBar(
              'Login Failed',
              loginResult.error ?? 'Google login failed on our server.',
            );
          }
        } else {
          await googleSignIn.signOut();
          THelperFunctions.showErrorSnackBar(
            'Error',
            'Could not get Google ID token.',
          );
        }
      } else {
        print("LOGIN_CONTROLLER: Google Sign-In cancelled by user.");
      }
    } catch (e) {
      THelperFunctions.showErrorSnackBar(
        'Error',
        'Google login failed: ${e.toString()}',
      );
      print("LOGIN_CONTROLLER: Google Sign-In Error: $e");
      try {
        await GoogleSignIn().signOut();
      } catch (_) {}
    } finally {
      if (!isClosed) {
        isGoogleLoading.value = false;
      }
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
