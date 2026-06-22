// lib/features/verification/controllers/driver_verification_controller.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sarri_ride/features/authentication/models/auth_model.dart';
import 'package:sarri_ride/features/authentication/services/auth_service.dart';
import 'package:sarri_ride/features/driver/screens/driver_dashboard_screen.dart';
import 'package:sarri_ride/features/driver/controllers/driver_dashboard_controller.dart';
import 'package:sarri_ride/utils/formatters/formatter.dart';
import 'package:sarri_ride/utils/helpers/helper_functions.dart';

// 3-step flow for verification: phone -> details -> documents
enum DriverVerificationStep { phone, details, documents }

class DriverVerificationController extends GetxController {
  static DriverVerificationController get instance => Get.find();

  late final PageController pageController;
  final Rx<DriverVerificationStep> currentStep = DriverVerificationStep.phone.obs;
  bool isInitializedWizard = false;

  void initWizard(DriverVerificationStep initialStep) {
    currentStep.value = initialStep;
    pageController = PageController(initialPage: initialStep.index);
    isInitializedWizard = true;

    // Pre-populate verified phone number from Dashboard Controller if available
    if (Get.isRegistered<DriverDashboardController>()) {
      final dashboardController = Get.find<DriverDashboardController>();
      final existingPhone = dashboardController.currentDriver.value?.phoneNumber;
      if (existingPhone != null && existingPhone.isNotEmpty) {
        _verifiedPhoneNumber = existingPhone;
        phoneNumberController.text = existingPhone;
      }
    }
  }
  final RxBool isLoading = false.obs;
  final RxBool privacyPolicy = false.obs;

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

  // Step 1 — phone (combined)
  final phoneNumberController = TextEditingController();
  final phoneFormKey = GlobalKey<FormState>();
  final phoneOtpController = TextEditingController();
  final phoneOtpFormKey = GlobalKey<FormState>();

  // Step 2 — details
  final detailsFormKey = GlobalKey<FormState>();
  final vehicleMakeController = TextEditingController();
  final vehicleModelController = TextEditingController();
  final vehicleYearController = TextEditingController();
  final vehiclePlateController = TextEditingController();
  final vehicleSeatController = TextEditingController();

  @override
  void onInit() {
    super.onInit();
    _checkInitialState();
  }

  void _checkInitialState() {
    ClientData? driver;
    if (Get.isRegistered<ClientData>(tag: 'currentUser')) {
      driver = Get.find<ClientData>(tag: 'currentUser');
    }
    
    // In our system, if the driver doesn't have a phone number attached to the client/driver profile,
    // we start at step 1. But wait, `ClientData` doesn't hold phoneNumber directly, it holds email and role.
    // So the DashboardController passes the `needsInitialSetup` state.
    // Let's rely on dashboard logic!
  }

  @override
  void onClose() {
    _timer?.cancel();
    pageController.dispose();
    phoneNumberController.dispose();
    phoneOtpController.dispose();
    vehicleMakeController.dispose();
    vehicleModelController.dispose();
    vehicleYearController.dispose();
    vehiclePlateController.dispose();
    vehicleSeatController.dispose();
    super.onClose();
  }

  // ── Navigation ───────────────────────────────────────────────────────────

  void nextStep() {
    if (currentStep.value.index < DriverVerificationStep.values.length - 1) {
      currentStep.value =
          DriverVerificationStep.values[currentStep.value.index + 1];
      pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.ease,
      );
    }
  }

  void previousStep() {
    if (currentStep.value.index > 0) {
      if (currentStep.value == DriverVerificationStep.phone) {
        otpFieldVisible.value = false;
        phoneOtpController.clear();
      }
      currentStep.value =
          DriverVerificationStep.values[currentStep.value.index - 1];
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

  // ── Phone formatter ──────────────────────────────────────────────────────

  String get formattedPhoneNumber {
    String formatted = TFormatter.formatNigeriaPhoneNumber(
      phoneNumberController.text.trim(),
    );
    return formatted.replaceAll(' ', '');
  }

  // ────────────────────────────────────────────────────────────────────────
  // PHONE — send OTP (combined screen: reveal OTP field inline)
  // ────────────────────────────────────────────────────────────────────────

  Future<void> sendPhoneVerificationOtp() async {
    if (!phoneFormKey.currentState!.validate()) return;

    if (!phoneFormKey.currentState!.validate()) return;

    final String phoneNumber = formattedPhoneNumber;
    isLoading.value = true;
    try {
      String userEmail = '';
      if (Get.isRegistered<ClientData>(tag: 'currentUser')) {
        userEmail = Get.find<ClientData>(tag: 'currentUser').email;
      }

      final result = await AuthService.instance.sendPhoneOtp(
        phoneNumber,
        'driver',
        userEmail,
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
      String userEmail = '';
      if (Get.isRegistered<ClientData>(tag: 'currentUser')) {
        userEmail = Get.find<ClientData>(tag: 'currentUser').email;
      }

      final result = await AuthService.instance.resendPhoneOtp(
        formattedPhoneNumber,
        'driver',
        userEmail,
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
      String userEmail = '';
      if (Get.isRegistered<ClientData>(tag: 'currentUser')) {
        userEmail = Get.find<ClientData>(tag: 'currentUser').email;
      }

      final result = await AuthService.instance.verifyPhoneOtp(
        formattedPhoneNumber,
        otpCode,
        'driver',
        userEmail,
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
    currentStep.value = DriverVerificationStep.details;
    pageController.animateToPage(
      DriverVerificationStep.details.index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.ease,
    );
  }

  // ────────────────────────────────────────────────────────────────────────
  // FINAL STEP — REGISTER DRIVER (vehicle details)
  // ────────────────────────────────────────────────────────────────────────

  Future<void> registerDriverDetails() async {
    if (!detailsFormKey.currentState!.validate()) return;
    if (_verifiedPhoneNumber == null) {
      THelperFunctions.showErrorSnackBar(
          'Error', 'Please verify your phone number first.');
      return;
    }
    if (!privacyPolicy.value) {
      THelperFunctions.showErrorSnackBar(
          'Error', 'Please accept the Privacy Policy & Terms.');
      return;
    }

    isLoading.value = true;

    try {
      final request = {
        'phoneNumber': _verifiedPhoneNumber,
        'seat': int.tryParse(vehicleSeatController.text.trim()) ?? 4,
        'vehicleDetails': {
          'make': vehicleMakeController.text.trim(),
          'model': vehicleModelController.text.trim(),
          'year': int.tryParse(vehicleYearController.text.trim()) ?? 2020,
          'licensePlate': vehiclePlateController.text.trim(),
        },
        'driverType': selectedDriverType.value,
      };

      final result = await AuthService.instance.completeDriverVerification(request);

      if (result.success) {
        THelperFunctions.showSuccessSnackBar(
          'Vehicle Saved!',
          'Now let\'s upload your verification documents.',
        );
        _goToDocuments();
      } else {
        THelperFunctions.showErrorSnackBar(
            'Verification Failed', result.error ?? 'Please try again.');
      }
    } catch (e) {
      THelperFunctions.showErrorSnackBar('Error', e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  void _goToDocuments() {
    currentStep.value = DriverVerificationStep.documents;
    pageController.animateToPage(
      DriverVerificationStep.documents.index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.ease,
    );
  }
}
