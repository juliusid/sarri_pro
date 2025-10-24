import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

// --- Local Imports ---
import 'package:sarri_ride/features/shared/models/user_model.dart'; //
import 'package:sarri_ride/features/shared/services/demo_data.dart'; //
import 'package:sarri_ride/features/location/services/location_service.dart'; //
import 'package:sarri_ride/features/driver/screens/driver_earnings_screen.dart'; //
import 'package:sarri_ride/features/driver/screens/driver_trips_screen.dart'; //
import 'package:sarri_ride/features/driver/screens/driver_profile_screen.dart'; //
import 'package:sarri_ride/features/driver/screens/driver_vehicle_screen.dart'; //
import 'package:sarri_ride/features/driver/screens/trip_request_screen.dart'; //
import 'package:sarri_ride/features/driver/screens/trip_navigation_screen.dart'; //
import 'package:sarri_ride/features/driver/controllers/trip_management_controller.dart'; // // Now includes ActiveTrip
import 'package:sarri_ride/utils/constants/enums.dart'; //
import 'package:sarri_ride/utils/helpers/helper_functions.dart'; //
import 'package:sarri_ride/utils/constants/colors.dart'; //
import 'package:sarri_ride/features/authentication/screens/login/login_screen_getx.dart'; //
import 'package:sarri_ride/features/authentication/models/auth_model.dart'; // Import ClientData

class DriverDashboardController extends GetxController {
  static DriverDashboardController get instance => Get.find();

  // Services
  final LocationService _locationService = LocationService.instance;
  final DemoDataService _demoDataService = DemoDataService.instance;

  // State Variables
  final Rx<User?> currentDriver = Rx<User?>(null);
  final Rx<DriverStatus> driverStatus = DriverStatus
      .offline
      .obs; // Main status: Online/Offline/OnTrip/Unavailable
  final RxBool isOnline = false.obs; // User toggle state
  final RxList<Map<String, dynamic>> recentTrips = <Map<String, dynamic>>[].obs;
  final RxMap<String, dynamic> earnings = <String, dynamic>{}.obs;
  final RxDouble todayEarnings = 0.0.obs;
  final RxInt todayTripsCount = 0.obs;
  final RxDouble todayHours = 0.0.obs;
  final Rx<LatLng?> currentLocation = Rx<LatLng?>(
    null,
  ); // Stores last known location
  final RxDouble acceptanceRate = 95.0.obs;
  final RxDouble cancellationRate = 2.5.obs;
  final RxDouble averageRating = 4.9.obs;

  // Link to TripManagementController
  TripManagementController? _tripController;

  @override
  void onInit() {
    super.onInit();
    _initializeDriver();
    // Delay slightly to ensure TripManagementController might be ready
    Future.delayed(
      const Duration(milliseconds: 100),
      _initializeTripManagement,
    );
  }

  @override
  void onClose() {
    // No timers owned by this controller anymore
    super.onClose();
  }

  void _initializeDriver() {
    try {
      if (Get.isRegistered<ClientData>(tag: 'currentUser')) {
        final clientData = Get.find<ClientData>(tag: 'currentUser');
        if (clientData.role == 'driver') {
          // Basic mapping - Fetch full profile from API recommended
          currentDriver.value = User(
            id: clientData.id,
            email: clientData.email,
            firstName: 'Driver',
            lastName: '',
            userType: UserType.driver,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
            driverProfile: DriverProfile(
              userId: clientData.id,
              licenseNumber: 'TEMP-LIC',
              vehicle: Vehicle(
                make: 'Make',
                model: 'Model',
                year: 2020,
                plateNumber: 'PLATE',
                color: 'Color',
                type: VehicleType.sedan,
              ),
            ),
          );
          _loadDriverData();
        } else {
          print(
            "Logged in user is not a driver. Role: ${clientData.role}. Redirecting...",
          );
          _redirectToLogin("Access Denied: Not a driver account.");
        }
      } else {
        print("No user data found (tag 'currentUser'). Redirecting to login.");
        _redirectToLogin('Please login as a driver.');
      }
    } catch (e) {
      print("Error initializing driver: $e. Redirecting to login.");
      _redirectToLogin('An error occurred. Please login again.');
    }
  }

