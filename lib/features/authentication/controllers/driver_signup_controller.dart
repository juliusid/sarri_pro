// lib/features/authentication/controllers/driver_signup_controller.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sarri_ride/features/authentication/models/driver_auth_model.dart';
import 'package:sarri_ride/features/authentication/screens/login/login_screen_getx.dart';
import 'package:sarri_ride/features/authentication/services/auth_service.dart';
import 'package:sarri_ride/utils/formatters/formatter.dart';
import 'package:sarri_ride/utils/helpers/helper_functions.dart';

enum DriverSignupStep { email, otp, details }

class DriverSignupController extends GetxController {
  static DriverSignupController get instance => Get.find();

  final pageController = PageController();
  final Rx<DriverSignupStep> currentStep = DriverSignupStep.email.obs;
  final RxBool isLoading = false.obs;

  // Step 1: Email
  final emailController = TextEditingController();
  final emailFormKey = GlobalKey<FormState>();

  // Step 2: OTP
  final otpController = TextEditingController();
  final otpFormKey = GlobalKey<FormState>();

  // Step 3: Details Form
  final detailsFormKey = GlobalKey<FormState>();
  // --- Personal Info
  final firstNameController = TextEditingController();
  final lastNameController = TextEditingController();
  final passwordController = TextEditingController();
  final phoneNumberController = TextEditingController();
  final dobController = TextEditingController();
  final genderController = TextEditingController(); // Or use a RxString
  // --- License Info
  final licenseNumberController = TextEditingController();
  final licenseIssueDateController = TextEditingController();
  final licenseExpiryDateController = TextEditingController();
  // --- Address Info
  final currentAddressController = TextEditingController();
  final currentStateController = TextEditingController();
  final currentCityController = TextEditingController();
  final permanentAddressController = TextEditingController();
  final permanentStateController = TextEditingController();
  final permanentCityController = TextEditingController();
  // --- Emergency Contact
  final emergencyContactController = TextEditingController();
  // --- Bank Details
  final bankAccountNameController = TextEditingController();
  final bankAccountNumberController = TextEditingController();
  final bankNameController = TextEditingController();
  // --- Vehicle Details
  final vehicleMakeController = TextEditingController();
  final vehicleModelController = TextEditingController();
  final vehicleYearController = TextEditingController();
  final vehiclePlateController = TextEditingController();
  final vehicleSeatController = TextEditingController();

  @override
  void onClose() {
    pageController.dispose();
    emailController.dispose();
    otpController.dispose();
    // Dispose all other controllers...
    firstNameController.dispose();
    lastNameController.dispose();
    passwordController.dispose();
    phoneNumberController.dispose();
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
      Get.back(); // Go back from the first step
    }
  }

  // --- API Calls ---

  // Step 1: Verify Email
  Future<void> sendVerificationEmail() async {
    if (!emailFormKey.currentState!.validate()) return;
    isLoading.value = true;
    try {
      final result = await AuthService.instance.sendRegistrationOtp(
        emailController.text.trim(),
        'driver', // Specify the role
      );
      if (result.success) {
        // --- CORRECTED ---
        THelperFunctions.showSuccessSnackBar(
          'Success',
          result.message ?? 'OTP sent successfully!',
        );
        nextStep();
      } else {
        // --- CORRECTED ---
        THelperFunctions.showErrorSnackBar(
          'Error',
          result.error ?? 'Failed to send OTP.',
        );
      }
    } finally {
      isLoading.value = false;
    }
  }

  // Step 2: Verify OTP
  Future<void> verifyOtp() async {
    if (!otpFormKey.currentState!.validate()) return;
    isLoading.value = true;
    try {
      final result = await AuthService.instance.verifyRegistrationOtp(
        emailController.text.trim(),
        otpController.text.trim(),
        'driver', // Specify the role
      );
      if (result.success) {
        // --- CORRECTED ---
        THelperFunctions.showSuccessSnackBar(
          'Success',
          result.message ?? 'Email verified!',
        );
        nextStep();
      } else {
        // --- CORRECTED ---
        THelperFunctions.showErrorSnackBar(
          'Error',
          result.error ?? 'Invalid OTP.',
        );
      }
    } finally {
      isLoading.value = false;
    }
  }

  // Step 3: Register Driver Details
  Future<void> registerDriverDetails() async {
    if (!detailsFormKey.currentState!.validate()) return;
    isLoading.value = true;
    try {
      // --- FIX: Ensure required permanentAddress fields are included ---
      String finalPermanentState = permanentStateController.text.trim().isEmpty
          ? currentStateController.text.trim()
          : permanentStateController.text.trim();

      String finalPermanentCity = permanentCityController.text.trim().isEmpty
          ? currentCityController.text.trim()
          : permanentCityController.text.trim();
      // --- END FIX ---
      final formattedPhoneNumber = TFormatter.formatNigeriaPhoneNumber(
        phoneNumberController.text.trim(),
      );

      final formattedemergencyContactNumber =
          TFormatter.formatNigeriaPhoneNumber(
            emergencyContactController.text.trim(),
          );

      // Create the request object from controllers
      final request = DriverRegistrationRequest(
        email: emailController.text.trim(),
        FirstName: firstNameController.text.trim(),
        LastName: lastNameController.text.trim(),
        password: passwordController.text.trim(),
        phoneNumber: formattedPhoneNumber,
        DateOfBirth: dobController.text.trim(), // Ensure format is YYYY-MM-DD
        Gender: genderController.text.trim().toLowerCase(),
        licenseNumber: licenseNumberController.text.trim(),
        drivingLicense: DrivingLicense(
          issueDate: licenseIssueDateController.text.trim(), // YYYY-MM-DD
          expiryDate: licenseExpiryDateController.text.trim(), // YYYY-MM-DD
        ),
        currentAddress: Address(
          address: currentAddressController.text.trim(),
          state: currentStateController.text.trim(),
          city: currentCityController.text.trim(),
          country: 'Nigeria',
          postalCode: '100001', // Placeholder
        ),
        permanentAddress: Address(
          address: permanentAddressController.text.trim(),
          state: finalPermanentState,
          city: finalPermanentCity,
          country: 'Nigeria',
          postalCode: '100001', // Placeholder
        ),
        emergencyContactNumber: formattedemergencyContactNumber,
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

      print('Sending Driver Registration Request:');
      print(json.encode(request.toJson()));

      final result = await AuthService.instance.registerDriver(request);

      if (result.success) {
        // --- CORRECTED ---
        THelperFunctions.showSuccessSnackBar(
          'Success',
          result.message ?? 'Registration successful! Please login.',
        );
        // Navigate to login screen after successful registration
        Get.offAll(() => const LoginScreenGetX());
      } else {
        // --- CORRECTED ---
        THelperFunctions.showErrorSnackBar(
          'Registration Failed',
          result.error ?? 'Registration failed.',
        );
      }
    } catch (e) {
      // --- CORRECTED ---
      THelperFunctions.showErrorSnackBar("An error occurred", e.toString());
    } finally {
      isLoading.value = false;
    }
  }
}
