// lib/common/widgets/loading_button.dart

import 'package:flutter/material.dart';
import 'package:sarri_ride/utils/constants/colors.dart';
import 'package:sarri_ride/utils/constants/sizes.dart';

/// A custom ElevatedButton that shows a loading indicator while maintaining its
/// background color and text.
class LoadingElevatedButton extends StatelessWidget {
  final bool isLoading;
  final String text;
  final String? loadingText;
  final VoidCallback onPressed;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final IconData? icon;

  const LoadingElevatedButton({
    super.key,
    required this.isLoading,
    required this.text,
    required this.onPressed,
    this.loadingText,
    this.backgroundColor = TColors.primary,
    this.foregroundColor = Colors.white,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      // Deem the button while loading
      opacity: isLoading ? 0.7 : 1.0,
      child: ElevatedButton(
        // We never pass null, so the button never turns gray
        onPressed: () {
          if (isLoading) return; // Manually block taps when loading
          onPressed();
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: foregroundColor,
          padding: const EdgeInsets.symmetric(vertical: TSizes.md),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(TSizes.buttonRadius),
          ),
        ),
        child: isLoading
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  ),
                  const SizedBox(width: TSizes.spaceBtwItems),
                  Text(
                    loadingText ?? text,
                    style: const TextStyle(
                      fontSize: TSizes.fontSizeMd,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 20),
                    const SizedBox(width: TSizes.spaceBtwItems / 2),
                  ],
                  Text(
                    text,
                    style: const TextStyle(
                      fontSize: TSizes.fontSizeMd,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

/// A custom OutlinedButton that shows a loading indicator while maintaining its
/// color and text.
class LoadingOutlinedButton extends StatelessWidget {
  final bool isLoading;
  final String text;
  final String? loadingText;
  final VoidCallback onPressed;
  final Color? foregroundColor;
  final IconData? icon;

  const LoadingOutlinedButton({
    super.key,
    required this.isLoading,
    required this.text,
    required this.onPressed,
    this.loadingText,
    this.foregroundColor = TColors.primary,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: isLoading ? 0.7 : 1.0,
      child: OutlinedButton(
        onPressed: () {
          if (isLoading) return;
          onPressed();
        },
        style: OutlinedButton.styleFrom(
          foregroundColor: foregroundColor,
          side: BorderSide(color: foregroundColor ?? TColors.primary),
          padding: const EdgeInsets.symmetric(
            vertical: TSizes.md,
            horizontal: TSizes.sm,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(TSizes.buttonRadius),
          ),
        ),
        child: isLoading
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: foregroundColor,
                      strokeWidth: 2,
                    ),
                  ),
                  const SizedBox(width: TSizes.spaceBtwItems),
                  Text(
                    loadingText ?? text,
                    style: const TextStyle(
                      fontSize: TSizes.fontSizeMd,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 18),
                    const SizedBox(width: TSizes.xs),
                  ],
                  Text(
                    text,
                    style: const TextStyle(
                      fontSize: TSizes.fontSizeMd,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
