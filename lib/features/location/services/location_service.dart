import 'dart:io'; // Required for Platform check
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sarri_ride/utils/constants/colors.dart';
import 'package:sarri_ride/utils/constants/sizes.dart';
import 'package:sarri_ride/utils/helpers/helper_functions.dart';

class LocationService extends GetxController {
  static LocationService get instance => Get.find();

  // Reactive variables
  final Rx<Position?> _currentPosition = Rx<Position?>(null);
  final RxBool _isLocationEnabled = false.obs;
  final RxBool _isLocationLoading = false.obs;
  final RxString _locationStatus = 'Available'.obs;

  // Default location (Lagos, Nigeria)
  static final Position _defaultPosition = Position(
    latitude: 6.5244,
    longitude: 3.3792,
    timestamp: DateTime.now(),
    accuracy: 0,
    altitude: 0,
    altitudeAccuracy: 0,
    heading: 0,
    headingAccuracy: 0,
    speed: 0,
    speedAccuracy: 0,
  );

  // Getters
  Position? get currentPosition => _currentPosition.value;
  bool get isLocationEnabled => _isLocationEnabled.value;
  bool get isLocationLoading => _isLocationLoading.value;
  String get locationStatus => _locationStatus.value;

  @override
  void onInit() {
    super.onInit();
    _currentPosition.value = _defaultPosition;
  }

  /// --- 1. ENSURE LOCATION AVAILABLE ---
  Future<bool> ensureLocationAvailable({bool isDriver = false}) async {
    bool serviceEnabled;
    LocationPermission permission;

    // A. Check System GPS Service
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _locationStatus.value = 'GPS is turned off.';
      THelperFunctions.showSnackBar('Please enable Location Services (GPS).');
      await Geolocator.openLocationSettings();
      return false;
    }

    // B. Check Foreground Permission (Basic)
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        _locationStatus.value = 'Permission denied.';
        THelperFunctions.showSnackBar('Location permissions are denied');
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      _locationStatus.value = 'Permission permanently denied.';
      THelperFunctions.showSnackBar('Please enable location in App Settings.');
      await Geolocator.openAppSettings();
      return false;
    }

    // C. Driver "Background" Check (Google Policy Requirement)
    if (isDriver && Platform.isAndroid) {
      var backgroundStatus = await Permission.locationAlways.status;

      if (!backgroundStatus.isGranted) {
        bool userAccepted = false;

        // --- 1. Show the "Prominent Disclosure" Bottom Sheet ---
        await Get.bottomSheet(
          Container(
            padding: const EdgeInsets.all(TSizes.defaultSpace),
            decoration: BoxDecoration(
              color: THelperFunctions.isDarkMode(Get.context!)
                  ? TColors.dark
                  : TColors.white,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: TColors.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Iconsax.map_1,
                    size: 40,
                    color: TColors.primary,
                  ),
                ),
                const SizedBox(height: TSizes.spaceBtwItems),
                Text(
                  "Location Access Required",
                  style: Theme.of(Get.context!).textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: TSizes.spaceBtwItems),
                Text(
                  "To enable ride tracking and fare calculation while you navigate or use other apps, Sarri Ride collects location data even when the app is closed or not in use.",
                  style: Theme.of(Get.context!).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: TSizes.spaceBtwSections),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      userAccepted = true;
                      Get.back(); // Close sheet
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: TColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text("Allow All The Time"),
                  ),
                ),
                const SizedBox(height: TSizes.spaceBtwItems),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () {
                      userAccepted = false;
                      Get.back();
                    },
                    child: Text(
                      "No, Thanks",
                      style: TextStyle(
                        color: THelperFunctions.isDarkMode(Get.context!)
                            ? TColors.darkGrey
                            : TColors.darkGrey,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          isDismissible: false,
          enableDrag: false,
        );

        // --- 2. Handle Logic with DELAY (The Fix) ---
        if (userAccepted) {
          // Wait for the BottomSheet close animation to finish
          await Future.delayed(const Duration(milliseconds: 300));

          // Now execute the request
          var status = await Permission.locationAlways.request();

          // If request failed/blocked, Force Open Settings
          if (!status.isGranted) {
            THelperFunctions.showSnackBar(
              'Please select "Allow all the time" in Settings.',
            );
            await Geolocator.openAppSettings();
          }
        }

        // --- 3. Final Verification ---
        if (!await Permission.locationAlways.isGranted) {
          THelperFunctions.showSnackBar(
            'You cannot go online without "Always Allow" location permission.',
          );
          return false;
        }
      }
    }

    _isLocationEnabled.value = true;
    return true;
  }

  /// --- 2. INITIALIZATION ---
  Future<void> initialize({bool isDriver = false}) async {
    _isLocationLoading.value = true;
    _locationStatus.value = 'Verifying GPS...';
    update();

    try {
      bool isReady = await ensureLocationAvailable(isDriver: isDriver);
      if (!isReady) {
        _isLocationLoading.value = false;
        update();
        return;
      }

      _locationStatus.value = 'Fetching position...';
      update();

      Position? lastPosition = await Geolocator.getLastKnownPosition();
      if (lastPosition != null) {
        _currentPosition.value = lastPosition;
        update();
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.bestForNavigation,
        timeLimit: const Duration(seconds: 25),
      );

      _currentPosition.value = position;
      _locationStatus.value = 'Location ready!';
    } catch (e) {
      _locationStatus.value = 'Timeout using last known location.';
      if (_currentPosition.value == null) {
        _currentPosition.value = _defaultPosition;
      }
    } finally {
      _isLocationLoading.value = false;
      update();
    }
  }

  /// --- 3. GET CURRENT LOCATION ---
  Future<Position?> getCurrentLocation({bool isDriver = false}) async {
    bool isReady = await ensureLocationAvailable(isDriver: isDriver);
    if (!isReady) return _currentPosition.value ?? _defaultPosition;

    try {
      _isLocationLoading.value = true;
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.bestForNavigation,
        timeLimit: const Duration(seconds: 15),
      );
      _currentPosition.value = position;
      return position;
    } catch (e) {
      return _currentPosition.value ?? _defaultPosition;
    } finally {
      _isLocationLoading.value = false;
    }
  }

  // --- Helpers ---
  Position getLocationForMap() {
    return _currentPosition.value ?? _defaultPosition;
  }

  Future<bool> requestLocationPermission() async {
    return await ensureLocationAvailable();
  }

  double calculateDistance(Position start, Position end) {
    try {
      return Geolocator.distanceBetween(
        start.latitude,
        start.longitude,
        end.latitude,
        end.longitude,
      );
    } catch (e) {
      return 0.0;
    }
  }

  Future<void> refreshLocation() async {
    await initialize();
  }
}
