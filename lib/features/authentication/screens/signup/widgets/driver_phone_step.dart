import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:sarri_ride/features/authentication/controllers/driver_signup_controller.dart';
import 'package:sarri_ride/utils/constants/sizes.dart';
import 'package:sarri_ride/utils/constants/text_strings.dart';
import 'package:sarri_ride/utils/validators/validation.dart';

class DriverPhoneStep extends StatelessWidget {
  const DriverPhoneStep({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<DriverSignupController>();
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
          "Next, verify your phone number",
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: TSizes.spaceBtwItems),
        Text(
          "We'll send an OTP to this number. This number will be linked to your driver account.",
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(height: TSizes.spaceBtwSections * 2),
        Form(
          key: controller.phoneFormKey,
          child: TextFormField(
            controller: controller.phoneNumberController,
            validator: TValidator.validatePhoneNumber,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              labelText: TTexts.phoneNo,
              prefixIcon: Icon(Iconsax.call),
            ),
          ),
        ),
        const Spacer(),
        SizedBox(
          width: double.infinity,
          child: Obx(
            () => ElevatedButton(
              onPressed: controller.isLoading.value
                  ? null
                  : () => controller.sendPhoneVerificationOtp(),
              child: controller.isLoading.value
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Send OTP'),
            ),
          ),
        ),
        const SizedBox(height: TSizes.spaceBtwItems),
      ],
    );
  }
}
