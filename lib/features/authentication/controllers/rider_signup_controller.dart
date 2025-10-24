// lib/features/authentication/controllers/rider_signup_controller.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sarri_ride/features/authentication/services/auth_service.dart';
import 'package:sarri_ride/features/authentication/screens/login/login_screen_getx.dart';
import 'package:sarri_ride/utils/helpers/helper_functions.dart';

enum RiderSignupStep { email, otp, details }

class RiderSignupController extends GetxController {
  static RiderSignupController get instance => Get.find();

  final pageController = PageController();
  final Rx<RiderSignupStep> currentStep = RiderSignupStep.email.obs;
  final RxBool isLoading = false.obs;
  final RxBool obscurePassword = true.obs;

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
    pageController.dispose();
    emailController.dispose();
    otpController.dispose();
    firstNameController.dispose();
    lastNameController.dispose();
    passwordController.dispose();
    super.onClose();
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
      Get.back(); // Go back from the first step
    }
  }

  void togglePasswordVisibility() {
    obscurePassword.value = !obscurePassword.value;
  }

  // --- API Calls ---

  Future<void> sendVerificationEmail() async {
    if (!emailFormKey.currentState!.validate()) return;
    isLoading.value = true;
    try {
      final result = await AuthService.instance.sendRegistrationOtp(
        emailController.text.trim(),
        'client',
      );
      if (result.success) {
        THelperFunctions.showSnackBar(
          result.message ?? 'OTP sent successfully!',
        );
        nextStep();
      } else {
        THelperFunctions.showSnackBar(result.error ?? 'Failed to send OTP.');
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
        THelperFunctions.showSnackBar(result.message ?? 'Email verified!');
        nextStep(); // Move to details screen
      } else {
        THelperFunctions.showSnackBar(result.error ?? 'Invalid OTP.');
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
        THelperFunctions.showSnackBar(
          'Registration successful! Please log in to your new account.',
        );
      } else {
        THelperFunctions.showSnackBar(
          authResult.error ?? 'Signup failed. Please try again.',
        );
      }
    } catch (e) {
      THelperFunctions.showSnackBar('Signup failed: ${e.toString()}');
    } finally {
      isLoading.value = false;
    }
  }
}
