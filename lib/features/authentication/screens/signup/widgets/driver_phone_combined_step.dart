// lib/features/authentication/screens/signup/widgets/driver_phone_combined_step.dart
//
// Phone number + OTP verification combined on a single screen.
// The OTP input field slides in below after the user taps "Send OTP".
// No page navigation needed — clean, fast, fewer taps.

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:sarri_ride/common/widgets/loading_button.dart';
import 'package:sarri_ride/features/authentication/controllers/driver_signup_controller.dart';
import 'package:sarri_ride/utils/constants/colors.dart';
import 'package:sarri_ride/utils/constants/sizes.dart';
import 'package:sarri_ride/utils/helpers/helper_functions.dart';
import 'package:sarri_ride/utils/validators/validation.dart';

class DriverPhoneCombinedStep extends StatelessWidget {
  final DriverSignupController controller;

  const DriverPhoneCombinedStep({super.key, required this.controller});

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
            'Verify your phone',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: TSizes.xs),
          Text(
            'We\'ll send a 6-digit code via SMS to verify your number.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: dark ? TColors.lightGrey : TColors.darkGrey,
                ),
          ),

          const SizedBox(height: TSizes.spaceBtwSections),

          // ── Phone Number Field ─────────────────────────────────────────
          Form(
            key: controller.phoneFormKey,
            child: TextFormField(
              controller: controller.phoneNumberController,
              validator: TValidator.validatePhoneNumber,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: 'Phone number',
                hintText: '08012345678',
                prefixIcon: Icon(
                  Iconsax.call,
                  color: dark ? TColors.light : TColors.dark,
                  size: TSizes.iconMd,
                ),
              ),
            ),
          ),

          const SizedBox(height: TSizes.spaceBtwItems),

          // ── Send OTP Button (shown until OTP is revealed) ──────────────
          Obx(() => !controller.otpFieldVisible.value
              ? SizedBox(
                  width: double.infinity,
                  child: LoadingElevatedButton(
                    isLoading: controller.isLoading.value,
                    text: 'Send OTP',
                    loadingText: 'Sending...',
                    onPressed: controller.sendPhoneVerificationOtp,
                    backgroundColor: TColors.primary,
                    foregroundColor: TColors.white,
                  ),
                )
              : const SizedBox.shrink()),

          // ── OTP Field (animated reveal) ────────────────────────────────
          Obx(() => AnimatedSwitcher(
                duration: const Duration(milliseconds: 350),
                transitionBuilder: (child, animation) {
                  return SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, 0.3),
                      end: Offset.zero,
                    ).animate(CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeOut,
                    )),
                    child: FadeTransition(opacity: animation, child: child),
                  );
                },
                child: controller.otpFieldVisible.value
                    ? _OtpRevealSection(controller: controller, dark: dark)
                    : const SizedBox.shrink(),
              )),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// OTP section — slides in below phone number after OTP is sent
// ─────────────────────────────────────────────────────────────────────────────
class _OtpRevealSection extends StatelessWidget {
  final DriverSignupController controller;
  final bool dark;

  const _OtpRevealSection({required this.controller, required this.dark});

  @override
  Widget build(BuildContext context) {
    return Form(
      key: controller.phoneOtpFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: TSizes.spaceBtwItems),

          // OTP sent confirmation banner
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: TColors.primary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                  color: TColors.primary.withOpacity(0.3), width: 1),
            ),
            child: Row(
              children: [
                const Icon(Iconsax.tick_circle,
                    color: TColors.primary, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'OTP sent to ${controller.phoneNumberController.text.trim()}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: TColors.primary,
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: TSizes.spaceBtwItems),

          // OTP input
          TextFormField(
            controller: controller.phoneOtpController,
            keyboardType: TextInputType.number,
            maxLength: 6,
            autofocus: true,
            validator: (v) =>
                (v == null || v.length != 6) ? 'Enter the 6-digit OTP' : null,
            decoration: InputDecoration(
              labelText: 'Enter OTP',
              hintText: '------',
              prefixIcon: Icon(
                Iconsax.shield_tick,
                color: dark ? TColors.light : TColors.dark,
                size: TSizes.iconMd,
              ),
            ),
          ),

          const SizedBox(height: TSizes.spaceBtwItems),

          // Verify OTP button
          SizedBox(
            width: double.infinity,
            child: Obx(() => LoadingElevatedButton(
                  isLoading: controller.isLoading.value,
                  text: 'Verify & Continue',
                  loadingText: 'Verifying...',
                  onPressed: controller.verifyPhoneOtp,
                  backgroundColor: TColors.primary,
                  foregroundColor: TColors.white,
                )),
          ),

          const SizedBox(height: TSizes.spaceBtwItems),

          // Resend + change number row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton(
                onPressed: () {
                  controller.otpFieldVisible.value = false;
                  controller.phoneOtpController.clear();
                },
                child: Text(
                  'Change number',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: TColors.primary,
                      ),
                ),
              ),
              Obx(() => TextButton(
                    onPressed: controller.isResendEnabled.value
                        ? controller.resendPhoneOtp
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
