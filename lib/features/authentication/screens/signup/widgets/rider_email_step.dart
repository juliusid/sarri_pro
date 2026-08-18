import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:sarri_ride/features/authentication/controllers/rider_signup_controller.dart';
import 'package:sarri_ride/features/authentication/widgets/google_button.dart';
import 'package:sarri_ride/features/authentication/widgets/apple_button.dart';
import 'package:sarri_ride/features/authentication/widgets/auth_illustration.dart';
import 'package:sarri_ride/utils/constants/sizes.dart';

// Email/password sign-up is suspended — Google/Apple only for now.
class RiderEmailStep extends StatelessWidget {
  const RiderEmailStep({super.key});

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
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const AuthIllustration(
                          variant: AuthIllustrationVariant.radar,
                        ),
                        const SizedBox(height: TSizes.spaceBtwSections),
                        Text(
                          "Create your Rider account",
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                        const SizedBox(height: TSizes.spaceBtwItems),
                        Text(
                          "Continue with Google or Apple to get started.",
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                        const SizedBox(height: TSizes.spaceBtwSections * 1.5),

                        SizedBox(
                          width: double.infinity,
                          child: Obx(
                            () => GoogleSignInButton(
                              isLoading: controller.isGoogleLoading.value,
                              onPressed: () => controller.handleGoogleSignup(),
                            ),
                          ),
                        ),
                        const SizedBox(height: TSizes.spaceBtwItems),
                        // Show Apple only on iOS
                        if (GetPlatform.isIOS)
                          SizedBox(
                            width: double.infinity,
                            child: Obx(
                              () => AppleSignInButton(
                                isLoading: controller.isAppleLoading.value,
                                onPressed: () => controller.handleAppleSignup(),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
