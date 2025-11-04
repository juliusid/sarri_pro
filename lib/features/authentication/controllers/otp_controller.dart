// lib/features/authentication/controllers/otp_controller.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sarri_ride/features/authentication/screens/login/login_screen_getx.dart';
import 'package:sarri_ride/features/authentication/services/auth_service.dart';
import 'package:sarri_ride/utils/helpers/helper_functions.dart';

class OTPController extends GetxController {
  static OTPController get instance => Get.find();

  final otpController = TextEditingController();
  final isLoading = false.obs;
  late final String email;

  @override
  void onInit() {
    super.onInit();
    // Get the email passed as an argument from the SignupScreen
    if (Get.arguments != null) {
      email = Get.arguments as String;
    } else {
      // Handle case where email is not passed, maybe navigate back
      Get.back();
      // --- CORRECTED ---
      THelperFunctions.showErrorSnackBar(
        'Error',
        'An error occurred. Please try signing up again.',
      );
    }
  }

  /// Verifies the OTP entered by the user.
  void verifyOTP() async {
    // Prevent multiple submissions
    if (isLoading.value) return;

    if (otpController.text.trim().length != 6) {
      // Basic validation for OTP length
      // --- CORRECTED ---
      THelperFunctions.showErrorSnackBar(
        'Invalid OTP',
        'Please enter a valid 6-digit OTP.',
      );
      return;
    }

    isLoading.value = true;
    try {
      // API call to verify OTP
      // We assume the role is 'client' for the rider app signup
      final result = await AuthService.instance.verifyEmail(
        email,
        otpController.text.trim(),
        "client",
      );

      if (result.success) {
        // IMPORTANT: Verification successful. Redirect to the Login screen.
        Get.offAll(() => const LoginScreenGetX());
        // --- CORRECTED ---
        THelperFunctions.showSuccessSnackBar(
          'Success',
          'Verification successful! Please log in to your new account.',
        );
      } else {
        // --- CORRECTED ---
        THelperFunctions.showErrorSnackBar(
          'Verification Failed',
          result.error ?? 'Invalid OTP. Please try again.',
        );
      }
    } catch (e) {
      // --- CORRECTED ---
      THelperFunctions.showErrorSnackBar(
        'Error',
        'An error occurred: ${e.toString()}',
      );
    } finally {
      isLoading.value = false;
    }
  }

  @override
  void onClose() {
    otpController.dispose();
    super.onClose();
  }
}
