// lib/features/ride/widgets/no_drivers_available_widget.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:sarri_ride/features/ride/widgets/common_widgets.dart';
import 'package:sarri_ride/utils/constants/colors.dart';
import 'package:sarri_ride/utils/constants/sizes.dart';
import 'package:sarri_ride/utils/helpers/helper_functions.dart';

class NoDriversAvailableWidget extends StatelessWidget {
  final String message;
  final VoidCallback onSearchAgain;

  const NoDriversAvailableWidget({
    super.key,
    required this.message,
    required this.onSearchAgain,
  });

  @override
  Widget build(BuildContext context) {
    final dark = THelperFunctions.isDarkMode(context);
    return Container(
      padding: const EdgeInsets.all(TSizes.defaultSpace),
      decoration: BoxDecoration(
        color: dark ? TColors.dark : TColors.white,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(TSizes.cardRadiusLg),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          const DragHandle(),
          const SizedBox(height: TSizes.spaceBtwSections),

          // Illustration (using an icon as a placeholder for the 3D man)
          Container(
            padding: const EdgeInsets.all(TSizes.lg),
            decoration: BoxDecoration(
              color: TColors.warning.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Iconsax.car, // Using a basic car icon as an alternative
              color: TColors.warning,
              size: 60,
            ),
          ),
          const SizedBox(height: TSizes.spaceBtwSections),

          // Title
          Text(
            'All drivers in this category are busy', //
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: TSizes.spaceBtwItems),

          // Subtitle (Dynamic from API)
          Text(
            message, // This will be "No available drivers found nearby..."
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: dark ? TColors.lightGrey : TColors.darkGrey,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: TSizes.spaceBtwItems),

          // Payment hold message
          Text(
            "You weren't charged, but you may see a temporary payment hold.", //
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: dark ? TColors.lightGrey : TColors.darkGrey,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: TSizes.spaceBtwSections * 1.5),

          // Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onSearchAgain,
              style: ElevatedButton.styleFrom(
                backgroundColor: TColors.success, // Using green like the image
                padding: const EdgeInsets.symmetric(vertical: TSizes.md),
              ),
              child: const Text(
                'Search again', //
                style: TextStyle(
                  color: TColors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: TSizes.spaceBtwItems),
        ],
      ),
    );
  }
}
