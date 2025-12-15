import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart'; // For MediaType
import 'package:flutter_image_compress/flutter_image_compress.dart'; // For converting to JPEG
import 'package:path_provider/path_provider.dart'; // For temp folders
import 'package:path/path.dart' as p; // For path manipulation

import 'package:sarri_ride/config/api_config.dart';
import 'package:sarri_ride/features/authentication/services/auth_service.dart';
import 'package:sarri_ride/features/ride/controllers/drawer_controller.dart';
import 'package:sarri_ride/utils/helpers/helper_functions.dart';

class ProfileController extends GetxController {
  static ProfileController get instance => Get.find();

  final RxBool isLoading = false.obs;
  final Rx<File?> selectedImage = Rx<File?>(null);

  /// Shows a dialog to select image from Camera or Gallery
  void showImageSourceDialog() {
    Get.bottomSheet(
      Container(
        color: Get.isDarkMode ? Colors.black87 : Colors.white,
        child: Wrap(
          children: <Widget>[
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Photo Library'),
              onTap: () {
                _pickImage(ImageSource.gallery);
                Get.back();
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera),
              title: const Text('Camera'),
              onTap: () {
                _pickImage(ImageSource.camera);
                Get.back();
              },
            ),
          ],
        ),
      ),
    );
  }

  /// 1. Pick Image -> 2. Convert to JPEG -> 3. Upload
  Future<void> _pickImage(ImageSource source) async {
    try {
      final pickedFile = await ImagePicker().pickImage(source: source);

      if (pickedFile != null) {
        // --- STEP 1: CONVERT TO CLEAN JPEG ---
        // This ensures the backend always gets a standard .jpg file
        File? cleanFile = await _convertToCleanJpeg(File(pickedFile.path));

        if (cleanFile != null) {
          selectedImage.value = cleanFile;
          // --- STEP 2: UPLOAD IMMEDIATELY ---
          await uploadProfilePicture();
        }
      }
    } catch (e) {
      THelperFunctions.showErrorSnackBar("Error", "Could not pick image: $e");
    }
  }

  /// Helper: Converts any image (png, heic, webp) to a standard JPG
  Future<File?> _convertToCleanJpeg(File originalFile) async {
    try {
      final dir = await getTemporaryDirectory();
      // Create a unique name ending in .jpg
      final targetPath = p.join(
        dir.path,
        "profile_${DateTime.now().millisecondsSinceEpoch}.jpg",
      );

      // Compress and convert format
      var result = await FlutterImageCompress.compressAndGetFile(
        originalFile.absolute.path,
        targetPath,
        quality: 85, // Good quality, optimized size
        format: CompressFormat.jpeg, // Force JPEG format
      );

      if (result != null) {
        return File(result.path);
      }
      return originalFile; // Fallback if compression fails
    } catch (e) {
      print("Compression error: $e");
      return originalFile; // Fallback
    }
  }

  Future<void> uploadProfilePicture() async {
    if (selectedImage.value == null) return;

    isLoading.value = true;

    try {
      final file = selectedImage.value!;

      // We KNOW it is a jpeg now because we converted it.
      final contentType = MediaType('image', 'jpeg');

      // Prepare Request
      // Combine base URL + endpoint
      final uri = Uri.parse(ApiConfig.updateProfilePictureEndpoint);
      var request = http.MultipartRequest('PUT', uri);

      // Add File
      request.files.add(
        await http.MultipartFile.fromPath(
          'picture', // Key expected by backend
          file.path,
          contentType: contentType, // Explicitly tell server it's a JPEG
        ),
      );
      print("-------------------------------------------------${file.path}");

      // Add Headers (Authorization)
      final token = AuthService.instance.accessToken;
      if (token != null) {
        request.headers['Authorization'] = 'Bearer $token';
      }

      // Send Request
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      // Handle Response
      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = jsonDecode(response.body);

        if (responseData['success'] == true) {
          final data = responseData['data'];
          if (data != null) {
            final newPicUrl = data['picture'] as String?;
            final newFirstName = data['FirstName'] as String?;
            final newLastName = data['LastName'] as String?;
            _updateLocalProfile(newPicUrl, newFirstName, newLastName);
          }
          THelperFunctions.showSuccessSnackBar(
            'Success',
            'Profile picture updated!',
          );
          selectedImage.value = null;
        } else {
          THelperFunctions.showErrorSnackBar(
            'Upload Failed',
            responseData['message'] ?? 'Unknown error',
          );
        }
      } else {
        THelperFunctions.showErrorSnackBar(
          'Upload Failed',
          'Server rejected the file (Status: ${response.statusCode})',
        );
      }
    } catch (e) {
      THelperFunctions.showErrorSnackBar('Error', 'An error occurred: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// Updates the Drawer Controller so the new image shows up instantly
  void _updateLocalProfile(String? newPicUrl, String? fName, String? lName) {
    if (Get.isRegistered<MapDrawerController>()) {
      final drawerController = Get.find<MapDrawerController>();

      if (newPicUrl != null && drawerController.fullProfile.value != null) {
        drawerController.fullProfile.value = drawerController.fullProfile.value!
            .copyWith(picture: newPicUrl);
      }
      if (fName != null && lName != null) {
        drawerController.userName.value = "$fName $lName";
      }

      drawerController.fullProfile.refresh();
      drawerController.userName.refresh();
    }
  }
}
