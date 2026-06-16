import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:sarri_ride/features/verification/controllers/driver_verification_controller.dart';
import 'package:sarri_ride/features/verification/widgets/driver_phone_verification_step.dart';
import 'package:sarri_ride/features/verification/widgets/driver_details_verification_step.dart';
import 'package:sarri_ride/utils/constants/colors.dart';
import 'package:sarri_ride/utils/constants/sizes.dart';
import 'package:sarri_ride/utils/helpers/helper_functions.dart';

import 'package:sarri_ride/features/verification/widgets/driver_document_verification_step.dart';

class DriverVerificationWizardScreen extends StatelessWidget {
  final DriverVerificationStep initialStep;

  const DriverVerificationWizardScreen({
    super.key,
    this.initialStep = DriverVerificationStep.phone,
  });

  @override
  Widget build(BuildContext context) {
    // Put registers the controller. If we want to initialize it once with an argument,
    // we should do it during the put phase.
    final controller = Get.put(DriverVerificationController());
    if (!controller.isInitializedWizard) {
      controller.initWizard(initialStep);
    }

    final dark = THelperFunctions.isDarkMode(context);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) controller.previousStep();
      },
      child: Scaffold(
        backgroundColor: dark ? TColors.dark : TColors.light,
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
                  totalSteps: DriverVerificationStep.values.length,
                )),
          ),
        ),
        body: PageView(
          controller: controller.pageController,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            DriverPhoneVerificationStep(controller: controller),
            DriverDetailsVerificationStep(controller: controller),
            const DriverDocumentVerificationStep(),
          ],
        ),
      ),
    );
  }

  String _stepTitle(DriverVerificationStep step) {
    switch (step) {
      case DriverVerificationStep.phone:
        return 'Verify Phone Number';
      case DriverVerificationStep.details:
        return 'Vehicle Details';
      case DriverVerificationStep.documents:
        return 'Upload Documents';
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
