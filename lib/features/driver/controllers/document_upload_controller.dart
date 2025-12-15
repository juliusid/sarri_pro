import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sarri_ride/features/authentication/services/auth_service.dart'; // Import AuthService
import 'package:sarri_ride/features/driver/screens/driver_dashboard_screen.dart'; // Or wherever you navigate after
import 'package:sarri_ride/utils/helpers/helper_functions.dart';

class DocumentUploadController extends GetxController {
  static DocumentUploadController get instance => Get.find();

  final RxBool isLoading = false.obs;

  // Document Variables
  final Rx<File?> frontSideImage = Rx<File?>(null);
  final Rx<File?> backSideImage = Rx<File?>(null);
  final Rx<File?> profilePicture = Rx<File?>(null);

  // --- ADDED NEW FIELDS ---
  final Rx<File?> insuranceCertificate = Rx<File?>(null);
  final Rx<File?> vehicleRegistration = Rx<File?>(null);

  // --- Image Picker ---
  Future<void> pickImage(ImageSource source, Rx<File?> imageFile) async {
    final pickedFile = await ImagePicker().pickImage(
      source: source,
      imageQuality: 80, // Compress slightly to stay under 5MB
    );

    if (pickedFile != null) {
      // Basic check for file extension (User requirement: Only JPG/PNG)
      final String path = pickedFile.path.toLowerCase();
      if (path.endsWith('.jpg') ||
          path.endsWith('.jpeg') ||
          path.endsWith('.png')) {
        imageFile.value = File(pickedFile.path);
      } else {
        THelperFunctions.showErrorSnackBar(
          'Invalid Format',
          'Please select a JPG or PNG image.',
        );
      }
    }
  }

  void showImageSourceDialog(Rx<File?> imageFile) {
    Get.bottomSheet(
      Container(
        color: Get.isDarkMode ? Colors.black87 : Colors.white,
        child: Wrap(
          children: <Widget>[
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Photo Library'),
              onTap: () {
                pickImage(ImageSource.gallery, imageFile);
                Get.back();
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera),
              title: const Text('Camera'),
              onTap: () {
                pickImage(ImageSource.camera, imageFile);
                Get.back();
              },
            ),
          ],
        ),
      ),
    );
  }

  // --- API Call ---
  Future<void> uploadDocuments() async {
    // 1. Validation
    if (frontSideImage.value == null || backSideImage.value == null) {
      THelperFunctions.showSnackBar(
        'Please upload both sides of your license.',
      );
      return;
    }
    if (insuranceCertificate.value == null) {
      THelperFunctions.showSnackBar(
        'Please upload your insurance certificate.',
      );
      return;
    }
    if (vehicleRegistration.value == null) {
      THelperFunctions.showSnackBar('Please upload your vehicle registration.');
      return;
    }
    // Profile picture is optional in the API, but usually good to have.
    // We will proceed even if null, or you can enforce it.

    isLoading.value = true;

    try {
      final result = await AuthService.instance.uploadDriverDocuments(
        frontsideImage: frontSideImage.value!,
        backsideImage: backSideImage.value!,
        insuranceCertificate: insuranceCertificate.value!,
        vehicleRegistration: vehicleRegistration.value!,
        picture: profilePicture.value,
      );

      if (result.success) {
        THelperFunctions.showSuccessSnackBar(
          'Success',
          'Documents uploaded successfully! Your account is under review.',
        );
        // Navigate to Dashboard (where they will see the "Pending" banner)
        Get.offAll(() => const DriverDashboardScreen());
      } else {
        THelperFunctions.showErrorSnackBar(
          'Upload Failed',
          result.error ?? 'Unknown error occurred',
        );
      }
    } catch (e) {
      THelperFunctions.showErrorSnackBar("Error", e.toString());
    } finally {
      isLoading.value = false;
    }
  }
}
