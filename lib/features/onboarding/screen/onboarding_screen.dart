import 'package:flutter/material.dart';
import 'package:sarri_ride/features/onboarding/controllers.onboarding/onboarding_controller.dart';
import 'package:sarri_ride/features/onboarding/widget/onboarding_dot_navigation.dart';
import 'package:sarri_ride/features/onboarding/widget/onboarding_next_button.dart';
import 'package:sarri_ride/features/onboarding/widget/onboarding_skip.dart';
import 'package:sarri_ride/utils/constants/colors.dart';
import 'package:sarri_ride/utils/constants/image_strings.dart';
import 'package:sarri_ride/utils/constants/text_strings.dart';
import 'package:sarri_ride/features/onboarding/widget/onboarding_page.dart';
import 'package:sarri_ride/features/onboarding/widget/applogo.dart';
import 'package:get/get.dart';
import 'dart:ui';

import 'package:sarri_ride/utils/helpers/helper_functions.dart';

class OnBoardingScreen extends StatelessWidget {
  const OnBoardingScreen({super.key});

  @override
  Widget build(BuildContext context) {

    final controller = Get.put(OnBoardingController());
    final dark = THelperFunctions.isDarkMode(context);
    
    return Scaffold(
      body: Stack(
        children: [
           // Gradient Background
          GradientContainer(dark: dark),

          // Soft Purple Shape with Blur
          const OverlayPosition(),
          // Horizontal Scrollable Pages
          PageView(
            controller: controller.pageController,
            onPageChanged: controller.updatePageIndicator,
            children: const [
              OnBoardingPage(
                image: TImages.onBoardingImage1,
                title: TTexts.onBoardingTitle1,
                subTitle: TTexts.onBoardingSubTitle1,
              ),
              OnBoardingPage(
                image: TImages.onBoardingImage2,
                title: TTexts.onBoardingTitle2,
                subTitle: TTexts.onBoardingSubTitle2,
              ),
              OnBoardingPage(
                image: TImages.onBoardingImage3,
                title: TTexts.onBoardingTitle3,
                subTitle: TTexts.onBoardingSubTitle3,
              ),
            ],
          ),
          // App Logo
          const AppLogo(),
          //Skip Button
          const OnBoardingSkip(),

          // Dot Navigation indicator
          const OnBoardingDotNavigation(),

          //  Circular Button
          const OnBoardingNextButtton(),
        ],
      ),
    );
  }
}

class OverlayPosition extends StatelessWidget {
  const OverlayPosition({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 100,
      left: -80,
      child: Container(
        width: 300,
        height: 300,
        decoration: BoxDecoration(
            color: TColors.primary.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(150),
        ),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 50, sigmaY: 50),
          child: Container(color: Colors.transparent),
        ),
      ),
    );
  }
}

class GradientContainer extends StatelessWidget {
  const GradientContainer({
    super.key,
    required this.dark,
  });

  final bool dark;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            dark ? TColors.dark : TColors.light,
            dark ? TColors.dark : TColors.light, // Light purple
          ],
        ),
      ),
    );
  }
}
