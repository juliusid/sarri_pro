// lib/features/authentication/controllers/rider_signup_controller.dart

import 'dart:async'; // Required for Timer
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
import 'package:sarri_ride/features/authentication/screens/login/login_screen_getx.dart';
import 'package:sarri_ride/features/ride/controllers/drawer_controller.dart';
import 'package:sarri_ride/features/ride/widgets/map_screen_getx.dart';
import 'package:sarri_ride/utils/helpers/helper_functions.dart';

enum RiderSignupStep { email, otp, details }

class RiderSignupController extends GetxController {
  static RiderSignupController get instance => Get.find();

  final pageController = PageController();
  final Rx<RiderSignupStep> currentStep = RiderSignupStep.email.obs;
  final RxBool isLoading = false.obs;
  final RxBool obscurePassword = true.obs;
  final RxBool isGoogleLoading = false.obs;
  final RxBool privacyPolicy = false.obs;

  // --- NEW: TIMER VARIABLES ---
  Timer? _timer;
  final RxInt resendTimer = 60.obs;
  final RxBool isResendEnabled = false.obs;

  // --- Step 1: Email
  final emailController = TextEditingController();
  final emailFormKey = GlobalKey<FormState>();

  // --- Step 2: OTP
  final otpController = TextEditingController();
  final otpFormKey = GlobalKey<FormState>();

  // --- Step 3: Details
  final detailsFormKey = GlobalKey<FormState>();
  final firstNameController = TextEditingController();
  final lastNameController = TextEditingController();
  final passwordController = TextEditingController();

  @override
  void onClose() {
    _timer?.cancel(); // Cancel timer
    pageController.dispose();
    emailController.dispose();
    otpController.dispose();
    firstNameController.dispose();
    lastNameController.dispose();
    passwordController.dispose();
    super.onClose();
  }

