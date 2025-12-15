import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:sarri_ride/common/styles/spacing_styles.dart';
import 'package:sarri_ride/common/widgets/loading_button.dart';
import 'package:sarri_ride/features/authentication/controllers/phone_verification_controller.dart';
import 'package:sarri_ride/utils/constants/sizes.dart';
import 'package:sarri_ride/utils/validators/validation.dart';
import 'package:sarri_ride/utils/helpers/helper_functions.dart';

class VerifyPhoneNumberScreen extends StatelessWidget {
  const VerifyPhoneNumberScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Find the existing controller
    final controller = Get.find<PhoneVerificationController>();

    return Scaffold(
      appBar: AppBar(
        // Allow user to go back and re-enter number
        leading: IconButton(
          onPressed: () => Get.back(),
          icon: const Icon(Iconsax.arrow_left_2),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: TSSpacingStyle.paddingWithAppBarHeight,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: TSizes.spaceBtwSections * 2),

              // Title
              Text(
                'Verify Phone Number',
                style: Theme.of(context).textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: TSizes.spaceBtwItems),
              Text(
                'Enter the 6-digit code sent to ${controller.formattedPhoneNumber}',
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: TSizes.spaceBtwSections * 2),

              // OTP Input Field
              Form(
                key: controller.otpFormKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: controller.otpController,
                      validator: (value) =>
                          TValidator.validateEmptyText('OTP', value),
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      maxLength: 6,
                      style: Theme.of(
                        context,
                      ).textTheme.headlineMedium?.copyWith(letterSpacing: 10),
                      decoration: const InputDecoration(
                        labelText: 'OTP',
                        counterText: "", // Hides the counter
                      ),
                    ),
                    const SizedBox(height: TSizes.spaceBtwSections),

                    // Verify Button
                    SizedBox(
                      width: double.infinity,
                      child: Obx(
                        () => LoadingElevatedButton(
                          text: 'Verify',
                          isLoading: controller.isLoading.value,
                          onPressed: () => controller.verifyOtp(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: TSizes.spaceBtwItems),

              // Resend OTP
              TextButton(
                onPressed: controller.isLoading.value
                    ? null
                    : () => controller.resendOtp(),
                child: const Text('Resend OTP'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
