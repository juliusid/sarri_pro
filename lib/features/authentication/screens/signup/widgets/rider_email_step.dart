import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:sarri_ride/features/authentication/controllers/rider_signup_controller.dart';
import 'package:sarri_ride/features/authentication/widgets/google_button.dart'; // ADDED
import 'package:sarri_ride/features/authentication/widgets/apple_button.dart';
import 'package:sarri_ride/utils/constants/colors.dart'; // ADDED
import 'package:sarri_ride/utils/constants/sizes.dart';
import 'package:sarri_ride/utils/constants/text_strings.dart';
import 'package:sarri_ride/utils/helpers/helper_functions.dart'; // ADDED
import 'package:sarri_ride/utils/validators/validation.dart';

class RiderEmailStep extends StatelessWidget {
  const RiderEmailStep({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<RiderSignupController>();
    final dark = THelperFunctions.isDarkMode(context); // Check dark mode

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
          "Create your Rider account",
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: TSizes.spaceBtwItems),
        Text(
          "First, let's verify your email. We'll send you an OTP to confirm.",
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(height: TSizes.spaceBtwSections * 2),
        Form(
          key: controller.emailFormKey,
          child: TextFormField(
            controller: controller.emailController,
            validator: TValidator.validateEmail,
            decoration: const InputDecoration(
              labelText: TTexts.email,
              prefixIcon: Icon(Iconsax.direct),
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
                  : () => controller.sendVerificationEmail(),
              child: controller.isLoading.value
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Send OTP'),
            ),
          ),
        ),

        // --- ADDED: Divider ---
        const SizedBox(height: TSizes.spaceBtwSections),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(
              child: Divider(
                color: dark ? TColors.darkGrey : TColors.grey,
                thickness: .5,
                indent: 60,
                endIndent: 5,
              ),
            ),
            const Text(TTexts.orSignInWith),
            Flexible(
              child: Divider(
                color: dark ? TColors.darkGrey : TColors.grey,
                thickness: .5,
                indent: 5,
                endIndent: 60,
              ),
            ),
          ],
        ),
        const SizedBox(height: TSizes.spaceBtwSections),

        // --- ADDED: Google Button ---
        Obx(
          () => GoogleSignInButton(
            isLoading: controller.isGoogleLoading.value,
            onPressed: () => controller.handleGoogleSignup(),
          ),
        ),
        const SizedBox(height: TSizes.spaceBtwItems),
        // Show Apple only on iOS
        if (GetPlatform.isIOS)
          Obx(
            () => AppleSignInButton(
              isLoading: controller.isAppleLoading.value,
              onPressed: () => controller.handleAppleSignup(),
            ),
          ),
        const SizedBox(height: TSizes.spaceBtwItems),
      ],
    );
  }
}