  // --- TIMER LOGIC ---
  void startResendTimer() {
    isResendEnabled.value = false;
    resendTimer.value = 60;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (resendTimer.value > 0) {
        resendTimer.value--;
      } else {
        isResendEnabled.value = true;
        _timer?.cancel();
      }
    });
  }

  void nextStep() {
    if (currentStep.value.index < RiderSignupStep.values.length - 1) {
      currentStep.value = RiderSignupStep.values[currentStep.value.index + 1];
      pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.ease,
      );
    }
  }

  void previousStep() {
    if (currentStep.value.index > 0) {
      currentStep.value = RiderSignupStep.values[currentStep.value.index - 1];
      pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.ease,
      );
    } else {
      Get.back();
    }
  }

  void togglePasswordVisibility() {
    obscurePassword.value = !obscurePassword.value;
  }

  // --- API Calls ---

  // Updated to accept isResend parameter
  Future<void> sendVerificationEmail({bool isResend = false}) async {
    if (!emailFormKey.currentState!.validate()) return;
    isLoading.value = true;
    try {
      final result = await AuthService.instance.sendRegistrationOtp(
        emailController.text.trim(),
        'client',
      );
      if (result.success) {
        THelperFunctions.showSuccessSnackBar(
          'Success',
          result.message ?? 'OTP sent successfully!',
        );

        startResendTimer();

        // Only move to next step if it's the first time
        if (!isResend) {
          nextStep();
        }
      } else {
        final errorMsg = result.error?.toLowerCase() ?? '';
        if (errorMsg.contains('already verified')) {
          THelperFunctions.showSuccessSnackBar(
            'Welcome Back',
            'Email already verified. Resuming account creation...',
          );
          currentStep.value = RiderSignupStep.details;
          pageController.animateToPage(
            RiderSignupStep.details.index,
            duration: const Duration(milliseconds: 300),
            curve: Curves.ease,
          );
        } else {
          THelperFunctions.showErrorSnackBar(
            'Error',
            result.error ?? 'Failed to send OTP.',
          );
        }
      }
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> verifyOtp() async {
    if (!otpFormKey.currentState!.validate()) return;
    isLoading.value = true;
    try {
      final result = await AuthService.instance.verifyRegistrationOtp(
        emailController.text.trim(),
        otpController.text.trim(),
        'client',
      );

      if (result.success) {
        THelperFunctions.showSuccessSnackBar(
          'Success',
          result.message ?? 'Email verified!',
        );
        nextStep();
      } else {
        THelperFunctions.showErrorSnackBar(
          'Error',
          result.error ?? 'Invalid OTP.',
        );
      }
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> registerRider() async {
    if (!detailsFormKey.currentState!.validate()) return;
    isLoading.value = true;
    try {
      final authResult = await AuthService.instance.signup(
        emailController.text.trim(),
        passwordController.text.trim(),
        firstNameController.text.trim(),
        lastNameController.text.trim(),
      );

      if (authResult.success) {
        Get.offAll(() => const LoginScreenGetX());
        THelperFunctions.showSuccessSnackBar(
          'Success',
          'Registration successful! Please log in to your new account.',
        );
      } else {
        THelperFunctions.showErrorSnackBar(
          'Signup Failed',
          authResult.error ?? 'Signup failed. Please try again.',
        );
      }
    } catch (e) {
      THelperFunctions.showErrorSnackBar('Signup Failed', e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> handleGoogleSignup() async {
    isGoogleLoading.value = true;
    try {
      final googleSignIn = GoogleSignIn(
        serverClientId:
            '145756377096-e0lc455dkoda47a1sfj9thkefnf5q8pr.apps.googleusercontent.com',
        scopes: ['email', 'profile'],
      );

      await googleSignIn.signOut();
      final googleUser = await googleSignIn.signIn();

      if (googleUser != null) {
        final googleAuth = await googleUser.authentication;
        final googleToken = googleAuth.idToken;

        if (googleToken != null) {
          final loginResult = await AuthService.instance.loginWithGoogle(
            googleToken,
          );

          if (loginResult.success && loginResult.client != null) {
            // 1. Store Data
            if (Get.isRegistered<ClientData>(tag: 'currentUser')) {
              Get.delete<ClientData>(tag: 'currentUser', force: true);
            }
            Get.put<ClientData>(
              loginResult.client!,
              tag: 'currentUser',
              permanent: true,
            );

            final drawerController = Get.find<MapDrawerController>();
            await drawerController.refreshUserData();

            final storage = GetStorage();
            storage.write('user_role', loginResult.client!.role);

            // 2. Refresh Token
            final String userId = loginResult.client!.id;
            bool refreshSuccess = await HttpService.instance
                .refreshTokenImmediately(isDriver: false, userId: userId);

            if (!refreshSuccess) {
              await googleSignIn.signOut();
              isGoogleLoading.value = false;
              return;
            }

            // 3. Connect Socket
            WebSocketService.instance.connect();

            // 4. Check Phone Number
            final profile = drawerController.fullProfile.value;
            if (profile != null && profile.phoneNumberVerified == false) {
              Get.offAll(() => const PhoneNumberScreen());
              THelperFunctions.showSnackBar('Please verify your phone number.');
            } else {
              Get.offAll(() => const MapScreenGetX());
              THelperFunctions.showSuccessSnackBar('Success', 'Welcome!');
            }
          } else {
            await googleSignIn.signOut();
            THelperFunctions.showErrorSnackBar(
              'Error',
              loginResult.error ?? 'Google signup failed.',
            );
          }
        } else {
          await googleSignIn.signOut();
          THelperFunctions.showErrorSnackBar(
            'Error',
            'Could not get Google ID token.',
          );
        }
      }
    } catch (e) {
      THelperFunctions.showErrorSnackBar(
        'Error',
        'Google signup failed: ${e.toString()}',
      );
    } finally {
      if (!isClosed) isGoogleLoading.value = false;
    }
  }
}
