// lib/features/authentication/controllers/driver_signup_controller.dart

import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sarri_ride/features/authentication/models/driver_auth_model.dart';
import 'package:sarri_ride/features/authentication/screens/login/login_screen_getx.dart';
import 'package:sarri_ride/features/authentication/services/auth_service.dart';
import 'package:sarri_ride/features/driver/screens/driver_dashboard_screen.dart';
import 'package:sarri_ride/utils/formatters/formatter.dart';
import 'package:sarri_ride/utils/helpers/helper_functions.dart';

// 3-step flow: authMethod → phone (enter+OTP combined) → details
enum DriverSignupStep { authMethod, phone, details }

class DriverSignupController extends GetxController {
  static DriverSignupController get instance => Get.find();

  final pageController = PageController();
  final Rx<DriverSignupStep> currentStep = DriverSignupStep.authMethod.obs;
  final RxBool isLoading = false.obs;
  final RxBool privacyPolicy = false.obs;

  // ── Google signup state ─────────────────────────────────────────────────
  final RxBool isGoogleSignup = false.obs;
  String? _googleIdToken;

  // ── Driver type ─────────────────────────────────────────────────────────
  final RxString selectedDriverType = 'ride_hailing'.obs;

  // ── OTP timer ───────────────────────────────────────────────────────────
  Timer? _timer;
  final RxInt resendTimer = 60.obs;
  final RxBool isResendEnabled = false.obs;

  // ── Phone OTP reveal state (combined phone screen) ───────────────────────
  final RxBool otpFieldVisible = false.obs;

  // ── Verified phone ───────────────────────────────────────────────────────
  String? _verifiedPhoneNumber;

  // Step 1 — auth method (email path)
  final emailController = TextEditingController();
  final emailFormKey = GlobalKey<FormState>();

  // OTP (email OTP, for email signup path)
  final otpController = TextEditingController();
  final otpFormKey = GlobalKey<FormState>();

  // Step 2 — phone (combined)
  final phoneNumberController = TextEditingController();
  final phoneFormKey = GlobalKey<FormState>();
  final phoneOtpController = TextEditingController();
  final phoneOtpFormKey = GlobalKey<FormState>();

  // Step 3 — details
  final detailsFormKey = GlobalKey<FormState>();
  final firstNameController = TextEditingController();
  final lastNameController = TextEditingController();
  final passwordController = TextEditingController();
  final vehicleMakeController = TextEditingController();
  final vehicleModelController = TextEditingController();
  final vehicleYearController = TextEditingController();
  final vehiclePlateController = TextEditingController();
  final vehicleSeatController = TextEditingController();

