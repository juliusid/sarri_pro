import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:sarri_ride/features/authentication/controllers/forgot_password_controller.dart';
import 'package:sarri_ride/utils/constants/sizes.dart';
import 'package:sarri_ride/utils/constants/text_strings.dart';
import 'package:sarri_ride/utils/validators/validation.dart';

class ForgotPasswordScreen extends StatelessWidget {
  const ForgotPasswordScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(ForgotPasswordController());
    return Scaffold(
      appBar: AppBar(),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(TSizes.defaultSpace),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Headings
              Text(TTexts.forgetPasswordTitle, style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: TSizes.spaceBtwItems),
              Text(TTexts.forgetPasswordSubTitle, style: Theme.of(context).textTheme.labelMedium),
              const SizedBox(height: TSizes.spaceBtwSections * 2),

              // Text field
              Form(
                key: controller.emailFormKey,
                child: TextFormField(
                  controller: controller.emailController,
                  validator: TValidator.validateEmail,
                  decoration: const InputDecoration(
                    labelText: TTexts.email,
                    prefixIcon: Icon(Iconsax.direct_right),
                  ),
                ),
              ),
              const SizedBox(height: TSizes.spaceBtwSections),

              // Submit Button
              SizedBox(
                width: double.infinity,
                child: Obx(
                  () => ElevatedButton(
                    onPressed: controller.isLoading.value ? null : () => controller.sendPasswordResetEmail(),
                    child: controller.isLoading.value
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('Submit'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}