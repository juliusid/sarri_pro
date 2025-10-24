import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sarri_ride/common/styles/spacing_styles.dart';
import 'package:sarri_ride/features/authentication/screens/login/login_screen_getx.dart';
import 'package:sarri_ride/features/authentication/screens/signup/driver_signup_screen.dart';
import 'package:sarri_ride/features/authentication/screens/signup/rider_signup_screen.dart';
// import 'package:sarri_ride/features/authentication/screens/signup/signup_screen_getx.dart';
// import 'package:ride_app/features/authentication/screens/driver_registration/driver_registration_screen.dart';
import 'package:sarri_ride/utils/constants/colors.dart';
import 'package:sarri_ride/utils/constants/enums.dart';
import 'package:sarri_ride/utils/constants/sizes.dart';
import 'package:sarri_ride/utils/constants/text_strings.dart';
import 'package:sarri_ride/utils/helpers/helper_functions.dart';
import 'package:iconsax/iconsax.dart';

class UserTypeSelectionScreen extends StatelessWidget {
  const UserTypeSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final dark = THelperFunctions.isDarkMode(context);

    return Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: TSSpacingStyle.paddingWithAppBarHeight,
          child: Column(
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

              const SizedBox(height: TSizes.spaceBtwSections),

              // Header
              Text(
                'Join RideApp',
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: TColors.primary,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: TSizes.spaceBtwItems),

              Text(
                'Choose how you want to use RideApp',
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: TSizes.spaceBtwSections * 2),

              // Rider Option
              _buildUserTypeCard(
                context: context,
                dark: dark,
                icon: Iconsax.car,
                title: 'I want to ride',
                subtitle: 'Book rides and get to your destination safely',
                features: [
                  'Quick and easy booking',
                  'Safe and reliable drivers',
                  'Multiple payment options',
                  'Real-time trip tracking',
                ],
                onTap: () => Get.to(() => const RiderSignupScreen()),
                buttonText: 'Sign up as Rider',
                primaryColor: TColors.primary,
              ),

              const SizedBox(height: TSizes.spaceBtwSections),

              // Driver Option
              _buildUserTypeCard(
                context: context,
                dark: dark,
                icon: Icons.drive_eta,
                title: 'I want to drive',
                subtitle: 'Earn money by driving with RideApp',
                features: [
                  'Flexible working hours',
                  'Weekly earnings payout',
                  'Navigation assistance',
                  'Driver support 24/7',
                ],
                onTap: () => Get.to(() => const DriverSignupScreen()),
                buttonText: 'Sign up as Driver',
                primaryColor: TColors.success,
              ),

              const SizedBox(height: TSizes.spaceBtwSections),

              // Already have account
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Already have an account?',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  TextButton(
                    onPressed: () => Get.to(() => const LoginScreenGetX()),
                    child: Text(
                      'Sign In',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: TColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: TSizes.spaceBtwSections),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUserTypeCard({
    required BuildContext context,
    required bool dark,
    required IconData icon,
    required String title,
    required String subtitle,
    required List<String> features,
    required VoidCallback onTap,
    required String buttonText,
    required Color primaryColor,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(TSizes.defaultSpace),
      decoration: BoxDecoration(
        color: dark ? TColors.dark : Colors.white,
        borderRadius: BorderRadius.circular(TSizes.cardRadiusLg),
        border: Border.all(color: primaryColor.withOpacity(0.2), width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(dark ? 0.3 : 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Icon
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(40),
            ),
            child: Icon(icon, size: 40, color: primaryColor),
          ),

          const SizedBox(height: TSizes.spaceBtwItems),

          // Title
          Text(
            title,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: dark ? TColors.white : TColors.black,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: TSizes.spaceBtwItems / 2),

          // Subtitle
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: dark ? TColors.lightGrey : TColors.darkGrey,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: TSizes.spaceBtwItems),

          // Features
          ...features
              .map(
                (feature) => Padding(
                  padding: const EdgeInsets.only(
                    bottom: TSizes.spaceBtwItems / 2,
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle, size: 16, color: primaryColor),
                      const SizedBox(width: TSizes.spaceBtwItems / 2),
                      Expanded(
                        child: Text(
                          feature,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: dark
                                    ? TColors.lightGrey
                                    : TColors.darkGrey,
                              ),
                        ),
                      ),
                    ],
                  ),
                ),
              )
              .toList(),

          const SizedBox(height: TSizes.spaceBtwItems),

          // Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onTap,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  vertical: TSizes.buttonHeight / 2,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(TSizes.buttonRadius),
                ),
              ),
              child: Text(
                buttonText,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
