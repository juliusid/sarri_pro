import 'dart:convert';
import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:sarri_ride/core/services/http_service.dart';
import 'package:sarri_ride/core/services/notification_service.dart';
import 'package:sarri_ride/core/services/websocket_service.dart';
import 'package:sarri_ride/features/authentication/models/auth_model.dart';
import 'package:sarri_ride/features/authentication/screens/phone_verification/phone_number_screen.dart';
import 'package:sarri_ride/features/authentication/services/auth_service.dart';
import 'package:sarri_ride/features/driver/screens/driver_dashboard_screen.dart';
import 'package:sarri_ride/features/ride/controllers/drawer_controller.dart';
import 'package:sarri_ride/features/ride/widgets/map_screen_getx.dart';
import 'package:sarri_ride/features/authentication/screens/signup/driver_signup_screen.dart';
import 'package:sarri_ride/features/authentication/screens/signup/rider_signup_screen.dart';
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
  final RxBool isAppleLoading = false.obs;
  final selectedRole = UserType.rider.obs;

  /// Name/email Apple returns only on a first-ever sign-in. Kept so a
  /// new-account signup can use it instead of falling back to placeholders.
  Map<String, dynamic>? _pendingAppleUserPayload;

  // @override
  // void onClose() {
  //   emailController.dispose();
  //   passwordController.dispose();
  //   super.onClose();
  // }

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
          await NotificationService.instance.updateTokenOnBackend();
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
        final String error = loginResult.error ?? 'Please check your credentials and selected role.';
        
        // Detect incomplete registration (missing password / social sign-in prompt)
        if (error.toLowerCase().contains('social sign-in') || 
            error.toLowerCase().contains('complete your registration')) {
          
          Get.snackbar(
            'Incomplete Registration',
            'It looks like you haven\'t finished setting up your account.',
            mainButton: TextButton(
              onPressed: () {
                if (isDriverLogin) {
                  Get.to(() => DriverSignupScreen(email: email));
                } else {
                  Get.to(() => RiderSignupScreen(email: email));
                }
              },
              child: const Text('Complete Signup'),
            ),
            duration: const Duration(seconds: 8),
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.orange.withOpacity(0.9),
            colorText: Colors.white,
          );
        } else {
          THelperFunctions.showErrorSnackBar('Login Failed', error);
        }
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

  // Unified Google login — backend detects Client vs Driver from the
  // Google account, so the app no longer needs to pick a role up front.
  Future<void> handleGoogleLogin() async {
    isGoogleLoading.value = true;

    final googleSignIn = GoogleSignIn(
      clientId: Platform.isIOS
          ? '566802818676-af50fhe86j05gsf22vcrpu5o25re8g0h.apps.googleusercontent.com'
          : null,
      serverClientId:
          '566802818676-kuc13au4v6ifp3oe6qimcdp78s84fnnd.apps.googleusercontent.com',
      scopes: ['email', 'profile'],
    );

    try {
      await googleSignIn.signOut();
      final googleUser = await googleSignIn.signIn();

      if (googleUser == null) {
        debugPrint('Google Sign-In canceled by user or returned null.');
        THelperFunctions.showSnackBar('Google Sign-In canceled.');
        return;
      }

      final googleAuth = await googleUser.authentication;
      final googleToken = googleAuth.idToken;

      if (googleToken == null) {
        THelperFunctions.showErrorSnackBar(
            'Error', 'Google did not return a token.');
        return;
      }

      final result = await AuthService.instance.socialLogin(googleToken, 'google');
      await _handleSocialLoginResult(
        result,
        provider: 'google',
        token: googleToken,
        onNoAccountOrFailure: () async {
          try {
            await googleSignIn.signOut();
          } catch (_) {}
        },
      );
    } catch (e) {
      THelperFunctions.showErrorSnackBar(
          'Error', 'Google login failed: ${e.toString()}');
      print('Google Sign-In Error: $e');
    } finally {
      if (!isClosed) {
        isGoogleLoading.value = false;
      }
    }
  }

  // Shared handling for the unified /auth/social/login response — routes to
  // the right dashboard by the role the backend detected, prompts Signup on
  // a genuine "no account" result, and lets the person pick a role when the
  // same provider account is linked to both a rider and a driver profile.
  Future<void> _handleSocialLoginResult(
    SocialLoginResult result, {
    required String provider,
    required String token,
    required Future<void> Function() onNoAccountOrFailure,
  }) async {
    if (result.success && result.client != null) {
      if (Get.isRegistered<ClientData>(tag: 'currentUser')) {
        Get.delete<ClientData>(tag: 'currentUser', force: true);
      }
      Get.put<ClientData>(result.client!, tag: 'currentUser', permanent: true);

      final storage = GetStorage();
      storage.write('user_role', result.role);
      storage.write('current_user_data', result.client!.toJson());

      WebSocketService.instance.connect();
      await NotificationService.instance.updateTokenOnBackend();

      if (result.role == 'driver') {
        Get.offAll(() => const DriverDashboardScreen());
        THelperFunctions.showSuccessSnackBar('Welcome back!', 'Signed in as driver.');
        return;
      }

      // Client/rider
      final drawerController = Get.find<MapDrawerController>();
      await drawerController.refreshUserData();
      final profile = drawerController.fullProfile.value;
      if (profile != null && profile.phoneNumberVerified == false) {
        Get.offAll(() => const PhoneNumberScreen());
      } else {
        Get.offAll(() => const MapScreenGetX());
        THelperFunctions.showSuccessSnackBar('Success', 'Welcome!');
      }
      return;
    }

    if (result.multipleAccounts) {
      await onNoAccountOrFailure();
      _promptRoleChoiceForMultipleAccounts(result.accounts!, provider, token);
      return;
    }

    if (result.noAccountFound) {
      // Genuinely new person. Don't dead-end them into "please sign up first"
      // and a second Google prompt — the only thing we still need is whether
      // they're a rider or a driver, so ask that one question and finish the
      // signup with the token already in hand.
      if (provider == 'apple') {
        // Drivers have no Apple backend yet, so Apple can only mean rider.
        await _completeNewAppleRiderSignup(token);
      } else {
        _promptRoleChoiceForNewAccount(token);
      }
      return;
    }

    await onNoAccountOrFailure();
    THelperFunctions.showErrorSnackBar(
      'Login Failed',
      result.error ?? 'Server rejected the login.',
    );
  }

  // New Google account: ask the one thing a Google token can't tell us —
  // rider or driver — then create the account straight away. Guessing instead
  // of asking would be worse than a dead end: silently making a rider account
  // for someone who meant to drive leaves their email permanently unusable
  // for a driver signup.
  void _promptRoleChoiceForNewAccount(String token) {
    Get.dialog(
      AlertDialog(
        title: const Text('How will you be using Sarri Ride?'),
        content: const Text(
          "Looks like you're new here. Pick how you'd like to get started.",
        ),
        actions: [
          TextButton(
            onPressed: () {
              Get.back();
              _completeRoleSpecificGoogleLogin('client', token);
            },
            child: const Text('As a Rider'),
          ),
          TextButton(
            onPressed: () {
              Get.back();
              _completeRoleSpecificGoogleLogin('driver', token);
            },
            child: const Text('As a Driver'),
          ),
        ],
      ),
      barrierDismissible: true,
    );
  }

  // New Apple account — rider only, so no role question to ask.
  Future<void> _completeNewAppleRiderSignup(String identityToken) async {
    isAppleLoading.value = true;
    try {
      final result = await AuthService.instance.loginWithApple(
        identityToken,
        user: _pendingAppleUserPayload,
      );

      if (result.success && result.client != null) {
        if (Get.isRegistered<ClientData>(tag: 'currentUser')) {
          Get.delete<ClientData>(tag: 'currentUser', force: true);
        }
        Get.put<ClientData>(result.client!, tag: 'currentUser', permanent: true);

        final storage = GetStorage();
        storage.write('user_role', result.client!.role);
        storage.write('current_user_data', result.client!.toJson());

        WebSocketService.instance.connect();
        await NotificationService.instance.updateTokenOnBackend();

        final drawerController = Get.find<MapDrawerController>();
        await drawerController.refreshUserData();
        final profile = drawerController.fullProfile.value;
        if (profile != null && profile.phoneNumberVerified == false) {
          Get.offAll(() => const PhoneNumberScreen());
        } else {
          Get.offAll(() => const MapScreenGetX());
          THelperFunctions.showSuccessSnackBar('Welcome!', 'Your account is ready.');
        }
      } else {
        THelperFunctions.showErrorSnackBar(
          'Sign Up Failed',
          result.error ?? 'Could not create your account. Please try again.',
        );
      }
    } finally {
      if (!isClosed) {
        isAppleLoading.value = false;
      }
    }
  }

  // One Google account linked to both a rider and a driver profile — let the
  // person choose, then complete sign-in through the existing per-role
  // Google endpoints (Apple never reaches here: Driver has no Apple auth).
  void _promptRoleChoiceForMultipleAccounts(
    List<Map<String, dynamic>> accounts,
    String provider,
    String token,
  ) {
    Get.dialog(
      AlertDialog(
        title: const Text('Choose an account'),
        content: const Text(
          'This sign-in is linked to both a rider and a driver account. Which one would you like to continue with?',
        ),
        actions: accounts.map((account) {
          final role = account['role'] as String;
          return TextButton(
            onPressed: () async {
              Get.back();
              await _completeRoleSpecificGoogleLogin(role, token);
            },
            child: Text(role == 'driver' ? 'Continue as Driver' : 'Continue as Rider'),
          );
        }).toList(),
      ),
    );
  }

  Future<void> _completeRoleSpecificGoogleLogin(String role, String googleToken) async {
    isGoogleLoading.value = true;
    try {
      if (role == 'driver') {
        final loginResult = await AuthService.instance.loginDriverWithGoogle(googleToken);
        if (loginResult.success && loginResult.client != null) {
          if (Get.isRegistered<ClientData>(tag: 'currentUser')) {
            Get.delete<ClientData>(tag: 'currentUser', force: true);
          }
          Get.put<ClientData>(loginResult.client!, tag: 'currentUser', permanent: true);
          final storage = GetStorage();
          storage.write('user_role', loginResult.client!.role);
          storage.write('current_user_data', loginResult.client!.toJson());
          WebSocketService.instance.connect();
          await NotificationService.instance.updateTokenOnBackend();
          Get.offAll(() => const DriverDashboardScreen());
          THelperFunctions.showSuccessSnackBar('Welcome back!', 'Signed in as driver.');
        } else {
          THelperFunctions.showErrorSnackBar(
              'Login Failed', loginResult.error ?? 'Server rejected the login.');
        }
      } else {
        final loginResult = await AuthService.instance.loginWithGoogle(googleToken);
        if (loginResult.success && loginResult.client != null) {
          if (Get.isRegistered<ClientData>(tag: 'currentUser')) {
            Get.delete<ClientData>(tag: 'currentUser', force: true);
          }
          Get.put<ClientData>(loginResult.client!, tag: 'currentUser', permanent: true);
          final storage = GetStorage();
          storage.write('user_role', loginResult.client!.role);
          storage.write('current_user_data', loginResult.client!.toJson());
          WebSocketService.instance.connect();
          await NotificationService.instance.updateTokenOnBackend();

          final drawerController = Get.find<MapDrawerController>();
          await drawerController.refreshUserData();
          final profile = drawerController.fullProfile.value;
          if (profile != null && profile.phoneNumberVerified == false) {
            Get.offAll(() => const PhoneNumberScreen());
          } else {
            Get.offAll(() => const MapScreenGetX());
            THelperFunctions.showSuccessSnackBar('Success', 'Welcome!');
          }
        } else {
          THelperFunctions.showErrorSnackBar(
              'Login Failed', loginResult.error ?? 'Server rejected the login.');
        }
      }
    } finally {
      if (!isClosed) {
        isGoogleLoading.value = false;
      }
    }
  }

  // Unified Sign in with Apple (iOS only). Apple has no Driver-side backend
  // support today, so a driver's Apple sign-in correctly resolves to
  // "no account found" and prompts Signup rather than erroring.
  Future<void> handleAppleSignIn() async {
    isAppleLoading.value = true;
    try {
      // Check if Sign in with Apple is available on this device/build
      final isAvailable = await SignInWithApple.isAvailable();
      if (!isAvailable) {
        THelperFunctions.showErrorSnackBar(
          'Not Available',
          'Sign in with Apple is not available on this device. Please use another sign-in method.',
        );
        isAppleLoading.value = false;
        return;
      }

      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      final identityToken = credential.identityToken;

      if (identityToken != null) {
        debugPrint(
          'APPLE SIGN-IN: identityToken received: ${identityToken.substring(0, 20)}...',
        );

        // Apple only hands over name/email on the very first sign-in. Hold on
        // to it here — if this turns out to be a new account, it's the only
        // chance we get to save a real name instead of "Apple User".
        final givenName = credential.givenName;
        final familyName = credential.familyName;
        final appleEmail = credential.email;
        if (givenName != null || familyName != null || appleEmail != null) {
          _pendingAppleUserPayload = {
            'name': {
              'firstName': givenName ?? '',
              'lastName': familyName ?? '',
            },
            'email': appleEmail ?? '',
          };
        }

        print("LOGIN_CONTROLLER: Calling unified AuthService.socialLogin (apple)...");
        final result = await AuthService.instance.socialLogin(identityToken, 'apple');

        print(
          "LOGIN_CONTROLLER: socialLogin(apple) returned - Success: ${result.success}, noAccount: ${result.noAccountFound}, error: ${result.error}",
        );

        await _handleSocialLoginResult(
          result,
          provider: 'apple',
          token: identityToken,
          onNoAccountOrFailure: () async {},
        );
      } else {
        print("LOGIN_CONTROLLER: No identity token returned from Apple");
        THelperFunctions.showErrorSnackBar(
          'Error',
          'Apple did not return a token. Please try again.',
        );
      }
    } on SignInWithAppleAuthorizationException catch (e) {
      print(
        "LOGIN_CONTROLLER: SignInWithAppleAuthorizationException - Code: ${e.code}, Message: ${e.message}",
      );
      if (e.code == AuthorizationErrorCode.canceled) {
        // User cancelled or OS aborted - show snackbar for debugging
        THelperFunctions.showSnackBar('Sign-In cancelled.');
        debugPrint('Apple Sign-In: User cancelled or OS aborted.');
      } else if (e.code == AuthorizationErrorCode.failed) {
        THelperFunctions.showErrorSnackBar(
          'Sign In Failed',
          'Apple Sign-In failed. Please check that Sign in with Apple is enabled in your device Settings > [Your Name] > Password & Security.',
        );
        debugPrint('Apple Sign-In failed: ${e.message}');
      } else if (e.code == AuthorizationErrorCode.notHandled) {
        THelperFunctions.showErrorSnackBar(
          'Sign In Error',
          'The sign-in request was not handled. Please try again.',
        );
        debugPrint('Apple Sign-In not handled: ${e.message}');
      } else if (e.code == AuthorizationErrorCode.notInteractive) {
        THelperFunctions.showErrorSnackBar(
          'Sign In Error',
          'Apple Sign-In requires interaction. Please try again.',
        );
        debugPrint('Apple Sign-In not interactive: ${e.message}');
      } else {
        THelperFunctions.showErrorSnackBar(
          'Sign In Error',
          'Apple Sign-In error: ${e.message}',
        );
        debugPrint('Apple Sign-In unknown error: ${e.code} - ${e.message}');
      }
    } catch (e, stackTrace) {
      print("LOGIN_CONTROLLER: Unexpected Apple Sign-In error: $e");
      print("LOGIN_CONTROLLER: Stack trace: $stackTrace");
      THelperFunctions.showErrorSnackBar(
        'Error',
        'Apple login failed. Please try again or use another sign-in method.',
      );
      debugPrint('Apple Sign-In unexpected error: $e');
      debugPrint('Stack trace: $stackTrace');
    } finally {
      if (!isClosed) {
        isAppleLoading.value = false;
      }
    }
  }

  // Placeholder for other social logins
  void handleSocialLogin(String provider) async {
    if (provider.toLowerCase() == 'google') {
      await handleGoogleLogin();
    } else if (provider.toLowerCase() == 'apple') {
      await handleAppleSignIn();
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
