import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart'; // Add iconsax import
import 'package:sarri_ride/features/driver/screens/document_upload/document_upload_screen.dart'; //
import 'package:sarri_ride/utils/constants/colors.dart'; //
import 'package:sarri_ride/utils/constants/sizes.dart'; //
import 'package:sarri_ride/utils/helpers/helper_functions.dart'; // For THelperFunctions

// --- MODIFICATION START ---
class VerificationBanner extends StatelessWidget {
  final String title;
  final String message;
  final String? buttonText; // Make button optional
  final Color bannerColor;
  final IconData iconData;
  final VoidCallback? onButtonPressed; // Make action optional

  const VerificationBanner({
    super.key,
    required this.title,
    required this.message,
    this.buttonText,
    required this.bannerColor,
    required this.iconData,
    this.onButtonPressed,
  });
  // --- MODIFICATION END ---

  @override
  Widget build(BuildContext context) {
    //
    return Container(
      //
      width: double.infinity, //
      margin: const EdgeInsets.all(TSizes.defaultSpace), //
      padding: const EdgeInsets.all(TSizes.md), //
      decoration: BoxDecoration(
        //
        color: bannerColor.withOpacity(0.1), // Use parameter
        border: Border.all(color: bannerColor), // Use parameter
        borderRadius: BorderRadius.circular(TSizes.cardRadiusLg), //
      ),
      child: Column(
        //
        crossAxisAlignment: CrossAxisAlignment.start, //
        children: [
          Row(
            // Add Row for icon and title
            children: [
              Icon(
                iconData,
                color: bannerColor,
                size: TSizes.iconMd,
              ), // Use parameter
              const SizedBox(width: TSizes.sm),
              Text(
                //
                title, // Use parameter
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: bannerColor,
                ), // Use parameter
              ),
            ],
          ),
          const SizedBox(height: TSizes.spaceBtwItems / 2), //
          Text(
            //
            message, // Use parameter
            style: Theme.of(context).textTheme.bodyMedium, //
          ),
          // Conditionally show the button
          if (buttonText != null && onButtonPressed != null) ...[
            const SizedBox(height: TSizes.spaceBtwItems), //
            SizedBox(
              //
              width: double.infinity, //
              child: OutlinedButton(
                //
                onPressed: onButtonPressed, // Use parameter
                style: OutlinedButton.styleFrom(
                  // Style based on color
                  foregroundColor: bannerColor,
                  side: BorderSide(color: bannerColor),
                ),
                child: Text(buttonText!), // Use parameter
              ),
            ),
          ],
        ],
      ),
    );
  }
}
