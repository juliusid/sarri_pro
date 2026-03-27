import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:sarri_ride/core/services/http_service.dart';
import 'package:sarri_ride/core/services/websocket_service.dart';
import 'package:sarri_ride/core/services/map_marker_service.dart';
import 'package:sarri_ride/features/driver/services/driver_trip_service.dart';
import 'package:sarri_ride/features/driver/screens/waiting_for_payment_screen.dart'; // ADDED
import 'package:sarri_ride/features/communication/screens/message_screen.dart';
import 'package:sarri_ride/features/emergency/screens/emergency_reporting_screen.dart';
import 'package:sarri_ride/features/ride/models/ride_model.dart';
import 'package:sarri_ride/features/location/services/location_service.dart';
import 'package:sarri_ride/features/location/services/route_service.dart';
import 'package:sarri_ride/features/location/services/places_service.dart';
import 'package:sarri_ride/utils/constants/enums.dart';
import 'package:sarri_ride/utils/helpers/helper_functions.dart';
import 'package:sarri_ride/utils/constants/colors.dart';
import 'package:sarri_ride/features/driver/controllers/driver_dashboard_controller.dart';
import 'package:sarri_ride/features/driver/screens/trip_request_screen.dart';

// --- Trip Request Model ---
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
  final int seats;
  final DateTime expiresAt;

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
    required this.seats,
    required this.expiresAt,
  });
}

