import 'dart:async';
import 'dart:math';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

// --- Local Imports ---
import 'package:sarri_ride/features/shared/models/user_model.dart';
import 'package:sarri_ride/features/shared/services/demo_data.dart';
import 'package:sarri_ride/features/location/services/location_service.dart';
import 'package:sarri_ride/features/location/services/route_service.dart';
import 'package:sarri_ride/utils/constants/enums.dart'; // Ensure TripStatus enum is here
import 'package:sarri_ride/utils/helpers/helper_functions.dart';
import 'package:sarri_ride/utils/constants/colors.dart';
import 'package:sarri_ride/features/driver/controllers/driver_dashboard_controller.dart';
import 'package:sarri_ride/core/services/websocket_service.dart';
import 'package:sarri_ride/features/authentication/screens/login/login_screen_getx.dart';
import 'package:sarri_ride/features/driver/screens/trip_request_screen.dart';
import 'package:sarri_ride/features/driver/screens/trip_navigation_screen.dart';

// Define enums and models locally ONLY IF they aren't imported correctly
// Ensure TripStatus includes arrivedAtDestination from enums.dart

enum DriverTripStatus {
  // This is for the Test Screen flow specifically
  none,
  hasNewRequest,
  drivingToPickup,
  arrivedAtPickup,
  tripInProgress,
  arrivedAtDestination,
  tripCompleted,
  cancelled,
}

// Trip Request Model (Ensure consistency with actual model file or define here)
class TripRequest {
  final String id;
  final String riderId;
  final String riderName;
  final String riderPhone;
  final double riderRating;
  final LatLng pickupLocation;
  final LatLng destinationLocation;
  final String pickupAddress;
  final String destinationAddress;
  final DateTime requestTime;
  final double estimatedFare;
  final double estimatedDistance;
  final int estimatedDuration;
  final String rideType;

  const TripRequest({
    required this.id,
    required this.riderId,
    required this.riderName,
    required this.riderPhone,
    required this.riderRating,
    required this.pickupLocation,
    required this.destinationLocation,
    required this.pickupAddress,
    required this.destinationAddress,
    required this.requestTime,
    required this.estimatedFare,
    required this.estimatedDistance,
    required this.estimatedDuration,
    required this.rideType,
  });
}

// Active Trip Model (Ensure consistency with actual model file or define here)
class ActiveTrip {
  final String id;
  final String riderId;
  final String riderName;
  final String riderPhone;
  final double riderRating;
  final LatLng pickupLocation;
  final LatLng destinationLocation;
  final String pickupAddress;
  final String destinationAddress;
  final double fare;
  final double distance;
  final int estimatedDuration;
  final String rideType;
  final DateTime startTime;
  final TripStatus status;
  final DateTime? arrivalTime;
  final DateTime? pickupTime;
  final DateTime? endTime;
  final double? actualDistance;
  final int? actualDuration;
  final String? cancellationReason;

  const ActiveTrip({
    required this.id,
    required this.riderId,
    required this.riderName,
    required this.riderPhone,
    required this.riderRating,
    required this.pickupLocation,
    required this.destinationLocation,
    required this.pickupAddress,
    required this.destinationAddress,
    required this.fare,
    required this.distance,
    required this.estimatedDuration,
    required this.rideType,
    required this.startTime,
    required this.status,
    this.arrivalTime,
    this.pickupTime,
    this.endTime,
    this.actualDistance,
    this.actualDuration,
    this.cancellationReason,
  });

  ActiveTrip copyWith({
    String? id,
    String? riderId,
    String? riderName,
    String? riderPhone,
    double? riderRating,
    LatLng? pickupLocation,
    LatLng? destinationLocation,
    String? pickupAddress,
    String? destinationAddress,
    double? fare,
    double? distance,
    int? estimatedDuration,
    String? rideType,
    DateTime? startTime,
    TripStatus? status,
    DateTime? arrivalTime,
    DateTime? pickupTime,
    DateTime? endTime,
    double? actualDistance,
    int? actualDuration,
    String? cancellationReason,
  }) {
    return ActiveTrip(
      id: id ?? this.id,
      riderId: riderId ?? this.riderId,
      riderName: riderName ?? this.riderName,
      riderPhone: riderPhone ?? this.riderPhone,
      riderRating: riderRating ?? this.riderRating,
      pickupLocation: pickupLocation ?? this.pickupLocation,
      destinationLocation: destinationLocation ?? this.destinationLocation,
      pickupAddress: pickupAddress ?? this.pickupAddress,
      destinationAddress: destinationAddress ?? this.destinationAddress,
      fare: fare ?? this.fare,
      distance: distance ?? this.distance,
      estimatedDuration: estimatedDuration ?? this.estimatedDuration,
      rideType: rideType ?? this.rideType,
      startTime: startTime ?? this.startTime,
      status: status ?? this.status,
      arrivalTime: arrivalTime ?? this.arrivalTime,
      pickupTime: pickupTime ?? this.pickupTime,
      endTime: endTime ?? this.endTime,
      actualDistance: actualDistance ?? this.actualDistance,
      actualDuration: actualDuration ?? this.actualDuration,
      cancellationReason: cancellationReason ?? this.cancellationReason,
    );
  }
}

class TripManagementController extends GetxController {
  static TripManagementController get instance => Get.find();

  // Services
  final LocationService _locationService = LocationService.instance;
  final DemoDataService _demoDataService = DemoDataService.instance;
  final WebSocketService _webSocketService = WebSocketService.instance;
  // Use a lazy getter for DashboardController to avoid initialization issues
  DriverDashboardController? get _dashboardController =>
      Get.isRegistered<DriverDashboardController>()
      ? Get.find<DriverDashboardController>()
      : null;

  // State
  final Rx<TripRequest?> currentTripRequest = Rx<TripRequest?>(null);
  final Rx<ActiveTrip?> activeTrip = Rx<ActiveTrip?>(null);
  final Rx<TripStatus> tripStatus = TripStatus.none.obs; // Main status

