// lib/features/driver/controllers/driver_dashboard_controller.dart

import 'dart:async';
import 'dart:math'; // For jitter in reconnect timer
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_state_manager/src/simple/get_controllers.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'package:intl/intl.dart'; // For formatting break end time
import 'package:sarri_ride/config/api_config.dart';
import 'package:sarri_ride/core/services/http_service.dart';
import 'package:sarri_ride/core/services/websocket_service.dart'; // Import WebSocketService
import 'package:sarri_ride/features/settings/controllers/settings_controller.dart'; // For logout on ban/suspend

// --- Local Imports ---
import 'package:sarri_ride/features/shared/models/user_model.dart';
import 'package:sarri_ride/features/shared/services/demo_data.dart'; // Still using for mock data loading
import 'package:sarri_ride/features/location/services/location_service.dart';
import 'package:sarri_ride/features/driver/screens/driver_earnings_screen.dart';
import 'package:sarri_ride/features/driver/screens/driver_trips_screen.dart';
import 'package:sarri_ride/features/driver/screens/driver_profile_screen.dart';
import 'package:sarri_ride/features/driver/screens/driver_vehicle_screen.dart';
import 'package:sarri_ride/features/driver/screens/trip_request_screen.dart';
import 'package:sarri_ride/features/driver/screens/trip_navigation_screen.dart';
import 'package:sarri_ride/features/driver/controllers/trip_management_controller.dart';
import 'package:sarri_ride/utils/constants/enums.dart'; // Ensure TripStatus enum is here
import 'package:sarri_ride/utils/helpers/helper_functions.dart';
import 'package:sarri_ride/utils/constants/colors.dart';
import 'package:sarri_ride/features/authentication/screens/login/login_screen_getx.dart';
import 'package:sarri_ride/features/authentication/models/auth_model.dart'; // Contains ClientData

class DriverDashboardController extends GetxController {
  static DriverDashboardController get instance => Get.find();

  // Services
  final LocationService _locationService = LocationService.instance;
  final DemoDataService _demoDataService =
      DemoDataService.instance; // Keep for mock data
  final HttpService _httpService = HttpService.instance;
  final WebSocketService _webSocketService = WebSocketService.instance;

  // State Variables
  final Rx<User?> currentDriver = Rx<User?>(null);

  /// Tracks the driver's *intended* state set via the Go Online/Offline button.
  final RxBool isOnline = false.obs;
  final RxList<Map<String, dynamic>> recentTrips = <Map<String, dynamic>>[].obs;
  final RxMap<String, dynamic> earnings =
      <String, dynamic>{}.obs; // Mock data for now
  final RxDouble todayEarnings = 0.0.obs;
  final RxInt todayTripsCount = 0.obs;
  final RxDouble todayHours = 0.0.obs;
  final Rx<LatLng?> currentLocation = Rx<LatLng?>(null);
  final RxDouble acceptanceRate = 95.0.obs; // Mock
  final RxDouble cancellationRate = 2.5.obs; // Mock
  final RxDouble averageRating = 4.9.obs; // Mock

  // --- REVISED STATUS MANAGEMENT ---
  /// Overall account status (e.g., active, pending, suspended, unverified). From API's 'accountStatus'.
  final RxString driverOperationalStatus = 'unknown'.obs;

  /// Real-time task/availability status (e.g., available, unavailable, on_trip). From API's 'availability'.
  final RxString driverTaskStatus = 'unavailable'.obs; // Default to unavailable

  /// Tracks if the driver is currently marked as being on a break. From API's 'isOnBreak'.
  final RxBool isOnBreak = false.obs;
  // --- END REVISED STATUS MANAGEMENT ---

  final Rx<DateTime?> breakEndsAt = Rx<DateTime?>(
    null,
  ); // Stores the break end time from API
  Timer? _breakEndTimer; // Local timer JUST for UI updates
  Timer? _statusRefreshTimer; // Timer to periodically refresh status via API

  // Link to TripManagementController
  TripManagementController? _tripController;

  @override
  void onInit() {
    super.onInit();
    _initializeDriver();
    Future.delayed(
      const Duration(milliseconds: 100), // Ensure Get.put order if needed
      _initializeTripManagementAndStatusPolling,
    );
  }

  @override
  void onClose() {
    _breakEndTimer?.cancel();
    _statusRefreshTimer?.cancel(); // Stop polling on close
    super.onClose();
  }

