import 'package:flutter/material.dart';
import 'package:sarri_ride/utils/constants/colors.dart';
import 'package:sarri_ride/utils/helpers/helper_functions.dart';


class SocialButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final Widget icon;
  final Color backgroundColor;
  final Color textColor;
  final bool isLoading;

  const SocialButton({
    super.key,
    required this.text,
    required this.icon,
    required this.backgroundColor,
    required this.textColor,
    this.onPressed,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final dark = THelperFunctions.isDarkMode(context);
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: Theme.of(context).elevatedButtonTheme.style?.copyWith(
          backgroundColor: WidgetStateProperty.all(backgroundColor),
          foregroundColor: WidgetStateProperty.all(textColor),
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: TColors.grey.withValues(alpha: .3), width: 1),
            ),
          ),
          elevation: WidgetStateProperty.all(1),
          shadowColor: WidgetStateProperty.all(dark ? TColors.darkGrey : TColors.grey),
        ) ?? ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: textColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: TColors.grey.withValues(alpha: .3), width: 1),
          ),
          elevation: 1,
          shadowColor: dark ? TColors.darkGrey : TColors.grey,
        ),
        child: isLoading
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(textColor),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  icon,
                  const SizedBox(width: 12),
                  Text(
                    text,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}