  // Test Screen State
  final Rx<DriverTripStatus> driverTripStatus =
      DriverTripStatus.none.obs; // Test flow status
  final RxString riderName = ''.obs;
  final RxString pickupAddress = ''.obs;
  final RxString destinationAddress = ''.obs;

  // Location & Map
  final Rx<LatLng?> driverLocation = Rx<LatLng?>(null);
  final RxSet<Marker> mapMarkers = <Marker>{}.obs;
  final RxSet<Polyline> mapPolylines = <Polyline>{}.obs;
  final RxList<LatLng> currentRoute = <LatLng>[].obs;
  GoogleMapController? mapController;
  // --- ADDED for custom marker and rotation ---
  BitmapDescriptor? driverIcon;
  LatLng? _previousDriverLocation;

  // Request Handling
  final RxBool hasNewRequest = false.obs;
  final RxInt requestTimeLeft = 15.obs;
  Timer? _requestTimer;
  final RxBool isGeneratingRequest = false.obs;

  // Navigation State
  final RxBool isNavigating = false.obs;
  final RxString navigationInstruction = ''.obs;
  final RxDouble distanceToDestination = 0.0.obs;
  final RxInt estimatedTimeToDestination = 0.obs;
  Timer? _navigationTimer;
  Timer? _locationUpdateTimer;

  // Initial Route Estimates
  double _initialRouteDistanceKm = 0.0;
  int _initialRouteDurationMinutes = 0;
  DateTime? _navigationStartTime;

  /// Helper to check if there is an ongoing trip (not just accepted, but actually started or heading to pickup).
  bool get hasActiveTrip =>
      activeTrip.value != null &&
      tripStatus.value != TripStatus.none &&
      tripStatus.value != TripStatus.completed &&
      tripStatus.value != TripStatus.cancelled;

  // --- ADDED GETTER ---
  /// Provides a user-friendly string representation of the current trip status.
  String get currentTripStatusDisplay {
    if (activeTrip.value == null && tripStatus.value == TripStatus.none) {
      return 'No Active Trip';
    }
    switch (tripStatus.value) {
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
      case TripStatus.requested: // Added requested state if applicable
        return 'Trip Requested';
      default: // Handles TripStatus.none when activeTrip is not null (shouldn't happen often)
        return 'Trip Status Unknown';
    }
  }
  // --- END GETTER ---

  @override
  void onInit() {
    super.onInit();
    _initializeLocationTracking();
    _loadCustomMarker();
    // _startListeningForTripRequests(); // Keep commented unless needed for testing
  }

  Future<void> _loadCustomMarker() async {
    try {
      driverIcon = await BitmapDescriptor.fromAssetImage(
        const ImageConfiguration(size: Size(48, 48)), // Adjust size as needed
        'assets/icons/map_pin_darkmode.png', // Path from pubspec.yaml
      );
      print("TripManagement: Custom driver icon loaded.");
      // Update marker if already on map
      _updateDriverLocationOnMap();
    } catch (e) {
      print("TripManagement: Error loading custom driver marker: $e");
    }
  }

  /// Calculates the bearing between two points in degrees.
  double _calculateBearing(LatLng start, LatLng end) {
    double lat1 = start.latitude * math.pi / 180;
    double lon1 = start.longitude * math.pi / 180;
    double lat2 = end.latitude * math.pi / 180;
    double lon2 = end.longitude * math.pi / 180;

    double dLon = lon2 - lon1;
    double y = math.sin(dLon) * math.cos(lat2);
    double x =
        math.cos(lat1) * math.sin(lat2) -
        math.sin(lat1) * math.cos(lat2) * math.cos(dLon);
    double bearing = math.atan2(y, x);

    bearing = bearing * 180 / math.pi; // Convert to degrees
    return (bearing + 360) % 360; // Normalize to 0-360
  }

  @override
  void onClose() {
    _requestTimer?.cancel();
    _navigationTimer?.cancel();
    _locationUpdateTimer?.cancel();
    super.onClose();
  }

  // Initialize location tracking AND WebSocket emission
  void _initializeLocationTracking() {
    _locationService.ensureLocationAvailable();
    final initialPosition = _locationService.getLocationForMap();
    driverLocation.value = LatLng(
      initialPosition.latitude,
      initialPosition.longitude,
    );
    _previousDriverLocation =
        driverLocation.value; // --- ADDED: Set initial previous location
    _updateDriverLocationOnMap(); // Add initial marker

    _locationUpdateTimer?.cancel();
    _locationUpdateTimer = Timer.periodic(const Duration(seconds: 10), (
      timer,
    ) async {
      try {
        // --- (This logic is slightly different from RideController, it uses getLocationForMap) ---
        final position = _locationService.getLocationForMap();
        final newLocation = LatLng(position.latitude, position.longitude);

        if (driverLocation.value == null ||
            _calculateDistance(driverLocation.value!, newLocation) > 0.01) {
          driverLocation.value = newLocation;
          _updateDriverLocationOnMap(); // --- MODIFIED: This will now handle rotation
        }

        // --- (Rest of WebSocket emission logic as before) ---
        final bool isOnlineIntent =
            _dashboardController?.isOnline.value ?? false;
        final bool isOnBreak = _dashboardController?.isOnBreak.value ?? false;
        final String currentTaskStatus =
            _dashboardController?.driverTaskStatus.value ?? 'unavailable';
        final isSocketConnected = _webSocketService.isConnected.value;

        if (isSocketConnected && driverLocation.value != null) {
          String availabilityStatusToSend;
          if (isOnBreak) {
            availabilityStatusToSend = 'unavailable';
          } else if (currentTaskStatus == 'on_trip') {
            availabilityStatusToSend = 'on_trip';
          } else if (isOnlineIntent && currentTaskStatus == 'available') {
            availabilityStatusToSend = 'available';
          } else {
            availabilityStatusToSend = 'unavailable';
          }

          if (availabilityStatusToSend == 'available' ||
              availabilityStatusToSend == 'on_trip' ||
              availabilityStatusToSend == 'unavailable') {
            _webSocketService.updateDriverLocation(
              latitude: driverLocation.value!.latitude,
              longitude: driverLocation.value!.longitude,
              state: 'Lagos',
              availabilityStatus: availabilityStatusToSend,
            );
          }
        }
        // --- End WebSocket logic ---
      } catch (e) {
        print("Error in location update timer: $e");
      }
    });
  }

