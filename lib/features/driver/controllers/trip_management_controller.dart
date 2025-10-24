import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

// --- Local Imports ---
import 'package:sarri_ride/features/shared/models/user_model.dart'; //
import 'package:sarri_ride/features/shared/services/demo_data.dart'; //
import 'package:sarri_ride/features/location/services/location_service.dart'; //
import 'package:sarri_ride/features/location/services/route_service.dart'; //
import 'package:sarri_ride/utils/constants/enums.dart'; // // Ensure TripStatus.arrivedAtDestination is added here
import 'package:sarri_ride/utils/helpers/helper_functions.dart'; //
import 'package:sarri_ride/utils/constants/colors.dart'; //
import 'package:sarri_ride/features/driver/controllers/driver_dashboard_controller.dart'; //
import 'package:sarri_ride/core/services/websocket_service.dart';
import 'package:sarri_ride/features/authentication/screens/login/login_screen_getx.dart'; //
import 'package:sarri_ride/features/driver/screens/trip_request_screen.dart'; //
import 'package:sarri_ride/features/driver/screens/trip_navigation_screen.dart'; //

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

  // --- ADDED GETTER ---
  /// Helper to check if there is an ongoing trip (not just accepted, but actually started or heading to pickup).
  bool get hasActiveTrip =>
      activeTrip.value != null &&
      tripStatus.value != TripStatus.none &&
      tripStatus.value != TripStatus.completed &&
      tripStatus.value != TripStatus.cancelled;
  // --- END GETTER ---

  @override
  void onInit() {
    super.onInit();
    _initializeLocationTracking();
    // _startListeningForTripRequests();
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
    /* ... (as before, uses _webSocketService.updateDriverLocation) ... */
    _locationService.ensureLocationAvailable();
    final initialPosition = _locationService.getLocationForMap();
    driverLocation.value = LatLng(
      initialPosition.latitude,
      initialPosition.longitude,
    );
    _updateDriverLocationOnMap();

    _locationUpdateTimer?.cancel();
    _locationUpdateTimer = Timer.periodic(const Duration(seconds: 10), (
      timer,
    ) async {
      try {
        final position = _locationService.getLocationForMap();
        final newLocation = LatLng(position.latitude, position.longitude);
        if (driverLocation.value == null ||
            _calculateDistance(driverLocation.value!, newLocation) > 0.01) {
          driverLocation.value = newLocation;
          _updateDriverLocationOnMap();
        }
        final isDriverOnline = _dashboardController?.isOnline.value ?? false;
        final isSocketConnected = _webSocketService.isConnected.value;
        if (isDriverOnline &&
            isSocketConnected &&
            driverLocation.value != null) {
          String availabilityStatus;
          switch (tripStatus.value) {
            case TripStatus.accepted:
            case TripStatus.drivingToPickup:
            case TripStatus.arrivedAtPickup:
            case TripStatus.tripInProgress:
            case TripStatus.arrivedAtDestination:
              availabilityStatus = 'on_trip';
              break;
            default:
              availabilityStatus =
                  (_dashboardController?.isOnline.value ?? false)
                  ? 'available'
                  : 'unavailable';
              break;
          }
          if (availabilityStatus == 'available' ||
              availabilityStatus == 'on_trip') {
            _webSocketService.updateDriverLocation(
              latitude: driverLocation.value!.latitude,
              longitude: driverLocation.value!.longitude,
              state: 'Lagos',
              availabilityStatus: availabilityStatus,
            );
          }
        }
      } catch (e) {
        print("Error in location update timer: $e");
      }
    });
  }

  // --- NEW METHOD ---
  /// Forces an immediate location update emission via WebSocket.
  /// Can override the status sent (e.g., to send 'unavailable' when going offline).
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

    String availabilityStatus;
    if (statusOverride != null) {
      availabilityStatus = statusOverride;
    } else {
      // Determine status normally
      switch (tripStatus.value) {
        case TripStatus.accepted:
        case TripStatus.drivingToPickup:
        case TripStatus.arrivedAtPickup:
        case TripStatus.tripInProgress:
        case TripStatus.arrivedAtDestination:
          availabilityStatus = 'on_trip';
          break;
        default:
          availabilityStatus = (_dashboardController?.isOnline.value ?? false)
              ? 'available'
              : 'unavailable';
          break;
      }
    }

    // Only emit relevant statuses
    if (availabilityStatus == 'available' ||
        availabilityStatus == 'on_trip' ||
        availabilityStatus == 'unavailable') {
      _webSocketService.updateDriverLocation(
        latitude: driverLocation.value!.latitude,
        longitude: driverLocation.value!.longitude,
        state: 'Lagos', // Placeholder
        availabilityStatus: availabilityStatus,
      );
      print("Forced location update emitted with status: $availabilityStatus");
    } else {
      print(
        "Skipping forced update: Status '$availabilityStatus' is not relevant.",
      );
    }
  }
  // --- END NEW METHOD ---

  // Start listening for trip requests (Simulation - Keep for testing?)
  void _startListeningForTripRequests() {
    /* ... (as before, likely keep commented out) ... */
  }

  // Check if driver is online
  bool _isDriverOnline() {
    /* ... (as before) ... */
    return _dashboardController?.isOnline.value ?? false;
  }

  // Simulate new trip request (Keep for potential testing)
  void _simulateNewTripRequest() {
    /* ... (as before) ... */
  }

  // Show trip request to driver (Called by WebSocket listener or simulation)
  void showTripRequest(TripRequest request) {
    /* ... (as before) ... */
    if (currentTripRequest.value != null || activeTrip.value != null) {
      print(
        "Skipping new trip request display: Already handling a request or trip.",
      );
      return;
    }
    print("Showing trip request: ${request.id}");
    currentTripRequest.value = request;
    hasNewRequest.value = true;
    requestTimeLeft.value = 15;
    _requestTimer?.cancel();
    _requestTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      requestTimeLeft.value--;
      if (requestTimeLeft.value <= 0) {
        timer.cancel();
        if (currentTripRequest.value?.id == request.id) {
          print("Trip request ${request.id} timed out.");
          declineTripRequest();
        }
      }
    });
    _addPickupMarker(request.pickupLocation);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (Get.currentRoute != '/TripRequestScreen') {
        Get.to(() => const TripRequestScreen());
      }
    });
  }

  // Accept trip request
  Future<void> acceptTripRequest() async {
    /* ... (as before, calls _proceedWithAcceptedTrip on ack) ... */
    if (currentTripRequest.value == null) {
      print("Cannot accept: No current trip request.");
      return;
    }
    _requestTimer?.cancel();
    hasNewRequest.value = false;
    final request = currentTripRequest.value!;
    print("Accepting trip request: ${request.id}");
    _webSocketService.emitWithAck(
      'ride:accept',
      {'rideId': request.id},
      ack: (response) {
        if (response is Map && response['status'] == 'success') {
          print("Backend acknowledged ride acceptance for ${request.id}.");
          _proceedWithAcceptedTrip(request);
        } else {
          print(
            "Backend rejected ride acceptance for ${request.id}: ${response['message'] ?? response}",
          );
          hasNewRequest.value = true;
          currentTripRequest.value = request;
          THelperFunctions.showSnackBar(
            "Could not accept ride: ${response['message'] ?? 'Server error'}",
          );
        }
      },
    );
  }

  // Handles logic after backend confirms acceptance via 'ride:accepted:ack'
  Future<void> _proceedWithAcceptedTrip(TripRequest request) async {
    /* ... (as before) ... */
    print("Proceeding with accepted trip: ${request.id}");
    activeTrip.value = ActiveTrip(
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
    tripStatus.value = TripStatus.accepted;
    currentTripRequest.value = null;
    await _startNavigationToPickup();
    THelperFunctions.showSnackBar('Trip accepted! Navigate to pickup.');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (Get.currentRoute == '/TripRequestScreen') {
        Get.back();
      }
    });
    update();
  }

  // Decline trip request
  void declineTripRequest() {
    /* ... (as before) ... */
    if (currentTripRequest.value == null) {
      print("Cannot decline: No current trip request.");
      return;
    }
    _requestTimer?.cancel();
    final requestId = currentTripRequest.value!.id;
    print("Declining trip request: $requestId");
    currentTripRequest.value = null;
    hasNewRequest.value = false;
    requestTimeLeft.value = 15;
    _webSocketService.emit('ride:reject', {
      'rideId': requestId,
      'reason': 'Driver declined',
    });
    mapMarkers.removeWhere((marker) => marker.markerId.value == 'pickup');
    THelperFunctions.showSnackBar('Trip request declined');
    isGeneratingRequest.value = true;
    Timer(const Duration(seconds: 10), () {
      isGeneratingRequest.value = false;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (Get.currentRoute == '/TripRequestScreen') {
        Get.back();
      }
    });
    update();
  }

  // Start navigation to pickup location
  Future<void> _startNavigationToPickup() async {
    /* ... (as before, sets _initial estimates) ... */
    if (activeTrip.value == null || driverLocation.value == null) {
      print(
        "Cannot start navigation to pickup: Missing active trip or driver location.",
      );
      return;
    }
    print("Starting navigation to pickup: ${activeTrip.value!.pickupAddress}");
    tripStatus.value = TripStatus.drivingToPickup;
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
      _addPickupMarker(activeTrip.value!.pickupLocation);
      if (!mapMarkers.any((m) => m.markerId.value.startsWith('driver')))
        _updateDriverLocationOnMap();
      _startNavigationUpdates();
      navigationInstruction.value =
          'Head to pickup: ${activeTrip.value!.pickupAddress}';
      distanceToDestination.value = _initialRouteDistanceKm;
      estimatedTimeToDestination.value = _initialRouteDurationMinutes;
      _fitMapToCurrentRoute();
    } catch (e) {
      print('Error getting route to pickup: $e');
      THelperFunctions.showSnackBar('Error calculating route to pickup.');
      isNavigating.value = false;
      tripStatus.value = TripStatus.accepted;
      navigationInstruction.value =
          'Could not calculate route. Proceed manually.';
      mapPolylines.clear();
    }
    update();
  }

  // Start navigation to destination
  Future<void> _startNavigationToDestination() async {
    /* ... (as before, sets _initial estimates) ... */
    if (activeTrip.value == null || driverLocation.value == null) {
      print(
        "Cannot start navigation to destination: Missing active trip or driver location.",
      );
      return;
    }
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
    tripStatus.value = TripStatus.tripInProgress;
    isNavigating.value = true;
    _webSocketService.emit('ride:start', {'tripId': activeTrip.value!.id});
    try {
      final routeInfo = await RouteService.getRouteInfo(
        driverLocation.value!,
        activeTrip.value!.destinationLocation,
      );
      print(
        "Route to destination calculated: ${routeInfo.distance}, ${routeInfo.duration}",
      );
      currentRoute.assignAll(routeInfo.points);
      _initialRouteDistanceKm = routeInfo.distanceValue / 1000.0;
      _initialRouteDurationMinutes = (routeInfo.durationValue / 60).round();
      _navigationStartTime = DateTime.now();
      mapPolylines.clear();
      mapPolylines.add(
        Polyline(
          polylineId: const PolylineId('route_to_destination'),
          points: routeInfo.points,
          color: TColors.success,
          width: 5,
        ),
      );
      mapMarkers.removeWhere((marker) => marker.markerId.value == 'pickup');
      _addDestinationMarker(activeTrip.value!.destinationLocation);
      if (!mapMarkers.any((m) => m.markerId.value.startsWith('driver')))
        _updateDriverLocationOnMap();
      _startNavigationUpdates();
      navigationInstruction.value =
          'Head to destination: ${activeTrip.value!.destinationAddress}';
      distanceToDestination.value = _initialRouteDistanceKm;
      estimatedTimeToDestination.value = _initialRouteDurationMinutes;
      activeTrip.value = activeTrip.value!.copyWith(
        status: TripStatus.tripInProgress,
        pickupTime: DateTime.now(),
      );
      _fitMapToCurrentRoute();
      THelperFunctions.showSnackBar('Trip started! Navigating to destination.');
    } catch (e) {
      print('Error getting route to destination: $e');
      THelperFunctions.showSnackBar('Error calculating route to destination.');
      isNavigating.value = false;
      navigationInstruction.value =
          'Could not calculate route. Proceed manually to ${activeTrip.value!.destinationAddress}.';
      mapPolylines.clear();
      activeTrip.value = activeTrip.value!.copyWith(
        status: TripStatus.tripInProgress,
        pickupTime: DateTime.now(),
      );
    }
    update();
  }

  // Start/Restart navigation update timer
  void _startNavigationUpdates() {
    /* ... (as before) ... */
    _navigationTimer?.cancel();
    if (currentRoute.isEmpty) {
      print("Cannot start navigation updates: Route is empty.");
      isNavigating.value = false;
      return;
    }
    print("Starting navigation updates timer.");
    isNavigating.value = true;
    _navigationTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (!isNavigating.value ||
          currentRoute.isEmpty ||
          activeTrip.value == null) {
        print("Stopping navigation updates timer.");
        timer.cancel();
        return;
      }
      _updateNavigationInstructions();
      if (_isNearDestination()) {
        print("Driver is near the target location.");
        timer.cancel();
        _handleArrival();
      }
    });
  }

  // Update navigation display info (distance/ETA) - CORRECTED
  void _updateNavigationInstructions() {
    /* ... (Corrected version from previous response) ... */
    if (activeTrip.value == null ||
        !isNavigating.value ||
        _navigationStartTime == null)
      return;
    DateTime startTime = _navigationStartTime!;
    double initialDistance = _initialRouteDistanceKm;
    int initialDuration = _initialRouteDurationMinutes;
    if (tripStatus.value == TripStatus.drivingToPickup) {
      navigationInstruction.value =
          'Continue to pickup: ${activeTrip.value!.pickupAddress}';
    } else if (tripStatus.value == TripStatus.tripInProgress) {
      navigationInstruction.value =
          'Continue to destination: ${activeTrip.value!.destinationAddress}';
    } else {
      isNavigating.value = false;
      _navigationTimer?.cancel();
      return;
    }
    if (initialDuration > 0) {
      final elapsedMinutes = DateTime.now().difference(startTime).inMinutes;
      final remainingMinutes = (initialDuration - elapsedMinutes).clamp(
        0,
        initialDuration,
      );
      final progress = elapsedMinutes / initialDuration;
      final remainingDistance = (initialDistance * (1.0 - progress)).clamp(
        0.0,
        initialDistance,
      );
      distanceToDestination.value = remainingDistance;
      estimatedTimeToDestination.value = remainingMinutes;
    } else {
      distanceToDestination.value = 0.0;
      estimatedTimeToDestination.value = 0;
    }
    update();
  }

  // Check if driver is near the current target
  bool _isNearDestination() {
    /* ... (as before) ... */
    if (driverLocation.value == null || activeTrip.value == null) return false;
    LatLng target;
    if (tripStatus.value == TripStatus.drivingToPickup) {
      target = activeTrip.value!.pickupLocation;
    } else if (tripStatus.value == TripStatus.tripInProgress ||
        tripStatus.value == TripStatus.arrivedAtDestination) {
      target = activeTrip.value!.destinationLocation;
    } else {
      return false;
    }
    final distanceKm = _calculateDistance(driverLocation.value!, target);
    return distanceKm < 0.1;
  }

  // Handle arrival at pickup OR destination - CORRECTED
  void _handleArrival() {
    /* ... (Corrected version from previous response, uses TripStatus.arrivedAtDestination) ... */
    if (activeTrip.value == null) return;
    print("Handling arrival at target...");
    _navigationTimer?.cancel();
    if (tripStatus.value == TripStatus.drivingToPickup) {
      print("Arrived at pickup location.");
      tripStatus.value = TripStatus.arrivedAtPickup;
      isNavigating.value = false;
      navigationInstruction.value = 'Arrived at pickup. Waiting for rider.';
      activeTrip.value = activeTrip.value!.copyWith(
        status: TripStatus.arrivedAtPickup,
        arrivalTime: DateTime.now(),
      );
      _webSocketService.emit('ride:arrived', {'tripId': activeTrip.value!.id});
      THelperFunctions.showSnackBar('Arrived at pickup location');
    } else if (tripStatus.value == TripStatus.tripInProgress) {
      print("Arrived at final destination.");
      tripStatus.value = TripStatus.arrivedAtDestination;
      isNavigating.value = false;
      navigationInstruction.value =
          'Arrived at destination. Tap "Complete Trip".';
      // _webSocketService.emit('ride:arrivedAtDestination', {'tripId': activeTrip.value!.id}); // Optional event
      THelperFunctions.showSnackBar('Arrived at destination');
      update(); // Update UI
    } else {
      print("HandleArrival called in unexpected state: ${tripStatus.value}");
    }
    update();
  }

  // Start trip (Driver confirms rider is picked up)
  void startTrip() {
    // Renamed main method to avoid conflict with test extension proxy
    _startNavigationToDestination();
  }

  // Manually complete the trip (called by button press) - CORRECTED
  void completeTripManual() {
    /* ... (Corrected version from previous response, checks for TripStatus.arrivedAtDestination) ... */
    if (activeTrip.value == null) {
      print("Cannot complete trip: No active trip.");
      return;
    }
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
    _navigationTimer?.cancel();
    isNavigating.value = false;
    tripStatus.value = TripStatus.completed;
    DateTime tripStartTime =
        activeTrip.value!.pickupTime ?? activeTrip.value!.startTime;
    int actualDurationMinutes = DateTime.now()
        .difference(tripStartTime)
        .inMinutes;
    activeTrip.value = activeTrip.value!.copyWith(
      status: TripStatus.completed,
      endTime: DateTime.now(),
      actualDistance: activeTrip.value!.distance,
      actualDuration: actualDurationMinutes,
    );
    _webSocketService.emit('ride:complete', {
      'tripId': activeTrip.value!.id,
      'finalFare': activeTrip.value!.fare,
      'distance': activeTrip.value!.actualDistance,
      'endTime': activeTrip.value!.endTime?.toIso8601String(),
      'finalLatitude': driverLocation.value?.latitude,
      'finalLongitude': driverLocation.value?.longitude,
    });
    mapPolylines.clear();
    mapMarkers.removeWhere((m) => m.markerId.value == 'destination');
    THelperFunctions.showSnackBar('Trip completed successfully!');
    _dashboardController?.updateEarningsFromCompletedTrip(activeTrip.value);
    Future.delayed(const Duration(seconds: 3), _resetTripState);
    update();
  }

  // Cancel active trip
  void cancelTrip(String reason) {
    /* ... (as before) ... */
    String? tripIdToCancel;
    bool wasActiveTrip = false;
    if (activeTrip.value != null) {
      tripIdToCancel = activeTrip.value!.id;
      wasActiveTrip = true;
    } else if (currentTripRequest.value != null) {
      tripIdToCancel = currentTripRequest.value!.id;
    }
    if (tripIdToCancel == null) {
      if (tripStatus.value != TripStatus.none) _resetTripState();
      return;
    }
    print("Cancelling trip ID: $tripIdToCancel. Reason: $reason");
    _requestTimer?.cancel();
    _navigationTimer?.cancel();
    final previousStatus = tripStatus.value;
    tripStatus.value = TripStatus.cancelled;
    isNavigating.value = false;
    hasNewRequest.value = false;
    bool driverInitiated =
        wasActiveTrip && previousStatus != TripStatus.cancelled;
    if (driverInitiated) {
      print("Driver initiated cancellation. Emitting event...");
      _webSocketService.emit('ride:driverCancel', {
        'tripId': tripIdToCancel,
        'reason': reason,
      });
    }
    if (activeTrip.value?.id == tripIdToCancel) {
      activeTrip.value = activeTrip.value!.copyWith(
        status: TripStatus.cancelled,
        endTime: DateTime.now(),
        cancellationReason: reason,
      );
    }
    if (currentTripRequest.value?.id == tripIdToCancel) {
      currentTripRequest.value = null;
    }
    mapPolylines.clear();
    mapMarkers.removeWhere(
      (m) => m.markerId.value == 'pickup' || m.markerId.value == 'destination',
    );
    THelperFunctions.showSnackBar('Trip cancelled: $reason');
    Future.delayed(const Duration(seconds: 3), _resetTripState);
    update();
  }

  // Reset trip state completely - CORRECTED
  void _resetTripState() {
    print("Resetting trip state...");
    activeTrip.value = null;
    currentTripRequest.value = null;
    tripStatus.value = TripStatus.none;
    hasNewRequest.value = false;
    isNavigating.value = false;
    navigationInstruction.value = '';
    currentRoute.clear(); // Reset route points
    mapPolylines.clear();
    mapMarkers.removeWhere(
      (m) => m.markerId.value == 'pickup' || m.markerId.value == 'destination',
    );
    _requestTimer?.cancel();
    _navigationTimer?.cancel();
    _initialRouteDistanceKm = 0.0;
    _initialRouteDurationMinutes = 0;
    _navigationStartTime = null;

    // Reset test screen status as well
    driverTripStatus.value = DriverTripStatus.none; // Use the test enum
    riderName.value = '';
    pickupAddress.value = '';
    destinationAddress.value = '';

    // Update dashboard controller status based on online toggle
    if (_dashboardController != null) {
      // This updates the DriverDashboardController's Rx<DriverStatus>
      _dashboardController!.driverStatus.value =
          _dashboardController!.isOnline.value
          ? DriverStatus.online
          : DriverStatus.offline;
    } else {
      print("Warning: Dashboard controller not found during reset.");
    }
    update(); // Notify UI
  }

  // Emergency assistance
  void requestEmergencyAssistance() {
    /* ... (as before) ... */
    print("Emergency Assistance Requested!");
    THelperFunctions.showSnackBar(
      'Emergency assistance requested. Help is on the way!',
    );
  }

  // Contact rider
  void contactRider() {
    /* ... (as before) ... */
    String? riderPhone =
        activeTrip.value?.riderPhone ?? currentTripRequest.value?.riderPhone;
    String? riderName =
        activeTrip.value?.riderName ?? currentTripRequest.value?.riderName;
    if (riderPhone != null && riderPhone.isNotEmpty && riderName != null) {
      print("Attempting to call rider: $riderName at $riderPhone");
      THelperFunctions.showSnackBar(
        'Calling $riderName...',
      ); /* TODO: launchUrl */
    } else {
      print("Cannot call rider: Phone number or name not available.");
      THelperFunctions.showSnackBar('Rider contact information not found.');
    }
  }

  // Add pickup marker
  void _addPickupMarker(LatLng location) {
    /* ... (as before) ... */
    mapMarkers.removeWhere((marker) => marker.markerId.value == 'pickup');
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
    update();
  }

  // Add destination marker
  void _addDestinationMarker(LatLng location) {
    /* ... (as before) ... */
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
    /* ... (as before) ... */
    if (driverLocation.value == null) return;
    final markerId = MarkerId('driver_${_getCurrentDriverId()}');
    mapMarkers.removeWhere((marker) => marker.markerId == markerId);
    mapMarkers.add(
      Marker(
        markerId: markerId,
        position: driverLocation.value!,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        anchor: const Offset(0.5, 0.5),
        rotation: 0.0,
        flat: true,
        zIndex: 2,
        infoWindow: const InfoWindow(title: '🚗 Your Location'),
      ),
    );
    update();
  }

  // Fit map to current route
  void _fitMapToCurrentRoute() {
    /* ... (as before) ... */
    if (mapController == null || currentRoute.isEmpty) return;
    LatLngBounds bounds;
    if (currentRoute.length == 1) {
      mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(currentRoute.first, 16.0),
      );
      return;
    }
    double minLat = currentRoute.map((p) => p.latitude).reduce(min);
    double maxLat = currentRoute.map((p) => p.latitude).reduce(max);
    double minLng = currentRoute.map((p) => p.longitude).reduce(min);
    double maxLng = currentRoute.map((p) => p.longitude).reduce(max);
    bounds = LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );
    double padding = 80.0;
    Future.delayed(const Duration(milliseconds: 100), () {
      mapController!.animateCamera(
        CameraUpdate.newLatLngBounds(bounds, padding),
      );
    });
  }

  // Calculate distance between two points (km)
  double _calculateDistance(LatLng point1, LatLng point2) {
    /* ... (as before) ... */
    const double R = 6371e3;
    final double phi1 = point1.latitude * pi / 180,
        phi2 = point2.latitude * pi / 180;
    final double deltaPhi = (point2.latitude - point1.latitude) * pi / 180;
    final double deltaLambda = (point2.longitude - point1.longitude) * pi / 180;
    final double a =
        sin(deltaPhi / 2) * sin(deltaPhi / 2) +
        cos(phi1) * cos(phi2) * sin(deltaLambda / 2) * sin(deltaLambda / 2);
    final double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return (R * c) / 1000.0;
  }

  // Helper methods
  String _getCurrentDriverId() {
    /* ... (as before) ... */
    try {
      if (Get.isRegistered<User>(tag: 'currentUser')) {
        final user = Get.find<User>(tag: 'currentUser');
        if (user.userType == UserType.driver) return user.id;
      }
      return _dashboardController?.currentDriver.value?.id ?? 'driver_001';
    } catch (e) {
      print("Error getting current driver ID: $e");
      return 'driver_001';
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
