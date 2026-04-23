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
import 'package:sarri_ride/features/location/screens/location_permission_screen.dart';

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
  /// Shows a full-screen educational page that handles the permission request.
  Future<bool> _showForegroundLocationEducationIfNeeded() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_kLocationEducationComplete) == true) {
      return true;
    }
    final context = Get.context;
    if (context == null || !context.mounted) {
      return true;
    }

    try {
      // Navigate to the location permission screen as a full page
      // The screen will handle the permission request internally
      await Navigator.of(context).push<void>(
        MaterialPageRoute(
          builder: (context) => const LocationPermissionScreen(),
        ),
      );
      
      // After the user returns from the screen, mark education as complete
      // (whether they granted permission or not)
      await prefs.setBool(_kLocationEducationComplete, true);
      return true;
    } catch (e) {
      debugPrint('Error showing location permission screen: $e');
      // If navigation fails, mark as complete anyway to avoid infinite loop
      await prefs.setBool(_kLocationEducationComplete, true);
      return true;
    }
  }

  Future<void> _offerOpenLocationServicesSettings(String message) async {
    final context = Get.context;
    if (context == null || !context.mounted) {
      THelperFunctions.showSnackBar(
        'Please enable Location Services (GPS) in Settings when you’re ready.',
      );
      return;
    }
    try {
      await showDialog<void>(
        context: context,
        builder: (BuildContext dialogContext) {
          return AlertDialog(
            title: const Text('Location Services off'),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('Not now'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                  Geolocator.openLocationSettings();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: TColors.primary,
                ),
                child: const Text('Open Settings'),
              ),
            ],
          );
        },
      );
    } catch (e) {
      debugPrint('Error showing location services dialog: $e');
      THelperFunctions.showSnackBar(
        'Please enable Location Services (GPS) in Settings when you\'re ready.',
      );
    }
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
    try {
      await showDialog<void>(
        context: context,
        builder: (BuildContext dialogContext) {
          return AlertDialog(
            title: Text(title),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('Not now'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                  Geolocator.openAppSettings();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: TColors.primary,
                ),
                child: const Text('Open Settings'),
              ),
            ],
          );
        },
      );
    } catch (e) {
      debugPrint('Error showing app settings dialog: $e');
      THelperFunctions.showSnackBar(
        'Location is turned off for this app. You can enable it in Settings when you\'re ready.',
      );
    }
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
  ///
  /// [isUserInitiated] – set to `true` when the user **actively** taps a
  /// feature that requires location (e.g. "Book a Ride", "Go Online").
  /// When `false` (the default, used during app startup / background refresh),
  /// a denied-forever permission will only show a lightweight snackbar instead
  /// of a dialog that links to Settings — satisfying App Store Guideline 5.1.1(iv).
  Future<bool> ensureLocationAvailable({
    bool isDriver = false,
    bool isUserInitiated = false,
  }) async {
    bool serviceEnabled;
    LocationPermission permission;

    // A. Check System GPS Service
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _locationStatus.value = 'GPS is turned off.';
      // Offering to open *Location Services* (the device-level GPS toggle) is
      // allowed by Apple — it is NOT the same as opening the app's permission page.
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

    // C. Handle permanently-denied permission (App Store 5.1.1(iv) compliant).
    //
    // Apple's rule: you must NOT redirect users to Settings **immediately**
    // after they tap "Don't Allow". You MAY offer a Settings link only when
    // the user later *actively tries* to use a feature that requires location.
    if (permission == LocationPermission.deniedForever) {
      _locationStatus.value = 'Permission permanently denied.';

      if (isUserInitiated) {
        // The user tapped a button that needs location (e.g. "Book a Ride").
        // Showing an explanatory dialog with a Settings link is allowed here
        // because the user initiated the action — Apple permits this.
        await _offerOpenAppSettings(
          title: 'Location access needed',
          message:
              'This feature requires location access. You can enable it in Settings > Privacy > Location Services > Sarri Ride.',
        );
      } else {
        // Automatic / startup check — only show a non-intrusive snackbar.
        THelperFunctions.showSnackBar(
          'Location is turned off. Enable it in Settings when you\'re ready.',
        );
      }
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
  Future<void> initialize({
    bool isDriver = false,
    bool isUserInitiated = false,
  }) async {
    _isLocationLoading.value = true;
    _locationStatus.value = 'Verifying GPS...';
    update();

    try {
      bool isReady = await ensureLocationAvailable(
        isDriver: isDriver,
        isUserInitiated: isUserInitiated,
      );
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
  Future<Position?> getCurrentLocation({
    bool isDriver = false,
    bool isUserInitiated = false,
  }) async {
    bool isReady = await ensureLocationAvailable(
      isDriver: isDriver,
      isUserInitiated: isUserInitiated,
    );
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

  Future<bool> requestLocationPermission({bool isUserInitiated = false}) async {
    return await ensureLocationAvailable(isUserInitiated: isUserInitiated);
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
