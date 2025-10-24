import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:sarri_ride/features/authentication/controllers/driver_signup_controller.dart';
import 'package:sarri_ride/utils/constants/sizes.dart';
import 'package:sarri_ride/utils/constants/text_strings.dart';
import 'package:sarri_ride/utils/validators/validation.dart';

class DriverEmailStep extends StatelessWidget {
  const DriverEmailStep({super.key});

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
        Text("Let's start with your email", style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: TSizes.spaceBtwItems),
        Text("We'll send a verification code to make sure it's you.", style: Theme.of(context).textTheme.bodyLarge),
        const SizedBox(height: TSizes.spaceBtwSections * 2),
        Form(
          key: controller.emailFormKey,
          child: TextFormField(
            controller: controller.emailController,
            validator: TValidator.validateEmail,
            decoration: const InputDecoration(labelText: TTexts.email, prefixIcon: Icon(Iconsax.direct)),
          ),
        ),
        const Spacer(),
        SizedBox(
          width: double.infinity,
          child: Obx(
            () => ElevatedButton(
              onPressed: controller.isLoading.value ? null : () => controller.sendVerificationEmail(),
              child: controller.isLoading.value
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Continue'),
            ),
          ),
        ),
        const SizedBox(height: TSizes.spaceBtwItems),
      ],
    );
  }
}