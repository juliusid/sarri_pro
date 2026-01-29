import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
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
      // Use an AppBar to put the Login button right at the top
      appBar: AppBar(
        automaticallyImplyLeading: false, // No back button needed here usually
        actions: [
          TextButton(
            onPressed: () => Get.to(() => const LoginScreenGetX()),
            child: Text(
              'Log In',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: TColors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: TSizes.defaultSpace / 2),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(TSizes.defaultSpace),
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center, // Center content vertically
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Text(
              'Welcome to Sarri Ride',
              style: Theme.of(
                context,
              ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: TSizes.sm),
            Text(
              'Choose how you want to continue',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: TSizes.spaceBtwSections * 1.5),

            // RIDER CARD (Simplified)
            _buildSelectionCard(
              context: context,
              dark: dark,
              title: "I am a Rider",
              subtitle: "Book rides instantly",
              icon: Iconsax.car,
              color: TColors.primary,
              onTap: () => Get.to(() => const RiderSignupScreen()),
            ),

            const SizedBox(height: TSizes.spaceBtwItems),

            // DRIVER CARD (Simplified)
            _buildSelectionCard(
              context: context,
              dark: dark,
              title: "I am a Driver",
              subtitle: "Earn money driving",
              icon: Iconsax.driver,
              color: const Color(0xFF4b68ff), // Or TColors.secondary
              onTap: () => Get.to(() => const DriverSignupScreen()),
            ),

            const Spacer(), // Pushes content up slightly if needed
            // Footer Text
            Center(
              child: Text(
                'By continuing, you agree to our Terms & Privacy Policy',
                style: Theme.of(
                  context,
                ).textTheme.labelSmall?.copyWith(color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: TSizes.sm),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectionCard({
    required BuildContext context,
    required bool dark,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(TSizes.md),
        decoration: BoxDecoration(
          // FIX: Use a hardcoded dark grey for dark mode to ensure it's visible
          color: dark ? const Color(0xFF1F1F1F) : Colors.white,
          borderRadius: BorderRadius.circular(TSizes.cardRadiusLg),
          border: Border.all(
            // Make the border slightly visible in dark mode
            color: dark ? Colors.grey.withOpacity(0.2) : color.withOpacity(0.3),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Icon Box
            Container(
              height: 60,
              width: 60,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(TSizes.cardRadiusMd),
              ),
              child: Icon(icon, color: color, size: 30),
            ),
            const SizedBox(width: TSizes.spaceBtwItems),

            // Text Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      // Ensure text is white in dark mode
                      color: dark ? Colors.white : Colors.black,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: Colors.grey),
                  ),
                ],
              ),
            ),

            // Arrow Icon
            Icon(Iconsax.arrow_right_3, color: color),
          ],
        ),
      ),
    );
  }
}
