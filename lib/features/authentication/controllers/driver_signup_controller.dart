// lib/features/authentication/controllers/driver_signup_controller.dart

import 'dart:async'; // Required for Timer
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sarri_ride/features/authentication/models/driver_auth_model.dart';
import 'package:sarri_ride/features/authentication/screens/login/login_screen_getx.dart';
import 'package:sarri_ride/features/authentication/services/auth_service.dart';
import 'package:sarri_ride/utils/formatters/formatter.dart';
import 'package:sarri_ride/utils/helpers/helper_functions.dart';

enum DriverSignupStep { email, otp, phone, phoneOtp, details }

class DriverSignupController extends GetxController {
  static DriverSignupController get instance => Get.find();

  final pageController = PageController();
  final Rx<DriverSignupStep> currentStep = DriverSignupStep.email.obs;
  final RxBool isLoading = false.obs;

  final RxBool privacyPolicy = false.obs;

  // --- NEW: TIMER VARIABLES ---
  Timer? _timer;
  final RxInt resendTimer = 60.obs;
  final RxBool isResendEnabled = false.obs;

  // --- Variable to store verified number ---
  String? _verifiedPhoneNumber;

  // Step 1: Email
  final emailController = TextEditingController();
  final emailFormKey = GlobalKey<FormState>();

  // Step 2: OTP
  final otpController = TextEditingController();
  final otpFormKey = GlobalKey<FormState>();

  // Step 3: Phone
  final phoneNumberController = TextEditingController();
  final phoneFormKey = GlobalKey<FormState>();

  // Step 4: Phone OTP
  final phoneOtpController = TextEditingController();
  final phoneOtpFormKey = GlobalKey<FormState>();

  // Step 5: Details
  final detailsFormKey = GlobalKey<FormState>();

  // --- Personal Info Controllers ---
  final firstNameController = TextEditingController();
  final lastNameController = TextEditingController();
  final passwordController = TextEditingController();
  final dobController = TextEditingController();
  final genderController = TextEditingController();
  final licenseNumberController = TextEditingController();
  final licenseIssueDateController = TextEditingController();
  final licenseExpiryDateController = TextEditingController();
  final currentAddressController = TextEditingController();
  final currentStateController = TextEditingController();
  final currentCityController = TextEditingController();
  final permanentAddressController = TextEditingController();
  final permanentStateController = TextEditingController();
  final permanentCityController = TextEditingController();
  final emergencyContactController = TextEditingController();
  final bankAccountNameController = TextEditingController();
  final bankAccountNumberController = TextEditingController();
  final bankNameController = TextEditingController();
  final vehicleMakeController = TextEditingController();
  final vehicleModelController = TextEditingController();
  final vehicleYearController = TextEditingController();
  final vehiclePlateController = TextEditingController();
  final vehicleSeatController = TextEditingController();

  @override
  void onClose() {
    _timer?.cancel(); // Cancel timer
    pageController.dispose();
    emailController.dispose();
    otpController.dispose();
    phoneNumberController.dispose();
    phoneOtpController.dispose();
    firstNameController.dispose();
    lastNameController.dispose();
    passwordController.dispose();
    dobController.dispose();
    genderController.dispose();
    licenseNumberController.dispose();
    licenseIssueDateController.dispose();
    licenseExpiryDateController.dispose();
    currentAddressController.dispose();
    currentStateController.dispose();
    currentCityController.dispose();
    permanentAddressController.dispose();
    permanentStateController.dispose();
    permanentCityController.dispose();
    emergencyContactController.dispose();
    bankAccountNameController.dispose();
    bankAccountNumberController.dispose();
    bankNameController.dispose();
    vehicleMakeController.dispose();
    vehicleModelController.dispose();
    vehicleYearController.dispose();
    vehiclePlateController.dispose();
    vehicleSeatController.dispose();
    super.onClose();
  }

