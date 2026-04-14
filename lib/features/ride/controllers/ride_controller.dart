import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:sarri_ride/core/services/http_service.dart';
import 'package:sarri_ride/core/services/websocket_service.dart';
import 'package:sarri_ride/features/location/services/location_service.dart'; // Moved up
import 'package:sarri_ride/utils/logging/app_logger.dart'; // Added
import 'package:sarri_ride/features/location/services/places_service.dart'; // Moved up
import 'package:sarri_ride/core/services/map_marker_service.dart';
import 'package:sarri_ride/features/emergency/screens/emergency_reporting_screen.dart';
import 'package:sarri_ride/features/ride/models/ride_model.dart';
import 'package:sarri_ride/features/ride/services/ride_service.dart';
import 'package:sarri_ride/features/ride/widgets/payment_selection_sheet.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';
import 'package:get_storage/get_storage.dart';
import 'package:sarri_ride/config/api_config.dart'; // IMPORTED FOR API CONFIG

import 'package:sarri_ride/features/location/services/route_service.dart';
import 'package:sarri_ride/features/ride/widgets/driver_info_card.dart';
import 'package:sarri_ride/features/ride/widgets/ride_selection_widget.dart';
import 'package:sarri_ride/features/ride/widgets/map_picker_screen.dart';
import 'package:sarri_ride/utils/constants/colors.dart';
import 'package:sarri_ride/utils/helpers/helper_functions.dart';
import 'package:sarri_ride/features/ride/widgets/pickup_location_modal.dart';
import 'package:sarri_ride/features/ride/widgets/no_drivers_available_widget.dart';
import 'package:sarri_ride/features/package_delivery/controllers/package_delivery_controller.dart';
import 'package:sarri_ride/features/package_delivery/services/package_delivery_service.dart';

// Enums
enum BookingState {
  initial,
  destinationSearch,
  selectRide,
  searchingDriver,
  driverAssigned,
  driverArrived,
  tripInProgress,
  tripCompleted,
  packageBooking,
  freightBooking,
}

class RideController extends GetxController with GetTickerProviderStateMixin, WidgetsBindingObserver {
  static RideController get instance => Get.find();
  final HttpService _httpService = HttpService.instance;

  // --- Services ---
  final WebSocketService _webSocketService = WebSocketService.instance;
  final LocationService _locationService = LocationService.instance;
  final RideService _rideService = RideService.instance;
  final MapMarkerService _markerService = MapMarkerService.instance;
  final _storage = GetStorage();

  // Controllers
  GoogleMapController? mapController;
  final PanelController panelController = PanelController();
  late AnimationController driverAnimationController;
  Timer? driverLocationTimer;

  // Text Controllers
  final TextEditingController destinationController = TextEditingController();
  final TextEditingController pickupController = TextEditingController();
  final TextEditingController packageDeliveryController =
      TextEditingController();
  final TextEditingController freightDeliveryController =
      TextEditingController();

  final RxString searchingStatusText = "Finding your driver...".obs;
  final RxString potentialDriverInfo = "".obs;

  /// Stores the currently selected payment method. Defaults to 'Cash'.
  final RxString selectedPaymentMethod = 'Cash'.obs;

  /// Stores the ID of the selected card (if not 'Cash').
  final RxString selectedCardId = ''.obs;

  // Reactive state variables
  final Rx<BookingState> currentState = BookingState.initial.obs;
  final Rx<LatLng?> pickupLocation = Rx<LatLng?>(null);
  final Rx<LatLng?> destinationLocation = Rx<LatLng?>(null);
  final RxString pickupState = ''.obs;

  // Multi-stop support
  final RxList<StopPoint> stops = <StopPoint>[].obs;
  final RxInt maxStops = 3.obs;
  final RxBool isMultiStop = false.obs;

  // Route calculation
  final RxList<RouteSegment> routeSegments = <RouteSegment>[].obs;
  final RxDouble totalDistance = 0.0.obs;
  final RxInt totalDuration = 0.obs;
  final RxDouble basePrice = 0.0.obs;
  final RxDouble totalPrice = 0.0.obs;

  // Store detailed place information for better markers
  final RxString pickupName = 'Current Location'.obs;
  final RxString pickupAddress = ''.obs;
  final RxString destinationName = ''.obs;
  final RxString destinationAddress = ''.obs;

  final RxList<Marker> markers = <Marker>[].obs;
  final RxList<Polyline> polylines = <Polyline>[].obs;
  final RxList<LatLng> currentRoutePoints = <LatLng>[].obs;
  final RxInt currentRouteIndex = 0.obs;
  final Rx<RideType?> selectedRideType = Rx<RideType?>(null);
  final Rx<Driver?> assignedDriver = Rx<Driver?>(null);
  final RxList<PlaceSuggestion> destinationSuggestions =
      <PlaceSuggestion>[].obs;
  final RxBool showDestinationSuggestions = false.obs;
  final Rx<DateTime?> actualTripStartTime = Rx<DateTime?>(null);
  final RxBool isPaymentCompleted = false.obs;
  final RxList<RideType> rideTypes = <RideType>[].obs;

  final RxString rideId = ''.obs;
  final RxString activeRideChatId = ''.obs;

  // --- Animation State ---
  LatLng? _animStartLocation;
  LatLng? _animEndLocation;
  double _animStartRotation = 0.0;
  double _animEndRotation = 0.0;

  // Local var to track rotation smoothly
  LatLng? _previousDriverLocation;

  // Ride types data
  final List<RideType> _defaultRideTypes = [
    const RideType(
      name: 'Luxury',
      price: 2500,
      eta: '3 min',
      icon: Icons.directions_car,
      seats: 4,
    ),
    const RideType(
      name: 'Comfort',
      price: 3200,
      eta: '5 min',
      icon: Icons.car_rental,
      seats: 4,
    ),
    const RideType(
      name: 'XL',
      price: 4500,
      eta: '7 min',
      icon: Icons.airport_shuttle,
      seats: 6,
    ),
  ];
  final List<RideType> _packageRideTypes = [
    const RideType(
      name: 'Bike Courier',
      price: 1200,
      eta: '10 min',
      icon: Icons.pedal_bike,
      seats: 1,
    ),
    const RideType(
      name: 'Car Delivery',
      price: 2500,
      eta: '15 min',
      icon: Icons.local_shipping,
      seats: 4,
    ),
    const RideType(
      name: 'Van Delivery',
      price: 3800,
      eta: '20 min',
      icon: Icons.fire_truck,
      seats: 6,
    ),
  ];
  final List<RideType> _freightRideTypes = [
    const RideType(
      name: 'Small Truck (3t)',
      price: 15000,
      eta: '30 min',
      icon: Icons.local_shipping_outlined,
      seats: 2,
    ),
    const RideType(
      name: 'Medium Truck (7t)',
      price: 25000,
      eta: '45 min',
      icon: Icons.local_shipping,
      seats: 2,
    ),
    const RideType(
      name: 'Large Truck (15t)',
      price: 40000,
      eta: '60 min',
      icon: Icons.fire_truck,
      seats: 2,
    ),
  ];

  // --- ADDED THIS LIST BACK ---
  final RxList<Map<String, dynamic>> recentDestinations =
      <Map<String, dynamic>>[].obs;
  @override
  void onInit() {
    super.onInit();
    rideTypes.clear();
    WidgetsBinding.instance.addObserver(this);

    // Package delivery booking (rider) state.
    if (!Get.isRegistered<PackageDeliveryController>()) {
      Get.put(PackageDeliveryController());
    }
    if (!Get.isRegistered<PackageDeliveryService>()) {
      Get.put(PackageDeliveryService(), permanent: false);
    }

    // 1. Initialize Controller (Keep this)
    driverAnimationController = AnimationController(
      duration: const Duration(
        seconds: 3,
      ), // 3 seconds creates a smooth glide for 4s pings
      vsync: this,
    );

    // 2. Add Listener (New)
    driverAnimationController.addListener(() {
      if (_animStartLocation != null &&
          _animEndLocation != null &&
          assignedDriver.value != null) {
        // Calculate the position at this exact moment (0.0 to 1.0)
        final double t = driverAnimationController.value;

        final double lat = _lerp(
          _animStartLocation!.latitude,
          _animEndLocation!.latitude,
          t,
        );
        final double lng = _lerp(
          _animStartLocation!.longitude,
          _animEndLocation!.longitude,
          t,
        );
        final double rot = _lerpRotation(
          _animStartRotation,
          _animEndRotation,
          t,
        );

        final newPos = LatLng(lat, lng);

        // Update the marker visually without triggering full logic re-calculations
        _updateDriverMarkerVisualsOnly(newPos, rot);
      }
    });

    initializeMap();
    initializeStops();
    _checkCurrentRideStatus();
    _webSocketService.registerPaymentConfirmedListener(_handlePaymentConfirmed);
    fetchRecentDestinations();
  }

