import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sarri_ride/features/authentication/services/auth_service.dart'; // Import AuthService
import 'package:sarri_ride/features/ride/controllers/drawer_controller.dart'; // Import DrawerController
import 'package:sarri_ride/features/ride/widgets/map_screen_getx.dart';
import 'package:sarri_ride/utils/formatters/formatter.dart'; // Import Formatter
import 'package:sarri_ride/utils/helpers/helper_functions.dart';
import 'package:sarri_ride/utils/validators/validation.dart';
import '../screens/phone_verification/verify_phone_number_screen.dart';

class PhoneVerificationController extends GetxController {
  static PhoneVerificationController get instance => Get.find();

  final phoneNumberController = TextEditingController();
  final otpController = TextEditingController();
  final formKey = GlobalKey<FormState>();
  final otpFormKey = GlobalKey<FormState>();
  final isLoading = false.obs;

  // This controller is only used for CLIENTS post-login
  final String _userType = "client";

  String get formattedPhoneNumber {
    // Format the number to +234...
    return TFormatter.formatNigeriaPhoneNumber(
      phoneNumberController.text.trim(),
    );
  }

  @override
  void onClose() {
    phoneNumberController.dispose();
    otpController.dispose();
    super.onClose();
  }

  /// Send OTP to the phone number
  Future<void> sendOtp() async {
    if (!formKey.currentState!.validate()) return;

    isLoading.value = true;
    try {
      final result = await AuthService.instance.sendPhoneOtp(
        formattedPhoneNumber,
        _userType,
      );

      if (result.success) {
        THelperFunctions.showSuccessSnackBar(
          'Success',
          result.message ?? 'OTP sent to $formattedPhoneNumber',
        );
        Get.to(() => const VerifyPhoneNumberScreen());
      } else {
        THelperFunctions.showErrorSnackBar(
          'Error',
          result.error ?? 'Failed to send OTP',
        );
      }
    } catch (e) {
      THelperFunctions.showErrorSnackBar('Error', e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  /// Resend the OTP
  Future<void> resendOtp() async {
    isLoading.value = true;
    try {
      final result = await AuthService.instance.resendPhoneOtp(
        formattedPhoneNumber,
        _userType,
      );

      if (result.success) {
        THelperFunctions.showSuccessSnackBar(
          'Success',
          result.message ?? 'OTP resent to $formattedPhoneNumber',
        );
      } else {
        THelperFunctions.showErrorSnackBar(
          'Error',
          result.error ?? 'Failed to resend OTP',
        );
      }
    } catch (e) {
      THelperFunctions.showErrorSnackBar('Error', e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  /// Verify the OTP
  Future<void> verifyOtp() async {
    if (!otpFormKey.currentState!.validate()) return;

    isLoading.value = true;
    try {
      final result = await AuthService.instance.verifyPhoneOtp(
        formattedPhoneNumber,
        otpController.text.trim(),
        _userType,
      );

      if (result.success) {
        THelperFunctions.showSuccessSnackBar(
          'Success',
          result.message ?? 'Phone number verified!',
        );

        // Refresh the main profile data to get the new 'phoneNumberVerified' status
        await Get.find<MapDrawerController>().refreshUserData();

        Get.offAll(() => const MapScreenGetX());
      } else {
        THelperFunctions.showErrorSnackBar(
          'Error',
          result.error ?? 'Invalid OTP',
        );
      }
    } catch (e) {
      THelperFunctions.showErrorSnackBar('Error', e.toString());
    } finally {
      isLoading.value = false;
    }
  }
}