  /// Forces an immediate location update emission via WebSocket.
  /// Uses the dashboard controller's state to determine the current status unless overridden.
  void forceLocationUpdate({String? statusOverride}) {
    print("Forcing location update emission. Override: $statusOverride");
    if (!_webSocketService.isConnected.value) {
      print("Cannot force update: WebSocket not connected.");
      return;
    }
    if (driverLocation.value == null) {
      print("Cannot force update: Driver location unknown.");
      return;
    }

    String availabilityStatusToSend;

    if (statusOverride != null) {
      availabilityStatusToSend = statusOverride;
    } else {
      // Determine status based on dashboard controller state
      final bool isOnlineIntent = _dashboardController?.isOnline.value ?? false;
      final bool isOnBreak = _dashboardController?.isOnBreak.value ?? false;
      final String currentTaskStatus =
          _dashboardController?.driverTaskStatus.value ?? 'unavailable';

      if (isOnBreak) {
        availabilityStatusToSend = 'unavailable';
      } else if (currentTaskStatus == 'on_trip') {
        availabilityStatusToSend = 'on_trip';
      } else if (isOnlineIntent && currentTaskStatus == 'available') {
        availabilityStatusToSend = 'available';
      } else {
        availabilityStatusToSend = 'unavailable';
      }
    }

    // Only emit relevant statuses
    if (availabilityStatusToSend == 'available' ||
        availabilityStatusToSend == 'on_trip' ||
        availabilityStatusToSend == 'unavailable') {
      _webSocketService.updateDriverLocation(
        latitude: driverLocation.value!.latitude,
        longitude: driverLocation.value!.longitude,
        state: 'Lagos', // Placeholder
        availabilityStatus: availabilityStatusToSend,
      );
      print(
        "Forced location update emitted with status: $availabilityStatusToSend",
      );
    } else {
      print(
        "Skipping forced update: Status '$availabilityStatusToSend' is not relevant.",
      );
    }
  }

  // Start listening for trip requests (Simulation - Keep for testing?)
  void _startListeningForTripRequests() {
    /* ... (as before) ... */
  }

  // Check if driver is online (Uses dashboard controller)
  bool _isDriverOnline() {
    return _dashboardController?.isOnline.value ?? false;
  }

  // Simulate new trip request (Keep for potential testing)
  void _simulateNewTripRequest() {
    /* ... (implementation as before using _getRandomRiderName etc.) ... */
  }

