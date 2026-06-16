// lib/features/authentication/controllers/driver_signup_controller.dart

import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sarri_ride/features/authentication/screens/login/login_screen_getx.dart';
import 'package:sarri_ride/features/authentication/services/auth_service.dart';
import 'package:sarri_ride/features/driver/screens/driver_dashboard_screen.dart';
import 'package:sarri_ride/utils/helpers/helper_functions.dart';
import 'package:get_storage/get_storage.dart';
import 'package:sarri_ride/features/authentication/models/auth_model.dart';

// 2-step flow for email: authMethod -> emailOtp
enum DriverSignupStep { authMethod, emailOtp }

class DriverSignupController extends GetxController {
  static DriverSignupController get instance => Get.find();

  final pageController = PageController();
  final Rx<DriverSignupStep> currentStep = DriverSignupStep.authMethod.obs;
  final RxBool isLoading = false.obs;
  final RxBool privacyPolicy = false.obs;

  // ── OTP timer ───────────────────────────────────────────────────────────
  Timer? _timer;
  final RxInt resendTimer = 60.obs;
  final RxBool isResendEnabled = false.obs;

  // Step 1 — auth method (email path)
  final emailController = TextEditingController();
  final firstNameController = TextEditingController();
  final lastNameController = TextEditingController();
  final passwordController = TextEditingController();
  final emailFormKey = GlobalKey<FormState>();

  // Step 2 — OTP (email OTP, for email signup path)
  final otpController = TextEditingController();
  final otpFormKey = GlobalKey<FormState>();

  @override
  void onClose() {
    _timer?.cancel();
    pageController.dispose();
    emailController.dispose();
    firstNameController.dispose();
    lastNameController.dispose();
    passwordController.dispose();
    otpController.dispose();
    super.onClose();
  }

  // ── Navigation ───────────────────────────────────────────────────────────

  void nextStep() {
    if (currentStep.value.index < DriverSignupStep.values.length - 1) {
      currentStep.value =
          DriverSignupStep.values[currentStep.value.index + 1];
      pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.ease,
      );
    }
  }

  void previousStep() {
    if (currentStep.value.index > 0) {
      currentStep.value =
          DriverSignupStep.values[currentStep.value.index - 1];
      pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.ease,
      );
    } else {
      Get.back();
    }
  }

  // ── Timer ────────────────────────────────────────────────────────────────

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

  // ────────────────────────────────────────────────────────────────────────
  // GOOGLE SIGN-IN (primary path)
  // ────────────────────────────────────────────────────────────────────────

  Future<void> signInWithGoogle() async {
    isLoading.value = true;
    try {
      final googleSignIn = GoogleSignIn(
        clientId: Platform.isIOS
            ? '566802818676-af50fhe86j05gsf22vcrpu5o25re8g0h.apps.googleusercontent.com'
            : null,
        serverClientId:
            '566802818676-kuc13au4v6ifp3oe6qimcdp78s84fnnd.apps.googleusercontent.com',
        scopes: ['email', 'profile'],
      );

      await googleSignIn.signOut();
      final googleUser = await googleSignIn.signIn();

      if (googleUser == null) {
        // User cancelled
        isLoading.value = false;
        return;
      }

      final googleAuth = await googleUser.authentication;
      final idToken = googleAuth.idToken;

      if (idToken == null) {
        THelperFunctions.showErrorSnackBar(
            'Error', 'Google did not return a token. Please try again.');
        return;
      }

      // Send token to backend — creates/finds driver account
      final result = await AuthService.instance.loginDriverWithGoogle(idToken);

      if (result.success && result.client != null) {
        _saveUserSession(result.client!);
        // Unconditionally route to Dashboard, where Verification Wizard takes over
        THelperFunctions.showSuccessSnackBar(
            'Welcome!', 'Signed in successfully.');
        Get.offAll(() => const DriverDashboardScreen());
      } else {
        THelperFunctions.showErrorSnackBar(
            'Sign-In Failed', result.error ?? 'Please try again.');
        await googleSignIn.signOut();
      }
    } catch (e) {
      THelperFunctions.showErrorSnackBar(
          'Error', 'Google Sign-In failed: ${e.toString()}');
    } finally {
      isLoading.value = false;
    }
  }

  void _saveUserSession(ClientData client) {
    if (Get.isRegistered<ClientData>(tag: 'currentUser')) {
      Get.delete<ClientData>(tag: 'currentUser', force: true);
    }
    Get.put<ClientData>(client, tag: 'currentUser', permanent: true);
    final storage = GetStorage();
    storage.write('user_role', client.role);
    storage.write('current_user_data', client.toJson());
  }

  // ────────────────────────────────────────────────────────────────────────
  // EMAIL PATH
  // ────────────────────────────────────────────────────────────────────────

  Future<void> sendVerificationEmail({bool isResend = false}) async {
    if (!emailFormKey.currentState!.validate()) return;
    isLoading.value = true;
    try {
      final result = await AuthService.instance.sendRegistrationOtp(
        emailController.text.trim(),
        'driver',
      );
      if (result.success) {
        THelperFunctions.showSuccessSnackBar(
            'OTP Sent', result.message ?? 'Check your email for the OTP.');
        otpController.clear();
        startResendTimer();
        if (!isResend) nextStep();
      } else {
        final errorMsg = result.error?.toLowerCase() ?? '';
        if (errorMsg.contains('already registered') ||
            errorMsg.contains('please login')) {
          THelperFunctions.showErrorSnackBar(
            'Account Exists',
            'This email is already registered. Please login.',
          );
          Get.offAll(() => const LoginScreenGetX());
        } else {
          THelperFunctions.showErrorSnackBar(
              'Error', result.error ?? 'Failed to send OTP.');
        }
      }
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> verifyEmailOtp() async {
    if (!otpFormKey.currentState!.validate()) return;
    isLoading.value = true;
    try {
      final result = await AuthService.instance.verifyRegistrationOtp(
        emailController.text.trim(),
        otpController.text.trim(),
        'driver',
      );
      if (result.success) {
        THelperFunctions.showSuccessSnackBar(
            'Email Verified!', 'Setting up your account...');
        await _completeEmailSignup();
      } else {
        THelperFunctions.showErrorSnackBar(
            'Error', result.error ?? 'Invalid OTP.');
        isLoading.value = false;
      }
    } catch (e) {
      isLoading.value = false;
    }
  }

  Future<void> _completeEmailSignup() async {
    try {
      final result = await AuthService.instance.driverEmailSignup(
        emailController.text.trim(),
        passwordController.text.trim(),
        firstNameController.text.trim(),
        lastNameController.text.trim(),
      );

      if (result.success) {
        if (result.client != null) {
          _saveUserSession(result.client!);
        }
        THelperFunctions.showSuccessSnackBar(
          'Welcome to SarriRide! 🎉',
          result.message ?? 'Your account is ready.',
        );
        Get.offAll(() => const DriverDashboardScreen());
      } else {
        THelperFunctions.showErrorSnackBar(
            'Registration Failed', result.error ?? 'Please try again.');
      }
    } finally {
      isLoading.value = false;
    }
  }
}
