// lib/features/driver/controllers/driver_dashboard_controller.dart

import 'dart:async';
import 'dart:math'; // For jitter in reconnect timer
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart'; // For formatting break end time

// --- Services ---
import 'package:sarri_ride/config/api_config.dart';
import 'package:sarri_ride/core/services/http_service.dart';
import 'package:sarri_ride/core/services/websocket_service.dart';
import 'package:sarri_ride/features/settings/controllers/settings_controller.dart';
import 'package:sarri_ride/features/shared/models/user_model.dart';
import 'package:sarri_ride/features/shared/services/demo_data.dart'; // Kept for type refs, but usage minimized
import 'package:sarri_ride/features/location/services/location_service.dart';
import 'package:sarri_ride/features/rating/services/rating_service.dart'; // <--- IMPORT RATING SERVICE

// --- Screens ---
import 'package:sarri_ride/features/driver/screens/driver_earnings_screen.dart';
import 'package:sarri_ride/features/driver/screens/driver_trips_screen.dart';
import 'package:sarri_ride/features/driver/screens/driver_profile_screen.dart';
import 'package:sarri_ride/features/driver/screens/driver_vehicle_screen.dart';
import 'package:sarri_ride/features/driver/screens/trip_request_screen.dart';
import 'package:sarri_ride/features/driver/screens/trip_navigation_screen.dart';
import 'package:sarri_ride/features/authentication/screens/login/login_screen_getx.dart';

// --- Controllers & Models ---
import 'package:sarri_ride/features/driver/controllers/trip_management_controller.dart';
import 'package:sarri_ride/features/authentication/models/auth_model.dart';
import 'package:sarri_ride/utils/constants/enums.dart';
import 'package:sarri_ride/utils/helpers/helper_functions.dart';
import 'package:sarri_ride/utils/constants/colors.dart';

class DriverDashboardController extends GetxController {
  static DriverDashboardController get instance => Get.find();

  // Services
  final LocationService _locationService = LocationService.instance;
  final DemoDataService _demoDataService = DemoDataService.instance;
  final HttpService _httpService = HttpService.instance;
  final WebSocketService _webSocketService = WebSocketService.instance;

  // --- ADDED RATING SERVICE ---
  final RatingService _ratingService = Get.put(RatingService());

  // State Variables
  final Rx<User?> currentDriver = Rx<User?>(null);

  // --- Real Stats Variables ---
  final RxDouble todayEarnings = 0.0.obs;
  final RxInt todayTrips = 0.obs;
  final RxDouble todayHours = 0.0.obs; // Calculated from trip duration
  final RxBool isLoadingStats = false.obs;

  // Status
  final RxBool isOnline = false.obs;
  final RxBool isLoadingStatus = false.obs;

  // Dashboard Lists
  final RxList<Map<String, dynamic>> recentTrips = <Map<String, dynamic>>[].obs;
  final RxMap<String, dynamic> earnings = <String, dynamic>{}.obs;
  final RxInt todayTripsCount = 0.obs;
  final Rx<LatLng?> currentLocation = Rx<LatLng?>(null);

  // --- PRODUCTION FIX: Set defaults to 0.0 ---
  final RxDouble acceptanceRate = 0.0.obs;
  final RxDouble cancellationRate = 0.0.obs;
  final RxDouble averageRating = 0.0.obs; // Updated via RatingService
  // ------------------------------------------

  // --- STATUS MANAGEMENT ---
  final RxString driverOperationalStatus = 'unknown'.obs; // accountStatus
  final RxString driverTaskStatus = 'unavailable'.obs; // availability
  final RxBool isOnBreak = false.obs;

  final Rx<DateTime?> breakEndsAt = Rx<DateTime?>(null);
  Timer? _breakEndTimer;
  Timer? _statusRefreshTimer;

  // Link to TripManagementController
  TripManagementController? _tripController;

  @override
  void onInit() {
    super.onInit();
    _initializeDriver();
    Future.delayed(
      const Duration(milliseconds: 100),
      _initializeTripManagementAndStatusPolling,
    );
    _webSocketService.registerWalletUpdateListener(_handleWalletUpdate);
    _webSocketService.registerPaymentProcessedListener(_handlePaymentProcessed);
  }

  @override
  void onClose() {
    _breakEndTimer?.cancel();
    _statusRefreshTimer?.cancel();
    _webSocketService.unregisterWalletUpdateListener(_handleWalletUpdate);
    _webSocketService.unregisterPaymentProcessedListener(
      _handlePaymentProcessed,
    );
    super.onClose();
  }

