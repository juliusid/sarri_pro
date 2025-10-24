import 'package:flutter/material.dart';
import 'package:sarri_ride/features/onboarding/controllers.onboarding/onboarding_controller.dart';
import 'package:sarri_ride/utils/constants/colors.dart';
import 'package:sarri_ride/utils/constants/sizes.dart';
import 'package:sarri_ride/utils/device/device_utility.dart';
import 'package:sarri_ride/utils/helpers/helper_functions.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';


class OnBoardingDotNavigation extends StatelessWidget {
  const OnBoardingDotNavigation({
    super.key,
  });

  @override
  Widget build(BuildContext context) {

    final dark = THelperFunctions.isDarkMode(context);
    final controller = OnBoardingController.instance;
    
    return Positioned(
      bottom: TDeviceUtils.getBottomNavigationBarHeight() + 25,
      left: TSizes.defaultSpace,
      child: SmoothPageIndicator(
        controller: controller.pageController,
        count: 3,
        onDotClicked: controller.dotNavigationClick,
        effect:  ExpandingDotsEffect(
          activeDotColor: dark 
            ?TColors.light
            :TColors.dark,
          dotHeight: 6
        ),
      ),
    );
  }
}