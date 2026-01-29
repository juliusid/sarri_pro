import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart'; // <--- 1. Import this
import 'package:sarri_ride/features/authentication/screens/user_type_selection/user_type_selection_screen.dart';

class OnBoardingController extends GetxController {
  static OnBoardingController get instance => Get.find();

  // variables
  final pageController = PageController();
  Rx<int> currentPagIndex = 0.obs;

  // update Current Index Page Scroll
  void updatePageIndicator(int index) => currentPagIndex.value = index;

  // jump to the specific dot selected page
  void dotNavigationClick(int index) {
    currentPagIndex.value = index;
    pageController.jumpToPage(index);
  }

  // Update current Index Page & jump to the page
  void nextPage() {
    if (currentPagIndex.value == 2) {
      // User finished the last page
      final storage = GetStorage();
      storage.write('IsFirstTime', false); // <--- 2. Save that they are done

      // Use offAll to prevent going back to onboarding
      Get.offAll(() => const UserTypeSelectionScreen());
    } else {
      currentPagIndex.value++;
      pageController.animateToPage(
        currentPagIndex.value,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeIn,
      );
    }
  }

  // Update current Index Page & jump to the last page
  void skipPage() {
    final storage = GetStorage();
    storage.write('IsFirstTime', false); // <--- 3. Save that they are done

    Get.offAll(() => const UserTypeSelectionScreen());
  }
}
