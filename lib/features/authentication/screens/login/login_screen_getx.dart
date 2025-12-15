// lib/features/authentication/screens/login/login_screen_getx.dart

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sarri_ride/common/styles/spacing_styles.dart';
import 'package:sarri_ride/features/authentication/controllers/login_controller.dart';
import 'package:sarri_ride/features/authentication/screens/user_type_selection/user_type_selection_screen.dart';
import 'package:sarri_ride/features/authentication/widgets/google_button.dart';
import 'package:sarri_ride/features/authentication/widgets/social_media_button.dart';
import 'package:sarri_ride/utils/constants/colors.dart';
import 'package:iconsax/iconsax.dart';
import 'package:sarri_ride/utils/constants/sizes.dart';
import 'package:sarri_ride/utils/constants/text_strings.dart';
import 'package:sarri_ride/utils/helpers/helper_functions.dart';
import 'package:sarri_ride/utils/validators/validation.dart';
import 'package:sarri_ride/features/authentication/screens/forgot_password/forgot_password_screen.dart';
import 'package:sarri_ride/utils/constants/enums.dart'; // Import Enums
import 'package:sarri_ride/common/widgets/loading_button.dart'; // <-- 1. IMPORT YOUR NEW WIDGET

// --- CONVERT TO STATEFULWIDGET ---
class LoginScreenGetX extends StatefulWidget {
  const LoginScreenGetX({super.key});

  @override
  State<LoginScreenGetX> createState() => _LoginScreenGetXState();
}

class _LoginScreenGetXState extends State<LoginScreenGetX> {
  // --- MANUALLY CREATE AND MANAGE THE CONTROLLER ---
  late final LoginController controller;

  @override
  void initState() {
    super.initState();
    // Create a fresh instance of the controller every time the screen is initialized
    controller = Get.put(LoginController());
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
        body: SingleChildScrollView(
          child: Padding(
            padding: TSSpacingStyle.paddingWithAppBarHeight,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                //  Back Button
                IconButton(
                  onPressed: () => Get.back(),
                  icon: Icon(
                    Iconsax.arrow_left_2,
                    color: dark ? TColors.light : TColors.dark,
                    size: TSizes.iconLg,
                  ),
                ),
                const SizedBox(height: TSizes.spaceBtwSections),
                // Login Title
                Text(
                  TTexts.loginTitle,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),

                const SizedBox(height: TSizes.spaceBtwItems),

                Text(
                  TTexts.loginSubTitle,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),

                const SizedBox(height: TSizes.spaceBtwSections),
                // --- NEW: ROLE SELECTION ---
                Obx(
                  () => CupertinoSlidingSegmentedControl<UserType>(
                    groupValue: controller.selectedRole.value,
                    backgroundColor: dark
                        ? TColors.darkerGrey
                        : TColors.lightGrey,
                    thumbColor: TColors.primary,
                    padding: const EdgeInsets.all(TSizes.xs),
                    children: {
                      UserType.rider: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                        child: Text(
                          'Rider',
                          style: TextStyle(
                            color:
                                controller.selectedRole.value == UserType.rider
                                ? Colors.white
                                : (dark ? TColors.lightGrey : TColors.darkGrey),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      UserType.driver: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                        child: Text(
                          'Driver',
                          style: TextStyle(
                            color:
                                controller.selectedRole.value == UserType.driver
                                ? Colors.white
                                : (dark ? TColors.lightGrey : TColors.darkGrey),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    },
                    onValueChanged: (UserType? value) {
                      if (value != null) {
                        controller.setSelectedRole(value);
                      }
                    },
                  ),
                ),
                const SizedBox(height: TSizes.spaceBtwSections),

                // Form
                Form(
                  key: controller.formKey,
                  child: Column(
                    children: [
                      // Email
                      TextFormField(
                        controller: controller.emailController,
                        validator: TValidator.validateEmail,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          labelText: TTexts.email,
                          prefixIcon: Icon(
                            Iconsax.sms,
                            color: dark ? TColors.light : TColors.dark,
                            size: TSizes.iconMd,
                          ),
                        ),
                      ),

                      const SizedBox(height: TSizes.spaceBtwInputFields),

                      // Password with Obx for reactive updates
                      Obx(
                        () => TextFormField(
                          controller: controller.passwordController,
                          validator: TValidator.validatePassword,
                          obscureText: controller.obscurePassword.value,
                          decoration: InputDecoration(
                            labelText: TTexts.password,
                            prefixIcon: Icon(
                              Iconsax.password_check,
                              color: dark ? TColors.light : TColors.dark,
                              size: TSizes.iconMd,
                            ),
                            suffixIcon: IconButton(
                              onPressed: controller.togglePasswordVisibility,
                              icon: Icon(
                                controller.obscurePassword.value
                                    ? Iconsax.eye_slash
                                    : Iconsax.eye,
                                color: dark ? TColors.light : TColors.dark,
                                size: TSizes.iconMd,
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: TSizes.spaceBtwInputFields),

                      // Forgot Password
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () =>
                              Get.to(() => const ForgotPasswordScreen()),
                          child: Text(
                            TTexts.forgetPassword,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                      ),

                      const SizedBox(height: TSizes.spaceBtwSections),

                      // --- 2. REPLACE THE BUTTON ---
                      // Login Button with Obx for loading state
                      SizedBox(
                        width: double.infinity,
                        child: Obx(
                          () => LoadingElevatedButton(
                            isLoading: controller.isEmailLoading.value,
                            text: TTexts.signIn,
                            loadingText: 'Signing In...',
                            onPressed: () => controller.handleLogin(),
                            backgroundColor: TColors.primary,
                            foregroundColor: TColors.white,
                          ),
                        ),
                      ),
                      // --- END OF REPLACEMENT ---
                    ],
                  ),
                ),

                const SizedBox(height: TSizes.spaceBtwSections),

                // Divider
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Flexible(
                      child: Divider(
                        color: dark ? TColors.darkGrey : TColors.grey,
                        thickness: .5,
                        indent: 60,
                        endIndent: 5,
                      ),
                    ),
                    const Text(TTexts.orSignInWith),
                    Flexible(
                      child: Divider(
                        color: dark ? TColors.darkGrey : TColors.grey,
                        thickness: .5,
                        indent: 5,
                        endIndent: 60,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: TSizes.spaceBtwSections),

                // Sign in Options with Obx for loading state
                Column(
                  children: [
                    Obx(
                      () => GoogleSignInButton(
                        isLoading: controller.isGoogleLoading.value,
                        onPressed: () => controller.handleSocialLogin('google'),
                      ),
                    ),
                    // const SizedBox(height: TSizes.spaceBtwItems),
                    // Obx(
                    //   () => SocialButton(
                    //     // Keep the Facebook button as is
                    //     text: 'Facebook',
                    //     icon: const Icon(Icons.facebook, size: 24),
                    //     backgroundColor: TColors.info,
                    //     textColor: Colors.white,
                    //     isLoading: controller.isFacebookLoading.value,
                    //     onPressed: () =>
                    //         controller.handleSocialLogin('facebook'),
                    //   ),
                    // ),
                  ],
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
                // to be removed in production
                // const SizedBox(height: TSizes.spaceBtwItems),
                // Align(
                //   alignment: Alignment.center,
                //   child: TextButton(
                //     onPressed: () => controller.hardReset(),
                //     child: Text(
                //       'Hard Reset / Clear Storage',
                //       style: Theme.of(context).textTheme.bodySmall?.copyWith(
                //         color: TColors.error,
                //         decoration: TextDecoration.underline,
                //       ),
                //     ),
                //   ),
                // ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
