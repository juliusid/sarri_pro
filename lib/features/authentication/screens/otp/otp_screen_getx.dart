// File Path: features/authentication/screens/otp/otp_screen_getx.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sarri_ride/common/styles/spacing_styles.dart';
import 'package:sarri_ride/features/authentication/controllers/otp_controller.dart';
import 'package:sarri_ride/utils/constants/colors.dart';
import 'package:sarri_ride/utils/constants/sizes.dart';
import 'package:sarri_ride/utils/helpers/helper_functions.dart';
import 'package:iconsax/iconsax.dart';

class OTPScreen extends StatelessWidget {
  const OTPScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(OTPController());
    final dark = THelperFunctions.isDarkMode(context);

    return Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: TSSpacingStyle.paddingWithAppBarHeight,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Back Button
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  onPressed: () => Get.back(),
                  icon: Icon(
                    Iconsax.arrow_left_2,
                    color: dark ? TColors.light : TColors.dark,
                    size: TSizes.iconLg,
                  ),
                ),
              ),
              const SizedBox(height: TSizes.spaceBtwSections * 2),

              // Title
              Text(
                'Verify your Email',
                style: Theme.of(context).textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: TSizes.spaceBtwItems),
              Text(
                'We have sent an OTP to ${controller.email}. Please enter it below to continue.',
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: TSizes.spaceBtwSections * 2),

              // OTP Input Field
              Form(
                child: Column(
                  children: [
                    TextFormField(
                      controller: controller.otpController,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      maxLength: 6,
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(letterSpacing: 10),
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
                        () => ElevatedButton(
                          onPressed: controller.isLoading.value ? null : () => controller.verifyOTP(),
                          child: controller.isLoading.value
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : const Text('Verify'),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: TSizes.spaceBtwItems),
              
              // Resend OTP
              TextButton(
                onPressed: () {
                  // TODO: Implement resend OTP logic in the controller
                  THelperFunctions.showSnackBar('OTP Resent (Feature not implemented)');
                },
                child: const Text('Resend OTP'),
              )
            ],
          ),
        ),
      ),
    );
  }
}