  void _initializeDriver() async {
    try {
      ClientData? clientData;
      // Check if ClientData exists from login/splash
      if (Get.isRegistered<ClientData>(tag: 'currentUser')) {
        clientData = Get.find<ClientData>(tag: 'currentUser');
      } else {
        // Maybe attempt to fetch basic user info if token exists but ClientData isn't registered?
        // For now, assume ClientData should be present if authenticated.
        print("No ClientData found (tag 'currentUser'). Redirecting to login.");
        _redirectToLogin('Please login as a driver.');
        return;
      }

      // Ensure the logged-in user is a driver
      if (clientData.role != 'driver') {
        print(
          "Logged in user is not a driver. Role: ${clientData.role}. Redirecting...",
        );
        _redirectToLogin("Access Denied: Not a driver account.");
        return;
      }

      print("Initializing Driver: ${clientData.id}");

      // --- Fetch Full Driver Profile ---
      bool profileFetched = await _fetchDriverProfile();
      if (!profileFetched) {
        // Handle profile fetch failure (e.g., show error, maybe try again, or redirect)
        print(
          "Critical Error: Failed to fetch driver profile. Redirecting to login.",
        );
        _redirectToLogin(
          'Could not load your driver profile. Please login again.',
        );
        return; // Stop initialization
      }
      // --- End Profile Fetch ---

      // Set initial location from profile or location service
      _updateInitialLocation();

      // Perform initial status check using `/getStatus` endpoint AFTER profile is fetched
      await checkDriverStatus();

      // Handle ban/suspension (checkDriverStatus manages this)
      if (driverOperationalStatus.value == 'banned' ||
          driverOperationalStatus.value == 'suspended') {
        print("Initialization stopped: Account restricted.");
        return; // checkDriverStatus handles the redirect
      }

      // Load mock data for things not in profile (earnings, recent trips)
      _loadMockStatsAndTrips();

      // Connect WebSocket now that profile and initial status are known
      _connectWebSocket();
    } catch (e) {
      print("Error during driver initialization: $e. Redirecting to login.");
      _redirectToLogin('An error occurred during setup. Please login again.');
    }
  }

  /// Fetches the full driver profile from the backend. Returns true on success.
  Future<bool> _fetchDriverProfile() async {
    print("Fetching driver profile...");
    try {
      final response = await _httpService.get(ApiConfig.driverProfileEndpoint);
      final responseData = _httpService.handleResponse(
        response,
      ); // Throws on error

      if (responseData['status'] == 'success' && responseData['data'] is Map) {
        final profileData = responseData['data'] as Map<String, dynamic>;

        // Create User object from the fetched profile data
        currentDriver.value = User.fromDriverProfileJson(profileData);

        if (currentDriver.value?.driverProfile != null) {
          // Update state variables directly from the fetched profile
          final profile = currentDriver.value!.driverProfile!;
          driverOperationalStatus.value = profile.status
              .toLowerCase(); // 'status' from profile
          driverTaskStatus.value = profile.availabilityStatus
              .toLowerCase(); // 'availabilityStatus' from profile
          isOnBreak.value =
              profileData['break']?['isOnBreak'] ??
              false; // 'isOnBreak' from profile 'break' object

          // Update stats (if available in profile response, otherwise keep defaults/mocks)
          averageRating.value = profile.rating;
          // acceptanceRate.value = profile.acceptanceRate; // Assuming these are in the profile model now
          // cancellationRate.value = profile.cancellationRate;

          print("Driver Profile successfully fetched and parsed.");
          print(
            "Initial Profile Status: Operational='${driverOperationalStatus.value}', Task='${driverTaskStatus.value}', IsOnBreak='${isOnBreak.value}'",
          );
          return true;
        } else {
          print(
            "Error: Parsed profile data is missing the 'driverProfile' section.",
          );
          return false;
        }
      } else {
        print(
          "Profile fetch API returned status != success or invalid data format.",
        );
        return false;
      }
    } on ApiException catch (e) {
      print(
        "API Error fetching driver profile: ${e.message} (Status: ${e.statusCode})",
      );
      // 401 handled globally, other errors might indicate issues
      return false;
    } catch (e) {
      print("Unexpected Error fetching driver profile: $e");
      return false;
    }
  }

  /// Sets the initial currentLocation based on profile or location service.
  void _updateInitialLocation() {
    // Prioritize location from fetched profile if available and recent enough
    final profileLocation =
        currentDriver.value?.driverProfile?.location.coordinates;
    final lastUpdate = currentDriver.value?.driverProfile?.lastLocationUpdate;
    bool useProfileLocation = false;
    if (profileLocation != null && lastUpdate != null) {
      // Check if the profile location is reasonably recent (e.g., within last 5 minutes)
      if (DateTime.now().difference(lastUpdate).inMinutes < 5) {
        currentLocation.value = profileLocation;
        useProfileLocation = true;
        print("Using initial location from profile: $profileLocation");
      }
    }

    // If profile location wasn't used, get from LocationService
    if (!useProfileLocation) {
      _locationService.ensureLocationAvailable();
      final position = _locationService.getLocationForMap();
      currentLocation.value = LatLng(position.latitude, position.longitude);
      print(
        "Using initial location from LocationService: ${currentLocation.value}",
      );
    }

    // Update TripManagementController's initial location if it's initialized
    _tripController?.driverLocation.value = currentLocation.value;
  }

