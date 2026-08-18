import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sarri_ride/features/authentication/screens/login/login_screen_getx.dart';
import 'package:sarri_ride/features/authentication/screens/signup/driver_signup_screen.dart';
import 'package:sarri_ride/features/authentication/screens/signup/rider_signup_screen.dart';
import 'package:sarri_ride/utils/constants/colors.dart';
import 'package:sarri_ride/utils/constants/sizes.dart';
import 'package:sarri_ride/utils/helpers/helper_functions.dart';

class UserTypeSelectionScreen extends StatelessWidget {
  const UserTypeSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final dark = THelperFunctions.isDarkMode(context);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: TSizes.defaultSpace),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: TSizes.spaceBtwItems),

              // Top row: intentionally empty on the left, Log in on the right.
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const SizedBox(width: 40, height: 40),
                  TextButton(
                    onPressed: () => Get.to(() => const LoginScreenGetX()),
                    child: Text(
                      'Log in',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: TColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: TSizes.spaceBtwSections * 1.5),

              // Header
              Text(
                'How will you\nride today?',
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  height: 1.15,
                ),
              ),
              const SizedBox(height: TSizes.sm),
              Text(
                'Pick one to continue.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: dark ? TColors.lightGrey : TColors.darkGrey,
                ),
              ),

              const SizedBox(height: TSizes.spaceBtwSections * 1.5),

              // Flat selectable rows, separated by a hairline divider.
              _buildSelectionRow(
                context: context,
                dark: dark,
                title: 'Rider',
                subtitle: 'Book instantly',
                onTap: () => Get.to(() => const RiderSignupScreen()),
              ),
              Divider(
                height: 1,
                color: dark ? TColors.darkGrey.withOpacity(0.4) : TColors.grey.withOpacity(0.4),
              ),
              _buildSelectionRow(
                context: context,
                dark: dark,
                title: 'Driver',
                subtitle: 'Start earning',
                onTap: () => Get.to(() => const DriverSignupScreen()),
              ),

              const Spacer(),

              // Footer Text
              Padding(
                padding: const EdgeInsets.only(bottom: TSizes.spaceBtwItems),
                child: Text.rich(
                  TextSpan(
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: dark ? TColors.lightGrey : TColors.darkGrey,
                    ),
                    children: const [
                      TextSpan(text: 'By continuing you agree to our '),
                      TextSpan(
                        text: 'terms',
                        style: TextStyle(decoration: TextDecoration.underline),
                      ),
                      TextSpan(text: ' and '),
                      TextSpan(
                        text: 'privacy policy',
                        style: TextStyle(decoration: TextDecoration.underline),
                      ),
                      TextSpan(text: '.'),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSelectionRow({
    required BuildContext context,
    required bool dark,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: TSizes.spaceBtwSections),
        child: Row(
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: dark ? TColors.lightGrey : TColors.darkGrey,
              ),
            ),
            const SizedBox(width: TSizes.sm),
            const Icon(Icons.arrow_forward, color: TColors.primary, size: TSizes.iconMd),
          ],
        ),
      ),
    );
  }
}
