import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sarri_ride/features/driver/controllers/document_upload_controller.dart';
import 'package:sarri_ride/utils/constants/colors.dart';
import 'package:sarri_ride/utils/constants/sizes.dart';

class DocumentUploadScreen extends StatelessWidget {
  const DocumentUploadScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Use Get.put to make sure controller is created
    final controller = Get.put(DocumentUploadController());

    return Scaffold(
      appBar: AppBar(title: const Text('Verify Your Documents')),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(TSizes.defaultSpace),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Upload Documents',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: TSizes.spaceBtwItems),
              Text(
                'Please upload clear JPG or PNG images (Max 5MB each).',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: TSizes.spaceBtwSections),

              // -- Driver's License --
              Text(
                'Driver\'s License',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: TSizes.spaceBtwItems),
              Row(
                children: [
                  Expanded(
                    child: _ImagePickerBox(
                      label: 'Front',
                      imageFile: controller.frontSideImage,
                      onTap: () => controller.showImageSourceDialog(
                        controller.frontSideImage,
                      ),
                    ),
                  ),
                  const SizedBox(width: TSizes.spaceBtwItems),
                  Expanded(
                    child: _ImagePickerBox(
                      label: 'Back',
                      imageFile: controller.backSideImage,
                      onTap: () => controller.showImageSourceDialog(
                        controller.backSideImage,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: TSizes.spaceBtwSections),

              // -- Vehicle Documents --
              Text(
                'Vehicle Documents',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: TSizes.spaceBtwItems),
              Row(
                children: [
                  Expanded(
                    child: _ImagePickerBox(
                      label: 'Insurance',
                      imageFile: controller.insuranceCertificate,
                      onTap: () => controller.showImageSourceDialog(
                        controller.insuranceCertificate,
                      ),
                    ),
                  ),
                  const SizedBox(width: TSizes.spaceBtwItems),
                  Expanded(
                    child: _ImagePickerBox(
                      label: 'Registration',
                      imageFile: controller.vehicleRegistration,
                      onTap: () => controller.showImageSourceDialog(
                        controller.vehicleRegistration,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: TSizes.spaceBtwSections),

              // -- Profile Picture --
              Text(
                'Profile Picture (Optional)',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: TSizes.spaceBtwItems),
              Center(
                child: _ImagePickerBox(
                  label: 'Photo',
                  imageFile: controller.profilePicture,
                  onTap: () => controller.showImageSourceDialog(
                    controller.profilePicture,
                  ),
                  isCircular: true,
                ),
              ),
              // Add extra space at bottom for scrolling past FAB/Button area
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(TSizes.defaultSpace),
        child: Obx(
          () => controller.isLoading.value
              ? const Center(child: CircularProgressIndicator())
              : SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => controller.uploadDocuments(),
                    child: const Text('Submit for Verification'),
                  ),
                ),
        ),
      ),
    );
  }
}

// --- Helper Widget for Image Selection Box ---
class _ImagePickerBox extends StatelessWidget {
  const _ImagePickerBox({
    required this.label,
    required this.onTap,
    required this.imageFile,
    this.isCircular = false,
  });

  final String label;
  final VoidCallback onTap;
  final Rx<File?> imageFile;
  final bool isCircular;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Obx(() {
        final image = imageFile.value;
        return Container(
          height: 120, // Slightly reduced height to fit more items
          width: isCircular ? 120 : double.infinity,
          decoration: BoxDecoration(
            color: Colors.grey.withOpacity(0.1),
            borderRadius: isCircular
                ? null
                : BorderRadius.circular(TSizes.cardRadiusLg),
            shape: isCircular ? BoxShape.circle : BoxShape.rectangle,
            border: Border.all(color: TColors.grey, width: 1),
            image: image != null
                ? DecorationImage(image: FileImage(image), fit: BoxFit.cover)
                : null,
          ),
          child: image == null
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      isCircular
                          ? Icons.person_add_alt_1
                          : Icons.add_a_photo_outlined,
                      color: TColors.darkGrey,
                      size: 30,
                    ),
                    const SizedBox(height: TSizes.xs),
                    Text(
                      label,
                      style: Theme.of(context).textTheme.labelMedium,
                      textAlign: TextAlign.center,
                    ),
                  ],
                )
              : null,
        );
      }),
    );
  }
}
