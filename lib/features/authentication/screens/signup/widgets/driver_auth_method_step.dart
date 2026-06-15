// lib/features/authentication/screens/signup/widgets/driver_auth_method_step.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:sarri_ride/common/widgets/loading_button.dart';
import 'package:sarri_ride/features/authentication/controllers/driver_signup_controller.dart';
import 'package:sarri_ride/features/authentication/widgets/google_button.dart';
import 'package:sarri_ride/utils/constants/colors.dart';
import 'package:sarri_ride/utils/constants/sizes.dart';
import 'package:sarri_ride/utils/helpers/helper_functions.dart';
import 'package:sarri_ride/utils/validators/validation.dart';

class DriverAuthMethodStep extends StatefulWidget {
  final DriverSignupController controller;

  const DriverAuthMethodStep({super.key, required this.controller});

  @override
  State<DriverAuthMethodStep> createState() => _DriverAuthMethodStepState();
}

class _DriverAuthMethodStepState extends State<DriverAuthMethodStep> {
  // Track whether to show email OTP input
  final _showOtpField = false.obs;

  DriverSignupController get c => widget.controller;

  @override
  Widget build(BuildContext context) {
    final dark = THelperFunctions.isDarkMode(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(TSizes.defaultSpace),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: TSizes.spaceBtwItems),

          // ── Header ─────────────────────────────────────────────────────
          Text(
            'Join as a Driver',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: TSizes.xs),
          Text(
            'Start earning in minutes. No long forms.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: dark ? TColors.lightGrey : TColors.darkGrey,
                ),
          ),

          const SizedBox(height: TSizes.spaceBtwSections),

          // ── Google Sign-In (Primary) ───────────────────────────────────
          Obx(() => GoogleSignInButton(
                isLoading: c.isLoading.value && !_showOtpField.value,
                onPressed: c.signInWithGoogle,
              )),

          const SizedBox(height: TSizes.spaceBtwItems),

          // ── Divider ───────────────────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: Divider(
                  color: dark ? TColors.darkGrey : TColors.grey,
                  thickness: .5,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  'or sign up with email',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: dark ? TColors.lightGrey : TColors.darkGrey,
                      ),
                ),
              ),
              Expanded(
                child: Divider(
                  color: dark ? TColors.darkGrey : TColors.grey,
                  thickness: .5,
                ),
              ),
            ],
          ),

          const SizedBox(height: TSizes.spaceBtwItems),

          // ── Email Form ────────────────────────────────────────────────
          Obx(() => _showOtpField.value
              ? _OtpSection(
                  controller: c,
                  showOtpField: _showOtpField,
                  dark: dark,
                )
              : _EmailSection(
                  controller: c,
                  showOtpField: _showOtpField,
                  dark: dark,
                )),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Email input section
// ─────────────────────────────────────────────────────────────────────────────
class _EmailSection extends StatelessWidget {
  final DriverSignupController controller;
  final RxBool showOtpField;
  final bool dark;

  const _EmailSection({
    required this.controller,
    required this.showOtpField,
    required this.dark,
  });

  @override
  Widget build(BuildContext context) {
    return Form(
      key: controller.emailFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(
            controller: controller.emailController,
            validator: TValidator.validateEmail,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              labelText: 'Email address',
              hintText: 'e.g. johndoe@gmail.com',
              prefixIcon: Icon(
                Iconsax.sms,
                color: dark ? TColors.light : TColors.dark,
                size: TSizes.iconMd,
              ),
            ),
          ),
          const SizedBox(height: TSizes.spaceBtwItems),
          SizedBox(
            width: double.infinity,
            child: Obx(() => LoadingElevatedButton(
                  isLoading: controller.isLoading.value,
                  text: 'Send OTP',
                  loadingText: 'Sending...',
                  onPressed: () async {
                    await controller.sendVerificationEmail();
                    if (controller.currentStep.value ==
                        DriverSignupStep.authMethod) {
                      // Still on authMethod step means OTP was sent, reveal OTP field
                      showOtpField.value = true;
                    }
                  },
                  backgroundColor: dark ? TColors.dark : TColors.black,
                  foregroundColor: TColors.white,
                )),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// OTP verify section (inline, after email OTP sent)
// ─────────────────────────────────────────────────────────────────────────────
class _OtpSection extends StatelessWidget {
  final DriverSignupController controller;
  final RxBool showOtpField;
  final bool dark;

  const _OtpSection({
    required this.controller,
    required this.showOtpField,
    required this.dark,
  });

  @override
  Widget build(BuildContext context) {
    return Form(
      key: controller.otpFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Enter the 6-digit code sent to ${controller.emailController.text.trim()}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: dark ? TColors.lightGrey : TColors.darkGrey,
                ),
          ),
          const SizedBox(height: TSizes.spaceBtwItems),
          TextFormField(
            controller: controller.otpController,
            keyboardType: TextInputType.number,
            maxLength: 6,
            validator: (v) => (v == null || v.length != 6)
                ? 'Enter the 6-digit OTP'
                : null,
            decoration: InputDecoration(
              labelText: 'Email OTP',
              prefixIcon: Icon(
                Iconsax.shield_tick,
                color: dark ? TColors.light : TColors.dark,
                size: TSizes.iconMd,
              ),
            ),
          ),
          const SizedBox(height: TSizes.spaceBtwItems),
          SizedBox(
            width: double.infinity,
            child: Obx(() => LoadingElevatedButton(
                  isLoading: controller.isLoading.value,
                  text: 'Verify Email',
                  loadingText: 'Verifying...',
                  onPressed: controller.verifyEmailOtp,
                  backgroundColor: TColors.primary,
                  foregroundColor: TColors.white,
                )),
          ),
          const SizedBox(height: TSizes.spaceBtwItems),
          // Resend + change email
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton(
                onPressed: () {
                  showOtpField.value = false;
                  controller.otpController.clear();
                },
                child: Text(
                  'Change email',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: TColors.primary,
                      ),
                ),
              ),
              Obx(() => TextButton(
                    onPressed: controller.isResendEnabled.value
                        ? () => controller.sendVerificationEmail(isResend: true)
                        : null,
                    child: Text(
                      controller.isResendEnabled.value
                          ? 'Resend OTP'
                          : 'Resend in ${controller.resendTimer.value}s',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: controller.isResendEnabled.value
                                ? TColors.primary
                                : TColors.darkGrey,
                          ),
                    ),
                  )),
            ],
          ),
        ],
      ),
    );
  }
}
