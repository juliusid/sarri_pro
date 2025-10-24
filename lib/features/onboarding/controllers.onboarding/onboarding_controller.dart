import 'package:flutter/material.dart';
import 'package:get/get.dart';
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
      Get.to(() => const UserTypeSelectionScreen());
    } else {
      currentPagIndex.value++;
      pageController.jumpToPage(currentPagIndex.value);
    }
  }

  // Update current Index Page & jump to the last page
  void skipPage() {
    Get.to(() => const UserTypeSelectionScreen());
  }
}
