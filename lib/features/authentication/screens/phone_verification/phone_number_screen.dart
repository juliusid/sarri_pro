import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:sarri_ride/common/styles/spacing_styles.dart';
import 'package:sarri_ride/common/widgets/loading_button.dart';
import 'package:sarri_ride/features/authentication/controllers/phone_verification_controller.dart';
import 'package:sarri_ride/features/authentication/services/auth_service.dart';
import 'package:sarri_ride/features/ride/widgets/map_screen_getx.dart';
import 'package:sarri_ride/utils/constants/sizes.dart';
import 'package:sarri_ride/utils/validators/validation.dart';

class PhoneNumberScreen extends StatelessWidget {
  const PhoneNumberScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Put the controller
    final controller = Get.put(PhoneVerificationController());

    return Scaffold(
      appBar: AppBar(
        title: const Text('Phone Verification'),
        actions: [
          // Logout button
          IconButton(
            icon: const Icon(Iconsax.logout),
            onPressed: () async {
              // Show confirmation dialog
              final confirmed = await Get.dialog<bool>(
                AlertDialog(
                  title: const Text('Logout'),
                  content: const Text('Are you sure you want to logout?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Logout'),
                    ),
                  ],
                ),
              );
              
              if (confirmed == true) {
                await AuthService.instance.logout();
                Get.offAllNamed('/login');
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: TSSpacingStyle.paddingWithAppBarHeight,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: TSizes.spaceBtwSections * 2),

              // Title
              Text(
                'Verify Your Phone Number',
                style: Theme.of(context).textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: TSizes.spaceBtwItems),
              Text(
                'Please enter your phone number. We will send you an OTP to verify your account.',
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: TSizes.spaceBtwSections * 2),

              // OTP Input Field
              Form(
                key: controller.formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: controller.phoneNumberController,
                      validator: TValidator.validatePhoneNumber,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'Phone Number',
                        prefixIcon: Icon(Iconsax.call),
                      ),
                    ),
                    const SizedBox(height: TSizes.spaceBtwSections),

                    // Verify Button
                    SizedBox(
                      width: double.infinity,
                      child: Obx(
                        () => LoadingElevatedButton(
                          text: 'Send OTP',
                          isLoading: controller.isLoading.value,
                          onPressed: () => controller.sendOtp(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: TSizes.spaceBtwSections),
              
              // Skip button - allows users to skip and continue using app
              TextButton(
                onPressed: () {
                  Get.dialog(
                    AlertDialog(
                      title: const Text('Skip Verification?'),
                      content: const Text('You can skip phone verification for now, but you\'ll need to verify it before booking a ride.'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                            Get.offAll(() => const MapScreenGetX());
                          },
                          child: const Text('Skip'),
                        ),
                      ],
                    ),
                  );
                },
                child: const Text('Skip for now'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
