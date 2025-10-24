import 'package:flutter/material.dart';
import 'package:sarri_ride/utils/constants/image_strings.dart';
import 'package:sarri_ride/utils/constants/sizes.dart';
import 'package:sarri_ride/utils/device/device_utility.dart';
import 'package:sarri_ride/utils/helpers/helper_functions.dart';

class AppLogo extends StatelessWidget {
  const AppLogo({super.key});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: TDeviceUtils.getAppBarHeight(),
      left: TSizes.defaultSpace,
      child: Image(
        width: THelperFunctions.screenWidth() * 0.3,
        height: TDeviceUtils.getAppBarHeight(),
        image: AssetImage(
          THelperFunctions.isDarkMode(context)
              ? TImages.darkAppLogo
              : TImages.lightAppLogo,
        ),
      ),
    );
  }
}