  Future<void> fetchRecentDestinations() async {
    try {
      final response = await _httpService.get(
        ApiConfig.clientTripHistoryEndpoint,
        queryParameters: {
          'limit': '10', // Fetch 10 to ensure we find enough unique ones
          'sortBy': 'bookedAt',
          'sortOrder': 'desc',
        },
      );

      final responseData = _httpService.handleResponse(response);

      if (responseData['status'] == 'success' && responseData['data'] != null) {
        final List trips = responseData['data']['trips'] ?? [];
        final Map<String, Map<String, dynamic>> uniqueDestinations = {};

        for (var trip in trips) {
          final dest = trip['destination'];
          if (dest != null &&
              dest['name'] != null &&
              dest['coordinates'] != null) {
            final String name = dest['name'];
            // Only add if we haven't seen this destination name yet
            if (!uniqueDestinations.containsKey(name)) {
              uniqueDestinations[name] = {
                'name': name,
                'address': name, // Use name as address for now
                'location': LatLng(
                  (dest['latitude'] ?? dest['coordinates'][1] as num)
                      .toDouble(),
                  (dest['longitude'] ?? dest['coordinates'][0] as num)
                      .toDouble(),
                ),
                'icon': Icons.history, // Use history icon
              };
            }
          }
          if (uniqueDestinations.length >= 5) break; // Limit to 5
        }

        recentDestinations.assignAll(uniqueDestinations.values.toList());
      }
    } catch (e) {
      print("Error fetching recent destinations: $e");
      // Don't clear list if error, just keep empty or previous state
    }
  }

  // --- STATE RESTORATION ---
  Future<void> _checkCurrentRideStatus() async {
    // If the rider already reached `rideCompleted` but payment is still pending,
    // the backend `reconnectToTrip` rejects `status=completed`. In that case we
    // restore the payment-pending UI from local storage.
    final isPaymentPending =
        _storage.read('rider_waiting_for_payment') == true;
    final waitingTripId = _storage.read<String>('rider_waiting_trip_id');
    if (isPaymentPending && waitingTripId != null && waitingTripId.isNotEmpty) {
      print(
        "RideController: Restoring payment-pending UI for trip $waitingTripId from storage.",
      );
      rideId.value = waitingTripId;
      await restorePaymentPendingFromStorage();
      return;
    }

    final storedRideId = _storage.read('active_ride_id');
    if (storedRideId != null && storedRideId.toString().isNotEmpty) {
      print(
        "RideController: Found active ride ID $storedRideId. Attempting reconnect...",
      );
      try {
        final response = await _rideService.reconnectToTrip(
          storedRideId,
          'rider',
        );

        if (response.status == 'success' && response.data != null) {
          print("RideController: Reconnect successful. Restoring state.");
          // Convert Map to Model
          final rideData = RiderReconnectData.fromJson(response.data!);
          await restoreRideState(rideData);

          if (currentState.value != BookingState.initial) {
            panelController.open();
          }
        } else {
          print(
            "RideController: Ride $storedRideId not active. Clearing storage.",
          );
          _storage.remove('active_ride_id');
        }
      } catch (e) {
        print("Error checking ride status: $e");
      }
    }
  }

