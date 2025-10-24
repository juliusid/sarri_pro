import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:sarri_ride/features/authentication/controllers/forgot_password_controller.dart';
import 'package:sarri_ride/utils/constants/sizes.dart';
import 'package:sarri_ride/utils/validators/validation.dart';

class ResetPasswordScreen extends StatelessWidget {
  const ResetPasswordScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<ForgotPasswordController>();
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        actions: [IconButton(onPressed: () => Get.back(), icon: const Icon(Icons.close))],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(TSizes.defaultSpace),
          child: Column(
            children: [
              // Heading
              Text(
                'Reset Your Password',
                style: Theme.of(context).textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: TSizes.spaceBtwItems),
              Text(
                'Enter the code sent to your email and set a new password.',
                style: Theme.of(context).textTheme.labelMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: TSizes.spaceBtwSections),

              // Form
              Form(
                key: controller.passwordFormKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: controller.resetCodeController,
                      keyboardType: TextInputType.number,
                      validator: (value) => TValidator.validateEmptyText('Reset Code', value),
                      decoration: const InputDecoration(labelText: 'Reset Code', prefixIcon: Icon(Iconsax.code)),
                    ),
                    const SizedBox(height: TSizes.spaceBtwInputFields),
                    TextFormField(
                      controller: controller.passwordController,
                      validator: TValidator.validatePassword,
                      obscureText: true,
                      decoration: const InputDecoration(labelText: 'New Password', prefixIcon: Icon(Iconsax.password_check)),
                    ),
                    const SizedBox(height: TSizes.spaceBtwInputFields),
                    TextFormField(
                      controller: controller.confirmPasswordController,
                      validator: TValidator.validatePassword,
                      obscureText: true,
                      decoration: const InputDecoration(labelText: 'Confirm New Password', prefixIcon: Icon(Iconsax.password_check)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: TSizes.spaceBtwSections),

              // Button
              SizedBox(
                width: double.infinity,
                child: Obx(
                  () => ElevatedButton(
                    onPressed: controller.isLoading.value ? null : () => controller.resetPassword(),
                    child: controller.isLoading.value
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('Reset Password'),
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