  void _initializeDriver() async {
    try {
      ClientData? clientData;
      if (Get.isRegistered<ClientData>(tag: 'currentUser')) {
        clientData = Get.find<ClientData>(tag: 'currentUser');
      } else {
        print("No ClientData found. Redirecting to login.");
        _redirectToLogin('Please login as a driver.');
        return;
      }

      if (clientData.role != 'driver') {
        _redirectToLogin("Access Denied: Not a driver account.");
        return;
      }

      print("Initializing Driver: ${clientData.id}");

      // 1. Fetch Profile
      bool profileFetched = await _fetchDriverProfile();
      if (!profileFetched) {
        _redirectToLogin(
          'Could not load your driver profile. Please login again.',
        );
        return;
      }

      // 2. Set Location
      _updateInitialLocation();

      // 3. Check Status
      await checkDriverStatus();

      if (driverOperationalStatus.value == 'banned' ||
          driverOperationalStatus.value == 'suspended') {
        print("Initialization stopped: Account restricted.");
        return;
      }

      // 4. Fetch Real Stats
      // Removed _loadMockStatsAndTrips();
      await fetchTodayStats();

      // --- ADDED: FETCH REAL RATINGS ---
      await fetchDriverRatings();

      // 5. Connect Socket
      _connectWebSocket();
    } catch (e) {
      print("Error during driver initialization: $e. Redirecting to login.");
      _redirectToLogin('An error occurred during setup. Please login again.');
    }
  }

  // --- FETCH REAL RATINGS ---
  Future<void> fetchDriverRatings() async {
    try {
      print("Fetching driver ratings from API...");
      final data = await _ratingService.getDriverRatings();

      if (data != null && data['overview'] != null) {
        final overview = data['overview'];
        // Update averageRating if available
        if (overview['averageRating'] != null) {
          averageRating.value = (overview['averageRating'] as num).toDouble();
        }
        print("Fetched Real Driver Rating: ${averageRating.value}");
      }
    } catch (e) {
      print("Error fetching driver ratings: $e");
    }
  }

  // --- FETCH REAL STATS FROM HISTORY ---
  Future<void> fetchTodayStats() async {
    isLoadingStats.value = true;
    try {
      final response = await _httpService.get(
        ApiConfig.driverTripHistoryEndpoint,
        queryParameters: {'period': 'today'},
      );

      final responseData = _httpService.handleResponse(response);

      if (responseData['status'] == 'success' && responseData['data'] != null) {
        final List trips = responseData['data'] is List
            ? responseData['data']
            : (responseData['data']['trips'] ?? []);

        double totalEarned = 0.0;
        int count = 0;
        double totalDurationMinutes = 0.0;

        for (var trip in trips) {
          if (trip['price'] != null) {
            totalEarned += (trip['price'] as num).toDouble();
          } else if (trip['fare'] != null) {
            totalEarned += (trip['fare'] as num).toDouble();
          }

          if (trip['duration'] != null) {
            totalDurationMinutes += (trip['duration'] as num).toDouble();
          }
          count++;
        }

        todayEarnings.value = totalEarned;
        todayTrips.value = count;
        todayHours.value = double.parse(
          (totalDurationMinutes / 60).toStringAsFixed(1),
        );

        todayTripsCount.value = count;
        print("Fetched Today's Stats: ₦$totalEarned, $count trips");
      }
    } catch (e) {
      print("Error fetching today's stats: $e");
    } finally {
      isLoadingStats.value = false;
    }
  }

  /// Handles 'wallet:update'
  void _handleWalletUpdate(dynamic data) {
    if (data is Map<String, dynamic>) {
      final String message = data['message'] ?? 'Wallet updated';
      THelperFunctions.showSuccessSnackBar('Earnings Update', message);
      print("Dashboard: Refreshing stats due to wallet update.");
      fetchTodayStats();
    }
  }

  /// Handles 'payment:processed'
  void _handlePaymentProcessed(dynamic data) {
    if (data is Map<String, dynamic>) {
      final amount = data['amount'];
      final amountString = amount != null ? '₦$amount' : '';
      THelperFunctions.showSuccessSnackBar(
        'Payment Received',
        'Payment of $amountString has been processed successfully.',
      );
      print("Dashboard: Refreshing stats due to processed payment.");
      fetchTodayStats();
    }
  }

