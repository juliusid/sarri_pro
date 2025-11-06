// lib/features/ride/controllers/ride_controller.dart

import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:sarri_ride/core/services/http_service.dart';
import 'package:sarri_ride/features/ride/models/ride_model.dart';
import 'package:sarri_ride/features/ride/services/ride_service.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';
import 'package:get_storage/get_storage.dart';

import 'package:sarri_ride/features/location/services/location_service.dart';
import 'package:sarri_ride/features/location/services/places_service.dart';
import 'package:sarri_ride/features/location/services/route_service.dart';
import 'package:sarri_ride/features/ride/widgets/driver_info_card.dart';
import 'package:sarri_ride/features/ride/widgets/ride_selection_widget.dart';
import 'package:sarri_ride/features/ride/widgets/map_picker_screen.dart';
import 'package:sarri_ride/utils/constants/enums.dart';
import 'package:sarri_ride/utils/constants/colors.dart';
import 'package:sarri_ride/utils/helpers/helper_functions.dart';
import 'package:sarri_ride/features/ride/widgets/pickup_location_modal.dart';
import 'package:sarri_ride/features/settings/models/saved_place.dart';

// --- ADDED IMPORT ---
import 'package:sarri_ride/features/ride/widgets/no_drivers_available_widget.dart';
// --- END ADDED IMPORT ---

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

class RideController extends GetxController with GetTickerProviderStateMixin {
  static RideController get instance => Get.find();

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

  // Reactive state variables
  final Rx<BookingState> currentState = BookingState.initial.obs;
  final Rx<LatLng?> pickupLocation = Rx<LatLng?>(null);
  final Rx<LatLng?> destinationLocation = Rx<LatLng?>(null);
  final RxString pickupState = 'Lagos'.obs;

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
  final RxBool isPaymentCompleted = false.obs;
  final RxList<RideType> rideTypes = <RideType>[].obs;

  // Location service
  final LocationService _locationService = LocationService.instance;

  final RideService _rideService = RideService.instance;
  final RxString rideId = ''.obs;
  final RxString activeRideChatId = ''.obs;

  BitmapDescriptor? driverIcon;
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

  // Mock recent destinations
  final List<Map<String, dynamic>> recentDestinations = [
    {
      'name': 'Victoria Island',
      'address': 'Victoria Island, Lagos',
      'location': const LatLng(6.4281, 3.4219),
      'icon': Icons.business,
    },
    {
      'name': 'Lekki Phase 1',
      'address': 'Lekki Phase 1, Lagos',
      'location': const LatLng(6.4474, 3.4647),
      'icon': Icons.home,
    },
    {
      'name': 'Ikeja GRA',
      'address': 'Ikeja GRA, Lagos',
      'location': const LatLng(6.5955, 3.3087),
      'icon': Icons.location_city,
    },
    {
      'name': 'Surulere',
      'address': 'Surulere, Lagos',
      'location': const LatLng(6.5027, 3.3641),
      'icon': Icons.store,
    },
  ];

  final _storage = GetStorage();

  @override
  void onInit() {
    super.onInit();
    rideTypes.assignAll(_defaultRideTypes);
    driverAnimationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    initializeMap();
    initializeStops();
    _loadCustomMarker();
  }

