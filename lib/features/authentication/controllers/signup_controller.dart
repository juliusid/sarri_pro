import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sarri_ride/features/authentication/screens/otp/otp_screen_getx.dart';
import 'package:sarri_ride/features/ride/widgets/map_screen_getx.dart';
// import 'package:sarri_ride/features/driver/screens/driver_dashboard_screen.dart';
import 'package:sarri_ride/features/authentication/services/auth_service.dart';
import 'package:sarri_ride/features/shared/models/user_model.dart';
import 'package:sarri_ride/utils/constants/enums.dart';
import 'package:sarri_ride/utils/helpers/helper_functions.dart';

class SignupController extends GetxController {
  static SignupController get instance => Get.find();
  final UserType userType;

  SignupController({required this.userType});

  // Text Controllers
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();

  // Form Key
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  // Reactive variables
  final RxBool obscurePassword = true.obs;
  final RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    // No need to initialize demo data for production
  }

  @override
  void onClose() {
    emailController.dispose();
    passwordController.dispose();
    super.onClose();
  }

  // Toggle password visibility
  void togglePasswordVisibility() {
    obscurePassword.value = !obscurePassword.value;
  }

  // Handle signup
  void handleSignup() async {
    if (formKey.currentState!.validate()) {
      isLoading.value = true;

      try {
        // Authenticate user with real API
        final authResult = await AuthService.instance.signup(
          emailController.text.trim(),
          passwordController.text.trim(),
          firstNameController.text.trim(),
          firstNameController.text.trim(),
        );

        if (authResult.success) {
          final email = emailController.text.trim();
          Get.to(() => const OTPScreen(), arguments: email); // Navigate to OTP screen
          THelperFunctions.showSnackBar(
            'Registration successful! Please check your email for the OTP.',
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

  // Handle social Signup
  void handleSocialSignup(String provider) {
    isLoading.value = true;

    // Simulate social Signup
    Future.delayed(const Duration(seconds: 2), () {
      isLoading.value = false;
      THelperFunctions.showSnackBar('$provider Signup successful!');
    });
  }
}
