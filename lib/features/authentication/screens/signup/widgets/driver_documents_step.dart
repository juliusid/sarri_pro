import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sarri_ride/features/authentication/controllers/driver_signup_controller.dart';
import 'package:sarri_ride/utils/constants/colors.dart';
import 'package:sarri_ride/utils/constants/sizes.dart';
import 'package:sarri_ride/utils/helpers/helper_functions.dart';

class DriverDocumentsStep extends StatelessWidget {
  const DriverDocumentsStep({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<DriverSignupController>();
    final dark = THelperFunctions.isDarkMode(context);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Iconsax.arrow_left_2),
          onPressed: () => controller.previousStep(),
        ),
        title: const Text('Upload Documents'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(TSizes.defaultSpace),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Final Step: Documents', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: TSizes.spaceBtwItems),
            Text('Please provide clear images of your documents.', style: Theme.of(context).textTheme.bodyLarge),
            const SizedBox(height: TSizes.spaceBtwSections),
            _buildImagePicker(
              context: context,
              dark: dark,
              label: 'License (Front Side)',
              imageFile: controller.frontSideImage,
              controller: controller,
            ),
            const SizedBox(height: TSizes.spaceBtwInputFields),
            _buildImagePicker(
              context: context,
              dark: dark,
              label: 'License (Back Side)',
              imageFile: controller.backSideImage,
              controller: controller,
            ),
            const SizedBox(height: TSizes.spaceBtwInputFields),
            _buildImagePicker(
              context: context,
              dark: dark,
              label: 'Profile Picture (Optional)',
              imageFile: controller.profilePicture,
              controller: controller,
              isOptional: true,
            ),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(TSizes.defaultSpace),
        child: SizedBox(
          width: double.infinity,
          child: Obx(
            () => ElevatedButton(
              onPressed: controller.isLoading.value ? null : () => controller.uploadDocuments(),
              child: controller.isLoading.value
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Finish Registration'),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImagePicker({
    required BuildContext context,
    required bool dark,
    required String label,
    required Rx<File?> imageFile,
    required DriverSignupController controller,
    bool isOptional = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(label, style: Theme.of(context).textTheme.titleMedium),
            if (isOptional)
              Text(' (Optional)', style: Theme.of(context).textTheme.bodySmall)
          ],
        ),
        const SizedBox(height: TSizes.spaceBtwItems),
        Obx(
          () => GestureDetector(
            onTap: () => _showImageSourceDialog(context, imageFile, controller),
            child: Container(
              height: 150,
              width: double.infinity,
              decoration: BoxDecoration(
                color: dark ? TColors.darkerGrey : TColors.lightGrey,
                borderRadius: BorderRadius.circular(TSizes.cardRadiusMd),
                border: Border.all(color: TColors.grey),
                image: imageFile.value != null
                    ? DecorationImage(image: FileImage(imageFile.value!), fit: BoxFit.cover)
                    : null,
              ),
              child: imageFile.value == null
                  ? const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Iconsax.camera, size: 40, color: TColors.darkGrey),
                        SizedBox(height: TSizes.spaceBtwItems),
                        Text('Tap to upload image', style: TextStyle(color: TColors.darkGrey)),
                      ],
                    )
                  : Align(
                      alignment: Alignment.bottomRight,
                      child: Container(
                        margin: const EdgeInsets.all(8),
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.5),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Iconsax.edit, color: Colors.white, size: 16),
                      ),
                    ),
            ),
          ),
        ),
      ],
    );
  }

  void _showImageSourceDialog(BuildContext context, Rx<File?> imageFile, DriverSignupController controller) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext bc) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: const Icon(Iconsax.camera),
                title: const Text('Camera'),
                onTap: () {
                  controller.pickImage(ImageSource.camera, imageFile);
                  Navigator.of(context).pop();
                },
              ),
              ListTile(
                leading: const Icon(Iconsax.gallery),
                title: const Text('Gallery'),
                onTap: () {
                  controller.pickImage(ImageSource.gallery, imageFile);
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        );
      },
    );
  }
}