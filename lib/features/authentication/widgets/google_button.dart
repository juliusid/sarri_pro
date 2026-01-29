import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:sarri_ride/utils/constants/colors.dart';
import 'package:sarri_ride/utils/constants/sizes.dart';
import 'package:sarri_ride/utils/helpers/helper_functions.dart';

class GoogleSignInButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final bool isLoading;

  const GoogleSignInButton({super.key, this.onPressed, this.isLoading = false});

  @override
  Widget build(BuildContext context) {
    final dark = THelperFunctions.isDarkMode(context);

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          elevation: 0, // Google buttons are typically flat or low elevation
          // Light Mode: Pure White. Dark Mode: Dark Container.
          backgroundColor: dark ? TColors.white : TColors.white,
          // Light Mode: Dark Text. Dark Mode: White Text.
          foregroundColor: dark ? TColors.white : TColors.textPrimary,
          // Border: Subtle Grey for definition
          side: BorderSide(
            color: dark ? TColors.borderSecondary : TColors.borderPrimary,
          ),
          padding: const EdgeInsets.symmetric(vertical: TSizes.md),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(TSizes.cardRadiusMd),
          ),
        ),
        child: isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SvgPicture.asset(
                    'assets/logos/google.svg', // Make sure this file exists!
                    height: 24,
                    width: 24,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Sign in with Google', // Standard Google phrasing
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      color: dark ? TColors.textPrimary : TColors.textPrimary,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
