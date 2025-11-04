import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sarri_ride/features/authentication/controllers/driver_signup_controller.dart';
import 'package:sarri_ride/utils/constants/sizes.dart';

// Import the step widgets
import 'widgets/driver_email_step.dart';
import 'widgets/driver_otp_step.dart';
import 'widgets/driver_details_step.dart';

class DriverSignupScreen extends StatelessWidget {
  const DriverSignupScreen({super.key});

  Widget build(BuildContext context) {
    final controller = Get.put(DriverSignupController());

    return Scaffold(
      body: PageView(
        controller: controller.pageController,
        physics: const NeverScrollableScrollPhysics(), // Disable swiping
        children: const [
          // Each child is a step in the registration process
          Padding(
            padding: EdgeInsets.all(TSizes.defaultSpace),
            child: DriverEmailStep(),
          ),
          Padding(
            padding: EdgeInsets.all(TSizes.defaultSpace),
            child: DriverOtpStep(),
          ),
          DriverDetailsStep(), // This one has its own scaffold and appbar
        ],
      ),
    );
  }
}
