// lib/features/authentication/screens/signup/widgets/driver_phone_otp_step.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:sarri_ride/features/authentication/controllers/driver_signup_controller.dart';
import 'package:sarri_ride/utils/constants/sizes.dart';
import 'package:sarri_ride/utils/validators/validation.dart';

class DriverPhoneOtpStep extends StatelessWidget {
  const DriverPhoneOtpStep({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<DriverSignupController>();
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.only(bottom: TSizes.defaultSpace),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: AppBar().preferredSize.height),
            IconButton(
              icon: const Icon(Iconsax.arrow_left_2),
              onPressed: () => controller.previousStep(),
            ),
            const SizedBox(height: TSizes.spaceBtwSections),
            Text(
              "Verify your Phone Number",
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: TSizes.spaceBtwItems),

            Text(
              "We sent an OTP to ${controller.formattedPhoneNumber}. Please enter it below.",
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: TSizes.spaceBtwSections * 2),
            Form(
              key: controller.phoneOtpFormKey,
              child: TextFormField(
                controller: controller.phoneOtpController,
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
                validator: (value) =>
                    TValidator.validateEmptyText('OTP', value),
              ),
            ),

            const SizedBox(height: TSizes.spaceBtwItems),

            // --- NEW: RESEND PHONE OTP UI ---
            Center(
              child: Obx(
                () => controller.resendTimer.value > 0
                    ? Text(
                        "Resend Code in ${controller.resendTimer.value}s",
                        style: Theme.of(
                          context,
                        ).textTheme.bodyMedium?.copyWith(color: Colors.grey),
                      )
                    : TextButton(
                        onPressed: controller.isLoading.value
                            ? null
                            : () => controller.resendPhoneOtp(),
                        child: const Text("Resend Code"),
                      ),
              ),
            ),

            const SizedBox(height: TSizes.spaceBtwSections),

            SizedBox(
              width: double.infinity,
              child: Obx(
                () => ElevatedButton(
                  onPressed: controller.isLoading.value
                      ? null
                      : () => controller.verifyPhoneOtp(),
                  child: controller.isLoading.value
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text('Verify & Proceed'),
                ),
              ),
            ),
            const SizedBox(height: TSizes.spaceBtwItems),
          ],
        ),
      ),
    );
  }
}
