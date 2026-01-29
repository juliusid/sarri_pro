import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sarri_ride/features/authentication/controllers/driver_signup_controller.dart';
import 'package:sarri_ride/utils/constants/sizes.dart';

// Import all step widgets
import 'widgets/driver_email_step.dart';
import 'widgets/driver_otp_step.dart';
import 'widgets/driver_phone_step.dart'; // <--- Added
import 'widgets/driver_phone_otp_step.dart'; // <--- Added
import 'widgets/driver_details_step.dart';

class DriverSignupScreen extends StatelessWidget {
  const DriverSignupScreen({super.key});

  @override // Good practice to add override
  Widget build(BuildContext context) {
    // Ensure controller is initialized
    final controller = Get.put(DriverSignupController());

    return Scaffold(
      body: PageView(
        controller: controller.pageController,
        physics: const NeverScrollableScrollPhysics(), // Disable swiping
        children: const [
          // Step 1: Email (Index 0)
          Padding(
            padding: EdgeInsets.all(TSizes.defaultSpace),
            child: DriverEmailStep(),
          ),

          // Step 2: Email OTP (Index 1)
          Padding(
            padding: EdgeInsets.all(TSizes.defaultSpace),
            child: DriverOtpStep(),
          ),

          // Step 3: Phone (Index 2)  <-- THIS WAS MISSING
          Padding(
            padding: EdgeInsets.all(TSizes.defaultSpace),
            child: DriverPhoneStep(),
          ),

          // Step 4: Phone OTP (Index 3) <-- THIS WAS MISSING
          Padding(
            padding: EdgeInsets.all(TSizes.defaultSpace),
            child: DriverPhoneOtpStep(),
          ),

          // Step 5: Details (Index 4)
          DriverDetailsStep(),
        ],
      ),
    );
  }
}