  /// Restore the rider's "trip completed, payment pending" UI after an app restart.
  /// This does not call the backend because `reconnectToTrip` rejects `status=completed`.
  Future<void> restorePaymentPendingFromStorage() async {
    final tripId = _storage.read<String>('rider_waiting_trip_id') ?? rideId.value;
    if (tripId.isEmpty) return;

    final category = _storage.read<String>('rider_waiting_category') ?? '';
    final fare = (_storage.read('rider_waiting_fare') as num?)?.toInt() ?? 0;
    final eta = _storage.read<String>('rider_waiting_eta') ?? '...';
    final seats = (_storage.read('rider_waiting_seats') as num?)?.toInt() ?? 4;

    rideId.value = tripId;
    selectedRideType.value = RideType(
      name: category,
      price: fare,
      eta: eta,
      icon: _getIconForCategory(category),
      seats: seats,
    );

    currentState.value = BookingState.tripCompleted;
    isPaymentCompleted.value = false;

    panelController.open();
    update();
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
    bearing = bearing * 180 / math.pi;
    return (bearing + 360) % 360;
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    driverAnimationController.dispose();
    driverLocationTimer?.cancel();
    destinationController.dispose();
    pickupController.dispose();
    packageDeliveryController.dispose();
    freightDeliveryController.dispose();
    _webSocketService.unregisterPaymentConfirmedListener(
      _handlePaymentConfirmed,
    );
    super.onClose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      print("RideController: App resumed, automatically syncing ride status...");
      // Re-fetch the ride state from the server silently so the UI updates to the latest step
      _checkCurrentRideStatus();
      // Auto-refresh the location after permission might have been granted
      refreshCurrentLocation();
    }
  }

  Future<void> initializeMap() async {
    final position = _locationService.getLocationForMap();
    final currentLatLng = LatLng(position.latitude, position.longitude);

    pickupLocation.value = currentLatLng;

    // Set placeholder
    pickupName.value = 'Fetching address...';
    pickupController.text = 'Fetching address...';

    // Force resolve the address immediately
    await _resolveAddressForPickup(currentLatLng);

    _getAndSetStateFromLatLng(currentLatLng, defaultState: "Lagos");
    addPickupMarker();
  }

  // --- ADD THIS NEW FUNCTION IMMEDIATELY AFTER initializeMap ---
  Future<void> _resolveAddressForPickup(LatLng location) async {
    try {
      final address = await PlacesService.getAddressFromCoordinates(
        location.latitude,
        location.longitude,
      );

      if (address != null && address.isNotEmpty) {
        pickupName.value = address;
        pickupAddress.value = address;
        pickupController.text = address;
      } else {
        pickupName.value = 'Current Location';
        pickupAddress.value = 'Unknown Location';
        pickupController.text = 'Current Location';
      }
    } catch (e) {
      pickupName.value = 'Current Location';
      pickupController.text = 'Current Location';
    }
  }

  void _handlePaymentConfirmed(dynamic data) {
    if (data is Map<String, dynamic> && data['tripId'] == rideId.value) {
      print("RIDE CONTROLLER: Received payment:confirmed event.");
      onPaymentSuccess();
    }
  }

  Future<void> _getAndSetStateFromLatLng(
    LatLng location, {
    String defaultState = '',
  }) async {
    try {
      final placeDetails = await PlacesService.getPlaceDetailsFromCoordinates(
        location.latitude,
        location.longitude,
      );
      if (placeDetails != null && placeDetails.state.isNotEmpty) {
        pickupState.value = _cleanStateName(placeDetails.state);
      } else if (defaultState.isNotEmpty) {
        pickupState.value = defaultState;
      }
    } catch (e) {
      if (defaultState.isNotEmpty) pickupState.value = defaultState;
    }
  }

  void initializeStops() {
    stops.clear();
    if (pickupLocation.value != null) {
      stops.add(
        StopPoint(
          id: 'pickup',
          type: StopType.pickup,
          location: pickupLocation.value!,
          name: pickupName.value,
          address: pickupAddress.value,
          isEditable: false,
        ),
      );
    }
  }

  CameraPosition get initialCameraPosition {
    final position = _locationService.getLocationForMap();
    return CameraPosition(
      target: LatLng(position.latitude, position.longitude),
      zoom: 16.0,
    );
  }

  void addPickupMarker() {
    markers.removeWhere((marker) => marker.markerId.value == 'pickup');

    if (pickupLocation.value != null) {
      // FIX: Simplify logic. If no destination is selected, we are likely
      // just browsing/idle at our current location.
      bool isIdleMode = destinationLocation.value == null;

      BitmapDescriptor iconToUse;
      String titleText;
      Offset anchor;

      if (isIdleMode) {
        // Show Current Location Icon (Blue Dot/Halo)
        iconToUse =
            _markerService.currentLocationIcon ??
            BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue);
        titleText = "You are here";
        // Center anchor for current location dot
        anchor = const Offset(0.5, 0.5);
      } else {
        // Show Pickup Pin (Green Pole) because we are setting up a ride
        iconToUse =
            _markerService.pickupIcon ??
            BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen);
        titleText = '📍 ${pickupName.value}';
        // Bottom anchor for pin so it stands on the point
        anchor = const Offset(0.5, 1.0);
      }

      markers.add(
        Marker(
          markerId: const MarkerId('pickup'),
          position: pickupLocation.value!,
          icon: iconToUse,
          anchor: anchor,
          zIndex: 1,
          infoWindow: InfoWindow(
            title: titleText,
            snippet: pickupAddress.value,
          ),
        ),
      );
      markers.refresh();
      update();
    }
  }

  Future<void> addStop(PlaceSuggestion suggestion) async {
    if (stops.length >= maxStops.value + 1) {
      THelperFunctions.showErrorSnackBar(
        'Error',
        'Maximum number of stops reached.',
      );
      return;
    }
    try {
      final placeDetails = await PlacesService.getPlaceDetails(
        suggestion.placeId,
      );
      if (placeDetails != null) {
        final newStop = StopPoint(
          id: 'stop_${DateTime.now().millisecondsSinceEpoch}',
          type: StopType.intermediate,
          location: placeDetails.location,
          name: placeDetails.name.isNotEmpty
              ? placeDetails.name
              : suggestion.mainText,
          address: placeDetails.formattedAddress,
          isEditable: true,
        );

        int insertIndex = stops.indexWhere(
          (s) => s.type == StopType.destination,
        );
        if (insertIndex == -1) {
          stops.add(newStop);
        } else {
          stops.insert(insertIndex, newStop);
        }
        isMultiStop.value = true;
        updateMapMarkers();
        await recalculateRoute();
        updatePricing();
        THelperFunctions.showSuccessSnackBar('Success', 'Stop added!');
      }
    } catch (e) {
      THelperFunctions.showErrorSnackBar('Error', 'Error adding stop: $e');
    }
  }

  void removeStop(String stopId) {
    if (stopId == 'pickup' || stopId == 'destination') return;
    stops.removeWhere((stop) => stop.id == stopId);
    if (stops.length <= 2) isMultiStop.value = false;
    updateMapMarkers();
    recalculateRoute();
    updatePricing();
  }

  void reorderStops(int oldIndex, int newIndex) {
    if (oldIndex < 1 ||
        newIndex < 1 ||
        oldIndex >= stops.length ||
        newIndex >= stops.length) {
      return;
    }
    if (newIndex > oldIndex) newIndex -= 1;
    final StopPoint item = stops.removeAt(oldIndex);
    stops.insert(newIndex, item);
    updateMapMarkers();
    recalculateRoute();
    updatePricing();
    update();
  }

  Future<void> updateDestination(PlaceSuggestion suggestion) async {
    try {
      final placeDetails = await PlacesService.getPlaceDetails(
        suggestion.placeId,
      );
      if (placeDetails != null) {
        stops.removeWhere((stop) => stop.type == StopType.destination);
        stops.add(
          StopPoint(
            id: 'destination',
            type: StopType.destination,
            location: placeDetails.location,
            name: placeDetails.name.isNotEmpty
                ? placeDetails.name
                : suggestion.mainText,
            address: placeDetails.formattedAddress,
            isEditable: true,
          ),
        );
        destinationLocation.value = placeDetails.location;
        destinationName.value = placeDetails.name.isNotEmpty
            ? placeDetails.name
            : suggestion.mainText;
        destinationAddress.value = placeDetails.formattedAddress;
        destinationController.text = destinationName.value;

        updateMapMarkers();
        await recalculateRoute();
        updatePricing();

        if (currentState.value == BookingState.tripInProgress) {
          driverLocationTimer?.cancel();
          startTripAnimation();
        }
      }
    } catch (e) {
      THelperFunctions.showErrorSnackBar(
        'Error',
        'Error updating destination: $e',
      );
    }
  }

  Future<void> recalculateRoute() async {
    if (stops.length < 2) {
      polylines.clear();
      currentRoutePoints.clear();
      totalDistance.value = 0.0;
      totalDuration.value = 0;
      updatePricing();
      return;
    }

    try {
      routeSegments.clear();
      polylines.clear();
      totalDistance.value = 0.0;
      totalDuration.value = 0;
      List<LatLng> allRoutePoints = [];

      for (int i = 0; i < stops.length - 1; i++) {
        final origin = stops[i].location;
        final destination = stops[i + 1].location;
        final routeInfo = await RouteService.getRouteInfo(origin, destination);

        routeSegments.add(
          RouteSegment(
            from: stops[i],
            to: stops[i + 1],
            points: routeInfo.points,
            distance: routeInfo.distanceValue,
            duration: routeInfo.durationValue,
          ),
        );

        totalDistance.value += routeInfo.distanceValue;
        totalDuration.value += routeInfo.durationValue;

        polylines.add(
          Polyline(
            polylineId: PolylineId('segment_$i'),
            points: routeInfo.points,
            color: _getSegmentColor(i),
            width: 5,
          ),
        );
        allRoutePoints.addAll(routeInfo.points);
      }

      currentRoutePoints.assignAll(allRoutePoints);
      currentRouteIndex.value = 0;

      if (currentState.value == BookingState.tripInProgress) {
        driverLocationTimer?.cancel();
        startTripAnimation();
      }

      fitMapToAllStops();
      update();
    } catch (e) {
      polylines.clear();
      currentRoutePoints.clear();
    }
  }

  void updatePricing() {
    final distanceKm = totalDistance.value / 1000.0;
    final durationMinutes = totalDuration.value / 60.0;
    basePrice.value = 500.0;
    final distancePrice = distanceKm * 150.0;
    final timePrice = durationMinutes * 20.0;
    totalPrice.value = basePrice.value + distancePrice + timePrice;

    // CHANGE: Trigger server API call immediately instead of local math
    _updatePricesFromApi();
  }

  // Helper for internal use
  Future<bool> _updatePricesFromApi() async {
    // FIX: Add null check to prevent crash
    if (pickupLocation.value == null || destinationLocation.value == null) {
      return false;
    }

    // Clear list to show loading state or prevent old prices
    rideTypes.clear();
    update();

    THelperFunctions.showSnackBar('Calculating fares from server...');

    try {
      // Use ! safely because we checked for null above
      final priceResponse = await _rideService.calculatePrice(
        pickupLocation.value!,
        destinationLocation.value!,
      );

      if (priceResponse.status == 'success' && priceResponse.data != null) {
        final prices = priceResponse.data!.prices;
        final newRideTypes = <RideType>[];
        final estimatedEtaMinutes = (totalDuration.value / 60).round() + 5;

        if (prices.luxury != null) {
          newRideTypes.add(
            RideType(
              name: 'Luxury',
              price: prices.luxury!.price,
              eta: '${estimatedEtaMinutes + 2} min',
              icon: Icons.directions_car,
              seats: prices.luxury!.seats,
            ),
          );
        }
        if (prices.comfort != null) {
          newRideTypes.add(
            RideType(
              name: 'Comfort',
              price: prices.comfort!.price,
              eta: '$estimatedEtaMinutes min',
              icon: Icons.car_rental,
              seats: prices.comfort!.seats,
            ),
          );
        }
        if (prices.xl != null) {
          newRideTypes.add(
            RideType(
              name: 'XL',
              price: prices.xl!.price,
              eta: '${estimatedEtaMinutes + 5} min',
              icon: Icons.airport_shuttle,
              seats: prices.xl!.seats,
            ),
          );
        }

        if (newRideTypes.isEmpty) {
          // Handle empty case
          return false;
        } else {
          rideTypes.assignAll(newRideTypes);
          return true;
        }
      } else {
        return false;
      }
    } catch (e) {
      return false;
    } finally {
      update();
    }
  }

  // ignore: unused_element
  double _getRideTypeMultiplier(String rideTypeName) {
    final nameLower = rideTypeName.toLowerCase();
    if (nameLower.contains('luxury')) return 1.5;
    if (nameLower.contains('comfort')) return 1.2;
    if (nameLower.contains('xl')) return 1.8;
    if (nameLower.contains('bike')) return 0.8;
    if (nameLower.contains('van')) return 1.4;
    if (nameLower.contains('truck')) return 3.0;
    return 1.0;
  }

  Color _getSegmentColor(int segmentIndex) {
    final colors = [
      TColors.primary,
      TColors.info,
      TColors.success,
      TColors.warning,
      TColors.secondary,
    ];
    return colors[segmentIndex % colors.length];
  }

  void fitMapToAllStops() {
    if (stops.isEmpty || mapController == null) return;
    if (stops.length == 1) {
      mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(stops.first.location, 15.0),
      );
      return;
    }
    LatLngBounds bounds = LatLngBounds(
      southwest: stops.fold(
        stops.first.location,
        (prev, stop) => LatLng(
          math.min(prev.latitude, stop.location.latitude),
          math.min(prev.longitude, stop.location.longitude),
        ),
      ),
      northeast: stops.fold(
        stops.first.location,
        (prev, stop) => LatLng(
          math.max(prev.latitude, stop.location.latitude),
          math.max(prev.longitude, stop.location.longitude),
        ),
      ),
    );
    mapController!.animateCamera(CameraUpdate.newLatLngBounds(bounds, 80));
  }

  void updateMapMarkers() {
    markers.removeWhere((m) => m.markerId.value != 'driver');
    for (int i = 0; i < stops.length; i++) {
      final stop = stops[i];
      markers.add(
        Marker(
          markerId: MarkerId(stop.id),
          position: stop.location,
          icon: _getStopMarkerIcon(stop.type, i),
          infoWindow: InfoWindow(
            title: _getStopMarkerTitle(stop, i),
            snippet: stop.address,
          ),
          draggable: stop.isEditable,
          onDragEnd: (_) {},
        ),
      );
    }
    if (assignedDriver.value != null) addDriverMarker();
    update();
  }

  BitmapDescriptor _getStopMarkerIcon(StopType type, int index) {
    switch (type) {
      case StopType.pickup:
        return _markerService.pickupIcon ??
            BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen);
      case StopType.destination:
        return _markerService.destinationIcon ??
            BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);
      case StopType.intermediate:
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue);
    }
  }

  String _getStopMarkerTitle(StopPoint stop, int index) {
    switch (stop.type) {
      case StopType.pickup:
        return '📍 Pickup: ${stop.name}';
      case StopType.destination:
        return '🎯 Destination: ${stop.name}';
      case StopType.intermediate:
        return '🛑 Stop $index: ${stop.name}';
    }
  }

  void selectPaymentMethod(String method, {String? cardId}) {
    selectedPaymentMethod.value = method;
    selectedCardId.value = cardId ?? '';
    update();
  }

  void showPaymentMethodPicker(BuildContext context) {
    PaymentSelectionSheet.show(context);
  }

  bool canModifyDuringRide() =>
      currentState.value == BookingState.tripInProgress &&
      stops.length < maxStops.value + 2;

  Future<void> addStopDuringRide(PlaceSuggestion suggestion) async {
    if (!canModifyDuringRide()) {
      THelperFunctions.showErrorSnackBar(
        'Error',
        'Cannot add more stops during this ride.',
      );
      return;
    }
    await addStop(suggestion);
  }

  Future<void> refreshCurrentLocation() async {
    await _locationService.refreshLocation();
    final position = _locationService.getLocationForMap();
    final newLatLng = LatLng(position.latitude, position.longitude);

    pickupLocation.value = newLatLng;
    pickupName.value = 'Current Location';

    try {
      final address = await PlacesService.getAddressFromCoordinates(
        newLatLng.latitude,
        newLatLng.longitude,
      );
      if (address != null) pickupAddress.value = address;
    } catch (e, stack) {
      AppLogger.error(
        'Failed to get address from coordinates',
        error: e,
        stackTrace: stack,
      );
    }

    pickupController.text = pickupName.value;
    await _getAndSetStateFromLatLng(newLatLng, defaultState: "Lagos");

    if (stops.isNotEmpty && stops.first.type == StopType.pickup) {
      stops[0] = StopPoint(
        id: stops.first.id,
        type: StopType.pickup,
        location: newLatLng,
        name: pickupName.value,
        address: pickupAddress.value,
        isEditable: false,
      );
    } else {
      initializeStops();
    }
    addPickupMarker();
    mapController?.animateCamera(CameraUpdate.newLatLngZoom(newLatLng, 16.0));
    if (destinationLocation.value != null) {
      await recalculateRoute();
      updatePricing();
    }
    update();
  }

  void addDestinationMarker() {
    if (destinationLocation.value != null) {
      markers.removeWhere((marker) => marker.markerId.value == 'destination');
      markers.add(
        Marker(
          markerId: const MarkerId('destination'),
          position: destinationLocation.value!,
          icon:
              _markerService.destinationIcon ??
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          infoWindow: InfoWindow(
            title: '🎯 ${destinationName.value}',
            snippet: destinationAddress.value,
          ),
        ),
      );
      update();
      if (pickupLocation.value != null) drawRoute();
    }
  }

  Future<void> drawRoute() async {
    if (pickupLocation.value == null || destinationLocation.value == null) {
      return;
    }
    try {
      final routeInfo = await RouteService.getRouteInfo(
        pickupLocation.value!,
        destinationLocation.value!,
      );
      currentRoutePoints.assignAll(routeInfo.points);
      currentRouteIndex.value = 0;
      polylines.clear();
      polylines.add(
        Polyline(
          polylineId: const PolylineId('route'),
          points: routeInfo.points,
          color: TColors.primary,
          width: 5,
        ),
      );
      fitMapToMarkers();
      update();
    } catch (e) {
      final fallbackRoute = [pickupLocation.value!, destinationLocation.value!];
      polylines.clear();
      polylines.add(
        Polyline(
          polylineId: const PolylineId('route'),
          points: fallbackRoute,
          color: TColors.primary.withOpacity(0.5),
          width: 5,
          patterns: [PatternItem.dash(15), PatternItem.gap(10)],
        ),
      );
      fitMapToMarkers();
      update();
    }
  }

  void fitMapToMarkers() {
    if (mapController == null) return;
    List<LatLng> pointsToFit = [];
    if (pickupLocation.value != null) pointsToFit.add(pickupLocation.value!);
    if (destinationLocation.value != null) {
      pointsToFit.add(destinationLocation.value!);
    }
    if (assignedDriver.value != null) {
      pointsToFit.add(assignedDriver.value!.location);
    }

    if (pointsToFit.length == 1) {
      mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(pointsToFit.first, 15.0),
      );
    } else if (pointsToFit.length > 1) {
      LatLngBounds bounds = LatLngBounds(
        southwest: LatLng(
          pointsToFit.map((p) => p.latitude).reduce(math.min),
          pointsToFit.map((p) => p.longitude).reduce(math.min),
        ),
        northeast: LatLng(
          pointsToFit.map((p) => p.latitude).reduce(math.max),
          pointsToFit.map((p) => p.longitude).reduce(math.max),
        ),
      );
      Future.delayed(const Duration(milliseconds: 100), () {
        mapController?.animateCamera(CameraUpdate.newLatLngBounds(bounds, 80));
      });
    }
  }

  Future<void> searchDestination(String query) async {
    if (query.length < 3) {
      destinationSuggestions.clear();
      showDestinationSuggestions.value = false;
      return;
    }
    try {
      final suggestions = await PlacesService.getPlaceSuggestions(
        query,
        location: pickupLocation.value,
      );
      destinationSuggestions.assignAll(suggestions);
      showDestinationSuggestions.value = suggestions.isNotEmpty;
    } catch (_) {
      destinationSuggestions.clear();
      showDestinationSuggestions.value = false;
    }
  }

  Future<void> selectDestination(PlaceSuggestion suggestion) async {
    destinationController.text = suggestion.mainText;
    destinationSuggestions.clear();
    showDestinationSuggestions.value = false;
    Get.focusScope?.unfocus();

    try {
      final placeDetails = await PlacesService.getPlaceDetails(
        suggestion.placeId,
      );
      if (placeDetails != null) {
        destinationLocation.value = placeDetails.location;
        destinationName.value = placeDetails.name.isNotEmpty
            ? placeDetails.name
            : suggestion.mainText;
        destinationAddress.value = placeDetails.formattedAddress;
        destinationController.text = destinationName.value;

        bool pricesFetched = await updatePricesFromApi();
        if (pricesFetched) {
          addDestinationMarker();
          stops.removeWhere((s) => s.type == StopType.destination);
          stops.add(
            StopPoint(
              id: 'destination',
              type: StopType.destination,
              location: placeDetails.location,
              name: destinationName.value,
              address: destinationAddress.value,
              isEditable: true,
            ),
          );
          currentState.value = BookingState.selectRide;
          _ensureMapFitsRoute();
          animatePanelTo80Percent();
        }
      }
    } catch (e) {
      THelperFunctions.showErrorSnackBar(
        'Error',
        'Error selecting destination.',
      );
    }
  }

  Future<void> selectDeliverySuggestion(
    PlaceSuggestion suggestion,
    TextEditingController controller,
  ) async {
    controller.text = suggestion.mainText;
    destinationSuggestions.clear();
    showDestinationSuggestions.value = false;
    Get.focusScope?.unfocus();

    try {
      final placeDetails = await PlacesService.getPlaceDetails(
        suggestion.placeId,
      );
      if (placeDetails != null) {
        destinationLocation.value = placeDetails.location;
        destinationName.value = placeDetails.name.isNotEmpty
            ? placeDetails.name
            : suggestion.mainText;
        destinationAddress.value = placeDetails.formattedAddress;
        controller.text = destinationName.value;

        stops.removeWhere((s) => s.type == StopType.destination);
        stops.add(
          StopPoint(
            id: 'destination',
            type: StopType.destination,
            location: placeDetails.location,
            name: destinationName.value,
            address: destinationAddress.value,
            isEditable: true,
          ),
        );

        addDestinationMarker();
        await recalculateRoute();
        updatePricing();
        update();
      }
    } catch (e) {
      THelperFunctions.showErrorSnackBar(
        'Error',
        'Error selecting delivery destination.',
      );
    }
  }

  Future<bool> updatePricesFromApi() async {
    if (pickupLocation.value == null || destinationLocation.value == null) {
      return false;
    }
    THelperFunctions.showSnackBar('Calculating fares...');

    try {
      final priceResponse = await _rideService.calculatePrice(
        pickupLocation.value!,
        destinationLocation.value!,
      );
      if (priceResponse.status == 'success' && priceResponse.data != null) {
        final prices = priceResponse.data!.prices;
        final newRideTypes = <RideType>[];
        final estimatedEtaMinutes = (totalDuration.value / 60).round() + 5;

        if (prices.luxury != null) {
          newRideTypes.add(
            RideType(
              name: 'Luxury',
              price: prices.luxury!.price,
              eta: '${estimatedEtaMinutes + 2} min',
              icon: Icons.directions_car,
              seats: prices.luxury!.seats,
            ),
          );
        }
        if (prices.comfort != null) {
          newRideTypes.add(
            RideType(
              name: 'Comfort',
              price: prices.comfort!.price,
              eta: '$estimatedEtaMinutes min',
              icon: Icons.car_rental,
              seats: prices.comfort!.seats,
            ),
          );
        }
        if (prices.xl != null) {
          newRideTypes.add(
            RideType(
              name: 'XL',
              price: prices.xl!.price,
              eta: '${estimatedEtaMinutes + 5} min',
              icon: Icons.airport_shuttle,
              seats: prices.xl!.seats,
            ),
          );
        }

        if (newRideTypes.isEmpty) {
          rideTypes.assignAll(_defaultRideTypes);
          return false;
        }

        rideTypes.assignAll(newRideTypes);
        return true;
      } else {
        rideTypes.assignAll(_defaultRideTypes);
        return false;
      }
    } catch (e) {
      rideTypes.assignAll(_defaultRideTypes);
      return false;
    }
  }

  Future<void> selectDestinationFromRecent(
    Map<String, dynamic> destination,
  ) async {
    destinationLocation.value = destination['location'] as LatLng;
    destinationName.value = destination['name'] as String;
    destinationAddress.value = destination['address'] as String;
    destinationController.text = destinationName.value;

    bool pricesFetched = await updatePricesFromApi();
    if (pricesFetched) {
      addDestinationMarker();
      stops.removeWhere((s) => s.type == StopType.destination);
      stops.add(
        StopPoint(
          id: 'destination',
          type: StopType.destination,
          location: destinationLocation.value!,
          name: destinationName.value,
          address: destinationAddress.value,
          isEditable: true,
        ),
      );
      currentState.value = BookingState.selectRide;
      _ensureMapFitsRoute();
      animatePanelTo80Percent();
    }
  }

  void onBackPressed() {
    switch (currentState.value) {
      case BookingState.destinationSearch:
      case BookingState.packageBooking:
      case BookingState.freightBooking:
        currentState.value = BookingState.initial;
        showDestinationSuggestions.value = false;
        destinationSuggestions.clear();
        destinationController.clear();
        packageDeliveryController.clear();
        freightDeliveryController.clear();
        destinationLocation.value = null;
        polylines.clear();
        markers.removeWhere((m) => m.markerId.value == 'destination');
        rideTypes.assignAll(_defaultRideTypes);
        if (panelController.isPanelOpen) panelController.close();
        break;
      case BookingState.selectRide:
        if (rideTypes.any((rt) => _packageRideTypes.contains(rt))) {
          currentState.value = BookingState.packageBooking;
        } else if (rideTypes.any((rt) => _freightRideTypes.contains(rt))) {
          currentState.value = BookingState.freightBooking;
        } else {
          currentState.value = BookingState.destinationSearch;
        }
        selectedRideType.value = null;
        break;
      case BookingState.searchingDriver:
      case BookingState.driverAssigned:
      case BookingState.driverArrived:
        _showCancelRideConfirmationDialog();
        break;
      default:
        break;
    }
  }

  void showPickupLocationOptions() {
    if (Get.context != null) {
      PickupLocationModal.show(
        Get.context!,
        onLocationSelected: _onPickupLocationSelected,
        onCurrentLocationPressed: _onCurrentLocationPressed,
        onMapPickerPressed: _onMapPickerPressed,
      );
    }
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

  void _onPickupLocationSelected(PlaceSuggestion suggestion) async {
    try {
      final placeDetails = await PlacesService.getPlaceDetails(
        suggestion.placeId,
      );
      if (placeDetails != null) {
        pickupLocation.value = placeDetails.location;
        pickupName.value = placeDetails.name.isNotEmpty
            ? placeDetails.name
            : suggestion.mainText;
        pickupAddress.value = placeDetails.formattedAddress;
        pickupController.text = pickupName.value;

        if (placeDetails.state.isNotEmpty) {
          pickupState.value = _cleanStateName(placeDetails.state);
        } else {
          await _getAndSetStateFromLatLng(
            placeDetails.location,
            defaultState: "Lagos",
          );
        }

        if (stops.isNotEmpty && stops.first.type == StopType.pickup) {
          stops[0] = StopPoint(
            id: 'pickup',
            type: StopType.pickup,
            location: placeDetails.location,
            name: pickupName.value,
            address: pickupAddress.value,
            isEditable: false,
          );
        } else {
          initializeStops();
        }
        addPickupMarker();
        mapController?.animateCamera(
          CameraUpdate.newLatLngZoom(placeDetails.location, 15.0),
        );
        if (destinationLocation.value != null) {
          await recalculateRoute();
          updatePricing();
        }
        update();
      }
    } catch (e, stack) {
      AppLogger.error(
        'Error in onPickupLocationSelected',
        error: e,
        stackTrace: stack,
      );
    }
  }

  void _onCurrentLocationPressed() async => await refreshCurrentLocation();

  void _onMapPickerPressed() async {
    try {
      final result = await Get.to(
        () => MapPickerScreen(
          initialLocation: pickupLocation.value,
          title: 'Choose Pickup Location',
        ),
      );
      if (result != null && result is Map) {
        final selectedLocation = result['location'] as LatLng;
        pickupLocation.value = selectedLocation;
        pickupName.value = result['name'] as String;
        pickupAddress.value = result['formattedAddress'] as String;
        pickupController.text = pickupName.value;
        await _getAndSetStateFromLatLng(
          selectedLocation,
          defaultState: "Lagos",
        );

        if (stops.isNotEmpty && stops.first.type == StopType.pickup) {
          stops[0] = StopPoint(
            id: 'pickup',
            type: StopType.pickup,
            location: selectedLocation,
            name: pickupName.value,
            address: pickupAddress.value,
            isEditable: false,
          );
        } else {
          initializeStops();
        }
        addPickupMarker();
        mapController?.animateCamera(
          CameraUpdate.newLatLngZoom(selectedLocation, 15.0),
        );
        if (destinationLocation.value != null) {
          await recalculateRoute();
          updatePricing();
        }
        update();
      }
    } catch (e, stack) {
      AppLogger.error(
        'Error in map picker selection',
        error: e,
        stackTrace: stack,
      );
    }
  }

  final RxBool isBooking = false.obs;

  void selectRideType(RideType rideType) {
    selectedRideType.value = rideType;
    update();
  }

  void confirmRide() async {
    if (selectedRideType.value == null) {
      THelperFunctions.showSnackBar('Please select a ride type first.');
      return;
    }
    if (isBooking.value) return; // FIX: Prevent double clicks
    if (pickupLocation.value == null || destinationLocation.value == null) {
      THelperFunctions.showSnackBar('Pickup or destination is missing.');
      return;
    }

    String finalPickupName = pickupName.value;
    if (finalPickupName.toLowerCase() == "current location" &&
        pickupAddress.value.isNotEmpty) {
      finalPickupName = pickupAddress.value;
    }

    isBooking.value = true;
    currentState.value = BookingState.searchingDriver;
    panelController.close();

    try {
      final isPackageDelivery =
          _packageRideTypes.any((rt) => rt.name == selectedRideType.value!.name);

      if (isPackageDelivery) {
        final packageDeliveryController =
            Get.find<PackageDeliveryController>();
        if (!packageDeliveryController.validateOrShowErrors()) {
          currentState.value = BookingState.selectRide;
          if (!panelController.isPanelOpen) panelController.open();
          return;
        }

        if (pickupLocation.value == null || destinationLocation.value == null) {
          THelperFunctions.showSnackBar('Pickup or destination is missing.');
          currentState.value = BookingState.selectRide;
          if (!panelController.isPanelOpen) panelController.open();
          return;
        }

        final packageRequest = packageDeliveryController.buildBookPackageRequest(
          currentLocationName: pickupName.value,
          destinationName: destinationName.value,
          currentLocation: pickupLocation.value!,
          destination: destinationLocation.value!,
          state: pickupState.value,
          selectedRideType: selectedRideType.value!,
        );

        final response = await PackageDeliveryService.instance
            .bookPackageDelivery(packageRequest);

        if (response.status == 'success' && response.tripId != null) {
          rideId.value = response.tripId!;
          _storage.write('active_ride_id', rideId.value);
          _storage.write('active_ride_mode', 'package_delivery');

          final price = response.price ?? selectedRideType.value!.price;
          selectedRideType.value = RideType(
            name: selectedRideType.value!.name,
            price: price.toInt(),
            eta: selectedRideType.value!.eta,
            icon: selectedRideType.value!.icon,
            seats: selectedRideType.value!.seats,
          );

          pickupName.value = pickupName.value;
          pickupController.text = pickupName.value;

          THelperFunctions.showSnackBar('Finding your driver...');
          return;
        }

        THelperFunctions.showErrorSnackBar(
          'Booking Failed',
          response.message,
        );
        currentState.value = BookingState.selectRide;
        if (!panelController.isPanelOpen) panelController.open();
        return;
      }

      final response = await _rideService.bookRide(
        pickupName: finalPickupName,
        destinationName: destinationName.value,
        pickupCoords: pickupLocation.value!,
        destinationCoords: destinationLocation.value!,
        category: selectedRideType.value!.name,
        state: pickupState.value,
      );

      if (response.status == 'success' && response.data != null) {
        rideId.value = response.data!.rideId;
        _storage.write('active_ride_id', rideId.value);

        selectedRideType.value = RideType(
          name: selectedRideType.value!.name,
          price: response.data!.price,
          eta: selectedRideType.value!.eta,
          icon: selectedRideType.value!.icon,
          seats: selectedRideType.value!.seats,
        );
        pickupName.value = finalPickupName;
        pickupController.text = finalPickupName;
        THelperFunctions.showSnackBar('Finding your driver...');
      } else {
        if (response.message.toLowerCase().contains('no available drivers')) {
          Get.bottomSheet(
            NoDriversAvailableWidget(
              message: response.message,
              onSearchAgain: () {
                Get.back();
                currentState.value = BookingState.selectRide;
                if (!panelController.isPanelOpen) panelController.open();
              },
            ),
            backgroundColor: Colors.transparent,
            isScrollControlled: true,
          );
        } else {
          THelperFunctions.showErrorSnackBar(
            'Booking Failed',
            response.message,
          );
          currentState.value = BookingState.selectRide;
          if (!panelController.isPanelOpen) panelController.open();
        }
      }
    } catch (e) {
      // FIX: Explicitly close any stranded dialogs
      if (Get.isDialogOpen!) Get.back();
      // FIX: Ensure snackbars aren't stuck loading
      THelperFunctions.showErrorSnackBar(
        'Error',
        'Failed to connect to server.',
      );
      currentState.value = BookingState.selectRide;
      if (!panelController.isPanelOpen) panelController.open();
    } finally {
      isBooking.value = false;
    }
  }

  // --- RESTORE RIDE STATE ---
  // --- REPLACE restoreRideState WITH THIS ---
  Future<void> restoreRideState(RiderReconnectData rideData) async {
    rideId.value = rideData.tripId;
    activeRideChatId.value = rideData.chatId ?? '';

    selectedRideType.value = RideType(
      name: rideData.category,
      price: rideData.price.toInt(),
      eta: '...',
      icon: _getIconForCategory(rideData.category),
      seats: rideData.seats,
    );

    // Locations
    LatLng? startCoords;
    LatLng? endCoords;

    if (rideData.pickup.toLowerCase().contains('current location')) {
      await _locationService.refreshLocation();
      final pos = _locationService.getLocationForMap();
      startCoords = LatLng(pos.latitude, pos.longitude);
      pickupName.value = "Current Location";
    } else {
      pickupName.value = rideData.pickup;
      final pSuggestions = await PlacesService.getPlaceSuggestions(
        rideData.pickup,
      );
      if (pSuggestions.isNotEmpty) {
        final pDetails = await PlacesService.getPlaceDetails(
          pSuggestions.first.placeId,
        );
        startCoords = pDetails?.location;
        if (pDetails != null) pickupAddress.value = pDetails.formattedAddress;
      }
    }
    pickupController.text = pickupName.value;

    destinationName.value = rideData.destination;
    destinationController.text = rideData.destination;
    final dSuggestions = await PlacesService.getPlaceSuggestions(
      rideData.destination,
    );
    if (dSuggestions.isNotEmpty) {
      final dDetails = await PlacesService.getPlaceDetails(
        dSuggestions.first.placeId,
      );
      endCoords = dDetails?.location;
      if (dDetails != null) {
        destinationAddress.value = dDetails.formattedAddress;
      }
    }

    if (startCoords != null && endCoords != null) {
      pickupLocation.value = startCoords;
      destinationLocation.value = endCoords;
      initializeStops();
      stops.add(
        StopPoint(
          id: 'destination',
          type: StopType.destination,
          location: endCoords,
          name: destinationName.value,
          address: destinationAddress.value,
          isEditable: true,
        ),
      );
      addPickupMarker();
      addDestinationMarker();
      await drawRoute();
      _ensureMapFitsRoute();
    }

    if (rideData.driver != null) {
      final d = rideData.driver!;
      assignedDriver.value = Driver(
        id: d.id,
        name: d.firstName,
        rating: 4.9,
        carModel: '${d.vehicleDetails.make} ${d.vehicleDetails.model}',
        plateNumber: d.vehicleDetails.licensePlate,
        phoneNumber: d.phoneNumber ?? '',
        eta: '...',
        location: pickupLocation.value ?? const LatLng(0, 0),
      );
      addDriverMarker();
    }

    switch (rideData.status.toLowerCase()) {
      case 'booked':
      case 'accepted':
        currentState.value = BookingState.driverAssigned;
        break;
      case 'arrived':
        currentState.value = BookingState.driverArrived;
        break;
      case 'on-trip':
      case 'in_progress':
        currentState.value = BookingState.tripInProgress;
        startTripAnimation();
        break;
      case 'completed':
        currentState.value = BookingState.tripCompleted;
        final paymentStatus = rideData.paymentStatus?.toLowerCase();
        // Default to "pending" if the backend didn't provide paymentStatus.
        isPaymentCompleted.value = paymentStatus == 'completed' ||
            paymentStatus == 'paid';
        break;
      case 'pending':
        currentState.value = BookingState.searchingDriver;
        break;
      default:
        _storage.remove('active_ride_id');
        _resetUIState();
    }
    update();
  }

  IconData _getIconForCategory(String category) {
    final lower = category.toLowerCase();
    if (lower.contains('van')) return Icons.local_shipping;
    if (lower.contains('bike') || lower.contains('courier')) return Icons.directions_bike;
    if (lower.contains('delivery')) return Icons.local_post_office;
    if (lower.contains('xl')) return Icons.airport_shuttle;
    if (lower.contains('comfort')) return Icons.car_rental;
    return Icons.directions_car;
  }

  void finishRide() => _resetUIState();

  // --- UPDATED: Use Service Icons for Driver ---
  void addDriverMarker({double rotation = 0.0}) {
    if (assignedDriver.value != null) {
      markers.removeWhere((marker) => marker.markerId.value == 'driver');
      markers.add(
        Marker(
          markerId: const MarkerId('driver'),
          position: assignedDriver.value!.location,
          icon:
              _markerService.driverIcon ??
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
          anchor: const Offset(0.5, 0.5),
          rotation: rotation,
          flat: true,
          zIndex: 2,
          infoWindow: InfoWindow(
            title: '🚗 ${assignedDriver.value!.name}',
            snippet:
                '${assignedDriver.value!.carModel} • ${assignedDriver.value!.plateNumber}',
          ),
        ),
      );
      markers.refresh();
      update();
    }
  }

  void updateDriverMarker({
    required LatLng newPosition,
    double rotation = 0.0,
  }) {
    if (assignedDriver.value != null) {
      final markerIndex = markers.indexWhere(
        (m) => m.markerId.value == 'driver',
      );
      if (markerIndex != -1) {
        markers[markerIndex] = markers[markerIndex].copyWith(
          positionParam: newPosition,
          rotationParam: rotation,
          iconParam:
              _markerService.driverIcon ??
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        );
      } else {
        addDriverMarker(rotation: rotation);
      }
      markers.refresh();
      update();
    }
  }

  void cancelRide() {
    if (rideId.value.isEmpty) {
      _resetUIState();
      return;
    }
    _showCancelRideConfirmationDialog();
  }

  void _showCancelRideConfirmationDialog() {
    Get.dialog(
      AlertDialog(
        title: const Text('Cancel Ride'),
        content: const Text(
          'Are you sure you want to cancel this ride? Cancellation fees may apply.',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Keep Ride'),
          ),
          TextButton(
            onPressed: () async {
              Get.back();
              THelperFunctions.showSnackBar('Cancelling ride...');
              final isPackageDelivery =
                  _storage.read('active_ride_mode') == 'package_delivery';
              bool success;
              if (isPackageDelivery) {
                success = await PackageDeliveryService.instance
                    .cancelPackageDelivery(rideId.value);
              } else {
                success = await _rideService.cancelRide(rideId.value);
              }
              if (!success) {
                THelperFunctions.showErrorSnackBar(
                  'Error',
                  'Failed to cancel ride.',
                );
              }
            },
            child: const Text(
              'Yes, Cancel',
              style: TextStyle(color: TColors.error),
            ),
          ),
        ],
      ),
      barrierDismissible: false,
    );
  }

  void _resetUIState() {
    currentState.value = BookingState.initial;
    selectedRideType.value = null;
    assignedDriver.value = null;
    destinationLocation.value = null;
    destinationName.value = '';
    destinationAddress.value = '';
    destinationController.clear();
    packageDeliveryController.clear();
    freightDeliveryController.clear();
    isPaymentCompleted.value = false;
    activeRideChatId.value = '';
    rideId.value = '';
    _storage.remove('active_ride_id');
    _storage.remove('active_ride_mode');

    // Clear persisted payment-pending restoration state.
    _storage.remove('rider_waiting_for_payment');
    _storage.remove('rider_waiting_trip_id');
    _storage.remove('rider_waiting_category');
    _storage.remove('rider_waiting_fare');
    _storage.remove('rider_waiting_eta');
    _storage.remove('rider_waiting_seats');

    markers.removeWhere(
      (m) => m.markerId.value == 'destination' || m.markerId.value == 'driver',
    );
    polylines.clear();
    currentRoutePoints.clear();
    currentRouteIndex.value = 0;
    rideTypes.assignAll(_defaultRideTypes);
    driverLocationTimer?.cancel();
    _previousDriverLocation = null;
    _refreshPickupMarker();
    if (panelController.isPanelOpen) {
      panelController.animatePanelToPosition(
        0.5,
        duration: const Duration(milliseconds: 300),
      );
    }

    // Clear package form state (rider package booking flow).
    if (Get.isRegistered<PackageDeliveryController>()) {
      Get.find<PackageDeliveryController>().clearPackageForm();
    }
    update();
  }

  void _refreshPickupMarker() {
    addPickupMarker();
    if (mapController != null && pickupLocation.value != null) {
      mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(pickupLocation.value!, 16.0),
      );
    }
  }

  void onPaymentSuccess() {
    isPaymentCompleted.value = true;

    // Payment completed; stop forcing the payment-pending UI restoration.
    _storage.remove('rider_waiting_for_payment');
    _storage.remove('rider_waiting_trip_id');
    _storage.remove('rider_waiting_category');
    _storage.remove('rider_waiting_fare');
    _storage.remove('rider_waiting_eta');
    _storage.remove('rider_waiting_seats');
    update();
  }

  void completePayment() => onPaymentSuccess();

  double calculateDistanceToDestination(LatLng destination) {
    if (pickupLocation.value == null) return 0.0;
    return calculateDistance(pickupLocation.value!, destination);
  }

  void startTripAnimation() {
    print("Trip animation started.");
    driverLocationTimer?.cancel();
  }

  void goToDestinationSearch() {
    currentState.value = BookingState.destinationSearch;
    rideTypes.assignAll(_defaultRideTypes);
    animatePanelTo80Percent();
  }

  void goToPackageBooking() {
    currentState.value = BookingState.packageBooking;
    rideTypes.assignAll(_packageRideTypes);
    animatePanelTo80Percent();
  }

  void goToFreightBooking() {
    currentState.value = BookingState.freightBooking;
    rideTypes.assignAll(_freightRideTypes);
    animatePanelTo80Percent();
  }

  void continueToRideSelection() async {
    selectedRideType.value = null;
    if (rideTypes.isEmpty || rideTypes.first.price == 0) {
      bool pricesFetched = await updatePricesFromApi();
      if (!pricesFetched) return;
    }
    currentState.value = BookingState.selectRide;
    showDestinationSuggestions.value = false;
    destinationSuggestions.clear();
    animatePanelTo80Percent();
    _ensureMapFitsRoute();
  }

  void continueWithPackageTypes() {
    rideTypes.assignAll(_packageRideTypes);
    continueToRideSelection();
  }

  void continueWithFreightTypes() {
    rideTypes.assignAll(_freightRideTypes);
    continueToRideSelection();
  }

  void handleEmergency() {
    final currentTripId = rideId.value.isNotEmpty ? rideId.value : null;
    Get.to(() => EmergencyReportingScreen(tripId: currentTripId));
  }

  void _ensureMapFitsRoute() {
    Future.delayed(const Duration(milliseconds: 300), () => fitMapToMarkers());
  }

  void animatePanelTo80Percent() {
    panelController.animatePanelToPosition(
      0.8,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void handleRideSearching(Map<String, dynamic> data) {
    if (currentState.value != BookingState.searchingDriver) return;
    final String driverName = data['driverName'] ?? 'a nearby driver';
    final int eta = (data['estimatedArrival'] as num?)?.toInt() ?? 5;
    if (data['status'] == 'pending') {
      searchingStatusText.value = "We're pinging a potential driver...";
      potentialDriverInfo.value = "$driverName is $eta minutes away";
    }
    update();
  }

  void handleRideAccepted(Driver driverDetails, String chatId) {
    if (currentState.value == BookingState.searchingDriver) {
      searchingStatusText.value = "Finding your driver...";
      potentialDriverInfo.value = "";
      assignedDriver.value = driverDetails;
      activeRideChatId.value = chatId;
      _storage.write('active_ride_id', rideId.value);
      currentState.value = BookingState.driverAssigned;
      _previousDriverLocation = driverDetails.location;
      addDriverMarker();
      THelperFunctions.showSuccessSnackBar(
        'Success',
        'Driver Found! ${driverDetails.name} is on the way!',
      );
      panelController.open();
      _ensureMapFitsRoute();
      update();
    }
  }

  void handleRideRejected(String message) {
    if (currentState.value == BookingState.searchingDriver) {
      THelperFunctions.showSnackBar(message);
    }
  }

  void handleCancellationConfirmed(String message) {
    THelperFunctions.showSnackBar(message);
    _resetUIState();
  }

  void handleRideStarted(Map<String, dynamic> data) {
    if (currentState.value != BookingState.driverArrived &&
        currentState.value != BookingState.driverAssigned) {
      return;
    }
    if (data['startedAt'] != null) {
      actualTripStartTime.value = DateTime.tryParse(
        data['startedAt'].toString(),
      );
    }
    actualTripStartTime.value ??= DateTime.now();
    currentState.value = BookingState.tripInProgress;
    startTripAnimation();
    update();
    THelperFunctions.showSuccessSnackBar('Success', 'Your trip has started!');
  }

  void updateDriverLocationOnMap(LatLng newLocation) {
    if (assignedDriver.value == null) return;

    // 1. Calculate Bearing (Rotation)
    double newBearing = 0.0;
    LatLng startLocation = assignedDriver.value!.location;

    // Use previous location for bearing if available
    if (_previousDriverLocation != null) {
      // Only update bearing if the car actually moved distance > 0
      if (calculateDistance(startLocation, newLocation) > 0.001) {
        newBearing = _calculateBearing(startLocation, newLocation);
      } else {
        newBearing = _previousDriverLocation != null
            ? _calculateBearing(_previousDriverLocation!, startLocation)
            : 0.0;
      }
    }

    // 2. Setup Animation Values
    _animStartLocation = startLocation;
    _animEndLocation = newLocation;

    // Get current marker rotation if possible, or use 0
    final currentMarker = markers.firstWhereOrNull(
      (m) => m.markerId.value == 'driver',
    );
    _animStartRotation = currentMarker?.rotation ?? 0.0;
    _animEndRotation = newBearing;

    // 3. Update the Data Model immediately (so the app logic knows where the driver IS)
    assignedDriver.value = assignedDriver.value!.copyWith(
      location: newLocation,
    );
    _previousDriverLocation = newLocation;

    // 4. Start the Animation (Visuals catch up to the Data)
    driverAnimationController.forward(from: 0.0);

    // 5. Arrival Logic (Keep your existing check)
    if (currentState.value == BookingState.driverAssigned &&
        pickupLocation.value != null) {
      if (calculateDistance(newLocation, pickupLocation.value!) < 0.1) {
        currentState.value = BookingState.driverArrived;
        driverLocationTimer?.cancel();
        THelperFunctions.showSuccessSnackBar(
          'Driver Arrived',
          'Your driver has arrived!',
        );
      }
    }
  }

  void handleRideCompleted(Map<String, dynamic> data) {
    final finalFare =
        (data['finalPrice'] as num?)?.toDouble() ??
        selectedRideType.value?.price.toDouble() ??
        0.0;
    final paymentStatusRaw = data['paymentStatus'] as String? ?? 'pending';
    final paymentStatus = paymentStatusRaw.toLowerCase();
    if (currentState.value == BookingState.tripInProgress ||
        currentState.value == BookingState.driverArrived ||
        currentState.value == BookingState.driverAssigned) {
      if (selectedRideType.value != null &&
          selectedRideType.value!.price != finalFare.toInt()) {
        selectedRideType.value = RideType(
          name: selectedRideType.value!.name,
          price: finalFare.toInt(),
          eta: selectedRideType.value!.eta,
          icon: selectedRideType.value!.icon,
          seats: selectedRideType.value!.seats,
        );
      }
      driverLocationTimer?.cancel();
      currentState.value = BookingState.tripCompleted;

      // Backend uses: pending, pending_confirmation, paid.
      final isPaid = paymentStatus == 'paid' || paymentStatus == 'completed';
      final isPending = paymentStatus == 'pending' ||
          paymentStatus == 'pending_confirmation';
      isPaymentCompleted.value = isPaid;

      // Persist payment-pending state so we can restore the payment UI after
      // restart when backend reconnect rejects `status=completed`.
      if (isPending && rideId.value.isNotEmpty) {
        _storage.write('rider_waiting_for_payment', true);
        _storage.write('rider_waiting_trip_id', rideId.value);
        _storage.write('rider_waiting_category',
            selectedRideType.value?.name ?? rideId.value);
        _storage.write('rider_waiting_fare', finalFare.toInt());
        _storage.write('rider_waiting_eta', selectedRideType.value?.eta ?? '...');
        _storage.write('rider_waiting_seats', selectedRideType.value?.seats ?? 4);
      }

      THelperFunctions.showSuccessSnackBar(
        'Trip Completed',
        'You have arrived at your destination!',
      );
      panelController.open();
      update();
    }
  }

  /// Backend emits `package:delivered` when delivery is confirmed.
  /// At that moment the package payment is not yet completed, so we send
  /// the rider to the payment UI (same UI as ride completion).
  void handlePackageDelivered(Map<String, dynamic> data) {
    final tripId = data['tripId']?.toString() ?? '';
    if (tripId.isEmpty) return;

    rideId.value = tripId;
    _storage.write('active_ride_mode', 'package_delivery');
    currentState.value = BookingState.tripCompleted;
    isPaymentCompleted.value = false;

    // Persist so we can restore this UI after app restart.
    _storage.write('rider_waiting_for_payment', true);
    _storage.write('rider_waiting_trip_id', tripId);
    _storage.write(
      'rider_waiting_category',
      selectedRideType.value?.name ?? 'Car Delivery',
    );
    _storage.write(
      'rider_waiting_fare',
      (selectedRideType.value?.price ?? 0).toInt(),
    );
    _storage.write(
      'rider_waiting_eta',
      selectedRideType.value?.eta ?? '...',
    );
    _storage.write(
      'rider_waiting_seats',
      selectedRideType.value?.seats ?? 4,
    );

    panelController.open();
    update();
  }

  void handlePackageArrived(Map<String, dynamic> data) {
    if (data['tripId'] == rideId.value) {
      currentState.value = BookingState.driverArrived; // Or a specific 'arrivedAtDropoff' if we had one
      THelperFunctions.showSuccessSnackBar(
        'Arrived',
        'Your package has arrived at the destination.',
      );
      update();
    }
  }

  void handlePackagePickedUp(Map<String, dynamic> data) {
    if (data['tripId'] == rideId.value) {
      currentState.value = BookingState.tripInProgress;
      THelperFunctions.showSuccessSnackBar(
        'Picked Up',
        'Your package has been picked up by the driver.',
      );
      update();
    }
  }

  void handlePackageDisputed(Map<String, dynamic> data) {
    if (data['tripId'] == rideId.value) {
      THelperFunctions.showWarningSnackBar(
        'Dispute Opened',
        data['reason'] ?? 'A dispute has been raised for this delivery.',
      );
      update();
    }
  }

  void handleDisputeResolved(Map<String, dynamic> data) {
    if (data['tripId'] == rideId.value) {
      final res = data['resolution'] == 'resolved' ? 'Settled' : 'Rejected';
      THelperFunctions.showSuccessSnackBar(
        'Dispute Resolved',
        'The dispute has been $res. ${data['adminNote'] ?? ''}',
      );
      update();
    }
  }

  void handleTransferCompleted(Map<String, dynamic> data) {
    if (data['tripId'] == rideId.value) {
      isPaymentCompleted.value = true;
      _storage.write('rider_waiting_for_payment', false);
      THelperFunctions.showSuccessSnackBar(
        'Payment Success',
        'Bank transfer confirmed.',
      );
      update();
    }
  }

  double calculateDistance(LatLng point1, LatLng point2) {
    const double R = 6371e3;
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
    return (R * c) / 1000.0;
  }

  // Standard Linear Interpolation
  double _lerp(double start, double end, double t) {
    return start + (end - start) * t;
  }

  // Smart Rotation Interpolation (Takes the shortest path)
  double _lerpRotation(double start, double end, double t) {
    double difference = (end - start).abs();
    if (difference > 180) {
      // If the difference is > 180, it's shorter to go the other way around the circle
      if (end > start) {
        start += 360;
      } else {
        end += 360;
      }
    }
    double result = start + (end - start) * t;
    return result % 360;
  }

  // Updates ONLY the marker icon, keeping the map smooth
  void _updateDriverMarkerVisualsOnly(LatLng pos, double rot) {
    final markerIndex = markers.indexWhere((m) => m.markerId.value == 'driver');
    if (markerIndex != -1) {
      // Use the copyWith pattern to be efficient
      markers[markerIndex] = markers[markerIndex].copyWith(
        positionParam: pos,
        rotationParam: rot,
      );
      // We use simple update() because markers is an RxList
      // This triggers the GoogleMap widget to redraw the markers
      markers.refresh();
    }
  }
}

// --- Helper Classes (StopPoint, RouteSegment) ---
enum StopType { pickup, intermediate, destination }

class StopPoint {
  final String id;
  final StopType type;
  final LatLng location;
  final String name;
  final String address;
  final bool isEditable;
  StopPoint({
    required this.id,
    required this.type,
    required this.location,
    required this.name,
    required this.address,
    required this.isEditable,
  });
}

class RouteSegment {
  final StopPoint from;
  final StopPoint to;
  final List<LatLng> points;
  final int distance;
  final int duration;
  RouteSegment({
    required this.from,
    required this.to,
    required this.points,
    required this.distance,
    required this.duration,
  });
}
