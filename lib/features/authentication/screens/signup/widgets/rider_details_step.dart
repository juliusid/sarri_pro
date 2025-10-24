// lib/features/authentication/screens/signup/widgets/rider_details_step.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:sarri_ride/features/authentication/controllers/rider_signup_controller.dart';
import 'package:sarri_ride/utils/constants/sizes.dart';
import 'package:sarri_ride/utils/constants/text_strings.dart';
import 'package:sarri_ride/utils/validators/validation.dart';

class RiderDetailsStep extends StatelessWidget {
  const RiderDetailsStep({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<RiderSignupController>();
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Iconsax.arrow_left_2),
          onPressed: () => controller.previousStep(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(TSizes.defaultSpace),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              TTexts.signupTitle,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: TSizes.spaceBtwSections),
            Form(
              key: controller.detailsFormKey,
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: controller.firstNameController,
                          validator: (value) =>
                              TValidator.validateEmptyText('First name', value),
                          decoration: const InputDecoration(
                            labelText: TTexts.firstName,
                            prefixIcon: Icon(Iconsax.user),
                          ),
                        ),
                      ),
                      const SizedBox(width: TSizes.spaceBtwInputFields),
                      Expanded(
                        child: TextFormField(
                          controller: controller.lastNameController,
                          validator: (value) =>
                              TValidator.validateEmptyText('Last name', value),
                          decoration: const InputDecoration(
                            labelText: TTexts.lastName,
                            prefixIcon: Icon(Iconsax.user),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: TSizes.spaceBtwInputFields),
                  Obx(
                    () => TextFormField(
                      controller: controller.passwordController,
                      validator: TValidator.validatePassword,
                      obscureText: controller.obscurePassword.value,
                      decoration: InputDecoration(
                        labelText: TTexts.password,
                        prefixIcon: const Icon(Iconsax.password_check),
                        suffixIcon: IconButton(
                          onPressed: controller.togglePasswordVisibility,
                          icon: Icon(
                            controller.obscurePassword.value
                                ? Iconsax.eye_slash
                                : Iconsax.eye,
                          ),
                        ),
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
                            : () => controller.registerRider(),
                        child: controller.isLoading.value
                            ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                            : const Text(TTexts.createAccount),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
