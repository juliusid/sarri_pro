import 'package:flutter/material.dart';
import 'package:sarri_ride/features/onboarding/controllers.onboarding/onboarding_controller.dart';
import 'package:sarri_ride/utils/constants/colors.dart';
import 'package:sarri_ride/utils/constants/sizes.dart';
import 'package:sarri_ride/utils/device/device_utility.dart';
import 'package:iconsax/iconsax.dart';

class OnBoardingNextButtton extends StatelessWidget {
  const OnBoardingNextButtton({super.key});
  

  @override
  Widget build(BuildContext context) {
    final controller = OnBoardingController.instance;
    return Positioned(
      bottom: TDeviceUtils.getBottomNavigationBarHeight() + 25,
      right: TSizes.defaultSpace,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          shape: const CircleBorder(),
          backgroundColor:  TColors.primary,
        ),
        onPressed: () {
          controller.nextPage();
        },
        child: const Icon(Iconsax.arrow_right_1),
      ),
    );
  }
}