  Future<bool> _fetchDriverProfile() async {
    print("Fetching driver profile...");
    try {
      final response = await _httpService.get(ApiConfig.driverProfileEndpoint);
      final responseData = _httpService.handleResponse(response);

      if (responseData['status'] == 'success' && responseData['data'] is Map) {
        final profileData = responseData['data'] as Map<String, dynamic>;
        currentDriver.value = User.fromDriverProfileJson(profileData);

        if (currentDriver.value?.driverProfile != null) {
          final profile = currentDriver.value!.driverProfile!;

          driverOperationalStatus.value = profile.status.toLowerCase();
          driverTaskStatus.value = profile.availabilityStatus.toLowerCase();
          isOnBreak.value = profileData['break']?['isOnBreak'] ?? false;

          // Note: We use fetchDriverRatings for rating, but we can init with profile values
          // acceptanceRate.value = profile.acceptanceRate;
          // cancellationRate.value = profile.cancellationRate;

          print("Driver Profile successfully fetched and parsed.");
          return true;
        } else {
          print("Error: Parsed profile data is missing 'driverProfile'.");
          return false;
        }
      } else {
        print("Profile fetch API returned status != success.");
        return false;
      }
    } on ApiException catch (e) {
      print("API Error fetching driver profile: ${e.message}");
      return false;
    } catch (e) {
      print("Unexpected Error fetching driver profile: $e");
      return false;
    }
  }

  void _updateInitialLocation() {
    final profileLocation =
        currentDriver.value?.driverProfile?.location.coordinates;
    final lastUpdate = currentDriver.value?.driverProfile?.lastLocationUpdate;
    bool useProfileLocation = false;

    if (profileLocation != null && lastUpdate != null) {
      if (DateTime.now().difference(lastUpdate).inMinutes < 5) {
        currentLocation.value = profileLocation;
        useProfileLocation = true;
      }
    }

    if (!useProfileLocation) {
      _locationService.ensureLocationAvailable();
      final position = _locationService.getLocationForMap();
      currentLocation.value = LatLng(position.latitude, position.longitude);
    }

    _tripController?.driverLocation.value = currentLocation.value;
  }

  void _connectWebSocket() {
    if (HttpService.instance.isAuthenticated &&
        driverOperationalStatus.value != 'banned' &&
        driverOperationalStatus.value != 'suspended') {
      print("Connecting WebSocket for driver...");
      _webSocketService.connect();
    } else {
      print("Skipping WebSocket connection: Not authenticated or restricted.");
    }
  }