// --- Active Trip Model ---
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
  final String chatId;
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
    this.chatId = '',
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
    String? chatId,
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
      chatId: chatId ?? this.chatId,
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

  // --- Services ---
  final LocationService _locationService = LocationService.instance;
  final WebSocketService _webSocketService = WebSocketService.instance;
  final DriverTripService _driverTripService = DriverTripService.instance;
  final MapMarkerService _markerService = MapMarkerService.instance;

  // Use a lazy getter for DashboardController to avoid initialization issues
  DriverDashboardController? get _dashboardController =>
      Get.isRegistered<DriverDashboardController>()
      ? Get.find<DriverDashboardController>()
      : null;

  final _storage = GetStorage();

  // --- State ---
  final Rx<TripRequest?> currentTripRequest = Rx<TripRequest?>(null);
  final Rx<ActiveTrip?> activeTrip = Rx<ActiveTrip?>(null);
  final Rx<TripStatus> tripStatus = TripStatus.none.obs;

  // Location & Map
  final Rx<LatLng?> driverLocation = Rx<LatLng?>(null);
  final RxSet<Marker> mapMarkers = <Marker>{}.obs;
  final RxSet<Polyline> mapPolylines = <Polyline>{}.obs;
  final RxList<LatLng> currentRoute = <LatLng>[].obs;
  GoogleMapController? mapController;

  LatLng? _previousDriverLocation;

  // Request Handling
  final RxBool hasNewRequest = false.obs;
  final RxBool isAccepting = false.obs; // ADDED: Loading state for accept
  final RxInt requestTimeLeft = 15.obs;
  Timer? _requestTimer;

  // Navigation State
  final RxBool isNavigating = false.obs;
  final RxString navigationInstruction = ''.obs;
  final RxDouble distanceToDestination = 0.0.obs;
  final RxInt estimatedTimeToDestination = 0.obs;

  // [MODIFIED] Added Stream Subscription
  StreamSubscription<Position>? _positionStreamSubscription;
  Timer? _locationUpdateLoopTimer;

  // Cached State for location updates
  String _currentState = "";

  // Initial Route Estimates
  double _initialRouteDistanceKm = 0.0;
  int _initialRouteDurationMinutes = 0;
  DateTime? _navigationStartTime;

  // Re-routing
  final RxBool isRecalculating = false.obs;

  // Payment
  final RxBool isWaitingForCash = false.obs;
  final RxDouble cashAmountToReceive = 0.0.obs;
  final RxBool isCompletingTrip = false.obs; // ADDED: Loading state for Complete Trip button
  bool _waitingForPaymentScreenOpened = false; // Prevent stacking the same waiting screen repeatedly.

  /// Helper to check if there is an ongoing trip
  bool get hasActiveTrip =>
      activeTrip.value != null &&
      tripStatus.value != TripStatus.none &&
      tripStatus.value != TripStatus.completed &&
      tripStatus.value != TripStatus.cancelled;

  void _showWaitingForPaymentScreenOnce() {
    if (_waitingForPaymentScreenOpened) return;
    _waitingForPaymentScreenOpened = true;
    Get.to(() => const WaitingForPaymentScreen());
  }

  void _restoreWaitingForPaymentFromStorage() {
    final shouldWait =
        _storage.read('driver_waiting_for_payment') == true;
    final tripId = (_storage.read('driver_waiting_trip_id')?.toString() ??
        '');

    if (!shouldWait || tripId.isEmpty) return;

    final isPackageWaiting =
        _storage.read('driver_waiting_is_package') == true;
    if (isPackageWaiting) {
      _storage.write('active_ride_mode', 'package_delivery');
    } else {
      _storage.remove('active_ride_mode');
    }

    // Ensure we can correlate incoming socket events to this trip.
    // Waiting screen itself does not require the full trip details.
    final fallbackLoc = driverLocation.value ?? const LatLng(0, 0);
    activeTrip.value ??= ActiveTrip(
      id: tripId,
      riderId: _storage.read('driver_waiting_rider_id')?.toString() ?? '',
      riderName: _storage.read('driver_waiting_rider_name')?.toString() ??
          'Rider',
      riderPhone: '',
      riderRating: 0.0,
      pickupLocation: fallbackLoc,
      destinationLocation: fallbackLoc,
      pickupAddress: '',
      destinationAddress: '',
      fare: (_storage.read('driver_waiting_fare') as num?)?.toDouble() ?? 0.0,
      distance: (_storage.read('driver_waiting_distance') as num?)?.toDouble() ??
          0.0,
      estimatedDuration:
          (_storage.read('driver_waiting_eta') as num?)?.toInt() ?? 0,
      rideType: _storage.read('driver_waiting_category')?.toString() ?? '',
      startTime: DateTime.now(),
      status: TripStatus.none,
      chatId: '',
    );

    // We are waiting for payment, so keep tripStatus as non-completed.
    tripStatus.value = TripStatus.none;

    isWaitingForCash.value =
        _storage.read('driver_waiting_for_cash') == true;
    cashAmountToReceive.value =
        (_storage.read('driver_waiting_cash_amount') as num?)?.toDouble() ??
            0.0;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showWaitingForPaymentScreenOnce();
    });
  }

  /// User-friendly string representation of current trip status
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
      case TripStatus.requested:
        return 'Trip Requested';
      default:
        return 'Trip Status Unknown';
    }
  }

  @override
  void onInit() {
    super.onInit();
    _initializeLocationTracking();
    _updateDriverLocationOnMap();
    _webSocketService.registerCashPaymentPendingListener(
      _handleCashPaymentPending,
    );
    _webSocketService.registerPaymentConfirmedListener(_handlePaymentConfirmed);

    // Restore the "waiting for payment" UX after app restart when a trip
    // was completed but the backend payment is still pending.
    _restoreWaitingForPaymentFromStorage();
  }

  @override
  void onClose() {
    _requestTimer?.cancel();
    _locationUpdateLoopTimer?.cancel();
    _positionStreamSubscription?.cancel(); // [ADDED] Clean up stream
    _webSocketService.unregisterCashPaymentPendingListener(
      _handleCashPaymentPending,
    );
    _webSocketService.unregisterPaymentConfirmedListener(
      _handlePaymentConfirmed,
    );
    super.onClose();
  }

  // --- GOOGLE MAPS LAUNCHER ---
  Future<void> launchMapNavigation() async {
    LatLng? target;
    if (tripStatus.value == TripStatus.drivingToPickup) {
      target = activeTrip.value?.pickupLocation;
    } else if (tripStatus.value == TripStatus.tripInProgress) {
      target = activeTrip.value?.destinationLocation;
    }

    if (target == null) {
      THelperFunctions.showSnackBar("No active navigation target.");
      return;
    }

    final uri = Uri.parse(
      "google.navigation:q=${target.latitude},${target.longitude}&mode=d",
    );

    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        // Fallback for iOS or if URI fails
        final url = Uri.parse(
          'https://www.google.com/maps/dir/?api=1&destination=${target.latitude},${target.longitude}&travelmode=driving',
        );
        await launchUrl(url, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      print("Could not launch maps: $e");
      THelperFunctions.showSnackBar("Could not launch Google Maps.");
    }
  }

  // --- CORE LOGIC ---
  void showTripRequest(TripRequest request) {
    if (currentTripRequest.value != null || hasActiveTrip) return;
    print("Showing trip request: ${request.id}");
    currentTripRequest.value = request;
    hasNewRequest.value = true;

    _requestTimer?.cancel();

    final now = DateTime.now();
    int secondsLeft = request.expiresAt.difference(now).inSeconds;
    requestTimeLeft.value = secondsLeft > 0 ? secondsLeft : 0;

    _requestTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final newNow = DateTime.now();
      secondsLeft = request.expiresAt.difference(newNow).inSeconds;
      requestTimeLeft.value = secondsLeft > 0 ? secondsLeft : 0;

      if (requestTimeLeft.value <= 0) {
        timer.cancel();
        if (currentTripRequest.value?.id == request.id) {
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

  Future<void> acceptTripRequest() async {
    if (currentTripRequest.value == null || isAccepting.value) return;
    
    isAccepting.value = true;
    _requestTimer?.cancel();
    final request = currentTripRequest.value!;

    Get.dialog(
      const Center(child: CircularProgressIndicator()),
      barrierDismissible: false,
    );

    try {
      final responseData = await _driverTripService.acceptRide(request.id);
      if (Get.isDialogOpen!) Get.back();

      if (responseData['status'] == 'success') {
        final String chatId = responseData['data'] != null
            ? responseData['data']['chatId'] ?? ''
            : '';

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
          chatId: chatId,
        );

        hasNewRequest.value = false;
        currentTripRequest.value = null;
        tripStatus.value = TripStatus.accepted;

        _storage.write('active_ride_id', request.id);
        // PERSIST coordinates locally so they survive app restarts
        _storage.write('trip_pickup_lat', request.pickupLocation.latitude);
        _storage.write('trip_pickup_lng', request.pickupLocation.longitude);
        _storage.write('trip_dest_lat', request.destinationLocation.latitude);
        _storage.write('trip_dest_lng', request.destinationLocation.longitude);
        await _startNavigationToPickup();
        THelperFunctions.showSnackBar('Trip accepted! Navigate to pickup.');

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (Get.currentRoute == '/TripRequestScreen') Get.back();
        });
      } else {
        THelperFunctions.showErrorSnackBar(
          "Error",
          responseData['message'] ?? 'Failed to accept.',
        );
      }
    } catch (e) {
      if (Get.isDialogOpen!) Get.back();
      THelperFunctions.showErrorSnackBar("Error", "Accept failed: $e");
    } finally {
      isAccepting.value = false;
    }
  }

  void declineTripRequest() {
    if (currentTripRequest.value == null) return;
    _requestTimer?.cancel();
    final requestId = currentTripRequest.value!.id;

    currentTripRequest.value = null;
    hasNewRequest.value = false;
    requestTimeLeft.value = 15;
    mapMarkers.removeWhere((m) => m.markerId.value == 'pickup');

    _webSocketService.emit('ride:reject', {
      'rideId': requestId,
      'reason': 'Driver declined',
    });

    THelperFunctions.showSnackBar('Trip request declined');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (Get.currentRoute == '/TripRequestScreen') Get.back();
    });
    update();
  }

  String _cleanStateName(String rawState) {
    if (rawState.isEmpty) {
      THelperFunctions.showSnackBar(
        'State information is missing. Please ensure location permissions are granted and try again.',
      );
    }
// Fallback

    String cleaned = rawState.trim();

    // REGEX EXPLANATION:
    // \s* -> Matches zero or more spaces
    // state -> Matches the word "state"
    // $     -> Matches the end of the string
    // caseSensitive: false -> Matches "State", "state", "STATE"
    final regExp = RegExp(r'\s*state$', caseSensitive: false);

    // Replace the matched part with empty string
    cleaned = cleaned.replaceAll(regExp, '');

    // Capitalize the first letter (Optional, makes it look nice)
    if (cleaned.isNotEmpty) {
      cleaned = cleaned[0].toUpperCase() + cleaned.substring(1);
    }

    return cleaned.trim();
  }

  Future<void> _startNavigationToPickup() async {
    if (activeTrip.value == null || driverLocation.value == null) return;
    tripStatus.value = TripStatus.drivingToPickup;
    isNavigating.value = true;

    try {
      final routeInfo = await RouteService.getRouteInfo(
        driverLocation.value!,
        activeTrip.value!.pickupLocation,
      );

      if (routeInfo.points.isEmpty) {
        throw Exception("RouteService returned empty points for pickup route.");
      }

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
      _updateDriverLocationOnMap();

      navigationInstruction.value =
          'Head to pickup: ${activeTrip.value!.pickupAddress}';
      distanceToDestination.value = _initialRouteDistanceKm;
      estimatedTimeToDestination.value = _initialRouteDurationMinutes;

      _fitMapToCurrentRoute();
    } catch (e) {
      print('Error getting route to pickup: $e');
      isNavigating.value = false;
      tripStatus.value = TripStatus.accepted;
    }
    update();
  }

  Future<void> _startNavigationToDestination() async {
    if (activeTrip.value == null || driverLocation.value == null) return;

    // 1. Allow if we are already in progress (Restoration)
    if (tripStatus.value != TripStatus.arrivedAtPickup &&
        tripStatus.value != TripStatus.tripInProgress) {
      THelperFunctions.showSnackBar("Confirm arrival at pickup first.");
      return;
    }

    try {
      // 2. Only call the server if we are transitioning FROM Arrived TO InProgress.
      if (tripStatus.value == TripStatus.arrivedAtPickup) {
        final responseData = await _driverTripService.startTrip(
          activeTrip.value!.id,
          driverLocation.value!.latitude,
          driverLocation.value!.longitude,
        );

        if (responseData['status'] != 'success') {
          THelperFunctions.showErrorSnackBar(
            "Error",
            responseData['message'] ?? 'Failed to start trip.',
          );
          return;
        }
        THelperFunctions.showSuccessSnackBar('Success', 'Trip started!');
      }

      // 3. MAP & BANNER DATA: Always runs to populate UI
      tripStatus.value = TripStatus.tripInProgress;
      isNavigating.value = true;

      final routeInfo = await RouteService.getRouteInfo(
        driverLocation.value!,
        activeTrip.value!.destinationLocation,
      );

      if (routeInfo.points.isNotEmpty) {
        currentRoute.assignAll(routeInfo.points);

        // Populate precise calculation variables
        _initialRouteDistanceKm = routeInfo.distanceValue / 1000.0;
        _initialRouteDurationMinutes = (routeInfo.durationValue / 60).round();
        _navigationStartTime = DateTime.now();

        // Update UI Observables immediately
        distanceToDestination.value = _initialRouteDistanceKm;
        estimatedTimeToDestination.value = _initialRouteDurationMinutes;

        mapPolylines.clear();
        mapPolylines.add(
          Polyline(
            polylineId: const PolylineId('route_to_dest'),
            points: routeInfo.points,
            color: TColors.success,
            width: 5,
          ),
        );

        mapMarkers.removeWhere((marker) => marker.markerId.value == 'pickup');
        _addDestinationMarker(activeTrip.value!.destinationLocation);
        _fitMapToCurrentRoute();
      }

      activeTrip.value = activeTrip.value!.copyWith(
        status: TripStatus.tripInProgress,
        pickupTime: activeTrip.value!.pickupTime ?? DateTime.now(),
      );
    } catch (e) {
      print("Navigation Error: $e");
      THelperFunctions.showErrorSnackBar(
        "Error",
        "Could not load trip route: $e",
      );
    }
    update();
  }

  void startTrip() => _startNavigationToDestination();

  void completeTripManual() async {
    if (activeTrip.value == null || driverLocation.value == null || isCompletingTrip.value) return;

    if (isWaitingForCash.value) {
      await confirmCashPayment();
      return;
    }

    isCompletingTrip.value = true;
    try {
      // Use the SAVED destination coordinates, not live GPS
      // This prevents the backend from seeing origin=destination when geocoding
      final responseData = await _driverTripService.endTrip(
        activeTrip.value!.id,
        activeTrip.value!.destinationLocation.latitude,
        activeTrip.value!.destinationLocation.longitude,
      );

      if (responseData['status'] == 'success') {
        double finalPrice = activeTrip.value!.fare;
        if (responseData['data']?['finalPrice'] != null) {
          final dynamic priceData = responseData['data']!['finalPrice'];
          if (priceData is Map && priceData['\$numberDecimal'] != null) {
            finalPrice = double.tryParse(priceData['\$numberDecimal'].toString()) ?? finalPrice;
          } else if (priceData is num) {
            finalPrice = priceData.toDouble();
          }
        }

        activeTrip.value = activeTrip.value!.copyWith(fare: finalPrice);
        THelperFunctions.showSuccessSnackBar(
          'Success',
          'Trip completed! Waiting for payment.',
        );

        // Persist state so we can restore the waiting screen after restart
        // even though `reconnectToTrip` does not support `status=completed`.
        _storage.write('driver_waiting_is_package', false);
        _storage.write('driver_waiting_for_payment', true);
        _storage.write('driver_waiting_trip_id', activeTrip.value!.id);
        _storage.write('driver_waiting_fare', finalPrice);
        _storage.write('driver_waiting_distance', activeTrip.value!.distance);
        _storage.write(
          'driver_waiting_eta',
          activeTrip.value!.estimatedDuration,
        );
        _storage.write('driver_waiting_category', activeTrip.value!.rideType);
        _storage.write('driver_waiting_rider_id', activeTrip.value!.riderId);
        _storage.write('driver_waiting_rider_name', activeTrip.value!.riderName);

        // Default until we receive a `cash_payment:pending` socket event.
        isWaitingForCash.value = false;
        cashAmountToReceive.value = 0.0;
        _storage.write('driver_waiting_for_cash', false);
        _storage.remove('driver_waiting_cash_amount');

        _showWaitingForPaymentScreenOnce();
      } else {
        throw Exception(responseData['message']);
      }
    } catch (e) {
      THelperFunctions.showErrorSnackBar("Error", "End trip failed: $e");
    } finally {
      isCompletingTrip.value = false;
    }
  }

  Future<bool> confirmCashPayment() async {
    if (activeTrip.value == null) return false;
    isCompletingTrip.value = true;
    try {
      final isPackageDelivery =
          _storage.read('active_ride_mode') == 'package_delivery';
      final responseData = isPackageDelivery
          ? await _driverTripService.confirmPackageCashPayment(
              activeTrip.value!.id,
            )
          : await _driverTripService.confirmCashPayment(
              activeTrip.value!.id,
            );
      if (responseData['status'] == 'success') {
        THelperFunctions.showSuccessSnackBar(
          'Success',
          'Cash payment confirmed!',
        );
        return true;
      }
      return false;
    } catch (e) {
      THelperFunctions.showErrorSnackBar("Error", "Cash confirm failed: $e");
      return false;
    } finally {
      isCompletingTrip.value = false;
    }
  }

  void cancelTrip(String reason) {
    String? tripIdToCancel;
    bool wasActiveTrip = false;

    if (activeTrip.value != null &&
        tripStatus.value != TripStatus.none &&
        tripStatus.value != TripStatus.completed &&
        tripStatus.value != TripStatus.cancelled) {
      tripIdToCancel = activeTrip.value!.id;
      wasActiveTrip = true;
    } else if (currentTripRequest.value != null) {
      tripIdToCancel = currentTripRequest.value!.id;
      wasActiveTrip = false;
    }

    if (tripIdToCancel == null) {
      if (tripStatus.value != TripStatus.none) _resetTripState();
      return;
    }

    _requestTimer?.cancel();
    isNavigating.value = false;

    final previousStatus = tripStatus.value;
    tripStatus.value = TripStatus.cancelled;
    hasNewRequest.value = false;

    bool driverInitiatedCancellation =
        wasActiveTrip && previousStatus != TripStatus.cancelled;

    if (driverInitiatedCancellation) {
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

    _storage.remove('active_ride_id');
    THelperFunctions.showSnackBar('Trip cancelled: $reason');
    Future.delayed(const Duration(seconds: 3), _resetTripState);
    update();
  }

  void requestEmergencyAssistance() {
    final tripId = activeTrip.value?.id;
    Get.to(() => EmergencyReportingScreen(tripId: tripId));
  }

  void messageRider() {
    if (activeTrip.value == null) {
      THelperFunctions.showSnackBar('No active trip to message.');
      return;
    }
    final trip = activeTrip.value!;
    if (trip.chatId.isEmpty) {
      THelperFunctions.showSnackBar('Chat not available for this trip.');
      return;
    }
    Get.to(
      () => MessageScreen(
        driverName: trip.riderName,
        subtitle: 'Rider',
        rating: trip.riderRating,
        chatId: trip.chatId,
      ),
    );
  }

  void contactRider() {
    String? riderPhone =
        activeTrip.value?.riderPhone ?? currentTripRequest.value?.riderPhone;
    String? riderName =
        activeTrip.value?.riderName ?? currentTripRequest.value?.riderName;

    if (riderPhone != null && riderPhone.isNotEmpty && riderName != null) {
      THelperFunctions.showSnackBar('Calling $riderName...');
    } else {
      THelperFunctions.showSnackBar('Rider contact information not found.');
    }
  }

  // --- LOCATION UPDATE LOGIC ---

  void _initializeLocationTracking() async {
    _locationService.ensureLocationAvailable();
    final initialPosition = _locationService.getLocationForMap();
    driverLocation.value = LatLng(
      initialPosition.latitude,
      initialPosition.longitude,
    );
    _previousDriverLocation = driverLocation.value;
    _updateDriverLocationOnMap();
    await updateCurrentStateFromLocation();
    // [CRITICAL FIX FOR GOOGLE PLAY CONSOLE]
    // Subscribe to the stream. This forces the Foreground Service Notification to appear.
    // We also use this to update the UI location in real-time.
    _positionStreamSubscription = _locationService.getPositionStream().listen((
      position,
    ) {
      driverLocation.value = LatLng(position.latitude, position.longitude);
      _updateDriverLocationOnMap();
    });

    if (!_webSocketService.isConnected.value) {
      await _webSocketService.isConnected.stream.firstWhere((c) => c == true);
    }
    _scheduleNextLocationUpdate();
  }

  Future<void> updateCurrentStateFromLocation() async {
    if (driverLocation.value == null) return;
    try {
      final placeDetails = await PlacesService.getPlaceDetailsFromCoordinates(
        driverLocation.value!.latitude,
        driverLocation.value!.longitude,
      );
      if (placeDetails != null) {
        _currentState = _cleanStateName(placeDetails.state);
      }
    } catch (_) {}
  }

  // --- ADDED METHOD: forceLocationUpdate ---
  Future<void> forceLocationUpdate({String? statusOverride}) async {
    if (!_webSocketService.isConnected.value ||
        !HttpService.instance.isAuthenticated) {
      return;
    }

    final position = _locationService.getLocationForMap();
    driverLocation.value = LatLng(position.latitude, position.longitude);

    // Ensure state is set
    if (_currentState.isEmpty) await updateCurrentStateFromLocation();

    String statusToSend;
    if (statusOverride != null) {
      statusToSend = statusOverride;
    } else {
      final String currentTaskStatus =
          _dashboardController?.driverTaskStatus.value ?? 'unavailable';
      statusToSend = currentTaskStatus;
    }

    String? category;
    if (activeTrip.value != null) {
      final rt = activeTrip.value!.rideType.toLowerCase();
      if (rt.contains('bike') || rt.contains('courier')) {
        category = 'bike_courier';
      } else if (rt.contains('van')) {
        category = 'Van_delivery';
      } else {
        category = 'car_delivery';
      }
    } else {
      // Fallback to driver's default vehicle type
      final vType =
          _dashboardController?.currentDriver.value?.driverProfile
              ?.vehicleDetails.type ??
          VehicleType.sedan;
      switch (vType) {
        case VehicleType.motorcycle:
          category = 'bike_courier';
          break;
        case VehicleType.van:
        case VehicleType.truck:
          category = 'Van_delivery';
          break;
        default:
          category = 'car_delivery';
          break;
      }
    }

    String? currentTripId;
    if (activeTrip.value != null) {
      currentTripId = activeTrip.value!.id;
    }

    _webSocketService.updateDriverLocation(
      latitude: position.latitude,
      longitude: position.longitude,
      state: _currentState,
      availabilityStatus: statusToSend,
      tripId: currentTripId,
      heading: position.heading,
      speed: position.speed,
      category: category,
    );
  }

  void _scheduleNextLocationUpdate() {
    _locationUpdateLoopTimer?.cancel();

    // If not authenticated, slow down
    if (!HttpService.instance.isAuthenticated) {
      _locationUpdateLoopTimer = Timer(
        const Duration(seconds: 30),
        () => _runLocationUpdate(false),
      );
      return;
    }

    final String currentTaskStatus =
        _dashboardController?.driverTaskStatus.value ?? 'unavailable';
    final bool isOnlineIntent = _dashboardController?.isOnline.value ?? false;

    Duration nextInterval;
    bool shouldSendUpdate = true;

    // THE FIX: Check hasActiveTrip directly.
    // If we have a trip, we MUST ping fast (4s), regardless of dashboard status.
    if (hasActiveTrip || (isOnlineIntent && currentTaskStatus == 'available')) {
      // --- FIX: Throttle if arrived at pickup ---
      if (tripStatus.value == TripStatus.arrivedAtPickup) {
        nextInterval = const Duration(seconds: 30);
      } else {
        nextInterval = const Duration(seconds: 4);
      }
    } else {
      shouldSendUpdate = false;
      nextInterval = const Duration(seconds: 20);
    }

    _locationUpdateLoopTimer = Timer(nextInterval, () {
      _runLocationUpdate(shouldSendUpdate);
    });
  }

  Future<void> _runLocationUpdate(bool shouldSendUpdate) async {
    // We remove the connection check here so the loop keeps running
    // even during a temporary disconnect, attempting to reconnect.

    try {
      final position = _locationService.getLocationForMap();
      final newLocation = LatLng(position.latitude, position.longitude);

      // Update local map UI
      driverLocation.value = newLocation;
      _updateDriverLocationOnMap();

      if (isNavigating.value && mapController != null) {
        mapController!.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(
              target: newLocation,
              zoom: 17.0,
              bearing: position.heading,
              tilt: 45.0,
            ),
          ),
        );
      }

      // FORCE send update if there is an active trip, even if dashboard says "offline"
      bool forceUpdate = hasActiveTrip;

      if ((shouldSendUpdate || forceUpdate) &&
          _webSocketService.isConnected.value) {
        String statusToSend = forceUpdate
            ? 'on_trip'
            : (_dashboardController?.driverTaskStatus.value ?? 'available');

        _webSocketService.updateDriverLocation(
          latitude: position.latitude,
          longitude: position.longitude,
          state: _currentState,
          availabilityStatus: statusToSend,
          tripId: activeTrip.value?.id,
          heading: position.heading,
          speed: position.speed,
        );
        print("Location Ping Sent: $statusToSend"); // Verification Print
      }

      // Update Navigation Banner
      if (isNavigating.value) {
        _updateNavigationInstructions();
      }
    } catch (e) {
      print("Error in location loop: $e");
    } finally {
      // THE FIX: Always schedule the next update no matter what happened above
      _scheduleNextLocationUpdate();
    }
  }
  // --- RE-ROUTING ---

  // ignore: unused_element
  bool _isOffRoute(LatLng driverLoc, List<LatLng> routePoints) {
    if (routePoints.isEmpty) return false;
    double minDistance = double.infinity;
    for (final point in routePoints) {
      final dist = _calculateDistance(driverLoc, point);
      if (dist < minDistance) minDistance = dist;
    }
    return minDistance > 0.05; // 50 meters
  }

  // ignore: unused_element
  Future<void> _recalculateRoute() async {
    if (isRecalculating.value ||
        activeTrip.value == null ||
        driverLocation.value == null) {
      return;
    }

    isRecalculating.value = true;
    THelperFunctions.showSnackBar("Rerouting...");

    LatLng target;
    if (tripStatus.value == TripStatus.drivingToPickup) {
      target = activeTrip.value!.pickupLocation;
    } else if (tripStatus.value == TripStatus.tripInProgress) {
      target = activeTrip.value!.destinationLocation;
    } else {
      isRecalculating.value = false;
      return;
    }

    try {
      final routeInfo = await RouteService.getRouteInfo(
        driverLocation.value!,
        target,
      );

      if (routeInfo.points.isNotEmpty) {
        currentRoute.assignAll(routeInfo.points);
        _initialRouteDistanceKm = routeInfo.distanceValue / 1000.0;
        _initialRouteDurationMinutes = (routeInfo.durationValue / 60).round();
        _navigationStartTime = DateTime.now();

        mapPolylines.clear();
        mapPolylines.add(
          Polyline(
            polylineId: PolylineId(
              tripStatus.value == TripStatus.drivingToPickup
                  ? 'route_to_pickup'
                  : 'route_to_destination',
            ),
            points: routeInfo.points,
            color: tripStatus.value == TripStatus.drivingToPickup
                ? TColors.primary
                : TColors.success,
            width: 5,
          ),
        );
        distanceToDestination.value = _initialRouteDistanceKm;
        estimatedTimeToDestination.value = _initialRouteDurationMinutes;
      }
    } catch (e) {
      print("Error recalculating route: $e");
    } finally {
      isRecalculating.value = false;
    }
  }

  // --- MARKERS ---

  void _addPickupMarker(LatLng location) {
    mapMarkers.removeWhere((marker) => marker.markerId.value == 'pickup');
    mapMarkers.add(
      Marker(
        markerId: const MarkerId('pickup'),
        position: location,
        icon:
            _markerService.pickupIcon ??
            BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        infoWindow: InfoWindow(
          title: 'Pickup Location',
          snippet: activeTrip.value?.pickupAddress ?? 'Rider pickup point',
        ),
      ),
    );
    update();
  }

  void _addDestinationMarker(LatLng location) {
    mapMarkers.removeWhere((marker) => marker.markerId.value == 'destination');
    mapMarkers.add(
      Marker(
        markerId: const MarkerId('destination'),
        position: location,
        icon:
            _markerService.destinationIcon ??
            BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        infoWindow: InfoWindow(
          title: 'Destination',
          snippet:
              activeTrip.value?.destinationAddress ?? 'Rider drop-off point',
        ),
      ),
    );
    update();
  }

  void _updateDriverLocationOnMap() {
    if (driverLocation.value == null) return;
    final markerId = MarkerId('driver_loc');

    double bearing = 0.0;
    if (_previousDriverLocation != null) {
      bearing = _calculateBearing(
        _previousDriverLocation!,
        driverLocation.value!,
      );
    }
    _previousDriverLocation = driverLocation.value;

    mapMarkers.removeWhere((marker) => marker.markerId == markerId);
    mapMarkers.add(
      Marker(
        markerId: markerId,
        position: driverLocation.value!,
        icon:
            _markerService.driverIcon ??
            BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        anchor: const Offset(0.5, 0.5),
        rotation: bearing,
        flat: true,
        zIndex: 2,
        infoWindow: const InfoWindow(title: 'Your Location'),
      ),
    );
    mapMarkers.refresh();
    update();
  }

  // --- HELPERS ---

  void _fitMapToCurrentRoute() {
    if (mapController == null || currentRoute.isEmpty) return;
    if (currentRoute.length == 1) {
      mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(currentRoute.first, 16.0),
      );
      return;
    }
    double minLat = currentRoute.map((p) => p.latitude).reduce(math.min);
    double maxLat = currentRoute.map((p) => p.latitude).reduce(math.max);
    double minLng = currentRoute.map((p) => p.longitude).reduce(math.min);
    double maxLng = currentRoute.map((p) => p.longitude).reduce(math.max);

    LatLngBounds bounds = LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );
    Future.delayed(const Duration(milliseconds: 100), () {
      mapController?.animateCamera(CameraUpdate.newLatLngBounds(bounds, 80));
    });
  }

  double _calculateDistance(LatLng point1, LatLng point2) {
    const double R = 6371;
    final double phi1 = point1.latitude * math.pi / 180;
    final double phi2 = point2.latitude * math.pi / 180;
    final double deltaPhi = (point2.latitude - point1.latitude) * math.pi / 180;
    final double deltaLambda =
        (point2.longitude - point1.longitude) * math.pi / 180;
    final double a =
        math.sin(deltaPhi / 2) * math.sin(deltaPhi / 2) +
        math.cos(phi1) *
            math.cos(phi2) *
            math.sin(deltaLambda / 2) *
            math.sin(deltaLambda / 2);
    final double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return R * c;
  }

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
    return (bearing * 180 / math.pi + 360) % 360;
  }

  void _handleCashPaymentPending(dynamic data) {
    if (data is Map<String, dynamic> &&
        data['tripId'] == activeTrip.value?.id) {
      cashAmountToReceive.value =
          (data['amount'] as num?)?.toDouble() ?? activeTrip.value!.fare;
      isWaitingForCash.value = true;

      // Persist cash-pending state so we can restore after restart.
      _storage.write('driver_waiting_for_payment', true);
      _storage.write('driver_waiting_trip_id', activeTrip.value!.id);
      _storage.write('driver_waiting_for_cash', true);
      _storage.write('driver_waiting_cash_amount', cashAmountToReceive.value);

      update();
    }
  }

  void _handlePaymentConfirmed(dynamic data) {
    if (data is Map<String, dynamic> &&
        data['tripId'] == activeTrip.value?.id) {
      tripStatus.value = TripStatus.completed;
      activeTrip.value = activeTrip.value?.copyWith(
        status: TripStatus.completed,
        endTime: DateTime.now(),
      );
      _dashboardController?.updateEarningsFromCompletedTrip(activeTrip.value);
      Future.delayed(const Duration(seconds: 3), _resetTripState);
      update();
    }
  }

  /// Backend emits `package:delivered` when a package delivery is confirmed.
  /// At this point payment is not yet completed, so we route the driver
  /// to `WaitingForPaymentScreen` (and keep it there until `payment:confirmed`).
  void handlePackageDelivered(Map<String, dynamic> data) {
    final tripId = data['tripId']?.toString() ?? '';
    if (tripId.isEmpty) return;

    final fallbackLoc = driverLocation.value ?? const LatLng(0, 0);
    final prev = activeTrip.value;

    // Ensure `activeTrip.id` matches so `cash_payment:pending` can be correlated.
    activeTrip.value = ActiveTrip(
      id: tripId,
      riderId: prev?.riderId ?? '',
      riderName: prev?.riderName ?? 'Rider',
      riderPhone: prev?.riderPhone ?? '',
      riderRating: prev?.riderRating ?? 0.0,
      pickupLocation: prev?.pickupLocation ?? fallbackLoc,
      destinationLocation: prev?.destinationLocation ?? fallbackLoc,
      pickupAddress: prev?.pickupAddress ?? '',
      destinationAddress: prev?.destinationAddress ?? '',
      fare: prev?.fare ?? 0.0,
      distance: prev?.distance ?? 0.0,
      estimatedDuration: prev?.estimatedDuration ?? 0,
      rideType: prev?.rideType ?? '',
      startTime: prev?.startTime ?? DateTime.now(),
      status: TripStatus.none,
      chatId: prev?.chatId ?? '',
    );

    tripStatus.value = TripStatus.none;
    isWaitingForCash.value = false;
    cashAmountToReceive.value = 0.0;

    // Persist so the waiting screen survives app restart.
    _storage.write('driver_waiting_is_package', true);
    _storage.write('active_ride_mode', 'package_delivery');
    _storage.write('driver_waiting_for_payment', true);
    _storage.write('driver_waiting_trip_id', tripId);
    _storage.write('driver_waiting_for_cash', false);
    _storage.remove('driver_waiting_cash_amount');

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showWaitingForPaymentScreenOnce();
    });
    update();
  }

  void handlePackageDisputed(Map<String, dynamic> data) {
    if (data['tripId'] == activeTrip.value?.id) {
      THelperFunctions.showWarningSnackBar(
        'Dispute Opened',
        data['reason'] ?? 'A dispute has been raised for this delivery.',
      );
      update();
    }
  }

  void handleDisputeResolved(Map<String, dynamic> data) {
    if (data['tripId'] == activeTrip.value?.id) {
      final res = data['resolution'] == 'resolved' ? 'Settled' : 'Rejected';
      THelperFunctions.showSuccessSnackBar(
        'Dispute Resolved',
        'The dispute has been $res. ${data['adminNote'] ?? ''}',
      );
      update();
    }
  }

  void handleDebtPaid(Map<String, dynamic> data) {
    THelperFunctions.showSuccessSnackBar(
      'Debt Paid',
      'Your commission debt has been cleared successfully.',
    );
    // Optionally refresh earnings or profile
    _dashboardController?.fetchTodayStats();
    update();
  }

  void handleLoyaltyReduction(Map<String, dynamic> data) {
    if (data['tripId'] == activeTrip.value?.id) {
      THelperFunctions.showSuccessSnackBar(
        'Loyalty Applied',
        'Commission reduction of ₦${data['reductionAmount']} applied.',
      );
      update();
    }
  }

  void handleTransferCompleted(Map<String, dynamic> data) {
    if (data['tripId'] == activeTrip.value?.id) {
      _handlePaymentConfirmed(data);
      THelperFunctions.showSuccessSnackBar(
        'Payment Success',
        'Bank transfer confirmed.',
      );
    }
  }

  void _resetTripState() {
    _storage.remove('active_ride_id');
    _storage.remove('active_ride_mode');
    // Clear persisted coordinates
    _storage.remove('trip_pickup_lat');
    _storage.remove('trip_pickup_lng');
    _storage.remove('trip_dest_lat');
    _storage.remove('trip_dest_lng');
    activeTrip.value = null;
    currentTripRequest.value = null;
    tripStatus.value = TripStatus.none;
    hasNewRequest.value = false;
    isNavigating.value = false;
    _requestTimer?.cancel();
    navigationInstruction.value = '';
    currentRoute.clear();
    mapPolylines.clear();
    mapMarkers.removeWhere(
      (m) => m.markerId.value == 'pickup' || m.markerId.value == 'destination',
    );
    _dashboardController?.checkDriverStatus();
    _waitingForPaymentScreenOpened = false;

    // Clear persisted "waiting for payment" flags.
    _storage.remove('driver_waiting_for_payment');
    _storage.remove('driver_waiting_is_package');
    _storage.remove('driver_waiting_trip_id');
    _storage.remove('driver_waiting_for_cash');
    _storage.remove('driver_waiting_cash_amount');
    _storage.remove('driver_waiting_fare');
    _storage.remove('driver_waiting_distance');
    _storage.remove('driver_waiting_eta');
    _storage.remove('driver_waiting_category');
    _storage.remove('driver_waiting_rider_id');
    _storage.remove('driver_waiting_rider_name');
    update();
  }

  // --- STATE RESTORATION ---

  Future<void> restoreDriverRideState(DriverReconnectData data) async {
    print("Restoring driver state. Status: ${data.status}");
    LatLng? pickupLoc;
    LatLng? destLoc;

    // 1. FIRST: Try to use locally persisted coordinates (most reliable)
    final storedPickupLat = _storage.read('trip_pickup_lat');
    final storedPickupLng = _storage.read('trip_pickup_lng');
    final storedDestLat = _storage.read('trip_dest_lat');
    final storedDestLng = _storage.read('trip_dest_lng');

    if (storedPickupLat != null && storedPickupLng != null &&
        storedDestLat != null && storedDestLng != null) {
      print("RESTORE: Using locally stored coordinates.");
      pickupLoc = LatLng(
        (storedPickupLat as num).toDouble(),
        (storedPickupLng as num).toDouble(),
      );
      destLoc = LatLng(
        (storedDestLat as num).toDouble(),
        (storedDestLng as num).toDouble(),
      );
    } else {
      // FALLBACK: Resolve from address names via PlacesService (unreliable for ambiguous names)
      print("RESTORE: No stored coordinates. Falling back to PlacesService.");
      // Pickup
      if (data.pickup.toLowerCase().contains('current location')) {
        final pos = _locationService.getLocationForMap();
        pickupLoc = LatLng(pos.latitude, pos.longitude);
      } else {
        final pSuggestions = await PlacesService.getPlaceSuggestions(data.pickup);
        if (pSuggestions.isNotEmpty) {
          final pDetails = await PlacesService.getPlaceDetails(
            pSuggestions.first.placeId,
          );
          pickupLoc = pDetails?.location;
        }
      }

      // Destination
      final dSuggestions = await PlacesService.getPlaceSuggestions(
        data.destination,
      );
      if (dSuggestions.isNotEmpty) {
        final dDetails = await PlacesService.getPlaceDetails(
          dSuggestions.first.placeId,
        );
        destLoc = dDetails?.location;
      }
    }

    // 2. Refresh current position
    await _locationService.refreshLocation();
    final currentPos = _locationService.getLocationForMap();
    driverLocation.value = LatLng(currentPos.latitude, currentPos.longitude);

    // 3. Initialize navigation variables
    _initialRouteDistanceKm = data.distance;
    _initialRouteDurationMinutes = (data.distance * 2).round();
    _navigationStartTime = DateTime.now();

    // 4. Set Active Trip Model
    activeTrip.value = ActiveTrip(
      id: data.tripId,
      riderId: data.riderId,
      riderName: data.riderName,
      riderPhone: '',
      riderRating: 0.0,
      pickupLocation: pickupLoc ?? driverLocation.value!,
      destinationLocation: destLoc ?? driverLocation.value!,
      pickupAddress: data.pickup,
      destinationAddress: data.destination,
      fare: data.price,
      distance: data.distance,
      estimatedDuration: _initialRouteDurationMinutes,
      rideType: data.category,
      startTime: DateTime.now(),
      status: TripStatus.none,
      chatId: data.chatId,
    );

    _storage.write('active_ride_id', data.tripId);
    _updateDriverLocationOnMap();

    // 5. Restore specific status and trigger navigation
    switch (data.status.toLowerCase()) {
      case 'booked':
      case 'accepted':
        tripStatus.value = TripStatus.drivingToPickup;
        _addPickupMarker(activeTrip.value!.pickupLocation);
        _startNavigationToPickup();
        break;
      case 'arrived':
        tripStatus.value = TripStatus.arrivedAtPickup;
        _addPickupMarker(activeTrip.value!.pickupLocation);
        // If we arrived, navigation stops, so we check if button should be visible
        break;
      case 'on-trip':
      case 'in_progress':
        tripStatus.value = TripStatus.tripInProgress;
        _addDestinationMarker(activeTrip.value!.destinationLocation);
        await _startNavigationToDestination();
        _fitMapToCurrentRoute();
        break;
      case 'completed':
        // Some flows may request reconnect for already completed trips.
        // `reconnectToTrip` currently doesn't provide paymentStatus, so we
        // rely on persisted local state and show the waiting UI.
        tripStatus.value = TripStatus.none;
        _restoreWaitingForPaymentFromStorage();
        update();
        return;
      default:
        _resetTripState();
        return; // Exit early if no valid status
    }

    // --- THE CRITICAL ADDITION FOR YOUR QUESTION ---
    // 6. Immediate Proximity Check after restoration
    // This forces the UI to show "Start Trip" or "Complete Trip" immediately
    // if the driver is already within the 1km threshold upon app launch.
    if (hasActiveTrip) {
      Future.delayed(const Duration(milliseconds: 500), () {
        if (_isNearDestination()) {
          print(
            "RESTORATION: Proximity detected immediately. Triggering Arrival.",
          );
          _handleArrival();
        }
      });
    }

    update(); // Force GetX update for UI
  }

  void _updateNavigationInstructions() {
    if (activeTrip.value == null || !isNavigating.value) return;

    double initialDistance = _initialRouteDistanceKm > 0
        ? _initialRouteDistanceKm
        : activeTrip.value!.distance;
    int initialDuration = _initialRouteDurationMinutes > 0
        ? _initialRouteDurationMinutes
        : activeTrip.value!.estimatedDuration;

    if (initialDistance <= 0) return;

    _navigationStartTime ??= DateTime.now();
    DateTime startTime = _navigationStartTime!;

    // Banner Text
    if (tripStatus.value == TripStatus.drivingToPickup) {
      navigationInstruction.value =
          'Continue to pickup: ${activeTrip.value!.pickupAddress}';
    } else if (tripStatus.value == TripStatus.tripInProgress) {
      navigationInstruction.value =
          'Continue to destination: ${activeTrip.value!.destinationAddress}';
    }

    // Countdown Logic
    if (initialDuration > 0) {
      final elapsedSeconds = DateTime.now().difference(startTime).inSeconds;
      final elapsedMinutes = elapsedSeconds / 60.0;
      final remainingMinutes = math.max(
        0,
        initialDuration - elapsedMinutes.round(),
      );
      final progress = math.min(
        1.0,
        elapsedSeconds / (initialDuration * 60),
      ); // Fixed progress math
      final remainingDistance = math.max(
        0.0,
        initialDistance * (1.0 - progress),
      );

      distanceToDestination.value = remainingDistance;
      estimatedTimeToDestination.value = remainingMinutes;
    }

    // THE KEY FIX: Run arrival check every time.
    // This flips the status to 'arrivedAtPickup' or 'arrivedAtDestination'
    if (_isNearDestination()) {
      _handleArrival();
    }

    update();
  }

  bool _isNearDestination() {
    if (driverLocation.value == null || activeTrip.value == null) return false;

    LatLng targetLocation;
    // Determine target based on trip phase
    if (tripStatus.value == TripStatus.drivingToPickup ||
        tripStatus.value == TripStatus.accepted) {
      targetLocation = activeTrip.value!.pickupLocation;
    } else if (tripStatus.value == TripStatus.tripInProgress) {
      targetLocation = activeTrip.value!.destinationLocation;
    } else {
      return false;
    }

    final distanceKm = _calculateDistance(
      driverLocation.value!,
      targetLocation,
    );

    // Debug print to see real-time distance in console
    print("DEBUG: Distance to target: ${distanceKm.toStringAsFixed(2)} km");

    // Return true if within 3km (3000 meters) to account for GPS drift
    return distanceKm < 3.0;
  }

  // 2. ADD: Manual Arrival Trigger
  // Call this if the GPS is stuck but the driver is physically there
  Future<void> verifyAndTriggerArrival() async {
    if (activeTrip.value == null) return;

    if (_isNearDestination()) {
      _handleArrival();
      THelperFunctions.showSuccessSnackBar('Success', 'Arrival confirmed.');
    } else {
      THelperFunctions.showErrorSnackBar(
        'Not Arrived',
        'You are not close enough to the location yet. Please get closer (within 3km).',
      );
    }
  }

  void _handleArrival() {
    if (activeTrip.value == null) return;

    // Phase A: Arriving at Pickup -> Shows "Start Trip"
    if (tripStatus.value == TripStatus.drivingToPickup ||
        tripStatus.value == TripStatus.accepted) {
      print(
        "APP LOGIC: Swapping to 'Arrived at Pickup' state (Frontend Only).",
      );
      tripStatus.value = TripStatus.arrivedAtPickup;
      isNavigating.value = false; // This stops the banner countdown

      activeTrip.value = activeTrip.value!.copyWith(
        status: TripStatus.arrivedAtPickup,
        arrivalTime: DateTime.now(),
      );

      // Purely frontend state change, no backend notification for arrival
    }
    // Phase B: Arriving at Destination -> Shows "Complete Trip"
    else if (tripStatus.value == TripStatus.tripInProgress) {
      print(
        "APP LOGIC: Swapping to 'Arrived at Destination' state (Frontend Only).",
      );
      tripStatus.value = TripStatus.arrivedAtDestination;
      isNavigating.value = false;

      activeTrip.value = activeTrip.value!.copyWith(
        status: TripStatus.arrivedAtDestination,
      );

      // Purely frontend state change
    }
    update();
  }
}