  /// Loads mock data for earnings and trips (replace with API calls later).
  void _loadMockStatsAndTrips() {
    if (currentDriver.value != null) {
      print("Loading mock earnings and trip data...");
      earnings.value = _demoDataService.getMockEarningsData(
        currentDriver.value!.id,
      );
      _updateTodayStats(); // Update Rx variables from mock map
      recentTrips.value = _demoDataService.getMockTripsForUser(
        currentDriver.value!.id,
        UserType.driver,
      );
    } else {
      print("Cannot load mock data: currentDriver is null.");
    }
  }

  void _connectWebSocket() {
    // Connect only if authenticated and account is not severely restricted
    if (HttpService.instance.isAuthenticated &&
        driverOperationalStatus.value != 'banned' &&
        driverOperationalStatus.value != 'suspended') {
      print("Connecting WebSocket for driver...");
      _webSocketService.connect();
    } else {
      print(
        "Skipping WebSocket connection: Not authenticated or account restricted.",
      );
    }
  }

  void _redirectToLogin(String message) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _webSocketService.disconnect(); // Ensure socket is disconnected
      _statusRefreshTimer?.cancel(); // Stop status polling
      Get.offAll(() => const LoginScreenGetX());
      THelperFunctions.showSnackBar(message);
    });
  }

  /// Initializes listeners for TripManagementController and starts periodic status polling.
  void _initializeTripManagementAndStatusPolling() {
    // Initialize Trip Management Listeners
    try {
      if (!Get.isRegistered<TripManagementController>()) {
        _tripController = Get.put(TripManagementController());
      } else {
        _tripController = Get.find<TripManagementController>();
      }

      // Listener 1: Show Trip Request Screen
      ever(_tripController!.hasNewRequest, (bool hasRequest) {
        // Show request ONLY if driver *intends* to be online, is *actually* available according to backend, and not on break
        if (hasRequest &&
            isOnline.value &&
            driverTaskStatus.value == 'available' &&
            !isOnBreak.value) {
          _showTripRequestNotification();
        } else if (hasRequest) {
          print(
            "New request received but suppressed. isOnline=${isOnline.value}, taskStatus=${driverTaskStatus.value}, isOnBreak=${isOnBreak.value}",
          );
        }
      });

      // Listener 2: Update task status based on trip progress from TripController
      ever(_tripController!.tripStatus, (TripStatus tripProgressStatus) {
        print(
          "Dashboard received Trip Status update from TripController: $tripProgressStatus",
        );
        if (tripProgressStatus == TripStatus.accepted ||
            tripProgressStatus == TripStatus.drivingToPickup ||
            tripProgressStatus == TripStatus.arrivedAtPickup ||
            tripProgressStatus == TripStatus.tripInProgress ||
            tripProgressStatus == TripStatus.arrivedAtDestination) {
          // If a trip is active, task status must be 'on_trip'
          if (driverTaskStatus.value != 'on_trip') {
            print("Updating task status to 'on_trip' based on trip progress.");
            driverTaskStatus.value = 'on_trip';
            isOnline.value = true; // Driver is busy but logically online
            isOnBreak.value = false; // Cannot be on break and on trip
            _breakEndTimer?.cancel();
            breakEndsAt.value = null;
            update(); // Update UI
          }
        } else if (tripProgressStatus == TripStatus.completed ||
            tripProgressStatus == TripStatus.cancelled ||
            tripProgressStatus == TripStatus.none) {
          // Trip ended or cleared
          print("Trip ended/cleared. Re-evaluating task status...");
          // Force a refresh from the API to get the definitive current state
          checkDriverStatus();
          // Don't immediately set to available/unavailable here, let checkDriverStatus handle it.
        }
      });
    } catch (e) {
      print('Error initializing trip management listener in Dashboard: $e');
    }

    // Start Periodic Status Polling via API
    _statusRefreshTimer?.cancel(); // Cancel any existing timer
    _statusRefreshTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      // Only poll if the user is logged in (check token) and WebSocket isn't reliably connected
      // Or simply poll regardless to ensure sync
      if (HttpService.instance.isAuthenticated) {
        print("Periodic status check triggered...");
        checkDriverStatus(); // Refresh status from API
      } else {
        print("Skipping periodic status check: User not authenticated.");
        timer.cancel(); // Stop timer if logged out
      }
    });
    print("Periodic status polling started (every 30 seconds).");
  }

  void _showTripRequestNotification() {
    if (Get.isSnackbarOpen ||
        Get.isDialogOpen == true ||
        Get.isBottomSheetOpen == true) {
      return;
    }
    final currentRoute = Get.currentRoute;
    if (currentRoute == '/TripRequestScreen' ||
        currentRoute == '/TripNavigationScreen') {
      return;
    }
    print("Dashboard: Showing trip request screen trigger.");
    try {
      Get.to(() => const TripRequestScreen());
    } catch (e) {
      print('Navigation error showing trip request: $e');
    }
  }

  void updateEarningsFromCompletedTrip(ActiveTrip? completedTrip) {
    // ... (same as before using mock data logic) ...
    if (completedTrip != null && completedTrip.status == TripStatus.completed) {
      print(
        "Dashboard: Updating earnings for completed trip ${completedTrip.id}",
      );
      todayEarnings.value += completedTrip.fare; // Update mock earnings
      todayTripsCount.value++; // Update mock count
      final tripData = {
        'id': completedTrip.id,
        'from': completedTrip.pickupAddress,
        'to': completedTrip.destinationAddress,
        'riderName': completedTrip.riderName,
        'earnings': completedTrip.fare, // Use actual fare
        'rating': completedTrip.riderRating,
        'date': completedTrip.endTime ?? DateTime.now(),
        'status': 'completed',
        'duration':
            completedTrip.actualDuration ?? completedTrip.estimatedDuration,
        'distance': completedTrip.actualDistance ?? completedTrip.distance,
        'fare': completedTrip.fare,
      };
      recentTrips.insert(0, tripData);
    } else {
      print(
        "Dashboard: Called updateEarnings but trip was null or not completed.",
      );
    }
  }

  void _loadDriverData() {
    // ... (same as before, loads mock stats/trips) ...
    if (currentDriver.value != null) {
      earnings.value = _demoDataService.getMockEarningsData(
        currentDriver.value!.id,
      );
      _updateTodayStats();
      recentTrips.value = _demoDataService.getMockTripsForUser(
        currentDriver.value!.id,
        UserType.driver,
      );
      final profile = currentDriver.value!.driverProfile;
      acceptanceRate.value = profile?.acceptanceRate ?? 95.0;
      cancellationRate.value = profile?.cancellationRate ?? 2.5;
      averageRating.value = profile?.rating ?? 4.9;
      final position = _locationService.getLocationForMap();
      currentLocation.value = LatLng(position.latitude, position.longitude);
      print("Mock driver data loaded.");
    } else {
      print("Cannot load driver data: currentDriver is null.");
    }
  }

  void _updateTodayStats() {
    // ... (same as before, updates mock stats) ...
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

  /// Fetches the driver's operational status from the backend.
  /// Updates `driverOperationalStatus`, `driverTaskStatus`, and `isOnBreak`.
  Future<void> checkDriverStatus() async {
    // Avoid concurrent calls if one is already in progress (optional)
    // if (_isCheckingStatus) return;
    // _isCheckingStatus = true;
    print("Checking driver status via API...");
    try {
      final response = await _httpService.get(ApiConfig.driverStatusEndpoint);
      // Use non-throwing response handler if needed, or keep global handling
      print(
        "DRIVER_DASH: checkDriverStatus - Raw Response Status Code: ${response.statusCode}",
      ); // <-- ADD LOG
      final responseData = _httpService.handleResponse(response);
      print("Driver GetStatus Response Data: $responseData");
      print(
        "DRIVER_DASH: checkDriverStatus - Parsed Response Data: $responseData",
      ); // <-- ADD LOG
      if (responseData['status'] == 'success' && responseData['data'] is Map) {
        final Map<String, dynamic> data = responseData['data'];

        // 1. Update Operational Status (Account State)
        final String? apiAccountStatus =
            data['accountStatus'] as String?; // e.g., 'unverified'
        if (apiAccountStatus != null) {
          final statusLower = apiAccountStatus.toLowerCase();
          if (driverOperationalStatus.value != statusLower) {
            // Update only if changed
            print("API Account Status: $statusLower");
            driverOperationalStatus.value = statusLower;
          }
          // Handle ban/suspension immediately
          if (statusLower == 'banned' || statusLower == 'suspended') {
            final String apiMessage =
                data['message'] as String? ?? "Account restricted.";
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _handleAccountRestriction(statusLower, apiMessage);
            });
            return; // Stop further processing
          }
        } else {
          if (driverOperationalStatus.value != 'unknown') {
            driverOperationalStatus.value = 'unknown';
            print(
              "API response missing 'accountStatus'. Setting operational status to unknown.",
            );
          }
        }

        // 2. Update Task Status (Availability State)
        final String? apiAvailability =
            data['availability'] as String?; // e.g., 'unavailable'
        if (apiAvailability != null) {
          final availabilityLower = apiAvailability.toLowerCase();
          if (driverTaskStatus.value != availabilityLower) {
            print("API Availability Status: $availabilityLower");
            driverTaskStatus.value = availabilityLower;
          }
        } else {
          if (driverTaskStatus.value != 'unavailable') {
            driverTaskStatus.value = 'unavailable'; // Default if missing
            print(
              "API response missing 'availability'. Setting task status to unavailable.",
            );
          }
        }

        // 3. Update Break Status
        final bool? apiIsOnBreak = data['isOnBreak'] as bool?;
        if (apiIsOnBreak != null) {
          if (isOnBreak.value != apiIsOnBreak) {
            print("API isOnBreak Status: $apiIsOnBreak");
            isOnBreak.value = apiIsOnBreak;
            if (apiIsOnBreak) {
              isOnline.value = false; // Ensure intent matches break state
              // Potentially parse break end time here if API provides it
              // breakEndsAt.value = DateTime.tryParse(data['breakEndsAt'] ?? '');
              // _scheduleLocalBreakEndUpdate();
            } else {
              // If API says not on break, clear local timer/end time
              breakEndsAt.value = null;
              _breakEndTimer?.cancel();
            }
          }
        } else {
          print(
            "API response missing 'isOnBreak'. Local break state might be inaccurate.",
          );
        }
      } else {
        // API call succeeded but returned status != 'success' or invalid data
        if (driverOperationalStatus.value != 'unknown') {
          driverOperationalStatus.value = 'unknown';
        }
        if (driverTaskStatus.value != 'unavailable') {
          driverTaskStatus.value = 'unavailable';
        }
        if (isOnBreak.value != false) {
          isOnBreak.value = false; // Assume not on break
        }
        print(
          "Failed to get valid driver status data: ${responseData['message'] ?? 'Unknown API error'}",
        );
      }
    } on ApiException catch (e) {
      // API call failed (e.g., network error, 500 server error)
      print(
        "DRIVER_DASH: checkDriverStatus - API Exception Caught! Status: ${e.statusCode}, Message: ${e.message}",
      );
      if (e.statusCode != 401) {
        // 401 is handled globally
        if (driverOperationalStatus.value != 'error') {
          driverOperationalStatus.value = 'error';
        }
        if (driverTaskStatus.value != 'unavailable') {
          driverTaskStatus.value = 'unavailable';
        }
        if (isOnBreak.value != false) isOnBreak.value = false;
        print("API Error checking driver status: ${e.message}");
        // Avoid spamming snackbar on repeated polling failures
        // THelperFunctions.showSnackBar('Could not verify driver status. Retrying...');
      }
    } catch (e) {
      print("DRIVER_DASH: checkDriverStatus - Unexpected Exception Caught: $e");
      // Other unexpected errors (e.g., JSON parsing)
      if (driverOperationalStatus.value != 'error') {
        driverOperationalStatus.value = 'error';
      }
      if (driverTaskStatus.value != 'unavailable') {
        driverTaskStatus.value = 'unavailable';
      }
      if (isOnBreak.value != false) isOnBreak.value = false;
      print("Unexpected Error checking driver status: $e");
      // THelperFunctions.showSnackBar('An error occurred while checking your status.');
    } finally {
      // _isCheckingStatus = false;
      update(); // Ensure UI updates with the latest fetched state
    }
  }

  void _handleAccountRestriction(String status, String message) {
    String title = status == 'banned' ? 'Account Banned' : 'Account Suspended';
    String displayMessage =
        message.isNotEmpty &&
            !message.toLowerCase().contains("could not be determined")
        ? message
        : (status == 'banned'
              ? 'Your driver account has been permanently banned. Please contact support.'
              : 'Your driver account has been temporarily suspended. Please contact support.');
    final settingsController = Get.find<SettingsController>();
    settingsController
        .logout()
        .then((_) {
          Get.dialog(
            AlertDialog(
              title: Text(title),
              content: Text(displayMessage),
              actions: [
                TextButton(
                  onPressed: () {
                    if (Get.isDialogOpen ?? false) Get.back();
                  },
                  child: const Text('OK'),
                ),
              ],
            ),
            barrierDismissible: false,
          );
        })
        .catchError((e) {
          print("Error during forced logout for restriction: $e");
          Get.dialog(
            AlertDialog(
              title: Text(title),
              content: Text(displayMessage),
              actions: [
                TextButton(
                  onPressed: () => Get.back(),
                  child: const Text('OK'),
                ),
              ],
            ),
            barrierDismissible: false,
          );
        });
  }

  // Toggle driver online/offline status (User Action)
  Future<void> toggleDriverStatus() async {
    // 1. Check Permissions/Conditions
    if (driverOperationalStatus.value != 'active') {
      _showOperationalStatusError(); // Show specific error based on status
      return;
    }
    if (isOnBreak.value) {
      THelperFunctions.showSnackBar(
        'End your break first before changing online status.',
      );
      return;
    }
    // Check trip status via TripManagementController BEFORE allowing toggle
    if (_tripController?.hasActiveTrip ?? false) {
      // It's possible the dashboard's taskStatus is slightly delayed. Double-check with TripController.
      THelperFunctions.showSnackBar('Cannot change status while on a trip.');
      await checkDriverStatus(); // Refresh status to ensure consistency
      return;
    }

    // 2. Determine Target State & Update Intent
    bool targetIsOnline = !isOnline.value;
    isOnline.value = targetIsOnline; // Update user's intent immediately

    // 3. Show Immediate Feedback & Notify Backend
    THelperFunctions.showSnackBar(
      targetIsOnline ? 'Going Online...' : 'Going Offline...',
    );
    update(); // Update UI based on intent for now

    // Ensure location is available if going online
    if (targetIsOnline) {
      bool serviceEnabled = await _locationService.isLocationServiceEnabled();
      bool permissionGranted = await _locationService
          .requestLocationPermission();
      if (!serviceEnabled || !permissionGranted) {
        // Revert intent if location fails
        isOnline.value = false;
        update();
        THelperFunctions.showSnackBar(
          serviceEnabled
              ? 'Location permission needed.'
              : 'Please enable location services.',
        );
        return; // Stop the process
      }
    }

    // Inform backend via WebSocket
    _tripController?.forceLocationUpdate(
      statusOverride: targetIsOnline ? 'available' : 'unavailable',
    );

    // 4. Schedule a status check shortly after to confirm backend update
    await Future.delayed(const Duration(seconds: 2));
    await checkDriverStatus();
    // Show confirmation based on actual status fetched
    final actualStatus = driverTaskStatus.value;
    if (targetIsOnline && actualStatus == 'available') {
      THelperFunctions.showSnackBar('You are now Online');
    } else if (!targetIsOnline && actualStatus == 'unavailable') {
      THelperFunctions.showSnackBar('You are now Offline');
    } else if (targetIsOnline && actualStatus != 'available') {
      THelperFunctions.showSnackBar(
        'Failed to go online. Status: $actualStatus',
      );
      isOnline.value =
          false; // Revert intent if backend didn't update as expected
    } else if (!targetIsOnline && actualStatus != 'unavailable') {
      THelperFunctions.showSnackBar(
        'Failed to go offline. Status: $actualStatus',
      );
      isOnline.value = true; // Revert intent
    }
    update(); // Final UI update based on confirmed status
  }

  /// Shows appropriate message if driver tries to go online but account is not active.
  void _showOperationalStatusError() {
    String message;
    switch (driverOperationalStatus.value) {
      case 'unverified':
      case 'rejected':
        message =
            'Please complete or update your verification documents to go online.';
        break;
      case 'pending':
        message =
            'Your account verification is pending. Please wait for approval.';
        break;
      case 'suspended':
        message = 'Your account is suspended. Contact support.';
        break;
      case 'banned':
        message = 'Your account is banned.';
        break;
      default:
        message = 'Your account is not active. Cannot change status.';
        break;
    }
    THelperFunctions.showSnackBar(message);
  }

  // --- START BREAK METHOD ---
  Future<void> startBreak(int durationMinutes) async {
    print("Attempting to start break for $durationMinutes minutes...");
    // isLoadingBreakAction.value = true; // Optional

    // Prevent starting break if not 'active' and 'available'
    if (driverOperationalStatus.value != 'active') {
      _showOperationalStatusError();
      return;
    }
    if (driverTaskStatus.value != 'available' || isOnBreak.value) {
      THelperFunctions.showSnackBar(
        "Cannot start break now. Ensure you are online and available.",
      );
      return;
    }
    // Double-check trip status via TripController
    if (_tripController?.hasActiveTrip ?? false) {
      THelperFunctions.showSnackBar("Cannot start break while on a trip.");
      return;
    }

    try {
      final response = await _httpService.post(
        ApiConfig.startBreakEndpoint,
        body: {"durationMinutes": durationMinutes},
      );
      final responseData = _httpService.handleResponse(response);

      if (responseData['status'] == 'success') {
        // Update state based on API success (checkDriverStatus will confirm later)
        isOnBreak.value = true;
        isOnline.value = false; // Set intent to offline
        driverTaskStatus.value = 'break'; // Optimistic update

        // Parse break end time if provided
        if (responseData['data']?['breakEndsAt'] != null) {
          breakEndsAt.value = DateTime.tryParse(
            responseData['data']['breakEndsAt'],
          );
        } else {
          breakEndsAt.value = DateTime.now().add(
            Duration(minutes: durationMinutes),
          ); // Estimate
        }
        print("Break started. Ends at: ${breakEndsAt.value}");
        _scheduleLocalBreakEndUpdate(); // Schedule UI timer

        THelperFunctions.showSnackBar(
          responseData['message'] ?? 'Break started successfully.',
        );
        _tripController?.forceLocationUpdate(
          statusOverride: 'unavailable',
        ); // Inform backend
        update(); // Update UI
      } else {
        THelperFunctions.showSnackBar(
          responseData['message'] ?? 'Could not start break.',
        );
        await checkDriverStatus(); // Re-sync status on failure
      }
    } on ApiException catch (e) {
      THelperFunctions.showSnackBar('Error starting break: ${e.message}');
      await checkDriverStatus(); // Re-sync status on failure
    } catch (e) {
      THelperFunctions.showSnackBar(
        'An unexpected error occurred: ${e.toString()}',
      );
      await checkDriverStatus(); // Re-sync status on failure
    } finally {
      // isLoadingBreakAction.value = false;
    }
  }
  // --- END START BREAK METHOD ---

  // --- END BREAK METHOD ---
  Future<void> endBreak() async {
    print("Attempting to end break manually...");
    // isLoadingBreakAction.value = true; // Optional

    // Allow ending break even if local state is slightly off, API is source of truth
    // if (!isOnBreak.value) { print("Cannot end break: Not currently on break locally."); return; }

    try {
      final response = await _httpService.post(ApiConfig.endBreakEndpoint);
      final responseData = _httpService.handleResponse(response);

      if (responseData['status'] == 'success') {
        _clearBreakState(); // Clear local state and go online INTENT
        THelperFunctions.showSnackBar(
          responseData['message'] ?? 'Break ended successfully.',
        );
        _tripController?.forceLocationUpdate(
          statusOverride: 'available',
        ); // Inform backend
      } else {
        // Handle conflict (e.g., already ended) gracefully
        if (response.statusCode == 409 ||
            responseData['message']?.contains('not on break')) {
          print(
            "API conflict ending break or already ended: ${responseData['message']}",
          );
          _clearBreakState(syncWithApi: false); // Just sync UI
        } else {
          THelperFunctions.showSnackBar(
            responseData['message'] ?? 'Could not end break.',
          );
        }
        await checkDriverStatus(); // Re-sync status on failure/conflict
      }
    } on ApiException catch (e) {
      // Handle conflict gracefully
      if (e.statusCode == 409 || e.message.contains('not on break')) {
        print("API conflict ending break or already ended: ${e.message}");
        _clearBreakState(syncWithApi: false); // Sync UI
      } else {
        THelperFunctions.showSnackBar('Error ending break: ${e.message}');
      }
      await checkDriverStatus(); // Re-sync status on failure/conflict
    } catch (e) {
      THelperFunctions.showSnackBar(
        'An unexpected error occurred: ${e.toString()}',
      );
      await checkDriverStatus(); // Re-sync status on failure
    } finally {
      // isLoadingBreakAction.value = false;
    }
  }
  // --- END END BREAK METHOD ---

  void _scheduleLocalBreakEndUpdate() {
    _breakEndTimer?.cancel();
    if (breakEndsAt.value != null) {
      final now = DateTime.now();
      final durationUntilEnd = breakEndsAt.value!.difference(now);

      if (durationUntilEnd.isNegative || durationUntilEnd.inSeconds < 1) {
        // Check if already past or very close
        print(
          "Break end time is in the past or imminent. Ending break via API.",
        );
        // Call endBreak API directly instead of just clearing state
        endBreak().catchError((e) {
          print(
            "Error calling endBreak API from scheduler (past time): $e. Clearing local state.",
          );
          _clearBreakState(
            syncWithApi: false,
          ); // Force clear local if API fails
        });
      } else {
        print(
          "Scheduling local break end API call in ${durationUntilEnd.inSeconds} seconds.",
        );
        _breakEndTimer = Timer(durationUntilEnd, () {
          print("Local break timer expired. Ending break via API...");
          // Call the API to end the break
          endBreak().catchError((e) {
            print(
              "Error calling endBreak API from timer expiry: $e. Clearing local state.",
            );
            _clearBreakState(
              syncWithApi: false,
            ); // Force clear local if API fails
            THelperFunctions.showSnackBar(
              "Your break has ended. You are now available.",
            );
            _tripController?.forceLocationUpdate(
              statusOverride: 'available',
            ); // Attempt WS update
          });
        });
      }
    }
  }

  /// Clears local break state variables and sets driver intent back to online.
  /// `syncWithApi`: If true (default), calls forceLocationUpdate.
  void _clearBreakState({bool syncWithApi = true}) {
    // Check if we were actually on break or if it ended prematurely
    if (isOnBreak.value || driverTaskStatus.value == 'break') {
      isOnBreak.value = false;
      breakEndsAt.value = null;
      _breakEndTimer?.cancel();

      // Set INTENT back to online, actual status will be confirmed by API/polling
      isOnline.value = true;
      // Do NOT set driverTaskStatus here, let _checkDriverStatus handle the source of truth

      print(
        "Cleared local break state. Set intent to online. Actual status pending API sync.",
      );

      // Inform backend if needed
      if (syncWithApi) {
        _tripController?.forceLocationUpdate(statusOverride: 'available');
      }
      update(); // Update UI
    } else {
      print("Attempted to clear break state, but wasn't on break locally.");
    }
  }

  // --- Navigation methods ---

  void navigateToEarnings() => Get.to(() => const DriverEarningsScreen());
  void navigateToTrips() => Get.to(() => const DriverTripsScreen());
  void navigateToProfile() => Get.to(() => const DriverProfileScreen());
  void navigateToVehicle() => Get.to(() => const DriverVehicleScreen());
  void navigateToTripNavigation() {
    if (_tripController?.hasActiveTrip ?? false) {
      Get.to(() => const TripNavigationScreen());
    } else {
      THelperFunctions.showSnackBar('No active trip to navigate');
    }
  }

  void navigateToDocuments() => Get.toNamed('/driver/documents');
  void navigateToSettings() => Get.toNamed('/driver/settings');

  // --- Utility Getters ---
  String get statusText {
    // 1. Priority to Break Status
    if (isOnBreak.value) {
      if (breakEndsAt.value != null) {
        final formatter = DateFormat('h:mm a');
        // Check if break end time is in the past
        if (breakEndsAt.value!.isBefore(DateTime.now())) {
          return 'Ending Break...'; // Or 'Break Ended'
        }
        return 'On Break until ${formatter.format(breakEndsAt.value!)}';
      }
      return 'On Break';
    }

    // 2. Use Task Status from API as source of truth
    switch (driverTaskStatus.value) {
      case 'on_trip':
        // Refine based on TripManagementController's specific trip status
        return _tripController?.currentTripStatusDisplay ?? 'On Trip';
      case 'available':
        return 'Online - Ready';
      case 'break': // Fallback if isOnBreak flag is somehow false
        return 'On Break';
      case 'unavailable':
      case 'unknown': // Treat unknown/error as offline for UI
      case 'error':
      default:
        // Check operational status for more specific offline reasons
        switch (driverOperationalStatus.value) {
          case 'unverified':
            return 'Offline - Verification Required';
          case 'rejected':
            return 'Offline - Documents Rejected';
          case 'pending':
            return 'Offline - Verification Pending';
          case 'suspended':
            return 'Offline - Account Suspended';
          case 'banned':
            return 'Offline - Account Banned';
          default:
            return 'Offline';
        }
    }
  }

  Color get statusColor {
    // 1. Priority to Break Status
    if (isOnBreak.value) return TColors.secondary;

    // 2. Use Task Status
    switch (driverTaskStatus.value) {
      case 'on_trip':
        // Maybe refine color based on specific trip stage (e.g., drivingToPickup vs tripInProgress)
        return TColors.info;
      case 'available':
        return TColors.onlineStatus;
      case 'break': // Fallback color
        return TColors.secondary;
      case 'unavailable':
      case 'unknown':
      case 'error':
      default:
        // Use error color for suspended/banned/rejected?
        if ([
          'rejected',
          'suspended',
          'banned',
        ].contains(driverOperationalStatus.value)) {
          return TColors.error;
        }
        // Use warning for pending/unverified?
        if (['unverified', 'pending'].contains(driverOperationalStatus.value)) {
          return TColors.warning;
        }
        return TColors.offlineStatus; // Default offline
    }
  }

  String get formattedTodayEarnings =>
      '₦${todayEarnings.value.toStringAsFixed(0)}'; // Mock
  String get formattedTotalEarnings =>
      '₦${currentDriver.value?.driverProfile?.totalEarnings.toStringAsFixed(0) ?? '0'}'; // Mock
  bool get hasActiveTrip => _tripController?.hasActiveTrip ?? false;

  String get currentTripStatusDisplay {
    if (_tripController == null || _tripController!.activeTrip.value == null) {
      return 'No Active Trip';
    }
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
