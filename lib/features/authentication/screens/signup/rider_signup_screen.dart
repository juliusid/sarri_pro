// lib/features/authentication/screens/signup/rider_signup_screen.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sarri_ride/features/authentication/controllers/rider_signup_controller.dart';
import 'package:sarri_ride/utils/constants/sizes.dart';
import 'widgets/rider_email_step.dart';
import 'widgets/rider_otp_step.dart';
import 'widgets/rider_details_step.dart';

class RiderSignupScreen extends StatelessWidget {
  const RiderSignupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Initialize the controller for the rider signup flow
    final controller = Get.put(RiderSignupController());

    return Scaffold(
      // Use PageView to manage the different steps
      body: PageView(
        controller: controller.pageController,
        physics:
            const NeverScrollableScrollPhysics(), // Disable swiping between pages
        children: const [
          // Each child is a step in the registration process
          Padding(
            padding: EdgeInsets.all(TSizes.defaultSpace),
            child: RiderEmailStep(),
          ),
          Padding(
            padding: EdgeInsets.all(TSizes.defaultSpace),
            child: RiderOtpStep(),
          ),
          RiderDetailsStep(), // This step has its own Scaffold for a better layout
        ],
      ),
    );
  }
}
