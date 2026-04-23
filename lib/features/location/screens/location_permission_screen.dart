import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sarri_ride/features/location/services/location_service.dart';
import 'package:sarri_ride/utils/constants/colors.dart';
import 'package:sarri_ride/utils/constants/sizes.dart';
import 'package:sarri_ride/utils/helpers/helper_functions.dart';

class LocationPermissionScreen extends StatelessWidget {
  const LocationPermissionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final dark = THelperFunctions.isDarkMode(context);

    return Scaffold(
      backgroundColor: dark ? TColors.dark : TColors.light,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(TSizes.defaultSpace),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Spacer(),
              // Icon Container (mimicking the 3D map icon)
              Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  color: dark ? Colors.white : Colors.grey.shade100,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Center(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Icon(
                        Icons.map_rounded,
                        size: 80,
                        color: Colors.orange.shade300,
                      ),
                      const Positioned(
                        top: 20,
                        child: Icon(
                          Icons.location_on,
                          size: 60,
                          color: Colors.redAccent,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: TSizes.spaceBtwSections),
              // Title
              Text(
                'Enable Location Access',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: TSizes.spaceBtwItems),
              // Subtitle
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: TSizes.md),
                child: Text(
                  'Enable location services to allow the app to find rides near you and navigate efficiently.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: dark ? Colors.grey.shade400 : Colors.grey.shade600,
                        height: 1.5,
                      ),
                  textAlign: TextAlign.center,
                ),
              ),
              const Spacer(),
              // Buttons
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () async {
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.setBool('location_education_complete_v1', true);
                    Get.back();
                    await Future.delayed(const Duration(milliseconds: 300));
                    final permission = await Geolocator.requestPermission();
                    if (permission == LocationPermission.denied ||
                        permission == LocationPermission.deniedForever) {
                      THelperFunctions.showSnackBar('Location permissions are denied');
                    } else {
                      await LocationService.instance.initialize(isUserInitiated: true);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade50,
                    foregroundColor: Colors.blue.shade900,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: const Text(
                    'Allow access',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: TSizes.spaceBtwItems),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Get.back(),
                  style: TextButton.styleFrom(
                    foregroundColor: dark ? Colors.white70 : Colors.black54,
                  ),
                  child: const Text(
                    'Maybe later',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ),
              const SizedBox(height: TSizes.sm),
            ],
          ),
        ),
      ),
    );
  }
}
