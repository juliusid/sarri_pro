// lib/features/authentication/screens/signup/driver_signup_screen.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:sarri_ride/features/authentication/controllers/driver_signup_controller.dart';
import 'package:sarri_ride/features/authentication/screens/signup/widgets/driver_auth_method_step.dart';
import 'package:sarri_ride/features/authentication/screens/signup/widgets/driver_details_step.dart';
import 'package:sarri_ride/features/authentication/screens/signup/widgets/driver_phone_combined_step.dart';
import 'package:sarri_ride/utils/constants/colors.dart';
import 'package:sarri_ride/utils/constants/sizes.dart';
import 'package:sarri_ride/utils/helpers/helper_functions.dart';

class DriverSignupScreen extends StatelessWidget {
  final String? email;

  const DriverSignupScreen({super.key, this.email});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(DriverSignupController());

    // Pre-fill email if coming from login with incomplete signup
    if (email != null && email!.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        controller.setInitialEmail(email!);
      });
    }

    final dark = THelperFunctions.isDarkMode(context);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) controller.previousStep();
      },
      child: Scaffold(
        backgroundColor:
            dark ? TColors.dark : TColors.light,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            onPressed: controller.previousStep,
            icon: Icon(
              Iconsax.arrow_left_2,
              color: dark ? TColors.light : TColors.dark,
              size: TSizes.iconLg,
            ),
          ),
          title: Obx(() => Text(
                _stepTitle(controller.currentStep.value),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              )),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(6),
            child: Obx(() => _ProgressBar(
                  currentStep: controller.currentStep.value.index,
                  totalSteps: DriverSignupStep.values.length,
                )),
          ),
        ),
        body: PageView(
          controller: controller.pageController,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            DriverAuthMethodStep(controller: controller),
            DriverPhoneCombinedStep(controller: controller),
            DriverDetailsStep(controller: controller),
          ],
        ),
      ),
    );
  }

  String _stepTitle(DriverSignupStep step) {
    switch (step) {
      case DriverSignupStep.authMethod:
        return 'Create Driver Account';
      case DriverSignupStep.phone:
        return 'Verify Phone Number';
      case DriverSignupStep.details:
        return 'Vehicle Details';
    }
  }
}

class _ProgressBar extends StatelessWidget {
  final int currentStep;
  final int totalSteps;

  const _ProgressBar({required this.currentStep, required this.totalSteps});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(totalSteps, (index) {
        final isCompleted = index <= currentStep;
        return Expanded(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            height: 4,
            margin: EdgeInsets.only(
              left: index == 0 ? 0 : 2,
              right: index == totalSteps - 1 ? 0 : 2,
            ),
            decoration: BoxDecoration(
              color: isCompleted ? TColors.primary : TColors.grey.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        );
      }),
    );
  }
}