  // --- NEW: TIMER LOGIC ---
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
    if (currentStep.value.index < DriverSignupStep.values.length - 1) {
      currentStep.value = DriverSignupStep.values[currentStep.value.index + 1];
      pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.ease,
      );
    }
  }

  void previousStep() {
    if (currentStep.value.index > 0) {
      currentStep.value = DriverSignupStep.values[currentStep.value.index - 1];
      pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.ease,
      );
    } else {
      Get.back();
    }
  }

  // --- HELPER: Get Clean Formatted Number ---
  String get formattedPhoneNumber {
    String formatted = TFormatter.formatNigeriaPhoneNumber(
      phoneNumberController.text.trim(),
    );
    return formatted.replaceAll(' ', '');
  }

  // --- API Calls ---

  // Updated with isResend
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
          'Success',
          result.message ?? 'OTP sent successfully!',
        );

        startResendTimer();

        if (!isResend) {
          nextStep();
        }
      } else {
        final errorMsg = result.error?.toLowerCase() ?? '';
        if (errorMsg.contains('already verified')) {
          THelperFunctions.showSuccessSnackBar(
            'Welcome Back',
            'Email verified. Resuming registration...',
          );
          currentStep.value = DriverSignupStep.phone;
          pageController.animateToPage(
            DriverSignupStep.phone.index,
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
        'driver',
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

  // Step 3: Send Phone OTP
  Future<void> sendPhoneVerificationOtp() async {
    if (!phoneFormKey.currentState!.validate()) return;
    isLoading.value = true;
    try {
      final result = await AuthService.instance.sendPhoneOtp(
        formattedPhoneNumber,
        'driver',
        emailController.text.trim(),
      );

      if (result.success) {
        THelperFunctions.showSuccessSnackBar(
          'Success',
          result.message ?? 'OTP sent to phone!',
        );
        startResendTimer(); // Start timer
        nextStep();
      } else {
        final errorMsg = result.error?.toLowerCase() ?? '';
        if (errorMsg.contains('verified phone number') ||
            errorMsg.contains('already has a verified')) {
          THelperFunctions.showSuccessSnackBar(
            'Verified',
            'Phone number already verified. Proceeding...',
          );
          _verifiedPhoneNumber = formattedPhoneNumber;
          currentStep.value = DriverSignupStep.details;
          pageController.animateToPage(
            DriverSignupStep.details.index,
            duration: const Duration(milliseconds: 300),
            curve: Curves.ease,
          );
        } else {
          THelperFunctions.showErrorSnackBar(
            'Error',
            result.error ?? 'Failed to send Phone OTP.',
          );
        }
      }
    } finally {
      isLoading.value = false;
    }
  }

  // --- NEW: Resend Phone OTP ---
  Future<void> resendPhoneOtp() async {
    isLoading.value = true;
    try {
      final result = await AuthService.instance.resendPhoneOtp(
        formattedPhoneNumber,
        'driver',
      );

      if (result.success) {
        THelperFunctions.showSuccessSnackBar(
          'Success',
          'Phone OTP resent successfully',
        );
        startResendTimer(); // Restart timer
      } else {
        THelperFunctions.showErrorSnackBar(
          'Error',
          result.error ?? 'Failed to resend OTP',
        );
      }
    } finally {
      isLoading.value = false;
    }
  }

  // Step 4: Verify Phone OTP
  Future<void> verifyPhoneOtp() async {
    String otpCode = phoneOtpController.text.trim();
    if (otpCode.length != 6) {
      THelperFunctions.showErrorSnackBar(
        'Invalid OTP',
        'Please enter a valid 6-digit OTP.',
      );
      return;
    }

    String email = emailController.text.trim();
    if (email.isEmpty) {
      THelperFunctions.showErrorSnackBar(
        'Error',
        'Email is missing. Please restart registration.',
      );
      return;
    }

    if (!phoneOtpFormKey.currentState!.validate()) return;
    isLoading.value = true;

    try {
      final result = await AuthService.instance.verifyPhoneOtp(
        formattedPhoneNumber,
        otpCode,
        'driver',
        email,
      );

      if (result.success) {
        THelperFunctions.showSuccessSnackBar(
          'Success',
          result.message ?? 'Phone verified!',
        );
        _verifiedPhoneNumber = formattedPhoneNumber;
        nextStep();
      } else {
        THelperFunctions.showErrorSnackBar(
          'Error',
          result.error ?? 'Invalid Phone OTP.',
        );
      }
    } finally {
      isLoading.value = false;
    }
  }

  // Step 5: Final Registration
  Future<void> registerDriverDetails() async {
    if (!detailsFormKey.currentState!.validate()) return;
    isLoading.value = true;
    try {
      String finalPhoneNumber = _verifiedPhoneNumber ?? formattedPhoneNumber;

      String finalPermanentState = permanentStateController.text.trim().isEmpty
          ? currentStateController.text.trim()
          : permanentStateController.text.trim();

      String finalPermanentCity = permanentCityController.text.trim().isEmpty
          ? currentCityController.text.trim()
          : permanentCityController.text.trim();

      final formattedEmergencyContact = TFormatter.formatNigeriaPhoneNumber(
        emergencyContactController.text.trim(),
      );

      final request = DriverRegistrationRequest(
        email: emailController.text.trim(),
        FirstName: firstNameController.text.trim(),
        LastName: lastNameController.text.trim(),
        password: passwordController.text.trim(),
        phoneNumber: finalPhoneNumber,
        DateOfBirth: dobController.text.trim(),
        Gender: genderController.text.trim().toLowerCase(),
        licenseNumber: licenseNumberController.text.trim(),
        drivingLicense: DrivingLicense(
          issueDate: licenseIssueDateController.text.trim(),
          expiryDate: licenseExpiryDateController.text.trim(),
        ),
        currentAddress: Address(
          address: currentAddressController.text.trim(),
          state: currentStateController.text.trim(),
          city: currentCityController.text.trim(),
          country: 'Nigeria',
          postalCode: '100001',
        ),
        permanentAddress: Address(
          address: permanentAddressController.text.trim(),
          state: finalPermanentState,
          city: finalPermanentCity,
          country: 'Nigeria',
          postalCode: '100001',
        ),
        emergencyContactNumber: formattedEmergencyContact,
        bankDetails: BankDetails(
          bankAccountNumber: bankAccountNumberController.text.trim(),
          bankName: bankNameController.text.trim(),
          bankAccountName: bankAccountNameController.text.trim(),
        ),
        vehicleDetails: VehicleDetails(
          make: vehicleMakeController.text.trim(),
          model: vehicleModelController.text.trim(),
          year: int.tryParse(vehicleYearController.text.trim()) ?? 2020,
          licensePlate: vehiclePlateController.text.trim(),
        ),
        seat: int.tryParse(vehicleSeatController.text.trim()) ?? 4,
      );

      final result = await AuthService.instance.registerDriver(request);

      if (result.success) {
        THelperFunctions.showSuccessSnackBar(
          'Success',
          result.message ?? 'Registration successful! Please login.',
        );
        Get.offAll(() => const LoginScreenGetX());
      } else {
        THelperFunctions.showErrorSnackBar(
          'Registration Failed',
          result.error ?? 'Registration failed.',
        );
      }
    } catch (e) {
      THelperFunctions.showErrorSnackBar("An error occurred", e.toString());
    } finally {
      isLoading.value = false;
    }
  }
}