  /// Loads the custom driver icon from assets.
  Future<void> _loadCustomMarker() async {
    try {
      driverIcon = await BitmapDescriptor.fromAssetImage(
        const ImageConfiguration(size: Size(48, 48)),
        'assets/icons/car_marker.png',
      );
      print("Custom driver icon loaded successfully.");
    } catch (e) {
      print("Error loading custom driver marker: $e");
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
    bearing = bearing * 180 / math.pi;
    return (bearing + 360) % 360;
  }

  @override
  void onClose() {
    driverAnimationController.dispose();
    driverLocationTimer?.cancel();
    destinationController.dispose();
    pickupController.dispose();
    packageDeliveryController.dispose();
    freightDeliveryController.dispose();
    super.onClose();
  }

  /// Initializes the map with the user's current or default location and fetches the state.
  void initializeMap() {
    final position = _locationService.getLocationForMap();
    final currentLatLng = LatLng(position.latitude, position.longitude);

    pickupLocation.value = currentLatLng;
    pickupName.value = _locationService.isLocationEnabled
        ? 'Current Location'
        : 'Default Location';
    pickupAddress.value = _locationService.isLocationEnabled
        ? 'Your current location'
        : 'Lagos, Nigeria (Default)';
    pickupController.text = pickupName.value;

    _getAndSetStateFromLatLng(currentLatLng, defaultState: "Lagos");

    addPickupMarker();
  }

  /// Helper to get State from LatLng
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
        pickupState.value = placeDetails.state;
        print("Pickup state dynamically set to: ${placeDetails.state}");
      } else if (defaultState.isNotEmpty) {
        pickupState.value = defaultState;
        print(
          "Could not find state from coordinates, using default: $defaultState",
        );
      } else {
        pickupState.value = '';
        print("Could not find state from coordinates.");
      }
    } catch (e) {
      print("Error getting state from latlng: $e");
      if (defaultState.isNotEmpty) {
        pickupState.value = defaultState;
        print("Using default state due to error: $defaultState");
      }
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
    } else {
      print("Warning: Pickup location is null during stop initialization.");
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
    if (pickupLocation.value != null) {
      markers.removeWhere((marker) => marker.markerId.value == 'pickup');
      markers.add(
        Marker(
          markerId: const MarkerId('pickup'),
          position: pickupLocation.value!,
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueGreen,
          ),
          infoWindow: InfoWindow(
            title: '📍 ${pickupName.value}',
            snippet: pickupAddress.value,
          ),
        ),
      );
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
    if (stops.length <= 2) {
      isMultiStop.value = false;
    }
    updateMapMarkers();
    recalculateRoute();
    updatePricing();
    THelperFunctions.showSnackBar('Stop removed');
  }

  void reorderStops(int oldIndex, int newIndex) {
    if (oldIndex < 1 || newIndex < 1) return;
    if (oldIndex >= stops.length || newIndex >= stops.length) return;
    if (newIndex > oldIndex) newIndex -= 1;
    final hasDestination = stops.last.type == StopType.destination;
    if (hasDestination && newIndex >= stops.length - 1) {
      newIndex = stops.length - 2;
    }
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
      } else {
        THelperFunctions.showErrorSnackBar(
          'Error',
          'Could not get details for the selected destination.',
        );
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
      print("Cannot calculate route: Less than 2 stops defined.");
      polylines.clear();
      currentRoutePoints.clear();
      totalDistance.value = 0.0;
      totalDuration.value = 0;
      updatePricing();
      return;
    }

    print("Recalculating route for ${stops.length} stops...");
    try {
      routeSegments.clear();
      polylines.clear();
      totalDistance.value = 0.0;
      totalDuration.value = 0;
      List<LatLng> allRoutePoints = [];

      for (int i = 0; i < stops.length - 1; i++) {
        final origin = stops[i].location;
        final destination = stops[i + 1].location;

        print(
          "Calculating segment $i: ${stops[i].name} -> ${stops[i + 1].name}",
        );
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
        print(
          "Segment $i: Distance=${routeInfo.distance}, Duration=${routeInfo.duration}",
        );
      }

      currentRoutePoints.assignAll(allRoutePoints);
      currentRouteIndex.value = 0;
      print(
        "Total Route: Distance=${(totalDistance.value / 1000).toStringAsFixed(1)}km, Duration=${(totalDuration.value / 60).round()}min",
      );

      if (currentState.value == BookingState.tripInProgress) {
        print("Restarting trip animation on recalculated route.");
        driverLocationTimer?.cancel();
        startTripAnimation();
      }

      fitMapToAllStops();
      update();
    } catch (e) {
      print('Error recalculating route: $e');
      THelperFunctions.showErrorSnackBar('Error', 'Error calculating route');
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
    print(
      "Updating pricing: Distance=${distanceKm.toStringAsFixed(1)}km, Duration=${durationMinutes.round()}min, Base Total=₦${totalPrice.value.round()}",
    );
    _updateRideTypesWithCalculatedPrice();
  }

  void _updateRideTypesWithCalculatedPrice() {
    List<RideType> updatedRideTypes = [];
    final currentTypes = currentState.value == BookingState.packageBooking
        ? _packageRideTypes
        : currentState.value == BookingState.freightBooking
        ? _freightRideTypes
        : _defaultRideTypes;

    final estimatedEtaMinutes = (totalDuration.value / 60).round() + 5;

    for (RideType baseType in currentTypes) {
      final multiplier = _getRideTypeMultiplier(baseType.name);
      final finalPrice = math
          .max(totalPrice.value * multiplier, 1000.0)
          .round();

      updatedRideTypes.add(
        RideType(
          name: baseType.name,
          price: finalPrice,
          eta: '$estimatedEtaMinutes min',
          icon: baseType.icon,
          seats: baseType.seats,
        ),
      );
      print("Updated Price for ${baseType.name}: ₦$finalPrice");
    }

    rideTypes.assignAll(updatedRideTypes);
    if (selectedRideType.value != null) {
      final updatedSelection = updatedRideTypes.firstWhereOrNull(
        (rt) => rt.name == selectedRideType.value!.name,
      );
      if (updatedSelection != null) {
        selectedRideType.value = updatedSelection;
      }
    }
    update();
  }

  double _getRideTypeMultiplier(String rideTypeName) {
    final nameLower = rideTypeName.toLowerCase();
    if (nameLower.contains('luxury')) return 1.5;
    if (nameLower.contains('comfort')) return 1.2;
    if (nameLower.contains('xl')) return 1.8;
    if (nameLower.contains('bike')) return 0.8;
    if (nameLower.contains('car delivery')) return 1.0;
    if (nameLower.contains('van')) return 1.4;
    if (nameLower.contains('small truck')) return 3.0;
    if (nameLower.contains('medium truck')) return 5.0;
    if (nameLower.contains('large truck')) return 8.0;
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
    double padding = 80.0;
    mapController!.animateCamera(CameraUpdate.newLatLngBounds(bounds, padding));
  }

  void updateMapMarkers() {
    print("Updating map markers for ${stops.length} stops...");
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
          onDragEnd: (newPosition) {
            print(
              "Marker ${stop.id} dragged to $newPosition. Update logic needed.",
            );
          },
        ),
      );
    }
    if (assignedDriver.value != null) {
      addDriverMarker();
    }
    print("Markers updated. Count: ${markers.length}");
    update();
  }

  BitmapDescriptor _getStopMarkerIcon(StopType type, int index) {
    switch (type) {
      case StopType.pickup:
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen);
      case StopType.destination:
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);
      case StopType.intermediate:
        final hues = [
          BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueCyan),
          BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueMagenta),
        ];
        return hues[(index - 1) % hues.length];
    }
  }

  String _getStopMarkerTitle(StopPoint stop, int index) {
    switch (stop.type) {
      case StopType.pickup:
        return '📍 Pickup: ${stop.name}';
      case StopType.destination:
        return '🎯 Destination: ${stop.name}';
      case StopType.intermediate:
        return '🛑 Stop ${index}: ${stop.name}';
    }
  }

  bool canModifyDuringRide() {
    return currentState.value == BookingState.tripInProgress &&
        stops.length < maxStops.value + 2;
  }

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

  /// Refresh current location
  Future<void> refreshCurrentLocation() async {
    print("Refreshing current location...");
    await _locationService.refreshLocation();
    final position = _locationService.getLocationForMap();
    final newLatLng = LatLng(position.latitude, position.longitude);

    pickupLocation.value = newLatLng;
    pickupName.value = 'Current Location';
    String address = 'Updated Location';
    try {
      address =
          await PlacesService.getAddressFromCoordinates(
            newLatLng.latitude,
            newLatLng.longitude,
          ) ??
          address;
    } catch (e) {
      print("Reverse geocoding failed on refresh: $e");
    }
    pickupAddress.value = address;
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

    THelperFunctions.showSuccessSnackBar(
      'Success',
      'Location updated successfully!',
    );
    update();
  }

  void addDestinationMarker() {
    print('Adding destination marker...');
    if (destinationLocation.value != null) {
      markers.removeWhere((marker) => marker.markerId.value == 'destination');
      final newMarker = Marker(
        markerId: const MarkerId('destination'),
        position: destinationLocation.value!,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        infoWindow: InfoWindow(
          title:
              '🎯 ${destinationName.value.isNotEmpty ? destinationName.value : "Destination"}',
          snippet: destinationAddress.value.isNotEmpty
              ? destinationAddress.value
              : 'Your selected destination',
        ),
      );
      markers.add(newMarker);
      print('Destination marker added at ${newMarker.position}');
      update();
      if (pickupLocation.value != null) {
        drawRoute();
      }
    } else {
      print('Cannot add destination marker: destinationLocation is null.');
      markers.removeWhere((marker) => marker.markerId.value == 'destination');
      update();
    }
  }

  Future<void> drawRoute() async {
    if (pickupLocation.value == null || destinationLocation.value == null) {
      print('Cannot draw route: Pickup or Destination is missing.');
      polylines.clear();
      currentRoutePoints.clear();
      update();
      return;
    }
    print(
      "Drawing route from ${pickupLocation.value} to ${destinationLocation.value}",
    );
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
      print("Route drawn successfully. Points: ${routeInfo.points.length}");
      fitMapToMarkers();
      update();
    } catch (e) {
      print('Error drawing route: $e');
      THelperFunctions.showSnackBar(
        'Could not calculate route. Using estimated path.',
      );
      final fallbackRoute = [pickupLocation.value!, destinationLocation.value!];
      currentRoutePoints.assignAll(fallbackRoute);
      currentRouteIndex.value = 0;
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
    if (destinationLocation.value != null)
      pointsToFit.add(destinationLocation.value!);
    if (assignedDriver.value != null)
      pointsToFit.add(assignedDriver.value!.location);

    if (pointsToFit.length == 1) {
      mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(pointsToFit.first, 15.0),
      );
    } else if (pointsToFit.length > 1) {
      double minLat = pointsToFit.map((p) => p.latitude).reduce(math.min);
      double maxLat = pointsToFit.map((p) => p.latitude).reduce(math.max);
      double minLng = pointsToFit.map((p) => p.longitude).reduce(math.min);
      double maxLng = pointsToFit.map((p) => p.longitude).reduce(math.max);

      LatLngBounds bounds = LatLngBounds(
        southwest: LatLng(minLat, minLng),
        northeast: LatLng(maxLat, maxLng),
      );

      double distanceKm = 0;
      if (pickupLocation.value != null && destinationLocation.value != null) {
        distanceKm = calculateDistanceToDestination(destinationLocation.value!);
      }
      double padding = distanceKm > 50
          ? 100.0
          : (distanceKm > 10 ? 80.0 : 60.0);

      Future.delayed(const Duration(milliseconds: 100), () {
        mapController?.animateCamera(
          CameraUpdate.newLatLngBounds(bounds, padding),
        );
      });
    }
  }

  Future<void> searchDestination(String query) async {
    if (query.length < 3) {
      destinationSuggestions.clear();
      showDestinationSuggestions.value = false;
      return;
    }
    print("Searching for destination: '$query'");
    try {
      final suggestions = await PlacesService.getPlaceSuggestions(
        query,
        location: pickupLocation.value,
      );
      destinationSuggestions.assignAll(suggestions);
      showDestinationSuggestions.value = suggestions.isNotEmpty;
      print("Found ${suggestions.length} suggestions.");
    } catch (e) {
      print('Error getting destination suggestions: $e');
      destinationSuggestions.clear();
      showDestinationSuggestions.value = false;
      THelperFunctions.showErrorSnackBar(
        'Network Error',
        'Unable to search locations. Check connection.',
      );
    }
  }

  Future<void> selectDestination(PlaceSuggestion suggestion) async {
    print("Selecting destination: ${suggestion.description}");
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

        print("Destination details fetched: ${placeDetails.location}");

        bool pricesFetched = await _updatePricesFromApi();
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
        } else {
          print("Price calculation failed. Staying on destination search.");
        }
      } else {
        THelperFunctions.showErrorSnackBar(
          'Error',
          'Could not get location details for ${suggestion.mainText}',
        );
        destinationController.text = '';
      }
    } catch (e) {
      THelperFunctions.showErrorSnackBar(
        'Error',
        'Error selecting destination: $e',
      );
      destinationController.text = '';
    }
  }

  Future<bool> _updatePricesFromApi() async {
    if (pickupLocation.value == null || destinationLocation.value == null) {
      print("Cannot update prices: Pickup or Destination is null.");
      return false;
    }

    print(
      "Fetching prices from ${pickupLocation.value} to ${destinationLocation.value}",
    );
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
          print("Luxury Price: ${prices.luxury!.price}");
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
          print("Comfort Price: ${prices.comfort!.price}");
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
          print("XL Price: ${prices.xl!.price}");
        }

        if (newRideTypes.isEmpty) {
          print(
            "Warning: Price API returned success but no ride categories found.",
          );
          THelperFunctions.showSnackBar(
            'No ride types available for this route.',
          );
          rideTypes.assignAll(_defaultRideTypes);
          return false;
        }

        rideTypes.assignAll(newRideTypes);
        print("Prices updated successfully.");
        return true;
      } else {
        if (!priceResponse.message.toLowerCase().contains('session expired') &&
            !priceResponse.message.toLowerCase().contains("unauthorized")) {
          THelperFunctions.showErrorSnackBar(
            'Error',
            priceResponse.message.isNotEmpty
                ? priceResponse.message
                : 'Failed to calculate fares.',
          );
        }
        print("Price calculation API failed: ${priceResponse.message}");
        rideTypes.assignAll(_defaultRideTypes);
        return false;
      }
    } catch (e) {
      print("Exception during price calculation: $e");
      THelperFunctions.showErrorSnackBar(
        'Error',
        'An error occurred while calculating fares.',
      );
      rideTypes.assignAll(_defaultRideTypes);
      return false;
    }
  }

  Future<void> selectDestinationFromRecent(
    Map<String, dynamic> destination,
  ) async {
    print("Selecting recent destination: ${destination['name']}");
    destinationLocation.value = destination['location'] as LatLng;
    destinationName.value = destination['name'] as String;
    destinationAddress.value = destination['address'] as String;
    destinationController.text = destinationName.value;

    bool pricesFetched = await _updatePricesFromApi();
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
    } else {
      print("Price fetch failed for recent destination.");
    }
  }

  void onBackPressed() {
    print("Back pressed. Current state: ${currentState.value}");
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

      case BookingState.tripInProgress:
      case BookingState.tripCompleted:
        print("Back press ignored in state: ${currentState.value}");
        break;

      case BookingState.initial:
      default:
        print("Back press in initial state.");
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
    } else {
      print("Error: Cannot show pickup options, context is null.");
    }
  }

  /// Handle location selection from autocomplete modal
  void _onPickupLocationSelected(PlaceSuggestion suggestion) async {
    print("Pickup selected from suggestions: ${suggestion.description}");
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

        // --- CLEANED: Get state directly from placeDetails ---
        if (placeDetails.state.isNotEmpty) {
          pickupState.value = placeDetails.state;
          print("Pickup state set to: ${placeDetails.state}");
        } else {
          await _getAndSetStateFromLatLng(
            placeDetails.location,
            defaultState: "Lagos",
          );
        }
        // --- END CLEANED ---

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

        THelperFunctions.showSuccessSnackBar(
          'Success',
          'Pickup location updated.',
        );
        update();
      } else {
        THelperFunctions.showErrorSnackBar(
          'Error',
          'Could not get location details.',
        );
      }
    } catch (e) {
      THelperFunctions.showErrorSnackBar(
        'Error',
        'Error updating pickup location: $e',
      );
    }
  }

  // Handle selection of 'Use current location' from modal
  void _onCurrentLocationPressed() async {
    print("Using current location for pickup.");
    await refreshCurrentLocation();
  }

  /// Handle selection of 'Choose on map' from modal
  void _onMapPickerPressed() async {
    print("Opening map picker for pickup location.");
    try {
      final result = await Get.to(
        () => MapPickerScreen(
          initialLocation: pickupLocation.value,
          title: 'Choose Pickup Location',
        ),
      );

      if (result != null && result is Map) {
        final selectedLocation = result['location'] as LatLng;
        final selectedName = result['name'] as String;
        final selectedAddress = result['formattedAddress'] as String;

        print("Pickup selected from map: $selectedName at $selectedLocation");

        pickupLocation.value = selectedLocation;
        pickupName.value = selectedName;
        pickupAddress.value = selectedAddress;
        pickupController.text = selectedName;

        // --- Use helper function to get state ---
        await _getAndSetStateFromLatLng(
          selectedLocation,
          defaultState: "Lagos",
        );

        if (stops.isNotEmpty && stops.first.type == StopType.pickup) {
          stops[0] = StopPoint(
            id: 'pickup',
            type: StopType.pickup,
            location: selectedLocation,
            name: selectedName,
            address: selectedAddress,
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

        THelperFunctions.showSuccessSnackBar(
          'Success',
          'Pickup location updated.',
        );
        update();
      } else {
        print("Map picker cancelled or returned null.");
      }
    } catch (e) {
      THelperFunctions.showErrorSnackBar(
        'Error',
        'Error selecting location from map: $e',
      );
    }
  }

  // /// Refresh current location
  // Future<void> refreshCurrentLocation() async {
  //   print("Refreshing current location...");
  //   await _locationService.refreshLocation();
  //   final position = _locationService.getLocationForMap();
  //   final newLatLng = LatLng(position.latitude, position.longitude);

  //   pickupLocation.value = newLatLng;
  //   pickupName.value = 'Current Location';
  //   String address = 'Updated Location';
  //   try {
  //     address =
  //         await PlacesService.getAddressFromCoordinates(
  //           newLatLng.latitude,
  //           newLatLng.longitude,
  //         ) ??
  //         address;
  //   } catch (e) {
  //     print("Reverse geocoding failed on refresh: $e");
  //   }
  //   pickupAddress.value = address;
  //   pickupController.text = pickupName.value;

  //   await _getAndSetStateFromLatLng(newLatLng, defaultState: "Lagos");

  //   if (stops.isNotEmpty && stops.first.type == StopType.pickup) {
  //     stops[0] = StopPoint(
  //       id: stops.first.id,
  //       type: StopType.pickup,
  //       location: newLatLng,
  //       name: pickupName.value,
  //       address: pickupAddress.value,
  //       isEditable: false,
  //     );
  //   } else {
  //     initializeStops();
  //   }

  //   addPickupMarker();
  //   mapController?.animateCamera(CameraUpdate.newLatLngZoom(newLatLng, 16.0));

  //   if (destinationLocation.value != null) {
  //     await recalculateRoute();
  //     updatePricing();
  //   }

  //   THelperFunctions.showSuccessSnackBar(
  //     'Success',
  //     'Location updated successfully!',
  //   );
  //   update();
  // }

  // Helper method to recalculate route
  void _calculateRoute() async {
    await recalculateRoute();
    updatePricing();
  }

  void _updateRideTypesWithRoute(RouteInfo routeInfo) {
    print(
      "Note: _updateRideTypesWithRoute is deprecated, logic moved to updatePricing.",
    );
  }

  void selectRideType(RideType rideType) {
    selectedRideType.value = rideType;
    update();
  }

  /// Confirm ride booking
  void confirmRide() async {
    if (selectedRideType.value == null) {
      THelperFunctions.showSnackBar('Please select a ride type first.');
      return;
    }
    if (pickupLocation.value == null || destinationLocation.value == null) {
      THelperFunctions.showSnackBar('Pickup or destination is missing.');
      return;
    }
    if (pickupState.value.isEmpty) {
      THelperFunctions.showSnackBar(
        'Could not determine your state. Please update pickup location.',
      );
      return;
    }

    print(
      "Confirming ride: ${selectedRideType.value!.name} in state: ${pickupState.value}",
    );
    currentState.value = BookingState.searchingDriver;
    panelController.close();

    try {
      final response = await _rideService.bookRide(
        pickupName: pickupName.value,
        destinationName: destinationName.value,
        pickupCoords: pickupLocation.value!,
        destinationCoords: destinationLocation.value!,
        category: selectedRideType.value!.name,
        state: pickupState.value,
      );

      if (response.status == 'success' && response.data != null) {
        rideId.value = response.data!.rideId;
        _storage.write('active_ride_id', rideId.value);
        print(
          "Ride booked successfully. Ride ID: ${rideId.value}, Price: ${response.data!.price}, Dist: ${response.data!.distanceKm}",
        );

        selectedRideType.value = RideType(
          name: selectedRideType.value!.name,
          price: response.data!.price,
          eta: selectedRideType.value!.eta,
          icon: selectedRideType.value!.icon,
          seats: selectedRideType.value!.seats,
        );

        THelperFunctions.showSnackBar('Finding your driver...');
      } else {
        print("Ride booking failed: ${response.message}");

        // --- MODIFICATION ---
        // Check for the specific "no drivers" message
        if (response.message.toLowerCase().contains('no available drivers')) {
          // Show the new custom bottom sheet
          Get.bottomSheet(
            NoDriversAvailableWidget(
              message: response.message,
              onSearchAgain: () {
                Get.back(); // Close the bottom sheet
                currentState.value =
                    BookingState.selectRide; // Go back to selection
                if (!panelController.isPanelOpen) panelController.open();
              },
            ),
            backgroundColor: Colors.transparent,
            isScrollControlled: true,
          );
        } else {
          // Show the generic error snackbar for other errors
          THelperFunctions.showErrorSnackBar(
            'Booking Failed',
            response.message.isNotEmpty
                ? response.message
                : 'Failed to book ride. Please try again.',
          );
          currentState.value = BookingState.selectRide;
          if (!panelController.isPanelOpen) panelController.open();
        }
        // --- END MODIFICATION ---
      }
    } catch (e) {
      print("Exception during ride booking: $e");

      // --- MODIFICATION for catch block ---
      String errorMessage =
          'An error occurred while booking. Please try again.';
      if (e is ApiException) {
        errorMessage = e.message; // Get the specific message
      }

      // Check for the "no drivers" message from the exception
      if (errorMessage.toLowerCase().contains('no available drivers')) {
        Get.bottomSheet(
          NoDriversAvailableWidget(
            message: errorMessage, // Pass the message to the widget
            onSearchAgain: () {
              Get.back(); // Close the bottom sheet
              currentState.value =
                  BookingState.selectRide; // Go back to selection
              if (!panelController.isPanelOpen) panelController.open();
            },
          ),
          backgroundColor: Colors.transparent,
          isScrollControlled: true,
        );
      } else {
        // Show a generic error for anything else
        THelperFunctions.showErrorSnackBar('Booking Failed', errorMessage);
      }
      // --- END MODIFICATION ---

      currentState.value = BookingState.selectRide;
      if (!panelController.isPanelOpen) panelController.open();
    }
  }

  Future<void> restoreRideState(RideStatusData rideData) async {
    print("Attempting to restore ride state for Ride ID: ${rideData.rideId}");
    rideId.value = rideData.rideId;
    pickupName.value = rideData.currentLocationName;
    destinationName.value = rideData.destinationName;
    _storage.write('active_ride_id', rideId.value);

    selectedRideType.value = RideType(
      name: rideData.category,
      price: rideData.price,
      eta: '...',
      icon: _getIconForCategory(rideData.category),
      seats: _getSeatsForCategory(rideData.category),
    );

    bool locationsFetched = false;
    try {
      final pickupSuggestions = await PlacesService.getPlaceSuggestions(
        pickupName.value,
      );
      final destSuggestions = await PlacesService.getPlaceSuggestions(
        destinationName.value,
      );

      if (pickupSuggestions.isNotEmpty && destSuggestions.isNotEmpty) {
        final pDetails = await PlacesService.getPlaceDetails(
          pickupSuggestions.first.placeId,
        );
        final dDetails = await PlacesService.getPlaceDetails(
          destSuggestions.first.placeId,
        );

        if (pDetails != null && dDetails != null) {
          pickupLocation.value = pDetails.location;
          destinationLocation.value = dDetails.location;
          pickupAddress.value = pDetails.formattedAddress;
          destinationAddress.value = dDetails.formattedAddress;
          pickupController.text = pickupName.value;
          destinationController.text = destinationName.value;

          if (pDetails.state.isNotEmpty) {
            pickupState.value = pDetails.state;
            print("Restored pickup state to: ${pDetails.state}");
          } else {
            await _getAndSetStateFromLatLng(
              pDetails.location,
              defaultState: "Lagos",
            );
          }

          initializeStops();
          stops.add(
            StopPoint(
              id: 'destination',
              type: StopType.destination,
              location: dDetails.location,
              name: destinationName.value,
              address: destinationAddress.value,
              isEditable: true,
            ),
          );

          addPickupMarker();
          addDestinationMarker();
          await drawRoute();
          locationsFetched = true;
        }
      }
    } catch (e) {
      print("Could not geocode locations to restore route: $e");
      THelperFunctions.showErrorSnackBar(
        'Error',
        'Could not display route map.',
      );
    }

    if (rideData.driver != null) {
      final driverData = rideData.driver!;
      LatLng driverLoc = pickupLocation.value ?? const LatLng(6.5244, 3.3792);

      assignedDriver.value = Driver(
        name: '${driverData.firstName} ${driverData.lastName}',
        rating: 4.9, // Placeholder
        carModel:
            '${driverData.vehicleDetails.make} ${driverData.vehicleDetails.model}',
        plateNumber: driverData.vehicleDetails.licensePlate,
        eta: '...',
        location: driverLoc,
      );
      addDriverMarker();
    }

    print("Restoring state based on API status: ${rideData.status}");
    switch (rideData.status.toLowerCase()) {
      case 'accepted':
        currentState.value = BookingState.driverAssigned;
        break;
      case 'arrived':
        currentState.value = BookingState.driverArrived;
        break;
      case 'on-trip':
        currentState.value = BookingState.tripInProgress;
        startTripAnimation();
        break;
      case 'pending':
        currentState.value = BookingState.searchingDriver;
        break;
      case 'completed':
      case 'cancelled':
      default:
        print(
          "Ride status (${rideData.status}) indicates ride is not active. Resetting UI.",
        );
        _storage.remove('active_ride_id');
        _resetUIState();
        return;
    }

    if (locationsFetched) {
      _ensureMapFitsRoute();
    }
    panelController.open();
    update();
    print("Ride state restored to: ${currentState.value}");
  }

  IconData _getIconForCategory(String category) {
    final lowerCategory = category.toLowerCase();
    if (lowerCategory.contains('luxury')) return Icons.directions_car;
    if (lowerCategory.contains('comfort')) return Icons.car_rental;
    if (lowerCategory.contains('xl')) return Icons.airport_shuttle;
    return Icons.directions_car;
  }

  int _getSeatsForCategory(String category) {
    final lowerCategory = category.toLowerCase();
    if (lowerCategory.contains('xl')) return 6;
    return 4;
  }

  void addDriverMarker({double rotation = 0.0}) {
    if (assignedDriver.value != null) {
      markers.removeWhere((marker) => marker.markerId.value == 'driver');
      markers.add(
        Marker(
          markerId: const MarkerId('driver'),
          position: assignedDriver.value!.location,
          icon:
              driverIcon ??
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
          anchor: const Offset(0.5, 0.5),
          rotation: rotation,
          flat: true,
          infoWindow: InfoWindow(
            title: '🚗 ${assignedDriver.value!.name}',
            snippet:
                '${assignedDriver.value!.carModel} • ${assignedDriver.value!.plateNumber}',
          ),
        ),
      );
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
          iconParam: driverIcon ?? markers[markerIndex].icon,
        );
      } else {
        addDriverMarker(rotation: rotation);
      }
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
    final double distance = R * c;
    return distance / 1000.0;
  }

  void cancelRide() {
    print("Attempting to cancel ride. Ride ID: ${rideId.value}");
    if (rideId.value.isEmpty) {
      print("Cannot cancel: No active Ride ID found. Resetting UI.");
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
              bool success = await _rideService.cancelRide(rideId.value);
              if (success) {
                print("Ride Cancel API successful.");
              } else {
                print("Ride Cancel API failed.");
                THelperFunctions.showErrorSnackBar(
                  'Error',
                  'Failed to cancel ride. Please try again.',
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
    print("Resetting UI state to initial.");
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
    print("Cleared active_ride_id from storage.");

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
    update();
  }

  void _refreshPickupMarker() {
    print("Refreshing pickup marker...");
    addPickupMarker();
    if (mapController != null && pickupLocation.value != null) {
      mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(pickupLocation.value!, 16.0),
      );
    }
  }

  void completePayment() {
    print("Payment completed.");
    isPaymentCompleted.value = true;
    update();
  }

  double calculateDistanceToDestination(LatLng destination) {
    if (pickupLocation.value == null) {
      print("Cannot calculate distance: Pickup location is null.");
      return 0.0;
    }
    return calculateDistance(pickupLocation.value!, destination);
  }

  Future<void> selectDeliverySuggestion(
    PlaceSuggestion suggestion,
    TextEditingController controller,
  ) async {
    print("Selecting delivery suggestion: ${suggestion.description}");
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

        print("Delivery destination set: ${destinationName.value}");
        update();
      } else {
        THelperFunctions.showErrorSnackBar(
          'Error',
          'Could not get location details.',
        );
        controller.clear();
      }
    } catch (e) {
      print('Delivery suggestion error: $e');
      THelperFunctions.showErrorSnackBar(
        'Error',
        'Error selecting delivery destination.',
      );
      controller.clear();
    }
  }

  void startTripAnimation() {
    print(
      "Trip animation started (will be driven by WebSocket location updates).",
    );
    driverLocationTimer?.cancel();
  }

  void animatePanelTo80Percent() {
    print("Animating panel to 80%");
    panelController.animatePanelToPosition(
      0.8,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void goToDestinationSearch() {
    print("Transitioning to DestinationSearch state");
    currentState.value = BookingState.destinationSearch;
    rideTypes.assignAll(_defaultRideTypes);
    animatePanelTo80Percent();
  }

  void goToPackageBooking() {
    print("Transitioning to PackageBooking state");
    currentState.value = BookingState.packageBooking;
    rideTypes.assignAll(_packageRideTypes);
    animatePanelTo80Percent();
  }

  void goToFreightBooking() {
    print("Transitioning to FreightBooking state");
    currentState.value = BookingState.freightBooking;
    rideTypes.assignAll(_freightRideTypes);
    animatePanelTo80Percent();
  }

  void continueToRideSelection() async {
    print("Continuing to RideSelection state");
    selectedRideType.value = null;
    if (rideTypes.isEmpty || rideTypes.first.price == 0) {
      print("Prices seem invalid, attempting refetch...");
      bool pricesFetched = await _updatePricesFromApi();
      if (!pricesFetched) {
        print(
          "Failed to fetch prices again, cannot proceed to ride selection.",
        );
        return;
      }
    }

    currentState.value = BookingState.selectRide;
    showDestinationSuggestions.value = false;
    destinationSuggestions.clear();
    animatePanelTo80Percent();
    _ensureMapFitsRoute();
  }

  void continueWithPackageTypes() {
    print("Setting Package Ride Types");
    rideTypes.assignAll(_packageRideTypes);
    continueToRideSelection();
  }

  void continueWithFreightTypes() {
    print("Setting Freight Ride Types");
    rideTypes.assignAll(_freightRideTypes);
    continueToRideSelection();
  }

  void handleEmergency() {
    print("Emergency button pressed!");
    THelperFunctions.showSnackBar('Emergency Action Triggered (Simulation)');
  }

  void _ensureMapFitsRoute() {
    Future.delayed(const Duration(milliseconds: 300), () {
      fitMapToMarkers();
    });
  }

  // --- ADDED: Handler for 'ride:searching' event ---
  /// Called by WebSocketService when the server is actively searching for a driver.
  /// This provides intermediate feedback to the rider.
  void handleRideSearching(Map<String, dynamic> data) {
    // Ensure we are still in the searching state
    if (currentState.value != BookingState.searchingDriver) {
      print(
        "Received 'ride:searching' event but not in searching state. Ignoring.",
      );
      return;
    }

    final String driverName = data['driverName'] ?? 'a nearby driver';
    final int eta = (data['estimatedArrival'] as num?)?.toInt() ?? 5;
    final String status = data['status'] ?? 'pending';

    if (status == 'pending') {
      // Update the UI text observables
      // The 'SearchingDriverWidget' would need to be updated to listen to these.
      searchingStatusText.value = "We're pinging a potential driver...";
      potentialDriverInfo.value = "$driverName is $eta minutes away";

      print("Ride Searching: Pinging $driverName ($eta mins)");

      // NOTE: We do NOT set the 'assignedDriver' here.
      // That only happens in 'handleRideAccepted' when the driver confirms.
    }
    update(); // Notify listeners
  }

  void handleRideAccepted(Driver driverDetails, String chatId) {
    print(
      "RideController: Handling ride accepted. Driver: ${driverDetails.name}, ChatID: $chatId",
    );
    if (currentState.value == BookingState.searchingDriver) {
      assignedDriver.value = driverDetails;
      activeRideChatId.value = chatId;
      currentState.value = BookingState.driverAssigned;
      _previousDriverLocation = driverDetails.location;
      addDriverMarker(rotation: 0.0);
      THelperFunctions.showSuccessSnackBar(
        'Driver Found!',
        'Driver ${driverDetails.name} is on the way!',
      );
      panelController.open();
      _ensureMapFitsRoute();
      update();
    } else {
      print(
        "Warning: Received ride:accepted event but current state is not searchingDriver (${currentState.value}). Ignoring.",
      );
    }
  }

  void handleRideRejected(String message) {
    print("RideController: Handling ride rejected. Message: $message");
    if (currentState.value == BookingState.searchingDriver) {
      THelperFunctions.showSnackBar(message);
    } else {
      print(
        "Warning: Received ride:rejected event in unexpected state: ${currentState.value}",
      );
    }
  }

  void handleCancellationConfirmed(String message) {
    print("RideController: Handling cancellation confirmed. Message: $message");
    THelperFunctions.showSnackBar(message);
    _resetUIState();
  }

  /// Handles the 'ride:started' event from WebSocketService
  void handleRideStarted() {
    print("RideController: Handling ride started event from WebSocket.");
    if (currentState.value == BookingState.driverArrived ||
        currentState.value == BookingState.driverAssigned) {
      print("RideController: Transitioning to tripInProgress state.");
      currentState.value = BookingState.tripInProgress;
      startTripAnimation();
      update();

      THelperFunctions.showSuccessSnackBar(
        'Trip Started',
        'Your trip has started!',
      );
    } else {
      print(
        "Warning: Received ride:started event in unexpected state: ${currentState.value}. Ignoring.",
      );
    }
  }

  /// Handles the 'ride:locationUpdated' event from WebSocketService
  void updateDriverLocationOnMap(LatLng newLocation) {
    if (assignedDriver.value != null) {
      double bearing = 0.0;
      if (_previousDriverLocation != null) {
        bearing = _calculateBearing(_previousDriverLocation!, newLocation);
      }
      _previousDriverLocation = newLocation;

      if (currentState.value == BookingState.driverAssigned &&
          pickupLocation.value != null) {
        final distanceToPickup = calculateDistance(
          newLocation,
          pickupLocation.value!,
        );
        if (distanceToPickup < 0.1) {
          print("Driver has arrived at pickup!");
          currentState.value = BookingState.driverArrived;
          driverLocationTimer?.cancel();
          THelperFunctions.showSuccessSnackBar(
            'Driver Arrived',
            'Your driver has arrived!',
          );
        }
      }

      assignedDriver.value = assignedDriver.value!.copyWith(
        location: newLocation,
      );
      updateDriverMarker(newPosition: newLocation, rotation: bearing);
    }
  }

  /// Handles the 'ride:completed' event from WebSocketService
  void handleRideCompleted(double finalFare) {
    print(
      "RideController: Handling ride completed event. Final Fare: $finalFare",
    );
    if (currentState.value == BookingState.tripInProgress ||
        currentState.value == BookingState.driverArrived ||
        currentState.value == BookingState.driverAssigned) {
      if (selectedRideType.value != null &&
          selectedRideType.value!.price != finalFare.toInt()) {
        print(
          "Final fare (₦$finalFare) differs from estimate (₦${selectedRideType.value!.price}). Updating.",
        );
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
      THelperFunctions.showSuccessSnackBar(
        'Trip Completed',
        'You have arrived at your destination! Please complete payment.',
      );
      panelController.open();
      update();
    } else {
      print(
        "Warning: Received ride:completed event in unexpected state: ${currentState.value}. Ignoring.",
      );
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
  final int distance; // meters
  final int duration; // seconds
  RouteSegment({
    required this.from,
    required this.to,
    required this.points,
    required this.distance,
    required this.duration,
  });
}