  // Show trip request to driver (Called by WebSocket listener or simulation)
  void showTripRequest(TripRequest request) {
    if (currentTripRequest.value != null || hasActiveTrip) {
      print(
        "Skipping new trip request display: Already handling a request or trip.",
      );
      // Optionally inform backend the driver is busy if needed
      // _webSocketService.emit('driver:busy', {'rideId': request.id});
      return;
    }
    print("Showing trip request: ${request.id}");
    currentTripRequest.value = request;
    hasNewRequest.value = true;
    requestTimeLeft.value = 15; // Reset timer

    _requestTimer?.cancel();
    _requestTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      requestTimeLeft.value--;
      if (requestTimeLeft.value <= 0) {
        timer.cancel();
        // Check if the *same* request is still active before declining
        if (currentTripRequest.value?.id == request.id) {
          print("Trip request ${request.id} timed out.");
          declineTripRequest(); // Auto-decline on timeout
        }
      }
    });

    _addPickupMarker(request.pickupLocation); // Show pickup on map

    // Navigate to TripRequestScreen only if not already there
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (Get.currentRoute != '/TripRequestScreen') {
        Get.to(() => const TripRequestScreen());
      }
    });
  }

  // Accept trip request
  Future<void> acceptTripRequest() async {
    if (currentTripRequest.value == null) {
      print("Cannot accept: No current trip request.");
      return;
    }
    _requestTimer?.cancel(); // Stop timeout timer
    hasNewRequest.value = false; // Clear flag immediately for UI feedback
    final request = currentTripRequest.value!; // Store request before clearing
    print("Accepting trip request: ${request.id}");

    // --- TEMPORARILY SET UI STATE ---
    // This provides faster feedback, assuming acceptance is likely.
    // The state will be corrected if the ack fails.
    tripStatus.value = TripStatus.accepted;
    activeTrip.value = ActiveTrip(
      // Create a temporary ActiveTrip
      id: request.id,
      riderId: request.riderId,
      riderName: request.riderName,
      riderPhone: request.riderPhone,
      riderRating: request.riderRating,
      pickupLocation: request.pickupLocation,
      destinationLocation: request.destinationLocation,
      pickupAddress: request.pickupAddress,
      destinationAddress: request.destinationAddress,
      fare: request.estimatedFare,
      distance: request.estimatedDistance,
      estimatedDuration: request.estimatedDuration,
      rideType: request.rideType,
      startTime: DateTime.now(),
      status: TripStatus.accepted,
    );
    currentTripRequest.value = null; // Clear the request object now
    update(); // Update UI optimistically
    // --- END TEMPORARY STATE ---

    _webSocketService.emitWithAck(
      'ride:accept',
      {'rideId': request.id},
      ack: (response) {
        if (response is Map && response['status'] == 'success') {
          print(
            "Backend acknowledged ride acceptance for ${request.id}. Proceeding...",
          );
          // Confirmation received, proceed with navigation setup
          _proceedWithAcceptedTrip(request); // Call the main logic now
        } else {
          print(
            "Backend rejected ride acceptance for ${request.id}: ${response['message'] ?? response}",
          );
          // --- REVERT UI STATE ON FAILURE ---
          tripStatus.value = TripStatus.none;
          activeTrip.value = null; // Clear temporary ActiveTrip
          currentTripRequest.value = request; // Restore the request object
          hasNewRequest.value = true; // Show request again
          update(); // Revert UI
          // --- END REVERT ---
          THelperFunctions.showSnackBar(
            "Could not accept ride: ${response['message'] ?? 'Server error'}",
          );
        }
      },
    );
  }

  // Handles logic AFTER backend confirms acceptance
  Future<void> _proceedWithAcceptedTrip(TripRequest request) async {
    print("Proceeding with accepted trip navigation setup: ${request.id}");
    // The activeTrip and tripStatus were already set optimistically in acceptTripRequest
    // Now just start the navigation process.
    await _startNavigationToPickup();
    THelperFunctions.showSnackBar('Trip accepted! Navigate to pickup.');

    // Navigate back from request screen if needed
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (Get.currentRoute == '/TripRequestScreen') {
        Get.back();
      }
      // Optionally navigate to NavigationScreen automatically
      // else if (Get.currentRoute != '/TripNavigationScreen') {
      //    Get.to(() => const TripNavigationScreen());
      // }
    });
    update(); // Ensure UI reflects navigation state
  }

  // Decline trip request
  void declineTripRequest() {
    if (currentTripRequest.value == null) {
      print("Cannot decline: No current trip request.");
      return;
    }
    _requestTimer?.cancel();
    final requestId = currentTripRequest.value!.id;
    print("Declining trip request: $requestId");

    // Clear local state immediately
    currentTripRequest.value = null;
    hasNewRequest.value = false;
    requestTimeLeft.value = 15; // Reset timer value for next potential request
    mapMarkers.removeWhere(
      (marker) => marker.markerId.value == 'pickup',
    ); // Remove marker

    // Notify backend
    _webSocketService.emit('ride:reject', {
      'rideId': requestId,
      'reason': 'Driver declined', // Or 'Timed out' if applicable
    });

    THelperFunctions.showSnackBar('Trip request declined');

    // Simulate looking for new request (optional UI feedback)
    // isGeneratingRequest.value = true;
    // Timer(const Duration(seconds: 10), () { isGeneratingRequest.value = false; });

    // Navigate back from request screen if currently on it
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (Get.currentRoute == '/TripRequestScreen') {
        Get.back();
      }
    });
    update(); // Update UI
  }

  // Start navigation to pickup location
  Future<void> _startNavigationToPickup() async {
    if (activeTrip.value == null || driverLocation.value == null) {
      print(
        "Cannot start navigation to pickup: Missing active trip or driver location.",
      );
      return;
    }
    print("Starting navigation to pickup: ${activeTrip.value!.pickupAddress}");
    tripStatus.value = TripStatus.drivingToPickup; // Update status
    isNavigating.value = true;

    try {
      final routeInfo = await RouteService.getRouteInfo(
        driverLocation.value!,
        activeTrip.value!.pickupLocation,
      );
      print(
        "Route to pickup calculated: ${routeInfo.distance}, ${routeInfo.duration}",
      );

      currentRoute.assignAll(routeInfo.points);
      _initialRouteDistanceKm = routeInfo.distanceValue / 1000.0;
      _initialRouteDurationMinutes = (routeInfo.durationValue / 60).round();
      _navigationStartTime = DateTime.now();

      mapPolylines.clear();
      mapPolylines.add(
        Polyline(
          polylineId: const PolylineId('route_to_pickup'),
          points: routeInfo.points,
          color: TColors.primary,
          width: 5,
        ),
      );

      _addPickupMarker(
        activeTrip.value!.pickupLocation,
      ); // Ensure pickup marker is visible
      _updateDriverLocationOnMap(); // Ensure driver marker is visible

      _startNavigationUpdates(); // Start timer for ETA/distance updates

      // Set initial display values
      navigationInstruction.value =
          'Head to pickup: ${activeTrip.value!.pickupAddress}';
      distanceToDestination.value = _initialRouteDistanceKm;
      estimatedTimeToDestination.value = _initialRouteDurationMinutes;

      _fitMapToCurrentRoute(); // Adjust map view
    } catch (e) {
      print('Error getting route to pickup: $e');
      THelperFunctions.showSnackBar('Error calculating route to pickup.');
      isNavigating.value = false;
      tripStatus.value = TripStatus.accepted; // Revert status slightly
      navigationInstruction.value =
          'Could not calculate route. Proceed manually.';
      mapPolylines.clear();
    }
    update();
  }

  // Start navigation to destination
  Future<void> _startNavigationToDestination() async {
    if (activeTrip.value == null || driverLocation.value == null) {
      print(
        "Cannot start navigation to destination: Missing active trip or driver location.",
      );
      return;
    }
    // Ensure driver is actually at pickup location
    if (tripStatus.value != TripStatus.arrivedAtPickup) {
      print(
        "Cannot start trip: Not currently arrived at pickup (Status: ${tripStatus.value}).",
      );
      THelperFunctions.showSnackBar("Confirm arrival at pickup first.");
      return;
    }

    print(
      "Starting navigation to destination: ${activeTrip.value!.destinationAddress}",
    );
    tripStatus.value = TripStatus.tripInProgress; // Update status
    isNavigating.value = true;
    _webSocketService.emit('ride:start', {
      'tripId': activeTrip.value!.id,
    }); // Notify backend

    try {
      final routeInfo = await RouteService.getRouteInfo(
        driverLocation.value!, // Use current driver location as start
        activeTrip.value!.destinationLocation,
      );
      print(
        "Route to destination calculated: ${routeInfo.distance}, ${routeInfo.duration}",
      );

      currentRoute.assignAll(routeInfo.points);
      _initialRouteDistanceKm = routeInfo.distanceValue / 1000.0;
      _initialRouteDurationMinutes = (routeInfo.durationValue / 60).round();
      _navigationStartTime = DateTime.now();

      mapPolylines.clear(); // Clear old route
      mapPolylines.add(
        Polyline(
          polylineId: const PolylineId('route_to_destination'),
          points: routeInfo.points,
          color: TColors.success, // Use different color for main trip
          width: 5,
        ),
      );

      mapMarkers.removeWhere(
        (marker) => marker.markerId.value == 'pickup',
      ); // Remove pickup marker
      _addDestinationMarker(
        activeTrip.value!.destinationLocation,
      ); // Add destination marker
      _updateDriverLocationOnMap(); // Ensure driver marker is visible

      _startNavigationUpdates(); // Restart timer for ETA/distance

      // Set initial display values
      navigationInstruction.value =
          'Head to destination: ${activeTrip.value!.destinationAddress}';
      distanceToDestination.value = _initialRouteDistanceKm;
      estimatedTimeToDestination.value = _initialRouteDurationMinutes;

      // Update ActiveTrip state
      activeTrip.value = activeTrip.value!.copyWith(
        status: TripStatus.tripInProgress,
        pickupTime: DateTime.now(), // Record pickup time
      );

      _fitMapToCurrentRoute(); // Adjust map view
      THelperFunctions.showSnackBar('Trip started! Navigating to destination.');
    } catch (e) {
      print('Error getting route to destination: $e');
      THelperFunctions.showSnackBar('Error calculating route to destination.');
      isNavigating.value = false;
      navigationInstruction.value =
          'Could not calculate route. Proceed manually to ${activeTrip.value!.destinationAddress}.';
      mapPolylines.clear();
      // Still update trip status even if route fails
      activeTrip.value = activeTrip.value!.copyWith(
        status: TripStatus.tripInProgress,
        pickupTime: DateTime.now(),
      );
    }
    update();
  }

  // Start/Restart navigation update timer
  void _startNavigationUpdates() {
    _navigationTimer?.cancel();
    if (currentRoute.isEmpty) {
      print("Cannot start navigation updates: Route is empty.");
      isNavigating.value = false;
      return;
    }
    print("Starting navigation updates timer.");
    isNavigating.value = true;
    _navigationTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      // Check conditions to continue timer
      if (!isNavigating.value ||
          currentRoute.isEmpty ||
          activeTrip.value == null ||
          (tripStatus.value != TripStatus.drivingToPickup &&
              tripStatus.value != TripStatus.tripInProgress)) {
        print("Stopping navigation updates timer. Conditions met.");
        timer.cancel();
        isNavigating.value = false; // Ensure navigation flag is off
        return;
      }

      _updateNavigationInstructions(); // Update distance/ETA display

      // Check proximity only if navigating
      if (_isNearDestination()) {
        print("Driver is near the target location.");
        timer.cancel(); // Stop timer before handling arrival
        isNavigating.value = false;
        _handleArrival(); // Handle arrival logic
      }
    });
  }

  // Update navigation display info (distance/ETA)
  void _updateNavigationInstructions() {
    if (activeTrip.value == null ||
        !isNavigating.value ||
        _navigationStartTime == null ||
        (_initialRouteDurationMinutes <= 0 && _initialRouteDistanceKm <= 0)) {
      // Add check for valid initial values
      // Reset values if navigation shouldn't be active or initial data invalid
      // distanceToDestination.value = 0.0;
      // estimatedTimeToDestination.value = 0;
      return;
    }

    DateTime startTime = _navigationStartTime!;
    double initialDistance = _initialRouteDistanceKm;
    int initialDuration = _initialRouteDurationMinutes;

    // Update instruction text based on current phase
    if (tripStatus.value == TripStatus.drivingToPickup) {
      navigationInstruction.value =
          'Continue to pickup: ${activeTrip.value!.pickupAddress}';
    } else if (tripStatus.value == TripStatus.tripInProgress) {
      navigationInstruction.value =
          'Continue to destination: ${activeTrip.value!.destinationAddress}';
    } else {
      // Should not happen if timer check is correct, but as a safeguard
      isNavigating.value = false;
      _navigationTimer?.cancel();
      return;
    }

    // Simple linear estimation based on initial route (more sophisticated logic needed for real-time traffic)
    if (initialDuration > 0) {
      final elapsedSeconds = DateTime.now().difference(startTime).inSeconds;
      // Use seconds for potentially better granularity if needed, convert back to minutes
      final elapsedMinutes = elapsedSeconds / 60.0;

      // Calculate remaining time, clamp to avoid negative values
      final remainingMinutes = max(0, initialDuration - elapsedMinutes.round());

      // Calculate progress ratio based on time (can also use distance traveled if available)
      final progress = min(
        1.0,
        elapsedMinutes / initialDuration,
      ); // Clamp progress to max 1.0

      // Estimate remaining distance based on progress
      final remainingDistance = max(0.0, initialDistance * (1.0 - progress));

      distanceToDestination.value = remainingDistance;
      estimatedTimeToDestination.value = remainingMinutes;
    } else {
      // Handle cases where initial duration was zero (very short trips)
      distanceToDestination.value = 0.0;
      estimatedTimeToDestination.value = 0;
      // Optionally trigger arrival check immediately if duration was 0
      if (_isNearDestination()) {
        _handleArrival();
      }
    }
    update(); // Notify UI
  }

  // Check if driver is near the current target (pickup or destination)
  bool _isNearDestination() {
    if (driverLocation.value == null || activeTrip.value == null) return false;

    LatLng target;
    // Determine target based on current trip status
    if (tripStatus.value == TripStatus.drivingToPickup) {
      target = activeTrip.value!.pickupLocation;
    } else if (tripStatus.value == TripStatus.tripInProgress) {
      target = activeTrip.value!.destinationLocation;
    } else {
      // Not navigating towards pickup or destination
      return false;
    }

    final distanceKm = _calculateDistance(driverLocation.value!, target);
    // Use a threshold (e.g., 100 meters = 0.1 km)
    return distanceKm < 0.1;
  }

  // Handle arrival at pickup OR destination
  void _handleArrival() {
    if (activeTrip.value == null) return;
    print("Handling arrival at target...");
    _navigationTimer?.cancel(); // Stop ETA updates
    isNavigating.value = false; // Mark navigation as complete for this leg

    if (tripStatus.value == TripStatus.drivingToPickup) {
      print("Arrived at pickup location.");
      tripStatus.value = TripStatus.arrivedAtPickup; // Update status
      navigationInstruction.value = 'Arrived at pickup. Waiting for rider.';
      // Update ActiveTrip state
      activeTrip.value = activeTrip.value!.copyWith(
        status: TripStatus.arrivedAtPickup,
        arrivalTime: DateTime.now(), // Record arrival time
      );
      _webSocketService.emit('ride:arrived', {
        'tripId': activeTrip.value!.id,
      }); // Notify backend
      THelperFunctions.showSnackBar('Arrived at pickup location');
    } else if (tripStatus.value == TripStatus.tripInProgress) {
      print("Arrived at final destination.");
      tripStatus.value = TripStatus.arrivedAtDestination; // Update status
      navigationInstruction.value =
          'Arrived at destination. Tap "Complete Trip".';
      // Update ActiveTrip state (optional, can be done on completeTripManual)
      activeTrip.value = activeTrip.value!.copyWith(
        status: TripStatus.arrivedAtDestination,
        // Don't set endTime here, set it when driver confirms completion
      );
      // Optional: Emit event if backend needs notification upon reaching destination zone
      // _webSocketService.emit('ride:arrivedAtDestination', {'tripId': activeTrip.value!.id});
      THelperFunctions.showSnackBar('Arrived at destination');
    } else {
      // Log if called in an unexpected state
      print("HandleArrival called in unexpected state: ${tripStatus.value}");
    }
    update(); // Update UI
  }

  // Start trip (Driver confirms rider is picked up) - Just calls internal method
  void startTrip() {
    _startNavigationToDestination();
  }

  // Manually complete the trip (called by button press)
  void completeTripManual() {
    if (activeTrip.value == null) {
      print("Cannot complete trip: No active trip.");
      return;
    }
    // Ensure driver has marked arrival at destination first
    if (tripStatus.value != TripStatus.arrivedAtDestination) {
      print(
        "Cannot complete trip: Not yet arrived at destination (Status: ${tripStatus.value}).",
      );
      THelperFunctions.showSnackBar(
        "Please confirm arrival at destination first.",
      );
      return;
    }

    print("Driver manually completing trip ID: ${activeTrip.value!.id}");
    _navigationTimer?.cancel(); // Ensure timer is stopped
    isNavigating.value = false;
    tripStatus.value = TripStatus.completed; // Update status

    // Calculate actual duration
    DateTime tripStartTime =
        activeTrip.value!.pickupTime ??
        activeTrip.value!.startTime; // Use pickup time if available
    int actualDurationMinutes = DateTime.now()
        .difference(tripStartTime)
        .inMinutes;

    // Update ActiveTrip state
    activeTrip.value = activeTrip.value!.copyWith(
      status: TripStatus.completed,
      endTime: DateTime.now(),
      // Use estimated distance for now, replace with calculated if available
      actualDistance: activeTrip.value!.distance,
      actualDuration: actualDurationMinutes,
    );

    // Notify backend about trip completion
    _webSocketService.emit('ride:complete', {
      'tripId': activeTrip.value!.id,
      'finalFare': activeTrip.value!.fare, // Send the agreed fare
      'distance': activeTrip.value!.actualDistance, // Send distance
      'endTime': activeTrip.value!.endTime?.toIso8601String(),
      'finalLatitude': driverLocation.value?.latitude, // Send final location
      'finalLongitude': driverLocation.value?.longitude,
    });

    // Clean up map elements
    mapPolylines.clear();
    mapMarkers.removeWhere((m) => m.markerId.value == 'destination');

    THelperFunctions.showSnackBar('Trip completed successfully!');

    // Update dashboard earnings (using the now-completed activeTrip value)
    _dashboardController?.updateEarningsFromCompletedTrip(activeTrip.value);

    // Reset state after a delay
    Future.delayed(const Duration(seconds: 3), _resetTripState);
    update(); // Update UI immediately
  }

  // Cancel active trip or current request
  void cancelTrip(String reason) {
    String? tripIdToCancel;
    bool wasActiveTrip = false; // Was it an ongoing trip or just a request?

    // Determine which ID to cancel
    if (activeTrip.value != null &&
        tripStatus.value != TripStatus.none &&
        tripStatus.value != TripStatus.completed &&
        tripStatus.value != TripStatus.cancelled) {
      tripIdToCancel = activeTrip.value!.id;
      wasActiveTrip = true;
    } else if (currentTripRequest.value != null) {
      tripIdToCancel = currentTripRequest.value!.id;
      wasActiveTrip = false; // It was just a request
    }

    if (tripIdToCancel == null) {
      print("Cannot cancel: No active trip or request ID found.");
      // If status indicates an issue, reset anyway
      if (tripStatus.value != TripStatus.none) _resetTripState();
      return;
    }

    print("Cancelling Trip/Request ID: $tripIdToCancel. Reason: $reason");

    // Stop timers
    _requestTimer?.cancel();
    _navigationTimer?.cancel();

    // Store previous status for logic below
    final previousStatus = tripStatus.value;
    // Update local status immediately
    tripStatus.value = TripStatus.cancelled;
    isNavigating.value = false;
    hasNewRequest.value = false;

    // Determine if the driver initiated this cancellation *after* accepting
    bool driverInitiatedCancellation =
        wasActiveTrip && previousStatus != TripStatus.cancelled;

    if (driverInitiatedCancellation) {
      print("Driver initiated cancellation for active trip. Emitting event...");
      _webSocketService.emit('ride:driverCancel', {
        'tripId': tripIdToCancel,
        'reason': reason,
      });
    }
    // Note: If cancelling a request (wasActiveTrip=false), the backend handles notifying the rider via ride:reject.

    // Update local trip/request objects
    if (activeTrip.value?.id == tripIdToCancel) {
      activeTrip.value = activeTrip.value!.copyWith(
        status: TripStatus.cancelled,
        endTime: DateTime.now(),
        cancellationReason: reason,
      );
    }
    if (currentTripRequest.value?.id == tripIdToCancel) {
      currentTripRequest.value = null; // Clear the cancelled request
    }

    // Clean up map
    mapPolylines.clear();
    mapMarkers.removeWhere(
      (m) => m.markerId.value == 'pickup' || m.markerId.value == 'destination',
    );

    THelperFunctions.showSnackBar('Trip cancelled: $reason');

    // Reset the full state after a delay
    Future.delayed(const Duration(seconds: 3), _resetTripState);
    update(); // Immediate UI update
  }

  // Reset trip state completely
  void _resetTripState() {
    print("Resetting trip state in TripManagementController...");
    // Clear trip data
    activeTrip.value = null;
    currentTripRequest.value = null;
    tripStatus.value = TripStatus.none; // Reset trip status enum

    // Clear flags and timers
    hasNewRequest.value = false;
    isNavigating.value = false;
    _requestTimer?.cancel();
    _navigationTimer?.cancel();

    // Clear navigation display
    navigationInstruction.value = '';
    distanceToDestination.value = 0.0;
    estimatedTimeToDestination.value = 0;

    // Clear route data
    currentRoute.clear();
    mapPolylines.clear();
    mapMarkers.removeWhere(
      (m) => m.markerId.value == 'pickup' || m.markerId.value == 'destination',
    ); // Keep driver marker

    // Reset route calculation variables
    _initialRouteDistanceKm = 0.0;
    _initialRouteDurationMinutes = 0;
    _navigationStartTime = null;

    // Reset test screen status as well (if using test screen)
    driverTripStatus.value = DriverTripStatus.none;
    riderName.value = '';
    pickupAddress.value = '';
    destinationAddress.value = '';

    // Trigger a status check in the dashboard controller to ensure it syncs
    print("Triggering dashboard status check after trip reset.");
    // Use ?. null-aware access in case dashboard isn't ready/registered yet
    // Accessing the controller via Get.find() might throw if not ready.
    _dashboardController?.checkDriverStatus();

    update(); // Notify UI relevant to TripManagementController
  }

  // Emergency assistance
  void requestEmergencyAssistance() {
    print("Emergency Assistance Requested!");
    // TODO: Implement actual emergency API call and logic
    THelperFunctions.showSnackBar(
      'Emergency assistance requested. Help is on the way!',
    );
  }

  // Contact rider
  void contactRider() {
    String? riderPhone =
        activeTrip.value?.riderPhone ?? currentTripRequest.value?.riderPhone;
    String? riderName =
        activeTrip.value?.riderName ?? currentTripRequest.value?.riderName;

    if (riderPhone != null && riderPhone.isNotEmpty && riderName != null) {
      print("Attempting to call rider: $riderName at $riderPhone");
      // TODO: Implement actual call functionality using url_launcher or specific package
      THelperFunctions.showSnackBar('Calling $riderName...');
      // Example using url_launcher:
      // final Uri phoneUri = Uri(scheme: 'tel', path: riderPhone);
      // try {
      //   if (await canLaunchUrl(phoneUri)) { await launchUrl(phoneUri); }
      //   else { throw 'Could not launch $phoneUri'; }
      // } catch (e) { THelperFunctions.showSnackBar('Could not place call.'); }
    } else {
      print("Cannot call rider: Phone number or name not available.");
      THelperFunctions.showSnackBar('Rider contact information not found.');
    }
  }

  // Add pickup marker
  void _addPickupMarker(LatLng location) {
    mapMarkers.removeWhere(
      (marker) => marker.markerId.value == 'pickup',
    ); // Remove old one first
    mapMarkers.add(
      Marker(
        markerId: const MarkerId('pickup'),
        position: location,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        infoWindow: InfoWindow(
          title: '📍 Pickup Location',
          snippet:
              activeTrip.value?.pickupAddress ??
              currentTripRequest.value?.pickupAddress ??
              'Rider pickup point',
        ),
      ),
    );
    update(); // Notify UI
  }

  // Add destination marker
  void _addDestinationMarker(LatLng location) {
    mapMarkers.removeWhere((marker) => marker.markerId.value == 'destination');
    mapMarkers.add(
      Marker(
        markerId: const MarkerId('destination'),
        position: location,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        infoWindow: InfoWindow(
          title: '🎯 Destination',
          snippet:
              activeTrip.value?.destinationAddress ??
              currentTripRequest.value?.destinationAddress ??
              'Rider drop-off point',
        ),
      ),
    );
    update();
  }

  // Update driver location marker on map
  void _updateDriverLocationOnMap() {
    if (driverLocation.value == null) return;
    final markerId = MarkerId('driver_${_getCurrentDriverId()}');

    // Calculate bearing
    double bearing = 0.0;
    if (_previousDriverLocation != null) {
      bearing = _calculateBearing(
        _previousDriverLocation!,
        driverLocation.value!,
      );
    }
    _previousDriverLocation = driverLocation.value; // Update previous location

    mapMarkers.removeWhere(
      (marker) => marker.markerId == markerId,
    ); // Remove old
    mapMarkers.add(
      Marker(
        markerId: markerId,
        position: driverLocation.value!,
        // --- USE CUSTOM ICON & ROTATION ---
        icon:
            driverIcon ??
            BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        anchor: const Offset(0.5, 0.5),
        rotation: bearing, // Set rotation
        flat: true, // Make marker flat
        // --- END MODIFICATION ---
        zIndex: 2,
        infoWindow: const InfoWindow(title: '🚗 Your Location'),
      ),
    );
    update();
  }

  // Fit map to current route
  void _fitMapToCurrentRoute() {
    if (mapController == null || currentRoute.isEmpty) return;

    if (currentRoute.length == 1) {
      // Only one point, zoom in on it
      mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(currentRoute.first, 16.0),
      );
      return;
    }

    // Calculate bounds from all points in the route
    double minLat = currentRoute.map((p) => p.latitude).reduce(min);
    double maxLat = currentRoute.map((p) => p.latitude).reduce(max);
    double minLng = currentRoute.map((p) => p.longitude).reduce(min);
    double maxLng = currentRoute.map((p) => p.longitude).reduce(max);

    LatLngBounds bounds = LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );

    // Add padding around the bounds
    double padding = 80.0;

    // Animate camera to fit the bounds with padding
    // Use a slight delay to ensure map is ready
    Future.delayed(const Duration(milliseconds: 100), () {
      mapController?.animateCamera(
        CameraUpdate.newLatLngBounds(bounds, padding),
      );
    });
  }

  // Calculate distance between two points (km) using Haversine formula
  double _calculateDistance(LatLng point1, LatLng point2) {
    const double R = 6371; // Earth radius in kilometers
    final double phi1 = point1.latitude * pi / 180;
    final double phi2 = point2.latitude * pi / 180;
    final double deltaPhi = (point2.latitude - point1.latitude) * pi / 180;
    final double deltaLambda = (point2.longitude - point1.longitude) * pi / 180;

    final double a =
        sin(deltaPhi / 2) * sin(deltaPhi / 2) +
        cos(phi1) * cos(phi2) * sin(deltaLambda / 2) * sin(deltaLambda / 2);
    final double c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return R * c; // Distance in kilometers
  }

  // Helper methods
  String _getCurrentDriverId() {
    try {
      // Try getting User model if globally registered
      if (Get.isRegistered<User>(tag: 'currentUser')) {
        final user = Get.find<User>(tag: 'currentUser');
        if (user.userType == UserType.driver) return user.id;
      }
      // Fallback to getting ID from dashboard controller
      return _dashboardController?.currentDriver.value?.id ??
          'driver_001'; // Default ID
    } catch (e) {
      print("Error getting current driver ID: $e");
      return 'driver_001'; // Fallback default ID
    }
  }

  String _getRandomRiderName() {
    /* ... (as before) ... */
    final names = [
      'Alice B.',
      'Bob C.',
      'Charlie D.',
      'Diana E.',
      'Ethan F.',
      'Fiona G.',
    ];
    return names[Random().nextInt(names.length)];
  }

  String _generateRandomAddress(String type) {
    /* ... (as before) ... */
    final areas = [
      'Victoria Island',
      'Lekki Phase 1',
      'Ikeja GRA',
      'Surulere',
      'Yaba',
      'Ikoyi',
      'Maryland',
      'Festac',
    ];
    final streets = [
      'Admiralty Way',
      'Adeola Odeku St',
      'Allen Avenue',
      'Bode Thomas St',
      'Herbert Macaulay Way',
      'Awolowo Road',
      'Kofo Abayomi St',
    ];
    final number = Random().nextInt(150) + 1;
    return '$number ${streets[Random().nextInt(streets.length)]}, ${areas[Random().nextInt(areas.length)]}, Lagos';
  }

  String _getRandomRideType() {
    /* ... (as before) ... */
    final types = ['Standard', 'Comfort', 'Premium', 'XL', 'Bike'];
    return types[Random().nextInt(types.length)];
  }

  // --- Test Screen Methods (Corrected) ---
  void generateTestTripRequest() {
    /* ... (as before, uses test enum DriverTripStatus) ... */
    if (driverLocation.value == null) return;
    final random = Random();
    final pickupLat =
        driverLocation.value!.latitude + (random.nextDouble() - 0.5) * 0.01;
    final pickupLng =
        driverLocation.value!.longitude + (random.nextDouble() - 0.5) * 0.01;
    final destLat = pickupLat + (random.nextDouble() - 0.5) * 0.02;
    final destLng = pickupLng + (random.nextDouble() - 0.5) * 0.02;
    final request = TripRequest(
      id: 'test_trip_${DateTime.now().millisecondsSinceEpoch}',
      riderId: 'test_rider_${random.nextInt(1000)}',
      riderName: _getRandomRiderName(),
      riderPhone:
          '+234${random.nextInt(1000000000).toString().padLeft(9, '0')}',
      riderRating: 3.5 + random.nextDouble() * 1.5,
      pickupLocation: LatLng(pickupLat, pickupLng),
      destinationLocation: LatLng(destLat, destLng),
      pickupAddress: _generateRandomAddress('pickup'),
      destinationAddress: _generateRandomAddress('destination'),
      requestTime: DateTime.now(),
      estimatedFare: 1500 + random.nextInt(3000).toDouble(),
      estimatedDistance: 2.0 + random.nextDouble() * 10.0,
      estimatedDuration: 5 + random.nextInt(25),
      rideType: _getRandomRideType(),
    );
    riderName.value = request.riderName;
    pickupAddress.value = request.pickupAddress;
    destinationAddress.value = request.destinationAddress;
    driverTripStatus.value = DriverTripStatus.hasNewRequest; // Use test enum
    showTripRequest(request);
    THelperFunctions.showSnackBar('Test trip request generated!');
  }

  Future<void> acceptTrip() async {
    // Renamed test method
    await acceptTripRequest(); // Calls main logic
    if (tripStatus.value == TripStatus.accepted ||
        tripStatus.value == TripStatus.drivingToPickup) {
      driverTripStatus.value =
          DriverTripStatus.drivingToPickup; // Update test enum
    }
  }

  void arriveAtPickup() {
    /* ... (as before, uses test enum DriverTripStatus) ... */
    if (activeTrip.value == null ||
        tripStatus.value != TripStatus.drivingToPickup)
      return;
    print("Manually triggering arrival at pickup for demo.");
    _handleArrival();
    driverTripStatus.value = DriverTripStatus.arrivedAtPickup; // Use test enum
  }

  void startTripForTest() {
    // Renamed test method
    if (activeTrip.value == null ||
        tripStatus.value != TripStatus.arrivedAtPickup)
      return;
    print("Manually triggering start trip for demo.");
    startTrip(); // Calls main logic (_startNavigationToDestination)
    driverTripStatus.value = DriverTripStatus.tripInProgress; // Use test enum
  }

  void arriveAtDestination() {
    /* ... (as before, uses test enum DriverTripStatus) ... */
    if (activeTrip.value == null ||
        tripStatus.value != TripStatus.tripInProgress)
      return;
    print("Manually triggering arrival at destination for demo.");
    _handleArrival(); // Main logic sets TripStatus.arrivedAtDestination
    driverTripStatus.value =
        DriverTripStatus.arrivedAtDestination; // Use test enum
  }

  void completeTrip() {
    // Renamed test method
    // Use TripStatus.arrivedAtDestination for check
    if (activeTrip.value == null ||
        tripStatus.value != TripStatus.arrivedAtDestination)
      return;
    print("Manually triggering trip completion for demo.");
    completeTripManual(); // Main logic
    driverTripStatus.value =
        DriverTripStatus.tripCompleted; // Use test enum (will reset soon)
  }
} // End of TripManagementController
