import 'dart:io'; // Required for Platform check
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sarri_ride/utils/constants/colors.dart';
import 'package:sarri_ride/utils/constants/sizes.dart';
import 'package:sarri_ride/utils/helpers/helper_functions.dart';

/// Persists that the user saw the in-app location explanation and chose to continue
/// (so we only show it once before the first system permission prompt).
const String _kLocationEducationComplete = 'location_education_complete_v1';

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

  /// In-app explanation before the first system location prompt (App Store 5.1.1).
  /// Returns false if the user chooses not to continue (no system dialog).
  Future<bool> _showForegroundLocationEducationIfNeeded() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_kLocationEducationComplete) == true) {
      return true;
    }
    final context = Get.context;
    if (context == null || !context.mounted) {
      return true;
    }
    final accepted = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Location'),
        content: const Text(
          'Sarri Ride uses your location to show the map, set pickups and destinations, and match you with rides. You can change this anytime in Settings.',
        ),
        actions: [
          TextButton(
            // onPressed: () => Get.back(result: false),
            onPressed: () =>  Navigator.of(Get.context!).pop(false),
            child: const Text('Not now'),
          ),
          ElevatedButton(
            onPressed: () =>  Navigator.of(Get.context!).pop(true),
            // onPressed: () => Get.back(result: true),
            style: ElevatedButton.styleFrom(backgroundColor: TColors.primary),
            child: const Text('Continue'),
          ),
        ],
      ),
      barrierDismissible: false,
    );
    if (accepted != true) {
      return false;
    }
    await prefs.setBool(_kLocationEducationComplete, true);
    return true;
  }

  Future<void> _offerOpenLocationServicesSettings(String message) async {
    final context = Get.context;
    if (context == null || !context.mounted) {
      THelperFunctions.showSnackBar(
        'Please enable Location Services (GPS) in Settings when you’re ready.',
      );
      return;
    }
    await Get.dialog<void>(
      AlertDialog(
        title: const Text('Location Services off'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Not now'),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              Geolocator.openLocationSettings();
            },
            style: ElevatedButton.styleFrom(backgroundColor: TColors.primary),
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  Future<void> _offerOpenAppSettings({
    required String title,
    required String message,
  }) async {
    final context = Get.context;
    if (context == null || !context.mounted) {
      THelperFunctions.showSnackBar(
        'Location is turned off for this app. You can enable it in Settings when you’re ready.',
      );
      return;
    }
    await Get.dialog<void>(
      AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Not now'),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              Geolocator.openAppSettings();
            },
            style: ElevatedButton.styleFrom(backgroundColor: TColors.primary),
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  /// --- 1. GET POSITION STREAM (THE GOOGLE REQUIREMENT) ---
  /// This is the stream that keeps the app alive in the background
  /// and shows the notification required by Play Console.
  Stream<Position> getPositionStream() {
    late LocationSettings locationSettings;

    if (Platform.isAndroid) {
      locationSettings = AndroidSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: 10, // Update every 10 meters
        forceLocationManager: true,
        intervalDuration: const Duration(seconds: 3),
        // [IMPORTANT] This config triggers the persistent notification
        foregroundNotificationConfig: const ForegroundNotificationConfig(
          notificationTitle: "Sarri Driver",
          notificationText: "Tracking your trip in real-time",
          notificationIcon: AndroidResource(name: 'launcher_icon'),
          enableWakeLock: true, // Prevents CPU from sleeping
        ),
      );
    } else if (Platform.isIOS) {
      locationSettings = AppleSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        activityType: ActivityType.automotiveNavigation,
        distanceFilter: 10,
        pauseLocationUpdatesAutomatically: false,
        showBackgroundLocationIndicator: true,
      );
    } else {
      locationSettings = const LocationSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: 10,
      );
    }

    return Geolocator.getPositionStream(locationSettings: locationSettings);
  }

  /// --- 2. ENSURE LOCATION AVAILABLE ---
  Future<bool> ensureLocationAvailable({bool isDriver = false}) async {
    bool serviceEnabled;
    LocationPermission permission;

    // A. Check System GPS Service
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _locationStatus.value = 'GPS is turned off.';
      await _offerOpenLocationServicesSettings(
        'Turn on Location Services in Settings to use maps, pickups, and ride features.',
      );
      return false;
    }

    // B. Check Foreground Permission (Basic)
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      final proceed = await _showForegroundLocationEducationIfNeeded();
      if (!proceed) {
        _locationStatus.value = 'Location not enabled.';
        return false;
      }
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        _locationStatus.value = 'Permission denied.';
        THelperFunctions.showSnackBar('Location permissions are denied');
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      _locationStatus.value = 'Permission permanently denied.';
      await _offerOpenAppSettings(
        title: 'Location access needed',
        message:
            'Sarri Ride needs location for maps and rides. You can enable it in Settings when you’re ready.',
      );
      return false;
    }

    // C. Driver Checks (Google Policy Requirements)
    if (isDriver && Platform.isAndroid) {
      // 1. NOTIFICATION PERMISSION (Android 13+) - CRITICAL FOR FOREGROUND SERVICE
      if (await Permission.notification.isDenied) {
        await Permission.notification.request();
      }

      // 2. BACKGROUND LOCATION CHECK
      var backgroundStatus = await Permission.locationAlways.status;

      if (!backgroundStatus.isGranted) {
        bool userAccepted = false;

        // --- Show the "Prominent Disclosure" Bottom Sheet ---
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

        // --- Handle Logic with DELAY ---
        if (userAccepted) {
          await Future.delayed(const Duration(milliseconds: 300));
          var status = await Permission.locationAlways.request();

          if (!status.isGranted) {
            await _offerOpenAppSettings(
              title: 'Allow all the time',
              message:
                  'To track trips in the background, choose "Allow all the time" for location in Settings.',
            );
          }
        }

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

  /// --- 3. INITIALIZATION ---
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

  /// --- 4. GET CURRENT LOCATION ---
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
