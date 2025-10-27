import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sarri_ride/features/authentication/models/driver_auth_model.dart';
import 'package:sarri_ride/features/authentication/services/auth_service.dart';
import 'package:sarri_ride/features/authentication/screens/login/login_screen_getx.dart';
import 'package:sarri_ride/utils/helpers/helper_functions.dart';
// Note: You'll need to add the image_picker package to your pubspec.yaml
// flutter pub add image_picker
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:convert';

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

  // Step 4: Document Upload
  final Rx<File?> frontSideImage = Rx<File?>(null);
  final Rx<File?> backSideImage = Rx<File?>(null);
  final Rx<File?> profilePicture = Rx<File?>(null);

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
        THelperFunctions.showSnackBar(result.message ?? 'Email verified!');
        nextStep();
      } else {
        THelperFunctions.showSnackBar(result.error ?? 'Invalid OTP.');
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
      // Since the form doesn't collect permanent State/City, we default to the current values to avoid 400 error.
      String finalPermanentState = permanentStateController.text.trim().isEmpty
          ? currentStateController.text.trim()
          : permanentStateController.text.trim();

      String finalPermanentCity = permanentCityController.text.trim().isEmpty
          ? currentCityController.text.trim()
          : permanentCityController.text.trim();
      // --- END FIX ---

      // Create the request object from controllers
      final request = DriverRegistrationRequest(
        email: emailController.text.trim(),
        FirstName: firstNameController.text.trim(),
        LastName: lastNameController.text.trim(),
        password: passwordController.text.trim(),
        phoneNumber: phoneNumberController.text.trim(),
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
          state: finalPermanentState, // <-- Now uses the corrected value
          city: finalPermanentCity, // <-- Now uses the corrected value
          country: 'Nigeria',
          postalCode: '100001', // Placeholder
        ),
        emergencyContactNumber: emergencyContactController.text.trim(),
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
        seat:
            int.tryParse(vehicleSeatController.text.trim()) ??
            4, // <-- PASS 'seat' HERE
      );
      // --- PRINT THE PAYLOAD (Requested by user) ---
      print('Sending Driver Registration Request:');
      print(json.encode(request.toJson()));
      // ---------------------------------------------

      final result = await AuthService.instance.registerDriver(request);

      if (result.success) {
        THelperFunctions.showSnackBar(
          result.message ?? 'Details saved successfully!',
        );
        nextStep(); // Move to document upload
      } else {
        THelperFunctions.showSnackBar(result.error ?? 'Registration failed.');
      }
    } catch (e) {
      THelperFunctions.showSnackBar("An error occurred: $e");
    } finally {
      isLoading.value = false;
    }
  }

  // --- Image Picker ---
  Future<void> pickImage(ImageSource source, Rx<File?> imageFile) async {
    final pickedFile = await ImagePicker().pickImage(source: source);
    if (pickedFile != null) {
      imageFile.value = File(pickedFile.path);
    }
  }

  // Step 4: Upload Documents
  Future<void> uploadDocuments() async {
    if (frontSideImage.value == null || backSideImage.value == null) {
      THelperFunctions.showSnackBar(
        'Please upload front and back images of your license.',
      );
      return;
    }
    isLoading.value = true;
    try {
      // NOTE: The backend endpoint for image upload is not in your spec.
      // This is a placeholder for how you would call it.
      // You will need a method in HttpService that handles multipart/form-data.
      // For now, we simulate success and redirect.

      await Future.delayed(const Duration(seconds: 2)); // Simulating upload

      THelperFunctions.showSnackBar(
        'Documents uploaded! Your application is under review.',
      );
      Get.offAll(() => const LoginScreenGetX()); // Redirect to login
    } catch (e) {
      THelperFunctions.showSnackBar("An error occurred during upload: $e");
    } finally {
      isLoading.value = false;
    }
  }
}