  void _redirectToLogin(String message) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _webSocketService.disconnect();
      _statusRefreshTimer?.cancel();
      Get.offAll(() => const LoginScreenGetX());
      THelperFunctions.showSnackBar(message);
    });
  }

  void _initializeTripManagementAndStatusPolling() {
    try {
      if (!Get.isRegistered<TripManagementController>()) {
        _tripController = Get.put(TripManagementController());
      } else {
        _tripController = Get.find<TripManagementController>();
      }

      // Listener 1: Show Trip Request Screen
      ever(_tripController!.hasNewRequest, (bool hasRequest) {
        if (hasRequest &&
            isOnline.value &&
            driverTaskStatus.value == 'available' &&
            !isOnBreak.value) {
          _showTripRequestNotification();
        }
      });

      // Listener 2: Update task status based on trip progress
      ever(_tripController!.tripStatus, (TripStatus tripProgressStatus) {
        String newDriverTaskStatus = driverTaskStatus.value;

        switch (tripProgressStatus) {
          case TripStatus.accepted:
            newDriverTaskStatus = 'accepted';
            break;
          case TripStatus.drivingToPickup:
          case TripStatus.arrivedAtPickup:
          case TripStatus.tripInProgress:
          case TripStatus.arrivedAtDestination:
            newDriverTaskStatus = 'on_trip';
            break;
          case TripStatus.completed:
          case TripStatus.cancelled:
          case TripStatus.none:
            // Trip ended. Re-check status from API.
            if (driverTaskStatus.value == 'on_trip' ||
                driverTaskStatus.value == 'accepted') {
              print("Trip ended/cleared. Re-evaluating status via API...");
              checkDriverStatus();
            }
            return;
          default:
            break;
        }

        if (driverTaskStatus.value != newDriverTaskStatus) {
          driverTaskStatus.value = newDriverTaskStatus;

          if (newDriverTaskStatus == 'on_trip' ||
              newDriverTaskStatus == 'accepted') {
            isOnline.value = true;
            if (isOnBreak.value) {
              isOnBreak.value = false;
              _breakEndTimer?.cancel();
              breakEndsAt.value = null;
            }
          }
          update();
          _tripController?.forceLocationUpdate(
            statusOverride: newDriverTaskStatus,
          );
        }
      });
    } catch (e) {
      print('Error initializing trip management listener in Dashboard: $e');
    }

    // Start Periodic Status Polling
    _statusRefreshTimer?.cancel();
    _statusRefreshTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (HttpService.instance.isAuthenticated) {
        checkDriverStatus();
      } else {
        timer.cancel();
      }
    });
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
    try {
      Get.to(() => const TripRequestScreen());
    } catch (e) {
      print('Navigation error showing trip request: $e');
    }
  }

  void updateEarningsFromCompletedTrip(ActiveTrip? completedTrip) {
    if (completedTrip != null && completedTrip.status == TripStatus.completed) {
      print(
        "Dashboard: Updating earnings for completed trip ${completedTrip.id}",
      );
      todayEarnings.value += completedTrip.fare;
      todayTrips.value += 1;
    }
  }

  Future<void> checkDriverStatus() async {
    try {
      final response = await _httpService.get(ApiConfig.driverStatusEndpoint);
      final responseData = _httpService.handleResponse(response);

      if (responseData['status'] == 'success' && responseData['data'] is Map) {
        final Map<String, dynamic> data = responseData['data'];

        // 1. Operational Status
        final String? apiAccountStatus = data['accountStatus'] as String?;
        if (apiAccountStatus != null) {
          final statusLower = apiAccountStatus.toLowerCase();
          if (driverOperationalStatus.value != statusLower) {
            driverOperationalStatus.value = statusLower;
          }
          if (statusLower == 'banned' || statusLower == 'suspended') {
            final String apiMessage =
                data['message'] as String? ?? "Account restricted.";
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _handleAccountRestriction(statusLower, apiMessage);
            });
            return;
          }
        }

        // 2. Task Status
        final String? apiAvailability = data['availability'] as String?;
        if (apiAvailability != null) {
          driverTaskStatus.value = apiAvailability.toLowerCase();
        }

        // 3. Break Status
        final bool? apiIsOnBreak = data['isOnBreak'] as bool?;
        if (apiIsOnBreak != null) {
          isOnBreak.value = apiIsOnBreak;
          if (apiIsOnBreak) {
            isOnline.value = false;
          } else {
            breakEndsAt.value = null;
            _breakEndTimer?.cancel();
          }
        }
      }
    } catch (e) {
      print("Error checking driver status: $e");
    } finally {
      update();
    }
  }

  void _handleAccountRestriction(String status, String message) {
    String title = status == 'banned' ? 'Account Banned' : 'Account Suspended';
    String displayMessage =
        message.isNotEmpty &&
            !message.toLowerCase().contains("could not be determined")
        ? message
        : 'Your driver account has been restricted.';

    final settingsController = Get.find<SettingsController>();
    settingsController.logout().then((_) {
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
    });
  }

  Future<void> toggleDriverStatus() async {
    if (isLoadingStatus.value) return;

    if (driverOperationalStatus.value != 'active') {
      _showOperationalStatusError();
      return;
    }
    if (isOnBreak.value) {
      THelperFunctions.showSnackBar(
        'End your break first before changing online status.',
      );
      return;
    }
    if (_tripController?.hasActiveTrip ?? false) {
      THelperFunctions.showSnackBar('Cannot change status while on a trip.');
      await checkDriverStatus();
      return;
    }

    isLoadingStatus.value = true;
    bool targetIsOnline = !isOnline.value;
    THelperFunctions.showSnackBar(
      targetIsOnline ? 'Going Online...' : 'Going Offline...',
    );
    update();

    if (targetIsOnline) {
      bool serviceEnabled = await _locationService.isLocationServiceEnabled();
      bool permissionGranted = await _locationService
          .requestLocationPermission();
      if (!serviceEnabled || !permissionGranted) {
        isOnline.value = false;
        update();
        THelperFunctions.showSnackBar(
          serviceEnabled
              ? 'Location permission needed.'
              : 'Please enable location services.',
        );
        isLoadingStatus.value = false;
        return;
      }
      await _tripController?.updateCurrentStateFromLocation();
    }

    try {
      final statusToSend = targetIsOnline ? 'available' : 'unavailable';
      _webSocketService.updateDriverAvailability(statusToSend);
      _tripController?.forceLocationUpdate(statusOverride: statusToSend);

      await Future.delayed(const Duration(seconds: 2));
      await checkDriverStatus();
      final actualStatus = driverTaskStatus.value;

      if (targetIsOnline && actualStatus == 'available') {
        THelperFunctions.showSuccessSnackBar('Success', 'You are now Online');
        isOnline.value = true;
      } else if (!targetIsOnline && actualStatus == 'unavailable') {
        THelperFunctions.showSuccessSnackBar('Success', 'You are now Offline');
        isOnline.value = false;
      }
    } catch (e) {
      THelperFunctions.showErrorSnackBar(
        "Error",
        "An error occurred. Please try again.",
      );
    } finally {
      isLoadingStatus.value = false;
      update();
    }
  }

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
      default:
        message = 'Your account is not active. Cannot change status.';
        break;
    }
    THelperFunctions.showSnackBar(message);
  }

  Future<void> startBreak(int durationMinutes) async {
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
        isOnBreak.value = true;
        isOnline.value = false;
        driverTaskStatus.value = 'break';

        if (responseData['data']?['breakEndsAt'] != null) {
          breakEndsAt.value = DateTime.tryParse(
            responseData['data']['breakEndsAt'],
          );
        } else {
          breakEndsAt.value = DateTime.now().add(
            Duration(minutes: durationMinutes),
          );
        }

        _scheduleLocalBreakEndUpdate();
        THelperFunctions.showSnackBar(
          responseData['message'] ?? 'Break started successfully.',
        );

        _webSocketService.updateDriverAvailability('unavailable');
        _tripController?.forceLocationUpdate(statusOverride: 'unavailable');
        update();
      } else {
        THelperFunctions.showSnackBar(
          responseData['message'] ?? 'Could not start break.',
        );
        await checkDriverStatus();
      }
    } catch (e) {
      THelperFunctions.showSnackBar('Error starting break: ${e.toString()}');
      await checkDriverStatus();
    }
  }

  Future<void> endBreak() async {
    try {
      final response = await _httpService.post(ApiConfig.endBreakEndpoint);
      final responseData = _httpService.handleResponse(response);

      if (responseData['status'] == 'success') {
        _clearBreakState();
        THelperFunctions.showSnackBar(
          responseData['message'] ?? 'Break ended successfully.',
        );
        _webSocketService.updateDriverAvailability('available');
        _tripController?.forceLocationUpdate(statusOverride: 'available');
      } else {
        await checkDriverStatus();
      }
    } catch (e) {
      await checkDriverStatus();
    }
  }

  void _scheduleLocalBreakEndUpdate() {
    _breakEndTimer?.cancel();
    if (breakEndsAt.value != null) {
      final now = DateTime.now();
      final durationUntilEnd = breakEndsAt.value!.difference(now);

      if (durationUntilEnd.isNegative || durationUntilEnd.inSeconds < 1) {
        endBreak();
      } else {
        _breakEndTimer = Timer(durationUntilEnd, () {
          endBreak();
        });
      }
    }
  }

  void _clearBreakState({bool syncWithApi = true}) {
    if (isOnBreak.value || driverTaskStatus.value == 'break') {
      isOnBreak.value = false;
      breakEndsAt.value = null;
      _breakEndTimer?.cancel();
      isOnline.value = true;

      if (syncWithApi) {
        _tripController?.forceLocationUpdate(statusOverride: 'available');
      }
      update();
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

  // --- Utility Getters ---
  String get statusText {
    if (isOnBreak.value) {
      if (breakEndsAt.value != null) {
        final formatter = DateFormat('h:mm a');
        if (breakEndsAt.value!.isBefore(DateTime.now())) {
          return 'Ending Break...';
        }
        return 'On Break until ${formatter.format(breakEndsAt.value!)}';
      }
      return 'On Break';
    }

    switch (driverTaskStatus.value) {
      case 'on_trip':
        return _tripController?.currentTripStatusDisplay ?? 'On Trip';
      case 'available':
        return 'Online - Ready';
      case 'break':
        return 'On Break';
      default:
        switch (driverOperationalStatus.value) {
          case 'unverified':
            return 'Offline - Verification Required';
          case 'rejected':
            return 'Offline - Documents Rejected';
          case 'pending':
            return 'Offline - Verification Pending';
          case 'suspended':
            return 'Offline - Account Suspended';
          default:
            return 'Offline';
        }
    }
  }

  Color get statusColor {
    if (isOnBreak.value) return TColors.secondary;

    switch (driverTaskStatus.value) {
      case 'on_trip':
        return TColors.info;
      case 'available':
        return TColors.onlineStatus;
      case 'break':
        return TColors.secondary;
      default:
        if ([
          'rejected',
          'suspended',
          'banned',
        ].contains(driverOperationalStatus.value)) {
          return TColors.error;
        }
        if (['unverified', 'pending'].contains(driverOperationalStatus.value)) {
          return TColors.warning;
        }
        return TColors.offlineStatus;
    }
  }

  String get formattedTodayEarnings =>
      '₦${todayEarnings.value.toStringAsFixed(0)}';
  bool get hasActiveTrip => _tripController?.hasActiveTrip ?? false;
}
