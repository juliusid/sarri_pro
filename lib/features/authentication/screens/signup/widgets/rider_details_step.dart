// lib/features/authentication/screens/signup/widgets/rider_details_step.dart

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:sarri_ride/features/authentication/controllers/rider_signup_controller.dart';
import 'package:sarri_ride/features/settings/screens/terms_conditions_screen.dart';
import 'package:sarri_ride/utils/constants/sizes.dart';
import 'package:sarri_ride/utils/constants/text_strings.dart';
import 'package:sarri_ride/utils/helpers/helper_functions.dart';
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
                  // ========================================================
                  // START NEW SECTION: Terms & Conditions Checkbox
                  // ========================================================
                  const SizedBox(height: TSizes.spaceBtwSections),
                  Row(
                    children: [
                      Obx(
                        () => SizedBox(
                          width: 24,
                          height: 24,
                          child: Checkbox(
                            value: controller.privacyPolicy.value,
                            onChanged: (value) =>
                                controller.privacyPolicy.value =
                                    !controller.privacyPolicy.value,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(
                                text: 'I agree to the ',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                              TextSpan(
                                text: 'Terms of Use',
                                style: Theme.of(context).textTheme.bodySmall!
                                    .apply(
                                      color: Colors.blue,
                                      decoration: TextDecoration.underline,
                                    ),
                                recognizer: TapGestureRecognizer()
                                  ..onTap = () => Get.to(
                                    () => const TermsConditionsScreen(),
                                  ),
                              ),
                              TextSpan(
                                text: ' and ',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                              TextSpan(
                                text: 'Privacy Policy',
                                style: Theme.of(context).textTheme.bodySmall!
                                    .apply(
                                      color: Colors.blue,
                                      decoration: TextDecoration.underline,
                                    ),
                                recognizer: TapGestureRecognizer()
                                  ..onTap = () => Get.to(
                                    () => const TermsConditionsScreen(),
                                  ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),

                  // ========================================================
                  const SizedBox(height: TSizes.spaceBtwSections),
                  SizedBox(
                    width: double.infinity,
                    child: Obx(
                      () => ElevatedButton(
                        onPressed: controller.isLoading.value
                            ? null
                            : () {
                                // 1. ADD CHECK HERE
                                if (!controller.privacyPolicy.value) {
                                  THelperFunctions.showSnackBar(
                                    'Please accept the Terms & Conditions',
                                  );
                                  return;
                                }
                                controller.registerRider();
                              },
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
