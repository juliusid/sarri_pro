// lib/features/authentication/screens/login/login_screen_getx.dart

import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sarri_ride/features/authentication/controllers/login_controller.dart';
import 'package:sarri_ride/features/authentication/screens/user_type_selection/user_type_selection_screen.dart';
import 'package:sarri_ride/features/authentication/widgets/google_button.dart';
import 'package:sarri_ride/features/authentication/widgets/apple_button.dart';
import 'package:sarri_ride/features/authentication/widgets/auth_illustration.dart';
import 'package:sarri_ride/features/authentication/widgets/sign_in_update_notice.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:sarri_ride/utils/constants/colors.dart';
import 'package:iconsax/iconsax.dart';
import 'package:sarri_ride/utils/constants/sizes.dart';
import 'package:sarri_ride/utils/constants/text_strings.dart';
import 'package:sarri_ride/utils/helpers/helper_functions.dart';

// --- CONVERT TO STATEFULWIDGET ---
class LoginScreenGetX extends StatefulWidget {
  const LoginScreenGetX({super.key});

  @override
  State<LoginScreenGetX> createState() => _LoginScreenGetXState();
}

class _LoginScreenGetXState extends State<LoginScreenGetX> {
  // --- MANUALLY CREATE AND MANAGE THE CONTROLLER ---
  late final LoginController controller;
  bool _isAppleSignInAvailable = false;

  @override
  void initState() {
    super.initState();
    // Create a fresh instance of the controller every time the screen is initialized
    controller = Get.put(LoginController());
    // Check Apple Sign-In availability asynchronously
    _checkAppleSignInAvailability();
    // One-time heads-up that passwords have been replaced by Google/Apple.
    SignInUpdateNotice.maybeShow(SignInNoticeSurface.login);
  }

  Future<void> _checkAppleSignInAvailability() async {
    if (Platform.isIOS) {
      try {
        final available = await SignInWithApple.isAvailable();
        if (mounted) {
          setState(() {
            _isAppleSignInAvailable = available;
          });
        }
      } catch (e) {
        debugPrint('Error checking Apple Sign-In availability: $e');
        // On error, still show the button (let the handler deal with it)
        if (mounted) {
          setState(() {
            _isAppleSignInAvailable = true;
          });
        }
      }
    }
  }

  @override
  void dispose() {
    // Explicitly delete the controller instance when the screen is disposed
    Get.delete<LoginController>();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dark = THelperFunctions.isDarkMode(context);

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              // Back Button — pinned to the top, outside the centered block.
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: TSizes.defaultSpace / 2,
                ),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Get.back(),
                      icon: Icon(
                        Iconsax.arrow_left_2,
                        color: dark ? TColors.light : TColors.dark,
                        size: TSizes.iconLg,
                      ),
                    ),
                  ],
                ),
              ),

              // Everything else is centered as one block in the remaining
              // space, so the screen doesn't read as a form with the
              // bottom half left empty.
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(
                        horizontal: TSizes.defaultSpace,
                      ),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: constraints.maxHeight,
                        ),
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const AuthIllustration(
                                variant: AuthIllustrationVariant.route,
                              ),
                              const SizedBox(height: TSizes.spaceBtwSections),

                              Text(
                                TTexts.loginTitle,
                                style: Theme.of(context).textTheme.headlineMedium,
                              ),
                              const SizedBox(height: TSizes.spaceBtwItems),
                              Text(
                                TTexts.loginSubTitle,
                                style: Theme.of(context).textTheme.bodyLarge,
                              ),

                              const SizedBox(height: TSizes.spaceBtwSections * 1.5),

                              // Sign in with Google or Apple — the backend
                              // detects whether this account is a rider or a
                              // driver, so there's no role switch here.
                              SizedBox(
                                width: double.infinity,
                                child: Column(
                                  children: [
                                    Obx(() => GoogleSignInButton(
                                          isLoading: controller.isGoogleLoading.value,
                                          onPressed: () =>
                                              controller.handleSocialLogin('google'),
                                        )),
                                    const SizedBox(height: TSizes.spaceBtwItems),
                                    if (_isAppleSignInAvailable)
                                      AppleSignInButton(
                                        isLoading: controller.isAppleLoading.value,
                                        onPressed: () =>
                                            controller.handleSocialLogin('apple'),
                                      ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: TSizes.spaceBtwSections),

                              // Don't have account
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    TTexts.dontHaveAccount,
                                    style: Theme.of(context).textTheme.bodyMedium,
                                  ),
                                  const SizedBox(width: 8),
                                  TextButton(
                                    onPressed: () => {
                                      Get.offAll(() => const UserTypeSelectionScreen()),
                                    },
                                    child: Text(
                                      TTexts.createAccount,
                                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                        color: TColors.primary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
