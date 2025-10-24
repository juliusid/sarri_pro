// lib/features/authentication/screens/signup/widgets/rider_otp_step.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:sarri_ride/features/authentication/controllers/rider_signup_controller.dart';
import 'package:sarri_ride/utils/constants/sizes.dart';
import 'package:sarri_ride/utils/validators/validation.dart';

class RiderOtpStep extends StatelessWidget {
  const RiderOtpStep({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<RiderSignupController>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: AppBar().preferredSize.height),
        IconButton(
          icon: const Icon(Iconsax.arrow_left_2),
          onPressed: () => controller.previousStep(),
        ),
        const SizedBox(height: TSizes.spaceBtwSections),
        Text(
          "Verify your Email",
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: TSizes.spaceBtwItems),
        Text(
          "We sent an OTP to ${controller.emailController.text}. Please enter it below.",
          style: Theme.of(context).textTheme.bodyLarge,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: TSizes.spaceBtwSections * 2),
        Form(
          key: controller.otpFormKey,
          child: TextFormField(
            controller: controller.otpController,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            maxLength: 6,
            style: Theme.of(
              context,
            ).textTheme.headlineMedium?.copyWith(letterSpacing: 20),
            decoration: const InputDecoration(
              labelText: 'OTP',
              counterText: "",
            ),
            validator: (value) => TValidator.validateEmptyText('OTP', value),
          ),
        ),
        const Spacer(),
        SizedBox(
          width: double.infinity,
          child: Obx(
            () => ElevatedButton(
              onPressed: controller.isLoading.value
                  ? null
                  : () => controller.verifyOtp(),
              child: controller.isLoading.value
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Verify & Proceed'),
            ),
          ),
        ),
        const SizedBox(height: TSizes.spaceBtwItems),
      ],
    );
  }
}
