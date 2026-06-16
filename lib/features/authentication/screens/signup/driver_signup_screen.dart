// lib/features/authentication/screens/signup/driver_signup_screen.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:sarri_ride/features/authentication/controllers/driver_signup_controller.dart';
import 'package:sarri_ride/features/authentication/screens/signup/widgets/driver_auth_method_step.dart';
import 'package:sarri_ride/utils/constants/colors.dart';
import 'package:sarri_ride/utils/constants/sizes.dart';
import 'package:sarri_ride/utils/helpers/helper_functions.dart';

class DriverSignupScreen extends StatelessWidget {
  final String? email;

  const DriverSignupScreen({super.key, this.email});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(DriverSignupController());

    final dark = THelperFunctions.isDarkMode(context);

    return Scaffold(
      backgroundColor: dark ? TColors.dark : TColors.light,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Get.back(),
          icon: Icon(
            Iconsax.arrow_left_2,
            color: dark ? TColors.light : TColors.dark,
            size: TSizes.iconLg,
          ),
        ),
      ),
      body: DriverAuthMethodStep(controller: controller),
    );
  }
}
