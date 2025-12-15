import 'dart:convert';
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

  // Step 1: Email
  final emailController = TextEditingController();
  final emailFormKey = GlobalKey<FormState>();

  // Step 2: OTP
  final otpController = TextEditingController();
  final otpFormKey = GlobalKey<FormState>();

  // Step 3: Phone (This stores the verified number)
  final phoneNumberController = TextEditingController();
  final phoneFormKey = GlobalKey<FormState>();

  // Step 4: Phone OTP
  final phoneOtpController = TextEditingController();
  final phoneOtpFormKey = GlobalKey<FormState>();

  // Step 5: Details Form
  final detailsFormKey = GlobalKey<FormState>();
  // --- Personal Info
  final firstNameController = TextEditingController();
  final lastNameController = TextEditingController();
  final passwordController = TextEditingController();
  // NOTE: phoneNumberController is NOT here, we reuse the one from Step 3
  final dobController = TextEditingController();
  final genderController = TextEditingController();
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

  // --- API Calls ---

  Future<void> sendVerificationEmail() async {
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
        nextStep(); // Normal flow: Go to OTP screen
      } else {
        // --- FIX START: Handle "Email already verified" ---
        if (result.error != null &&
            result.error!.toString().toLowerCase().contains(
              'email already verified',
            )) {
          THelperFunctions.showSuccessSnackBar(
            'Welcome Back',
            'Email already verified. Resuming registration...',
          );

          // Skip Email OTP (index 1) and jump to Phone Number (index 2)
          currentStep.value = DriverSignupStep.phone;
          pageController.animateToPage(
            DriverSignupStep.phone.index,
            duration: const Duration(milliseconds: 300),
            curve: Curves.ease,
          );
        } else {
          // Normal Error
          THelperFunctions.showErrorSnackBar(
            'Error',
            result.error ?? 'Failed to send OTP.',
          );
        }
        // --- FIX END ---
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
        nextStep(); // Moves to Phone Number step
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

  // --- PHONE VERIFICATION LOGIC ---

  String get formattedPhoneNumber {
    return TFormatter.formatNigeriaPhoneNumber(
      phoneNumberController.text.trim(),
    );
  }

  // Step 3: Send Phone OTP
  Future<void> sendPhoneVerificationOtp() async {
    if (!phoneFormKey.currentState!.validate()) return;
    isLoading.value = true;
    try {
      final result = await AuthService.instance.sendPhoneOtp(
        formattedPhoneNumber,
        'driver',
      );
      if (result.success) {
        THelperFunctions.showSuccessSnackBar(
          'Success',
          result.message ?? 'OTP sent to phone!',
        );
        nextStep(); // Moves to Phone OTP step
      } else {
        THelperFunctions.showErrorSnackBar(
          'Error',
          result.error ?? 'Failed to send Phone OTP.',
        );
      }
    } finally {
      isLoading.value = false;
    }
  }

  // Step 4: Verify Phone OTP
  Future<void> verifyPhoneOtp() async {
    if (!phoneOtpFormKey.currentState!.validate()) return;
    isLoading.value = true;
    try {
      final result = await AuthService.instance.verifyPhoneOtp(
        formattedPhoneNumber,
        phoneOtpController.text.trim(),
        'driver',
      );
      if (result.success) {
        THelperFunctions.showSuccessSnackBar(
          'Success',
          result.message ?? 'Phone verified!',
        );
        nextStep(); // Moves to Details Form
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
      String finalPermanentState = permanentStateController.text.trim().isEmpty
          ? currentStateController.text.trim()
          : permanentStateController.text.trim();

      String finalPermanentCity = permanentCityController.text.trim().isEmpty
          ? currentCityController.text.trim()
          : permanentCityController.text.trim();

      final formattedEmergencyContact = TFormatter.formatNigeriaPhoneNumber(
        emergencyContactController.text.trim(),
      );

      // We use 'formattedPhoneNumber' here which grabs the text from
      // the phoneNumberController used in Step 3

      final request = DriverRegistrationRequest(
        email: emailController.text.trim(),
        FirstName: firstNameController.text.trim(),
        LastName: lastNameController.text.trim(),
        password: passwordController.text.trim(),
        phoneNumber:
            formattedPhoneNumber, // <-- USING VERIFIED NUMBER FROM STEP 3
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

      print('Sending Driver Registration Request...');
      // print(json.encode(request.toJson()));

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
