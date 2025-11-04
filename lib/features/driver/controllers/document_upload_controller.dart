import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sarri_ride/features/authentication/screens/login/login_screen_getx.dart';
import 'package:sarri_ride/utils/helpers/helper_functions.dart';

class DocumentUploadController extends GetxController {
  static DocumentUploadController get instance => Get.find();

  final RxBool isLoading = false.obs;

  // Document Variables
  final Rx<File?> frontSideImage = Rx<File?>(null);
  final Rx<File?> backSideImage = Rx<File?>(null);
  final Rx<File?> profilePicture = Rx<File?>(null);

  // --- Image Picker ---
  Future<void> pickImage(ImageSource source, Rx<File?> imageFile) async {
    final pickedFile = await ImagePicker().pickImage(source: source);
    if (pickedFile != null) {
      imageFile.value = File(pickedFile.path);
    }
  }

  void showImageSourceDialog(Rx<File?> imageFile) {
    Get.bottomSheet(
      Container(
        color: Colors.white,
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
        'Please upload the front and back images of your driver\'s license.',
      );
      return;
    }
    if (profilePicture.value == null) {
      THelperFunctions.showSnackBar('Please upload a profile picture.');
      return;
    }

    isLoading.value = true;

    try {
      //
      // NOTE: The API endpoint for document upload will be added here later.
      // This is a placeholder for how you would call it.
      // You will need a method in your service that handles multipart/form-data.
      //
      print("Simulating document upload...");
      print("Front Image: ${frontSideImage.value!.path}");
      print("Back Image: ${backSideImage.value!.path}");
      print("Profile Picture: ${profilePicture.value!.path}");

      // Simulate network delay
      await Future.delayed(const Duration(seconds: 3));

      // On success:
      THelperFunctions.showSnackBar(
        'Documents uploaded successfully! Your application is now under review.',
      );

      // Redirect user, perhaps to the dashboard or a "pending review" screen
      // For now, we'll just pop the screen. You might want to navigate somewhere specific.
      Get.back();
    } catch (e) {
      THelperFunctions.showSnackBar("An error occurred during upload: $e");
    } finally {
      isLoading.value = false;
    }
  }
}