  // Helper to schedule redirect safely
  void _redirectToLogin(String message) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Get.offAll(() => const LoginScreenGetX());
      THelperFunctions.showSnackBar(message);
    });
  }

  void _initializeTripManagement() {
    try {
      // Find TripManagementController (should be registered by now, or handle error)
      if (!Get.isRegistered<TripManagementController>()) {
        print(
          "Error: TripManagementController not registered. Putting it now.",
        );
        _tripController = Get.put(
          TripManagementController(),
        ); // Ensure it's available
      } else {
        _tripController = Get.find<TripManagementController>();
      }

      // Listen for new trip requests
      ever(_tripController!.hasNewRequest, (bool hasRequest) {
        if (hasRequest && isOnline.value) {
          // Only show if driver is online
          _showTripRequestNotification();
        }
      });

      // Listen for trip status changes to update driver's general status
      ever(_tripController!.tripStatus, (TripStatus status) {
        print("Dashboard received Trip Status update: $status");
        if (status == TripStatus.accepted ||
            status == TripStatus.drivingToPickup ||
            status == TripStatus.arrivedAtPickup ||
            status == TripStatus.tripInProgress ||
            status == TripStatus.arrivedAtDestination) // Driver is busy
        {
          driverStatus.value = DriverStatus.onTrip;
          isOnline.value = true; // Implicitly online when on trip
        } else {
          // none, requested, completed, cancelled
          // Return to state based on the online toggle
          driverStatus.value = isOnline.value
              ? DriverStatus.online
              : DriverStatus.offline;
        }
      });
    } catch (e) {
      print('Error initializing trip management listener in Dashboard: $e');
    }
  }

  void _showTripRequestNotification() {
    if (Get.isSnackbarOpen ||
        Get.isDialogOpen == true ||
        Get.isBottomSheetOpen == true)
      return;
    final currentRoute = Get.currentRoute;
    if (currentRoute == '/TripRequestScreen' ||
        currentRoute == '/TripNavigationScreen')
      return;

    print("Dashboard: Showing trip request screen trigger.");
    try {
      Get.to(() => const TripRequestScreen());
    } catch (e) {
      print('Navigation error showing trip request: $e');
    }
  }

  /// Updates earnings and trip counts after a trip is completed. Called by TripManagementController.
  void updateEarningsFromCompletedTrip(ActiveTrip? completedTrip) {
    if (completedTrip != null && completedTrip.status == TripStatus.completed) {
      print(
        "Dashboard: Updating earnings for completed trip ${completedTrip.id}",
      );
      todayEarnings.value += completedTrip.fare;
      todayTripsCount.value++;

      final tripData = {
        'id': completedTrip.id,
        'from': completedTrip.pickupAddress,
        'to': completedTrip.destinationAddress,
        'riderName': completedTrip.riderName,
        'earnings': completedTrip.fare,
        'rating': completedTrip.riderRating,
        'date': completedTrip.endTime ?? DateTime.now(),
        'status': 'completed',
        'duration':
            completedTrip.actualDuration ?? completedTrip.estimatedDuration,
        'distance': completedTrip.actualDistance ?? completedTrip.distance,
        'fare': completedTrip.fare,
      };
      recentTrips.insert(0, tripData);
      // Optional: Update total earnings/trips (better fetched from API periodically)
    } else {
      print(
        "Dashboard: Called updateEarnings but trip was null or not completed.",
      );
    }
  }

  void _loadDriverData() {
    if (currentDriver.value != null) {
      // TODO: Replace placeholders with actual data fetch (API call recommended)
      final profile = currentDriver.value!.driverProfile;

      driverStatus.value = profile?.status ?? DriverStatus.offline;
      isOnline.value = driverStatus.value == DriverStatus.online;

      // Load demo data (replace with API)
      earnings.value = _demoDataService.getMockEarningsData(
        currentDriver.value!.id,
      );
      _updateTodayStats();
      recentTrips.value = _demoDataService.getMockTripsForUser(
        currentDriver.value!.id,
        UserType.driver,
      );

      if (profile?.currentLocation != null) {
        currentLocation.value = profile!.currentLocation;
      } else {
        final position = _locationService.getLocationForMap();
        currentLocation.value = LatLng(position.latitude, position.longitude);
      }

      acceptanceRate.value = profile?.acceptanceRate ?? 95.0;
      cancellationRate.value = profile?.cancellationRate ?? 2.5;
      averageRating.value = profile?.rating ?? 4.9;

      print("Driver data loaded. Status: ${driverStatus.value}");
      // Trigger location updates if online
      // Note: Location tracking timer is in TripManagementController,
      // it checks this controller's isOnline status.
      if (isOnline.value) {
        print(
          "Driver is online, location updates should start via TripManagementController timer.",
        );
      }
    } else {
      print("Cannot load driver data: currentDriver is null.");
    }
  }

  void _updateTodayStats() {
    final today = earnings['today'];
    if (today is Map) {
      todayEarnings.value = (today['earnings'] as num?)?.toDouble() ?? 0.0;
      todayTripsCount.value = (today['trips'] as num?)?.toInt() ?? 0;
      todayHours.value = (today['hours'] as num?)?.toDouble() ?? 0.0;
    } else {
      todayEarnings.value = 0.0;
      todayTripsCount.value = 0;
      todayHours.value = 0.0;
    }
  }

  // Toggle driver online/offline status
  Future<void> toggleDriverStatus() async {
    // Prevent status change if on an active trip
    // Use the getter from TripManagementController if available
    if (_tripController?.hasActiveTrip ?? false) {
      THelperFunctions.showSnackBar('Cannot change status while on a trip.');
      return;
    }

    // Optimistic UI update
    isOnline.value = !isOnline.value;
    driverStatus.value = isOnline.value
        ? DriverStatus.online
        : DriverStatus.offline;
    THelperFunctions.showSnackBar(
      isOnline.value ? 'Going Online...' : 'Going Offline...',
    );

    try {
      // --- API Call to Update Status ---
      // TODO: Implement API call to backend to set driver status online/offline
      // Example: await YourApiService.setDriverStatus(isOnline.value);
      await Future.delayed(
        const Duration(milliseconds: 500),
      ); // Simulate API call
      // --- End API Call ---

      // Update Demo Data Service (replace/remove when API is live)
      if (currentDriver.value != null) {
        await _demoDataService.updateDriverStatus(
          currentDriver.value!.id,
          driverStatus.value,
        );
      }

      // --- Trigger WebSocket Location Emission (or stop) ---
      // The timer in TripManagementController checks `isOnline`, so just updating
      // `isOnline.value` is enough to control emission.
      // If going online, ensure location service is ready.
      if (isOnline.value) {
        bool serviceEnabled = await _locationService.isLocationServiceEnabled();
        bool permissionGranted = await _locationService
            .requestLocationPermission();
        if (!serviceEnabled || !permissionGranted) {
          THelperFunctions.showSnackBar(
            serviceEnabled
                ? 'Location permission needed.'
                : 'Please enable location services.',
          );
          // Revert optimistic UI update if location fails
          isOnline.value = false;
          driverStatus.value = DriverStatus.offline;
          throw Exception("Location not available");
        }
        // Trigger an immediate location update emission if possible
        _tripController
            ?.forceLocationUpdate(); // Need to add this method to TripManagementController
      } else {
        // If going offline, optionally emit one last 'unavailable' status
        _tripController?.forceLocationUpdate(
          statusOverride: 'unavailable',
        ); // Need to add this method
      }
      // --- End WebSocket Control ---

      print("Driver status updated successfully to ${driverStatus.value}");
      THelperFunctions.showSnackBar(
        isOnline.value ? 'You are now Online' : 'You are now Offline',
      );
    } catch (e) {
      // Revert UI on failure
      isOnline.value = !isOnline.value;
      driverStatus.value = isOnline.value
          ? DriverStatus.online
          : DriverStatus.offline;
      THelperFunctions.showSnackBar('Failed to update status: ${e.toString()}');
      print("Error toggling driver status: $e");
    }
  }

  // --- Removed _goOnline, _goOffline, _startLocationTracking, _stopLocationTracking ---
  // These functionalities are now implicitly handled by toggling `isOnline`
  // and the location emission logic resides in `TripManagementController`'s timer.

  // Navigation methods
  void navigateToEarnings() {
    Get.to(() => const DriverEarningsScreen());
  }

  void navigateToTrips() {
    Get.to(() => const DriverTripsScreen());
  }

  void navigateToProfile() {
    Get.to(() => const DriverProfileScreen());
  }

  void navigateToVehicle() {
    Get.to(() => const DriverVehicleScreen());
  }

  void navigateToTripNavigation() {
    // Check using the TripManagementController's getter
    if (_tripController?.hasActiveTrip ?? false) {
      Get.to(() => const TripNavigationScreen());
    } else {
      THelperFunctions.showSnackBar('No active trip to navigate');
    }
  }

  void navigateToDocuments() {
    /* ... (Placeholder) ... */
    Get.toNamed('/driver/documents');
  }

  void navigateToSettings() {
    /* ... (Placeholder) ... */
    Get.toNamed('/driver/settings');
  }

  // Utility methods
  String get statusText {
    /* ... (as before) ... */
    switch (driverStatus.value) {
      case DriverStatus.offline:
        return 'Offline';
      case DriverStatus.online:
        return 'Online - Ready';
      case DriverStatus.onTrip:
        return 'On Trip';
      case DriverStatus.unavailable:
        return 'Unavailable';
    }
  }

  Color get statusColor {
    /* ... (as before) ... */
    switch (driverStatus.value) {
      case DriverStatus.offline:
        return TColors.offlineStatus;
      case DriverStatus.online:
        return TColors.onlineStatus;
      case DriverStatus.onTrip:
        return TColors.info;
      case DriverStatus.unavailable:
        return TColors.warning;
    }
  }

  String get formattedTodayEarnings {
    /* ... (as before) ... */
    return '₦${todayEarnings.value.toStringAsFixed(0)}';
  }

  String get formattedTotalEarnings {
    /* ... (as before) ... */
    return '₦${currentDriver.value?.driverProfile?.totalEarnings.toStringAsFixed(0) ?? '0'}';
  }

  // Check if driver has active trip (delegates to TripManagementController)
  bool get hasActiveTrip {
    return _tripController?.hasActiveTrip ?? false;
  }

  // Get current trip status string for display
  String get currentTripStatusDisplay {
    /* ... (as before, uses _tripController) ... */
    if (_tripController == null || _tripController!.activeTrip.value == null)
      return 'No Active Trip';
    switch (_tripController!.tripStatus.value) {
      case TripStatus.accepted:
        return 'Accepted - Heading to Pickup';
      case TripStatus.drivingToPickup:
        return 'Driving to Pickup';
      case TripStatus.arrivedAtPickup:
        return 'Arrived at Pickup';
      case TripStatus.tripInProgress:
        return 'Trip in Progress';
      case TripStatus.arrivedAtDestination:
        return 'Arrived at Destination';
      case TripStatus.completed:
        return 'Trip Completed';
      case TripStatus.cancelled:
        return 'Trip Cancelled';
      default:
        return 'Trip Status Unknown';
    }
  }
}
