import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sarri_ride/features/authentication/screens/login/login_screen_getx.dart';
import 'package:sarri_ride/features/authentication/services/auth_service.dart';
import 'package:sarri_ride/utils/helpers/helper_functions.dart';
import '../screens/forgot_password/reset_password_screen.dart';

class ForgotPasswordController extends GetxController {
  static ForgotPasswordController get instance => Get.find();

  final emailController = TextEditingController();
  final resetCodeController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  final emailFormKey = GlobalKey<FormState>();
  final passwordFormKey = GlobalKey<FormState>();
  final isLoading = false.obs;

  String _resetTokenId = '';

  @override
  void onClose() {
    emailController.dispose();
    resetCodeController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.onClose();
  }

  Future<void> sendPasswordResetEmail() async {
    if (!emailFormKey.currentState!.validate()) return;
    isLoading.value = true;
    try {
      final response = await AuthService.instance.forgotPassword(
        emailController.text.trim(),
        'client',
      );
      if (response.status == 'success' && response.resetTokenId != null) {
        _resetTokenId = response.resetTokenId!;
        THelperFunctions.showSnackBar(response.message);
        Get.to(() => const ResetPasswordScreen());
      } else {
        THelperFunctions.showSnackBar(response.message);
      }
    } catch (e) {
      THelperFunctions.showSnackBar(e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> resetPassword() async {
    if (!passwordFormKey.currentState!.validate()) return;
    if (passwordController.text != confirmPasswordController.text) {
      THelperFunctions.showSnackBar("Passwords do not match.");
      return;
    }
    isLoading.value = true;
    try {
      final result = await AuthService.instance.resetPassword(
        resetTokenId: _resetTokenId,
        resetCode: resetCodeController.text.trim(),
        password: passwordController.text.trim(),
        role: 'client',
      );

      if (result.success) {
        THelperFunctions.showSnackBar(
          result.message ?? 'Password has been reset.',
        );
        // THIS IS THE CRITICAL LINE
        Get.offAll(() => const LoginScreenGetX());
      } else {
        THelperFunctions.showSnackBar(result.error ?? 'An error occurred.');
      }
    } catch (e) {
      THelperFunctions.showSnackBar(e.toString());
    } finally {
      isLoading.value = false;
    }
  }
}
