import 'package:flutter/material.dart';
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
      child: ElevatedButton.icon(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: dark ? TColors.darkerGrey : TColors.lightGrey,
          foregroundColor: dark ? TColors.white : TColors.black,
          side: BorderSide(color: dark ? TColors.darkGrey : TColors.grey),
          padding: const EdgeInsets.symmetric(vertical: TSizes.md),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(TSizes.cardRadiusMd),
          ),
        ),
        icon: isLoading
            ? const SizedBox.shrink() // Don't show icon when loading
            : const Icon(Icons.g_mobiledata, size: 24),

        label: isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Text(
                'Continue with Google',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
              ),
      ),
    );
  }
}
