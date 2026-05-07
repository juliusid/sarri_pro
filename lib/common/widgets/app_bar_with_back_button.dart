import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:sarri_ride/utils/constants/colors.dart';
import 'package:sarri_ride/utils/helpers/helper_functions.dart';

/// Reusable AppBar widget that ensures proper back button behavior
/// Fixes iOS App Store and .ipa back button navigation issues
class TTAppBarWithBackButton extends StatelessWidget
    implements PreferredSizeWidget {
  final String title;
  final VoidCallback? onBackPressed;
  final List<Widget>? actions;
  final double elevation;
  final bool centerTitle;

  const TTAppBarWithBackButton({
    super.key,
    required this.title,
    this.onBackPressed,
    this.actions,
    this.elevation = 0,
    this.centerTitle = false,
  });

  @override
  Widget build(BuildContext context) {
    final dark = THelperFunctions.isDarkMode(context);

    return AppBar(
      title: Text(title),
      backgroundColor: Colors.transparent,
      elevation: elevation,
      centerTitle: centerTitle,
      leading: IconButton(
        onPressed: onBackPressed ?? () => Get.back(),
        icon: Icon(
          Iconsax.arrow_left_2,
          color: dark ? TColors.white : TColors.black,
        ),
      ),
      actions: actions,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

/// Alternative version for dark AppBar
class TTAppBarWithBackButtonDark extends StatelessWidget
    implements PreferredSizeWidget {
  final String title;
  final VoidCallback? onBackPressed;
  final List<Widget>? actions;
  final Color backgroundColor;
  final Color foregroundColor;
  final double elevation;

  const TTAppBarWithBackButtonDark({
    super.key,
    required this.title,
    this.onBackPressed,
    this.actions,
    this.backgroundColor = TColors.dark,
    this.foregroundColor = Colors.white,
    this.elevation = 0,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(title),
      backgroundColor: backgroundColor,
      foregroundColor: foregroundColor,
      elevation: elevation,
      leading: IconButton(
        onPressed: onBackPressed ?? () => Get.back(),
        icon: Icon(Iconsax.arrow_left_2, color: foregroundColor),
      ),
      actions: actions,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

/// Extension method for easier usage
extension AppBarExtensions on BuildContext {
  AppBar createAppBarWithBackButton({
    required String title,
    VoidCallback? onBackPressed,
    List<Widget>? actions,
    double elevation = 0,
  }) {
    final dark = THelperFunctions.isDarkMode(this);
    return AppBar(
      title: Text(title),
      backgroundColor: Colors.transparent,
      elevation: elevation,
      leading: IconButton(
        onPressed: onBackPressed ?? () => Get.back(),
        icon: Icon(
          Iconsax.arrow_left_2,
          color: dark ? TColors.white : TColors.black,
        ),
      ),
      actions: actions,
    );
  }
}