  @override
  void onClose() {
    _timer?.cancel();
    pageController.dispose();
    emailController.dispose();
    otpController.dispose();
    phoneNumberController.dispose();
    phoneOtpController.dispose();
    firstNameController.dispose();
    lastNameController.dispose();
    passwordController.dispose();
    vehicleMakeController.dispose();
    vehicleModelController.dispose();
    vehicleYearController.dispose();
    vehiclePlateController.dispose();
    vehicleSeatController.dispose();
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
      if (currentStep.value == DriverSignupStep.phone) {
        otpFieldVisible.value = false;
        phoneOtpController.clear();
      }
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

  // ── Pre-fill email (when coming from login with incomplete signup) ────────

  void setInitialEmail(String email) {
    emailController.text = email.trim().toLowerCase();
  }

  // ── Phone formatter ──────────────────────────────────────────────────────

  String get formattedPhoneNumber {
    String formatted = TFormatter.formatNigeriaPhoneNumber(
      phoneNumberController.text.trim(),
    );
    return formatted.replaceAll(' ', '');
  }

  // ── Name formatter ───────────────────────────────────────────────────────

  String _formatName(String name) {
    if (name.isEmpty) return name;
    final trimmed = name.trim();
    return trimmed[0].toUpperCase() + trimmed.substring(1).toLowerCase();
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
        if (result.isNewDriver) {
          // Incomplete signup — pre-fill from Google
          isGoogleSignup.value = true;
          _googleIdToken = idToken;

          // Pre-fill name and email from Google profile
          final nameParts = googleUser.displayName?.split(' ') ?? [];
          if (nameParts.isNotEmpty) {
            firstNameController.text = nameParts.first;
            if (nameParts.length > 1) {
              lastNameController.text = nameParts.sublist(1).join(' ');
            }
          }
          emailController.text = result.client!.email;

          if (result.signupStep == 'step2' && result.phoneNumber != null) {
            // Already verified phone before — skip to Step 3 directly!
            _verifiedPhoneNumber = result.phoneNumber;
            phoneNumberController.text = result.phoneNumber!;
            currentStep.value = DriverSignupStep.details;
            pageController.animateToPage(
              DriverSignupStep.details.index,
              duration: const Duration(milliseconds: 300),
              curve: Curves.ease,
            );
            THelperFunctions.showSuccessSnackBar(
              'Almost there!',
              'Phone already verified. Complete your vehicle details.',
            );
          } else {
            // Phone not yet verified — go to Step 2
            currentStep.value = DriverSignupStep.phone;
            pageController.animateToPage(
              DriverSignupStep.phone.index,
              duration: const Duration(milliseconds: 300),
              curve: Curves.ease,
            );
            THelperFunctions.showSuccessSnackBar(
              'Welcome!',
              'Google account verified. Please verify your phone number.',
            );
          }
        } else {
          // Fully registered driver — go to dashboard
          THelperFunctions.showSuccessSnackBar(
              'Welcome back!', 'Signed in successfully.');
          Get.offAll(() => const DriverDashboardScreen());
        }
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

  // ────────────────────────────────────────────────────────────────────────
  // EMAIL PATH — send OTP
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
        } else if (errorMsg.contains('already verified')) {
          THelperFunctions.showSuccessSnackBar(
            'Welcome Back',
            'Email verified. Continuing registration...',
          );
          // Skip OTP step, go to phone
          currentStep.value = DriverSignupStep.phone;
          pageController.animateToPage(
            DriverSignupStep.phone.index,
            duration: const Duration(milliseconds: 300),
            curve: Curves.ease,
          );
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
            'Email Verified!', result.message ?? '');
        // Go to phone step (index 1 in the new 3-step flow)
        currentStep.value = DriverSignupStep.phone;
        pageController.animateToPage(
          DriverSignupStep.phone.index,
          duration: const Duration(milliseconds: 300),
          curve: Curves.ease,
        );
      } else {
        THelperFunctions.showErrorSnackBar(
            'Error', result.error ?? 'Invalid OTP.');
      }
    } finally {
      isLoading.value = false;
    }
  }

  // ────────────────────────────────────────────────────────────────────────
  // PHONE — send OTP (combined screen: reveal OTP field inline)
  // ────────────────────────────────────────────────────────────────────────

  Future<void> sendPhoneVerificationOtp() async {
    if (!phoneFormKey.currentState!.validate()) return;

    // Dev bypass
    final String phoneNumber = formattedPhoneNumber;
    if (phoneNumber.startsWith('+234777')) {
      THelperFunctions.showSuccessSnackBar(
          'Dev Bypass', 'Test number — skipping OTP.');
      _verifiedPhoneNumber = phoneNumber;
      _goToDetails();
      return;
    }

    isLoading.value = true;
    try {
      final email = isGoogleSignup.value ? '' : emailController.text.trim();
      final result = await AuthService.instance.sendPhoneOtp(
        phoneNumber,
        'driver',
        email,
      );

      if (result.success) {
        if (result.alreadyVerified) {
          _verifiedPhoneNumber = phoneNumber;
          _goToDetails();
          return;
        }
        THelperFunctions.showSuccessSnackBar(
            'OTP Sent', 'Check your phone for the verification code.');
        startResendTimer();
        // Reveal the OTP input field inline (no page navigation)
        otpFieldVisible.value = true;
      } else {
        final errorMsg = result.error?.toLowerCase() ?? '';
        if (errorMsg.contains('verified') ||
            errorMsg.contains('already verified')) {
          _verifiedPhoneNumber = phoneNumber;
          _goToDetails();
        } else {
          THelperFunctions.showErrorSnackBar(
              'Error', result.error ?? 'Failed to send OTP.');
        }
      }
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> resendPhoneOtp() async {
    isLoading.value = true;
    try {
      final email = isGoogleSignup.value ? '' : emailController.text.trim();
      final result = await AuthService.instance.resendPhoneOtp(
        formattedPhoneNumber,
        'driver',
        email,
      );
      if (result.success) {
        THelperFunctions.showSuccessSnackBar('Resent', 'OTP sent again.');
        startResendTimer();
      } else {
        THelperFunctions.showErrorSnackBar(
            'Error', result.error ?? 'Failed to resend OTP.');
      }
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> verifyPhoneOtp() async {
    final otpCode = phoneOtpController.text.trim();
    if (otpCode.length != 6) {
      THelperFunctions.showErrorSnackBar(
          'Invalid OTP', 'Please enter the 6-digit code.');
      return;
    }
    if (!phoneOtpFormKey.currentState!.validate()) return;
    isLoading.value = true;

    try {
      final email = isGoogleSignup.value ? '' : emailController.text.trim();
      final result = await AuthService.instance.verifyPhoneOtp(
        formattedPhoneNumber,
        otpCode,
        'driver',
        email,
      );
      if (result.success) {
        THelperFunctions.showSuccessSnackBar(
            'Phone Verified!', result.message ?? '');
        _verifiedPhoneNumber = formattedPhoneNumber;
        // Silently save phone to backend so resume works if they drop off
        AuthService.instance.saveDriverPhone(formattedPhoneNumber);
        _goToDetails();
      } else {
        THelperFunctions.showErrorSnackBar(
            'Error', result.error ?? 'Invalid OTP.');
      }
    } finally {
      isLoading.value = false;
    }
  }

  void _goToDetails() {
    otpFieldVisible.value = false;
    currentStep.value = DriverSignupStep.details;
    pageController.animateToPage(
      DriverSignupStep.details.index,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    );
  }

  // ────────────────────────────────────────────────────────────────────────
  // FINAL REGISTRATION — Step 3
  // ────────────────────────────────────────────────────────────────────────

  Future<void> registerDriverDetails() async {
    if (!detailsFormKey.currentState!.validate()) return;

    // Password required only for email signup
    if (!isGoogleSignup.value && passwordController.text.trim().isEmpty) {
      THelperFunctions.showErrorSnackBar('Error', 'Password is required.');
      return;
    }

    if (!privacyPolicy.value) {
      THelperFunctions.showSnackBar(
          'Please accept the Terms & Conditions to continue.');
      return;
    }

    isLoading.value = true;
    try {
      final firstName = _formatName(firstNameController.text);
      final lastName = _formatName(lastNameController.text);
      final email = emailController.text.trim().toLowerCase();
      final finalPhone = _verifiedPhoneNumber ?? formattedPhoneNumber;
      final int vehicleYear =
          int.tryParse(vehicleYearController.text.trim()) ?? 2020;

      final request = DriverRegistrationRequest(
        email: email,
        FirstName: firstName,
        LastName: lastName,
        password: isGoogleSignup.value ? null : passwordController.text.trim(),
        phoneNumber: finalPhone,
        // KYC-deferred fields — sent as empty/null
        DateOfBirth: '',
        Gender: '',
        licenseNumber: '',
        drivingLicense: DrivingLicense(issueDate: '', expiryDate: ''),
        currentAddress: Address(
          address: '',
          state: '',
          city: '',
          country: 'Nigeria',
          postalCode: '100001',
        ),
        permanentAddress: Address(
          address: '',
          state: '',
          city: '',
          country: 'Nigeria',
          postalCode: '100001',
        ),
        emergencyContactNumber: '',
        bankDetails: BankDetails(
          bankAccountNumber: '',
          bankName: '',
          bankAccountName: '',
        ),
        vehicleDetails: VehicleDetails(
          make: vehicleMakeController.text.trim(),
          model: vehicleModelController.text.trim(),
          year: vehicleYear,
          licensePlate: vehiclePlateController.text.trim(),
        ),
        seat: int.tryParse(vehicleSeatController.text.trim()) ?? 4,
        driverType: selectedDriverType.value,
        googleId: isGoogleSignup.value ? _googleIdToken : null,
      );

      final result = await AuthService.instance.registerDriver(request);

      if (result.success) {
        // Tokens already stored by AuthService.registerDriver — driver is logged in!
        THelperFunctions.showSuccessSnackBar(
          'Welcome to SarriRide! 🎉',
          result.message ?? 'Your account is pending admin verification.',
        );
        Get.offAll(() => const DriverDashboardScreen());
      } else {
        THelperFunctions.showErrorSnackBar(
            'Registration Failed', result.error ?? 'Please try again.');
      }
    } catch (e) {
      THelperFunctions.showErrorSnackBar(
          'Error', 'An unexpected error occurred: ${e.toString()}');
    } finally {
      isLoading.value = false;
    }
  }
}
