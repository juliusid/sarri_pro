import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:sarri_ride/features/ride/models/ride_model.dart'; //
import 'package:sarri_ride/features/ride/services/ride_service.dart'; //
import 'package:sliding_up_panel/sliding_up_panel.dart';
import 'package:get_storage/get_storage.dart'; // Import GetStorage

import 'package:sarri_ride/features/location/services/location_service.dart'; //
import 'package:sarri_ride/features/location/services/places_service.dart'; //
import 'package:sarri_ride/features/location/services/route_service.dart'; //
import 'package:sarri_ride/features/ride/widgets/driver_info_card.dart'; //
import 'package:sarri_ride/features/ride/widgets/ride_selection_widget.dart'; //
import 'package:sarri_ride/features/ride/widgets/map_picker_screen.dart'; //
import 'package:sarri_ride/utils/constants/enums.dart'; //
import 'package:sarri_ride/utils/constants/colors.dart'; //
import 'package:sarri_ride/utils/helpers/helper_functions.dart'; //
import 'package:sarri_ride/features/ride/widgets/pickup_location_modal.dart'; //

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

  // Reactive state variables
  final Rx<BookingState> currentState = BookingState.initial.obs;
  final Rx<LatLng?> pickupLocation = Rx<LatLng?>(null);
  final Rx<LatLng?> destinationLocation = Rx<LatLng?>(null);

  // Multi-stop support (temporarily disabled from UI flows)
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
  final LocationService _locationService = LocationService.instance; //

  final RideService _rideService = RideService.instance; //
  final RxString rideId = ''.obs; // To store the ride ID after booking
  final RxString activeRideChatId =
      ''.obs; // To store the chat ID for the current ride

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
  ]; //

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
  ]; //

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
  ]; //

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

  final _storage = GetStorage(); // GetStorage instance for persistence

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

  // Initialize map
  void initializeMap() {
    final position = _locationService.getLocationForMap(); //
    final currentLatLng = LatLng(position.latitude, position.longitude);

    pickupLocation.value = currentLatLng;
    pickupName.value =
        _locationService
            .isLocationEnabled //
        ? 'Current Location'
        : 'Default Location';
    pickupAddress.value =
        _locationService
            .isLocationEnabled //
        ? 'Your current location in Lagos, Nigeria'
        : 'Lagos, Nigeria (Default location)';
    pickupController.text = pickupName.value;
    addPickupMarker();
  }

  void initializeStops() {
    // Initialize with pickup
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
      // Handle appropriately, maybe use default or wait for location
    }
  }

  // Get initial camera position
  CameraPosition get initialCameraPosition {
    final position = _locationService.getLocationForMap(); //
    return CameraPosition(
      target: LatLng(position.latitude, position.longitude),
      zoom: 16.0,
    );
  }

  // Add pickup marker with detailed information
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
      update(); // Notify listeners about marker changes
    }
  }

  // Add a new stop (currently disabled in UI flow)
  Future<void> addStop(PlaceSuggestion suggestion) async {
    if (stops.length >= maxStops.value + 1) {
      // +1 because pickup is already there
      THelperFunctions.showSnackBar('Maximum number of stops reached.'); //
      return;
    }
    try {
      final placeDetails = await PlacesService.getPlaceDetails(
        suggestion.placeId,
      ); //
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

        // Insert before the destination if it exists
        int insertIndex = stops.indexWhere(
          (s) => s.type == StopType.destination,
        );
        if (insertIndex == -1) {
          stops.add(newStop); // Add at the end if no destination yet
        } else {
          stops.insert(insertIndex, newStop);
        }
        isMultiStop.value = true;
        updateMapMarkers();
        await recalculateRoute(); // Use await
        updatePricing();
        THelperFunctions.showSnackBar('Stop added!'); //
      }
    } catch (e) {
      THelperFunctions.showSnackBar('Error adding stop: $e'); //
    }
  }

  // Remove a stop
  void removeStop(String stopId) {
    if (stopId == 'pickup' || stopId == 'destination')
      return; // Cannot remove pickup/destination directly

    stops.removeWhere((stop) => stop.id == stopId);
    if (stops.length <= 2) {
      // Only pickup and destination left
      isMultiStop.value = false;
    }
    updateMapMarkers();
    recalculateRoute();
    updatePricing();
    THelperFunctions.showSnackBar('Stop removed'); //
  }

  // Reorder stops (drag and drop)
  void reorderStops(int oldIndex, int newIndex) {
    if (oldIndex < 1 || newIndex < 1) return; // Don't move pickup
    if (oldIndex >= stops.length || newIndex >= stops.length)
      return; // Index out of bounds

    // Adjust index if moving down past the original position
    if (newIndex > oldIndex) {
      newIndex -= 1;
    }
    // Ensure destination stays last if it exists
    final hasDestination = stops.last.type == StopType.destination;
    if (hasDestination && newIndex >= stops.length - 1) {
      newIndex = stops.length - 2; // Insert before destination
    }

    final StopPoint item = stops.removeAt(oldIndex);
    stops.insert(newIndex, item);

    updateMapMarkers(); // Update marker appearance/order if needed
    recalculateRoute();
    updatePricing();
    update(); // Notify UI
  }

  // Update destination (replaces or adds the last stop)
  Future<void> updateDestination(PlaceSuggestion suggestion) async {
    try {
      final placeDetails = await PlacesService.getPlaceDetails(
        suggestion.placeId,
      ); //
      if (placeDetails != null) {
        // Remove existing destination if present
        stops.removeWhere((stop) => stop.type == StopType.destination);

        // Add new destination at the end
        stops.add(
          StopPoint(
            id: 'destination',
            type: StopType.destination,
            location: placeDetails.location,
            name: placeDetails.name.isNotEmpty
                ? placeDetails.name
                : suggestion.mainText,
            address: placeDetails.formattedAddress,
            isEditable: true, // Destination can be changed
          ),
        );
        // Update explicit destination fields used by single-route flows
        destinationLocation.value = placeDetails.location;
        destinationName.value = placeDetails.name.isNotEmpty
            ? placeDetails.name
            : suggestion.mainText;
        destinationAddress.value = placeDetails.formattedAddress;
        destinationController.text = destinationName.value; // Update text field

        updateMapMarkers();
        await recalculateRoute(); // Use await
        updatePricing();

        // If trip is already in progress, restart the animation on the new route
        if (currentState.value == BookingState.tripInProgress) {
          driverLocationTimer?.cancel();
          startTripAnimation();
        }
      } else {
        THelperFunctions.showSnackBar(
          'Could not get details for the selected destination.',
        ); //
      }
    } catch (e) {
      THelperFunctions.showSnackBar('Error updating destination: $e'); //
    }
  }

  // Recalculate route through all stops
  Future<void> recalculateRoute() async {
    if (stops.length < 2) {
      print("Cannot calculate route: Less than 2 stops defined.");
      polylines.clear(); // Clear existing route
      currentRoutePoints.clear();
      totalDistance.value = 0.0;
      totalDuration.value = 0;
      updatePricing(); // Reset pricing
      return;
    }

    print("Recalculating route for ${stops.length} stops...");
    try {
      routeSegments.clear();
      polylines.clear();
      totalDistance.value = 0.0;
      totalDuration.value = 0;
      List<LatLng> allRoutePoints = [];

      // Calculate route between consecutive stops
      for (int i = 0; i < stops.length - 1; i++) {
        final origin = stops[i].location;
        final destination = stops[i + 1].location;

        print(
          "Calculating segment $i: ${stops[i].name} -> ${stops[i + 1].name}",
        );
        final routeInfo = await RouteService.getRouteInfo(
          origin,
          destination,
        ); //

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

        // Add polyline for this segment
        polylines.add(
          Polyline(
            polylineId: PolylineId('segment_$i'),
            points: routeInfo.points,
            color: _getSegmentColor(i),
            width: 5,
          ),
        );
        allRoutePoints.addAll(routeInfo.points); // Accumulate all points
        print(
          "Segment $i: Distance=${routeInfo.distance}, Duration=${routeInfo.duration}",
        );
      }

      // Update the main route points used for animation
      currentRoutePoints.assignAll(allRoutePoints);
      currentRouteIndex.value = 0; // Reset animation index
      print(
        "Total Route: Distance=${(totalDistance.value / 1000).toStringAsFixed(1)}km, Duration=${(totalDuration.value / 60).round()}min",
      );

      // Restart animation if trip is in progress
      if (currentState.value == BookingState.tripInProgress) {
        print("Restarting trip animation on recalculated route.");
        driverLocationTimer?.cancel();
        startTripAnimation();
      }

      // Fit map to show all stops
      fitMapToAllStops();
      update(); // Notify listeners of polyline changes
    } catch (e) {
      print('Error recalculating route: $e');
      THelperFunctions.showSnackBar('Error calculating route'); //
      // Handle fallback or clear route if necessary
      polylines.clear();
      currentRoutePoints.clear();
    }
  }

  // Update pricing based on new route
  void updatePricing() {
    // Use total distance/duration calculated from routeSegments
    final distanceKm = totalDistance.value / 1000.0;
    final durationMinutes = totalDuration.value / 60.0;

    // More realistic base pricing logic (Example)
    basePrice.value = 500.0; // Base fare in Naira
    final distancePrice = distanceKm * 150.0; // Naira per km
    final timePrice = durationMinutes * 20.0; // Naira per minute (adjust rate)

    // Calculate total base price before ride type multipliers
    totalPrice.value = basePrice.value + distancePrice + timePrice;

    print(
      "Updating pricing: Distance=${distanceKm.toStringAsFixed(1)}km, Duration=${durationMinutes.round()}min, Base Total=₦${totalPrice.value.round()}",
    );

    // Update ride type prices based on this new total base price
    _updateRideTypesWithCalculatedPrice();
  }

  // Updated method name for clarity
  void _updateRideTypesWithCalculatedPrice() {
    List<RideType> updatedRideTypes = [];
    final currentTypes = currentState.value == BookingState.packageBooking
        ? _packageRideTypes
        : currentState.value == BookingState.freightBooking
        ? _freightRideTypes
        : _defaultRideTypes;

    final estimatedEtaMinutes =
        (totalDuration.value / 60).round() + 5; // Base ETA + buffer

    for (RideType baseType in currentTypes) {
      final multiplier = _getRideTypeMultiplier(baseType.name);
      // Calculate final price, ensuring a minimum fare if needed
      final finalPrice = max(
        totalPrice.value * multiplier,
        1000.0,
      ).round(); // Example minimum fare ₦1000

      updatedRideTypes.add(
        RideType(
          name: baseType.name,
          price: finalPrice,
          eta: '$estimatedEtaMinutes min', // Use calculated ETA
          icon: baseType.icon,
          seats: baseType.seats,
        ),
      );
      print("Updated Price for ${baseType.name}: ₦$finalPrice");
    }

    rideTypes.assignAll(updatedRideTypes);
    // If a ride type was already selected, update its price in the selection
    if (selectedRideType.value != null) {
      final updatedSelection = updatedRideTypes.firstWhereOrNull(
        (rt) => rt.name == selectedRideType.value!.name,
      );
      if (updatedSelection != null) {
        selectedRideType.value = updatedSelection;
      }
    }
    update(); // Notify listeners
  }

  double _getRideTypeMultiplier(String rideTypeName) {
    // Adjust multipliers as needed for different categories
    final nameLower = rideTypeName.toLowerCase();
    // Ride types
    if (nameLower.contains('luxury')) return 1.5;
    if (nameLower.contains('comfort')) return 1.2;
    if (nameLower.contains('xl')) return 1.8;
    // Package types
    if (nameLower.contains('bike')) return 0.8;
    if (nameLower.contains('car delivery')) return 1.0; // Assume base car price
    if (nameLower.contains('van')) return 1.4;
    // Freight types
    if (nameLower.contains('small truck')) return 3.0;
    if (nameLower.contains('medium truck')) return 5.0;
    if (nameLower.contains('large truck')) return 8.0;

    return 1.0; // Default multiplier
  }

  Color _getSegmentColor(int segmentIndex) {
    // Cycle through colors for different route segments if needed
    final colors = [
      TColors.primary,
      TColors.info,
      TColors.success,
      TColors.warning,
      TColors.secondary,
    ]; //
    return colors[segmentIndex % colors.length];
  }

  // Fit map to show all stops
  void fitMapToAllStops() {
    if (stops.isEmpty || mapController == null) return;
    if (stops.length == 1) {
      // Only one stop (pickup), center on it
      mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(stops.first.location, 15.0),
      );
      return;
    }

    // Calculate bounds encompassing all stops
    LatLngBounds bounds = LatLngBounds(
      southwest: stops.fold(
        stops.first.location,
        (prev, stop) => LatLng(
          min(prev.latitude, stop.location.latitude),
          min(prev.longitude, stop.location.longitude),
        ),
      ),
      northeast: stops.fold(
        stops.first.location,
        (prev, stop) => LatLng(
          max(prev.latitude, stop.location.latitude),
          max(prev.longitude, stop.location.longitude),
        ),
      ),
    );

    // Add padding - adjust based on number of stops or distance maybe
    double padding = 80.0;

    // Animate camera to fit bounds
    mapController!.animateCamera(CameraUpdate.newLatLngBounds(bounds, padding));
  }

  // Update all markers on the map based on the 'stops' list
  void updateMapMarkers() {
    print("Updating map markers for ${stops.length} stops...");
    markers.removeWhere(
      (m) => m.markerId.value != 'driver',
    ); // Keep only driver marker temporarily

    for (int i = 0; i < stops.length; i++) {
      final stop = stops[i];
      markers.add(
        Marker(
          markerId: MarkerId(stop.id), // Use stop ID for marker ID
          position: stop.location,
          icon: _getStopMarkerIcon(stop.type, i),
          infoWindow: InfoWindow(
            title: _getStopMarkerTitle(stop, i),
            snippet: stop.address,
          ),
          draggable: stop
              .isEditable, // Allow dragging only for editable stops (intermediate/destination)
          onDragEnd: (newPosition) {
            // TODO: Handle marker drag end - requires reverse geocoding and recalculation
            print(
              "Marker ${stop.id} dragged to $newPosition. Update logic needed.",
            );
            // _handleMarkerDragEnd(stop.id, newPosition);
          },
        ),
      );
    }
    // Add driver marker back if exists
    if (assignedDriver.value != null) {
      addDriverMarker(); // Re-add driver marker
    }
    print("Markers updated. Count: ${markers.length}");
    update(); // Notify GetX
  }

  BitmapDescriptor _getStopMarkerIcon(StopType type, int index) {
    switch (type) {
      case StopType.pickup:
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen);
      case StopType.destination:
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);
      case StopType.intermediate:
        // Use different colors or numbers for intermediate stops
        // Example: cycle through blue, cyan, magenta
        final hues = [
          BitmapDescriptor.hueBlue,
          BitmapDescriptor.hueCyan,
          BitmapDescriptor.hueMagenta,
        ];
        return BitmapDescriptor.defaultMarkerWithHue(
          hues[(index - 1) % hues.length],
        ); // index-1 because pickup is 0
    }
  }

  String _getStopMarkerTitle(StopPoint stop, int index) {
    switch (stop.type) {
      case StopType.pickup:
        return '📍 Pickup: ${stop.name}';
      case StopType.destination:
        return '🎯 Destination: ${stop.name}';
      case StopType.intermediate:
        return '🛑 Stop ${index}: ${stop.name}'; // Index starts from 1 for intermediate stops
    }
  }

  // --- Marker Drag Handling (Placeholder) ---
  /*
  Future<void> _handleMarkerDragEnd(String stopId, LatLng newPosition) async {
      final index = stops.indexWhere((s) => s.id == stopId);
      if (index == -1 || !stops[index].isEditable) return; // Only move editable stops

      try {
          // Reverse geocode to get new address
          final newAddress = await PlacesService.getAddressFromCoordinates(newPosition.latitude, newPosition.longitude);
          final stop = stops[index];

          // Update the stop in the list
          stops[index] = StopPoint(
              id: stop.id,
              type: stop.type,
              location: newPosition,
              name: newAddress ?? 'Updated Location', // Use geocoded address as name or keep old?
              address: newAddress ?? 'Address not found',
              isEditable: stop.isEditable
          );

          // Update the corresponding text controller if it's the destination
          if (stop.type == StopType.destination) {
              destinationController.text = stops[index].name;
              destinationLocation.value = newPosition;
              destinationName.value = stops[index].name;
              destinationAddress.value = stops[index].address;
          }

          updateMapMarkers(); // Refresh markers visually
          await recalculateRoute();
          updatePricing();

          THelperFunctions.showSnackBar('${stop.type == StopType.destination ? "Destination" : "Stop"} location updated.');

      } catch (e) {
          print("Error updating location after drag: $e");
          THelperFunctions.showSnackBar('Could not update location.');
          // Optionally revert marker position on error
          updateMapMarkers(); // Redraw markers with original positions
      }
  }
  */
  // --- End Placeholder ---

  // In-ride modifications check
  bool canModifyDuringRide() {
    // Allow modification if trip is in progress AND below max stops (including destination)
    return currentState.value == BookingState.tripInProgress &&
        stops.length < maxStops.value + 2;
  }

  // Add stop during ride
  Future<void> addStopDuringRide(PlaceSuggestion suggestion) async {
    if (!canModifyDuringRide()) {
      THelperFunctions.showSnackBar(
        'Cannot add more stops during this ride.',
      ); //
      return;
    }
    await addStop(suggestion); // Use the existing addStop logic
    // No need for extra snackbar here as addStop already shows one
  }

  // Refresh current location
  Future<void> refreshCurrentLocation() async {
    print("Refreshing current location...");
    await _locationService.refreshLocation(); //
    final position = _locationService.getLocationForMap(); //
    final newLatLng = LatLng(position.latitude, position.longitude);

    pickupLocation.value = newLatLng;
    pickupName.value = 'Current Location';
    // Attempt reverse geocoding for a better address
    String address = 'Updated Location';
    try {
      address =
          await PlacesService.getAddressFromCoordinates(
            newLatLng.latitude,
            newLatLng.longitude,
          ) ??
          address; //
    } catch (e) {
      print("Reverse geocoding failed on refresh: $e");
    }
    pickupAddress.value = address;
    pickupController.text = pickupName.value; // Keep controller text simple

    // Update the pickup stop in the stops list
    if (stops.isNotEmpty && stops.first.type == StopType.pickup) {
      stops[0] = StopPoint(
        id: stops.first.id,
        type: stops.first.type,
        location: newLatLng,
        name: pickupName.value,
        address: pickupAddress.value,
        isEditable: stops.first.isEditable,
      );
    } else {
      // If stops list was empty or pickup wasn't first, reinitialize
      initializeStops();
    }

    addPickupMarker(); // Update marker on map

    mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(newLatLng, 16.0),
    ); // Zoom closer

    // Recalculate route immediately if destination is set
    if (destinationLocation.value != null) {
      await recalculateRoute(); // Use await
      updatePricing();
    }

    THelperFunctions.showSnackBar('Location updated successfully!'); //
    update(); // Notify UI
  }

  // Add destination marker with detailed information
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
      update(); // Notify GetX
      // Consider drawing route immediately after adding marker if pickup exists
      if (pickupLocation.value != null) {
        drawRoute();
      }
    } else {
      print('Cannot add destination marker: destinationLocation is null.');
      // Ensure existing destination marker is removed if location becomes null
      markers.removeWhere((marker) => marker.markerId.value == 'destination');
      update(); // Notify GetX
    }
  }

  // Draw route between pickup and destination (simplified for single route)
  Future<void> drawRoute() async {
    if (pickupLocation.value == null || destinationLocation.value == null) {
      print('Cannot draw route: Pickup or Destination is missing.');
      polylines.clear(); // Clear any existing route
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
      ); //
      currentRoutePoints.assignAll(routeInfo.points);
      currentRouteIndex.value = 0; // Reset animation index

      polylines.clear(); // Clear previous polylines
      polylines.add(
        Polyline(
          polylineId: const PolylineId('route'), // Single route ID
          points: routeInfo.points,
          color: TColors.primary, // Use primary color for main route
          width: 5, // Slightly thicker line
        ),
      );
      print("Route drawn successfully. Points: ${routeInfo.points.length}");
      fitMapToMarkers(); // Adjust map view
      // THelperFunctions.showSnackBar('Route: ${routeInfo.distance} • ${routeInfo.duration}'); // // Optional: Can be noisy
      update(); // Notify GetX
    } catch (e) {
      print('Error drawing route: $e');
      THelperFunctions.showSnackBar(
        'Could not calculate route. Using estimated path.',
      ); //
      // Fallback: Draw a straight line or use fallback points
      final fallbackRoute = [
        pickupLocation.value!,
        destinationLocation.value!,
      ]; // Simple straight line
      currentRoutePoints.assignAll(fallbackRoute);
      currentRouteIndex.value = 0;
      polylines.clear();
      polylines.add(
        Polyline(
          polylineId: const PolylineId('route'),
          points: fallbackRoute,
          color: TColors.primary.withOpacity(0.5), //
          width: 5,
          patterns: [
            PatternItem.dash(15),
            PatternItem.gap(10),
          ], // Dashed line for fallback
        ),
      );
      fitMapToMarkers();
      update(); // Notify GetX
    }
  }

  // Fit map to show pickup and destination markers
  void fitMapToMarkers() {
    if (mapController == null) return;

    List<LatLng> pointsToFit = [];
    if (pickupLocation.value != null) pointsToFit.add(pickupLocation.value!);
    if (destinationLocation.value != null)
      pointsToFit.add(destinationLocation.value!);
    if (assignedDriver.value != null)
      pointsToFit.add(
        assignedDriver.value!.location,
      ); // Include driver if assigned

    if (pointsToFit.length == 1) {
      mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(pointsToFit.first, 15.0),
      );
    } else if (pointsToFit.length > 1) {
      double minLat = pointsToFit.map((p) => p.latitude).reduce(min);
      double maxLat = pointsToFit.map((p) => p.latitude).reduce(max);
      double minLng = pointsToFit.map((p) => p.longitude).reduce(min);
      double maxLng = pointsToFit.map((p) => p.longitude).reduce(max);

      LatLngBounds bounds = LatLngBounds(
        southwest: LatLng(minLat, minLng),
        northeast: LatLng(maxLat, maxLng),
      );

      // Calculate distance to determine padding
      double distanceKm = 0;
      if (pickupLocation.value != null && destinationLocation.value != null) {
        distanceKm = calculateDistanceToDestination(destinationLocation.value!);
      }
      double padding = distanceKm > 50
          ? 100.0
          : (distanceKm > 10 ? 80.0 : 60.0); // Dynamic padding

      // Add a small delay to allow map to render elements before animating camera
      Future.delayed(const Duration(milliseconds: 100), () {
        mapController?.animateCamera(
          CameraUpdate.newLatLngBounds(bounds, padding),
        );
      });
    }
  }

  // Search destination
  Future<void> searchDestination(String query) async {
    if (query.length < 3) {
      destinationSuggestions.clear();
      showDestinationSuggestions.value = false;
      return;
    }
    print("Searching for destination: '$query'");
    try {
      // Use current pickup location to bias results if available
      final suggestions = await PlacesService.getPlaceSuggestions(
        query,
        location: pickupLocation.value,
      ); //
      destinationSuggestions.assignAll(suggestions);
      showDestinationSuggestions.value = suggestions.isNotEmpty;
      print("Found ${suggestions.length} suggestions.");
    } catch (e) {
      print('Error getting destination suggestions: $e');
      destinationSuggestions.clear();
      showDestinationSuggestions.value = false;
      THelperFunctions.showSnackBar(
        'Unable to search locations. Check connection.',
      ); //
    }
  }

  // Select destination from suggestions
  Future<void> selectDestination(PlaceSuggestion suggestion) async {
    print("Selecting destination: ${suggestion.description}");
    destinationController.text =
        suggestion.mainText; // Update text field immediately
    destinationSuggestions.clear(); // Hide suggestions
    showDestinationSuggestions.value = false;
    Get.focusScope?.unfocus(); // Hide keyboard

    try {
      final placeDetails = await PlacesService.getPlaceDetails(
        suggestion.placeId,
      ); //
      if (placeDetails != null) {
        destinationLocation.value = placeDetails.location;
        destinationName.value = placeDetails.name.isNotEmpty
            ? placeDetails.name
            : suggestion.mainText;
        destinationAddress.value = placeDetails.formattedAddress;
        destinationController.text =
            destinationName.value; // Update with potentially better name

        print("Destination details fetched: ${placeDetails.location}");

        // --- Fetch Prices and Proceed ---
        bool pricesFetched = await _updatePricesFromApi();
        if (pricesFetched) {
          addDestinationMarker(); // Add marker *after* prices are fetched
          // Update the destination stop in the stops list
          stops.removeWhere(
            (s) => s.type == StopType.destination,
          ); // Remove old one
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
          currentState.value =
              BookingState.selectRide; // Move to ride selection
          _ensureMapFitsRoute(); // Adjust map view
          animatePanelTo80Percent(); // Expand bottom sheet
        } else {
          // Price calculation failed (error shown in _updatePricesFromApi), reset destination fields?
          print("Price calculation failed. Staying on destination search.");
          // Optionally clear destination fields if price fetch fails critically
          // destinationLocation.value = null; destinationName.value = ''; // etc.
        }
        // --- End Fetch Prices ---
      } else {
        THelperFunctions.showSnackBar(
          'Could not get location details for ${suggestion.mainText}',
        ); //
        destinationController.text = ''; // Clear input on failure
      }
    } catch (e) {
      THelperFunctions.showSnackBar('Error selecting destination: $e'); //
      destinationController.text = ''; // Clear input on failure
    }
  }

  // Fetches prices from API and updates rideTypes list. Returns true on success.
  Future<bool> _updatePricesFromApi() async {
    if (pickupLocation.value == null || destinationLocation.value == null) {
      print("Cannot update prices: Pickup or Destination is null.");
      return false;
    }

    print(
      "Fetching prices from ${pickupLocation.value} to ${destinationLocation.value}",
    );
    THelperFunctions.showSnackBar('Calculating fares...'); //

    try {
      final priceResponse = await _rideService.calculatePrice(
        pickupLocation.value!,
        destinationLocation.value!,
      ); //

      if (priceResponse.status == 'success' && priceResponse.data != null) {
        final prices = priceResponse.data!.prices; //
        final newRideTypes = <RideType>[];
        final estimatedEtaMinutes =
            (totalDuration.value / 60).round() + 5; // Base ETA + buffer

        // --- Map API response to RideType objects ---
        // Ensure names match _defaultRideTypes for consistency if needed
        if (prices.luxury != null) {
          newRideTypes.add(
            RideType(
              name: 'Luxury',
              price: prices.luxury!.price,
              eta: '${estimatedEtaMinutes + 2} min', // Add slight ETA variation
              icon: Icons.directions_car,
              seats: prices.luxury!.seats,
            ),
          ); //
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
          ); //
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
          ); //
          print("XL Price: ${prices.xl!.price}");
        }
        // --- End Mapping ---

        if (newRideTypes.isEmpty) {
          print(
            "Warning: Price API returned success but no ride categories found.",
          );
          THelperFunctions.showSnackBar(
            'No ride types available for this route.',
          ); //
          rideTypes.assignAll(
            _defaultRideTypes,
          ); // Show default prices as fallback?
          return false; // Treat as failure if no types returned
        }

        rideTypes.assignAll(newRideTypes); // Update the list for the UI
        print("Prices updated successfully.");
        return true; // Indicate success
      } else {
        // Error handled globally for 401, show message for other errors
        if (!priceResponse.message.toLowerCase().contains('session expired') &&
            !priceResponse.message.toLowerCase().contains("unauthorized")) {
          THelperFunctions.showSnackBar(
            priceResponse.message.isNotEmpty
                ? priceResponse.message
                : 'Failed to calculate fares.',
          ); //
        }
        print("Price calculation API failed: ${priceResponse.message}");
        rideTypes.assignAll(
          _defaultRideTypes,
        ); // Show default prices as fallback? Or empty list?
        return false; // Indicate failure
      }
    } catch (e) {
      print("Exception during price calculation: $e");
      THelperFunctions.showSnackBar(
        'An error occurred while calculating fares.',
      ); //
      rideTypes.assignAll(_defaultRideTypes); // Fallback
      return false; // Indicate failure
    }
  }

  // Select destination from recent places list
  Future<void> selectDestinationFromRecent(
    Map<String, dynamic> destination,
  ) async {
    // Make async
    print("Selecting recent destination: ${destination['name']}");
    destinationLocation.value = destination['location'] as LatLng;
    destinationName.value = destination['name'] as String;
    destinationAddress.value = destination['address'] as String;
    destinationController.text = destinationName.value; // Update text field

    // Fetch prices for the selected recent destination
    bool pricesFetched = await _updatePricesFromApi();
    if (pricesFetched) {
      addDestinationMarker(); // Add marker
      // Update destination in stops list
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
      currentState.value = BookingState.selectRide; // Move to ride selection
      _ensureMapFitsRoute(); // Adjust map
      animatePanelTo80Percent(); // Expand panel
    } else {
      // Handle price fetch failure - stay on current screen or go back?
      print("Price fetch failed for recent destination.");
      // Maybe clear destination fields if needed
    }
  }

  // Handle back button press in different states
  void onBackPressed() {
    print("Back pressed. Current state: ${currentState.value}");
    switch (currentState.value) {
      case BookingState.destinationSearch:
      case BookingState
          .packageBooking: // Go back to initial from package/freight input
      case BookingState.freightBooking:
        currentState.value = BookingState.initial;
        showDestinationSuggestions.value = false;
        destinationSuggestions.clear();
        destinationController.clear(); // Clear input
        packageDeliveryController.clear();
        freightDeliveryController.clear();
        destinationLocation.value = null; // Clear selected location
        polylines.clear(); // Clear route
        markers.removeWhere(
          (m) => m.markerId.value == 'destination',
        ); // Remove dest marker
        rideTypes.assignAll(_defaultRideTypes); // Reset ride types
        if (panelController.isPanelOpen)
          panelController.close(); // Close panel if fully open
        break;

      case BookingState.selectRide:
        // Go back to destination search or initial based on previous state?
        // For simplicity, let's go back to destination search for rides, initial for others
        if (rideTypes.any((rt) => _packageRideTypes.contains(rt))) {
          currentState.value = BookingState.packageBooking;
        } else if (rideTypes.any((rt) => _freightRideTypes.contains(rt))) {
          currentState.value = BookingState.freightBooking;
        } else {
          currentState.value = BookingState.destinationSearch;
        }
        selectedRideType.value = null; // Clear selection
        // Keep destination details, don't clear route/markers
        break;

      case BookingState.searchingDriver:
      case BookingState.driverAssigned:
      case BookingState.driverArrived:
        // Show cancel confirmation dialog
        _showCancelRideConfirmationDialog();
        break;

      // Cannot go back from trip in progress or completed via this button
      case BookingState.tripInProgress:
      case BookingState.tripCompleted:
        print("Back press ignored in state: ${currentState.value}");
        break;

      case BookingState.initial:
      default:
        // If somehow back is pressed in initial state, maybe close app or do nothing
        print("Back press in initial state.");
        break;
    }
  }

  // Show pickup location selection modal
  void showPickupLocationOptions() {
    // Check if context is available
    if (Get.context != null) {
      PickupLocationModal.show(
        //
        Get.context!,
        onLocationSelected: _onPickupLocationSelected, // Renamed for clarity
        onCurrentLocationPressed: _onCurrentLocationPressed,
        onMapPickerPressed: _onMapPickerPressed,
      );
    } else {
      print("Error: Cannot show pickup options, context is null.");
    }
  }

  // Handle location selection from autocomplete modal
  void _onPickupLocationSelected(PlaceSuggestion suggestion) async {
    // Renamed
    print("Pickup selected from suggestions: ${suggestion.description}");
    try {
      final placeDetails = await PlacesService.getPlaceDetails(
        suggestion.placeId,
      ); //
      if (placeDetails != null) {
        pickupLocation.value = placeDetails.location;
        pickupName.value = placeDetails.name.isNotEmpty
            ? placeDetails.name
            : suggestion.mainText;
        pickupAddress.value = placeDetails.formattedAddress;
        pickupController.text = pickupName.value; // Update text field

        // Update pickup in stops list
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
          initializeStops(); // Re-initialize if something went wrong
        }

        addPickupMarker(); // Update map marker

        // Center map
        mapController?.animateCamera(
          CameraUpdate.newLatLngZoom(placeDetails.location, 15.0),
        );

        // Recalculate route and prices if destination is already set
        if (destinationLocation.value != null) {
          await recalculateRoute(); // Use await
          updatePricing(); // updatePricing calls _updateRideTypes...
        }

        THelperFunctions.showSnackBar('Pickup location updated.'); //
        update(); // Notify GetX
      } else {
        THelperFunctions.showSnackBar('Could not get location details.'); //
      }
    } catch (e) {
      THelperFunctions.showSnackBar('Error updating pickup location: $e'); //
    }
  }

  // Handle selection of 'Use current location' from modal
  void _onCurrentLocationPressed() async {
    // Make async
    print("Using current location for pickup.");
    await refreshCurrentLocation(); // Use existing refresh logic
    // refreshCurrentLocation handles UI updates, snackbar, and route recalculation
  }

  // Handle selection of 'Choose on map' from modal
  void _onMapPickerPressed() async {
    print("Opening map picker for pickup location.");
    try {
      final result = await Get.to(
        () => MapPickerScreen(
          //
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
        pickupController.text = selectedName; // Update text field

        // Update pickup in stops list
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
          initializeStops(); // Re-initialize
        }

        addPickupMarker(); // Update map marker

        // Center map
        mapController?.animateCamera(
          CameraUpdate.newLatLngZoom(selectedLocation, 15.0),
        );

        // Recalculate route and prices if destination is set
        if (destinationLocation.value != null) {
          await recalculateRoute(); // Use await
          updatePricing();
        }

        THelperFunctions.showSnackBar('Pickup location updated.'); //
        update(); // Notify GetX
      } else {
        print("Map picker cancelled or returned null.");
      }
    } catch (e) {
      THelperFunctions.showSnackBar('Error selecting location from map: $e'); //
    }
  }

  // Helper method to recalculate route (Only used internally now)
  void _calculateRoute() async {
    await recalculateRoute(); // Just call the main recalculate method
    updatePricing(); // Ensure prices update after route calculation
  }

  // Update ride types based on route info (Now part of updatePricing flow)
  void _updateRideTypesWithRoute(RouteInfo routeInfo) {
    // This logic is now handled within updatePricing and _updateRideTypesWithCalculatedPrice
    print(
      "Note: _updateRideTypesWithRoute is deprecated, logic moved to updatePricing.",
    );
  }

  // Select ride type
  void selectRideType(RideType rideType) {
    selectedRideType.value = rideType;
    update(); // Notify UI if needed
  }

  // Confirm ride booking
  void confirmRide() async {
    if (selectedRideType.value == null) {
      THelperFunctions.showSnackBar('Please select a ride type first.'); //
      return;
    }
    if (pickupLocation.value == null || destinationLocation.value == null) {
      THelperFunctions.showSnackBar('Pickup or destination is missing.'); //
      return;
    }

    print("Confirming ride: ${selectedRideType.value!.name}");
    currentState.value = BookingState.searchingDriver;
    panelController.close(); // Collapse panel while searching

    try {
      final response = await _rideService.bookRide(
        //
        pickupName: pickupName.value,
        destinationName: destinationName.value,
        pickupCoords: pickupLocation.value!,
        destinationCoords: destinationLocation.value!,
        category: selectedRideType.value!.name, // Use the selected type name
      );

      if (response.status == 'success' && response.data != null) {
        rideId.value = response.data!.rideId; // Store the ride ID
        _storage.write('active_ride_id', rideId.value); // Persist ride ID
        print("Ride booked successfully. Ride ID: ${rideId.value}");
        THelperFunctions.showSnackBar('Finding your driver...'); //
        // Wait for WebSocket event 'ride:accepted' - remove simulation
        // _simulateDriverSearch(); // REMOVED SIMULATION
      } else {
        print("Ride booking failed: ${response.message}");
        THelperFunctions.showSnackBar(
          response.message.isNotEmpty
              ? response.message
              : 'Failed to book ride. Please try again.',
        ); //
        currentState.value =
            BookingState.selectRide; // Go back to selection on failure
        if (!panelController.isPanelOpen)
          panelController.open(); // Re-open panel
      }
    } catch (e) {
      print("Exception during ride booking: $e");
      THelperFunctions.showSnackBar(
        'An error occurred while booking. Please try again.',
      ); //
      currentState.value = BookingState.selectRide; // Go back on error
      if (!panelController.isPanelOpen) panelController.open();
    }
  }

  // Restore ride state from persisted data or API check
  Future<void> restoreRideState(RideStatusData rideData) async {
    //
    print("Attempting to restore ride state for Ride ID: ${rideData.rideId}");
    // Restore basic info
    rideId.value = rideData.rideId;
    pickupName.value = rideData.currentLocationName;
    destinationName.value = rideData.destinationName;
    // Store persisted ride ID again (in case it wasn't already)
    _storage.write('active_ride_id', rideId.value);

    // Find the matching RideType based on category and price
    selectedRideType.value = RideType(
      name: rideData.category,
      price: rideData.price,
      eta: '...', // ETA is dynamic, use placeholder
      icon: _getIconForCategory(rideData.category), // Helper to get icon
      seats: _getSeatsForCategory(rideData.category), // Helper to get seats
    );

    // Geocode locations to draw route (Essential)
    bool locationsFetched = false;
    try {
      // Use PlacesService to find coordinates from names
      final pickupSuggestions = await PlacesService.getPlaceSuggestions(
        pickupName.value,
      ); //
      final destSuggestions = await PlacesService.getPlaceSuggestions(
        destinationName.value,
      ); //

      if (pickupSuggestions.isNotEmpty && destSuggestions.isNotEmpty) {
        final pDetails = await PlacesService.getPlaceDetails(
          pickupSuggestions.first.placeId,
        ); //
        final dDetails = await PlacesService.getPlaceDetails(
          destSuggestions.first.placeId,
        ); //

        if (pDetails != null && dDetails != null) {
          pickupLocation.value = pDetails.location;
          destinationLocation.value = dDetails.location;
          pickupAddress.value = pDetails.formattedAddress; // Update address too
          destinationAddress.value =
              dDetails.formattedAddress; // Update address too
          pickupController.text = pickupName.value;
          destinationController.text = destinationName.value;

          // Update stops list
          initializeStops(); // Re-init with pickup
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
          await drawRoute(); // Draw the route using fetched coords
          locationsFetched = true;
        }
      }
    } catch (e) {
      print("Could not geocode locations to restore route: $e");
      THelperFunctions.showSnackBar('Could not display route map.'); //
    }

    // Restore driver info if available
    if (rideData.driver != null) {
      final driverData = rideData.driver!; //
      // Use a default/last known location for driver until first location update event
      LatLng driverLoc = pickupLocation.value ?? const LatLng(6.5244, 3.3792);

      assignedDriver.value = Driver(
        //
        name: '${driverData.firstName} ${driverData.lastName}',
        rating: 4.9, // Placeholder - API should provide this eventually
        carModel:
            '${driverData.vehicleDetails.make} ${driverData.vehicleDetails.model}', //
        plateNumber: driverData.vehicleDetails.licensePlate, //
        eta: '...', // Placeholder - calculated dynamically or via event
        location: driverLoc, // Use placeholder
      );
      addDriverMarker(); // Add marker to map
    }

    // Restore state based on API status
    print("Restoring state based on API status: ${rideData.status}");
    switch (rideData.status.toLowerCase()) {
      case 'accepted':
        currentState.value = BookingState.driverAssigned;
        // Don't start simulation here, wait for ride:locationUpdated events
        // startDriverLocationUpdates(); // REMOVED SIMULATION
        break;
      case 'arrived':
        currentState.value = BookingState.driverArrived;
        break;
      case 'on-trip':
        currentState.value = BookingState.tripInProgress;
        // Don't start simulation, wait for ride:locationUpdated events
        // startTripAnimation(); // REMOVED SIMULATION
        break;
      case 'pending': // If status check happens before acceptance
        currentState.value = BookingState.searchingDriver;
        break;
      case 'completed':
      case 'cancelled':
      default: // Handle unknown or finished states
        print(
          "Ride status (${rideData.status}) indicates ride is not active. Resetting UI.",
        );
        _storage.remove('active_ride_id'); // Clear persisted ID
        _resetUIState(); // Go back to initial state
        // Return immediately to avoid further updates
        return;
    }

    // Ensure map fits markers and route if locations were fetched
    if (locationsFetched) {
      _ensureMapFitsRoute();
    }
    panelController.open(); // Ensure panel is open to show ride state
    update(); // Notify GetX
    print("Ride state restored to: ${currentState.value}");
  }

  // Helper to get icon based on category name
  IconData _getIconForCategory(String category) {
    final lowerCategory = category.toLowerCase();
    if (lowerCategory.contains('luxury')) return Icons.directions_car;
    if (lowerCategory.contains('comfort')) return Icons.car_rental;
    if (lowerCategory.contains('xl')) return Icons.airport_shuttle;
    // Add checks for package/freight if needed
    return Icons.directions_car; // Default
  }

  // Helper to get seats based on category name
  int _getSeatsForCategory(String category) {
    final lowerCategory = category.toLowerCase();
    if (lowerCategory.contains('xl')) return 6;
    if (lowerCategory.contains('luxury')) return 4;
    if (lowerCategory.contains('comfort')) return 4;
    // Add checks for package/freight if needed
    return 4; // Default
  }

  // Simulate driver search (REMOVED - Now handled by WebSocket)
  // void _simulateDriverSearch() { ... }

  // Add driver marker
  void addDriverMarker() {
    if (assignedDriver.value != null) {
      markers.removeWhere((marker) => marker.markerId.value == 'driver');
      markers.add(
        Marker(
          markerId: const MarkerId('driver'),
          position: assignedDriver.value!.location,
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueAzure,
          ), // Changed color
          anchor: const Offset(0.5, 0.5), // Center icon over location
          rotation: 0.0, // TODO: Update rotation based on movement direction
          flat: true, // Make marker flat on map
          infoWindow: InfoWindow(
            title: '🚗 ${assignedDriver.value!.name}',
            snippet:
                '${assignedDriver.value!.carModel} • ${assignedDriver.value!.plateNumber}',
          ),
        ),
      );
      update(); // Notify GetX
    }
  }

  // Start simulation of driver moving to pickup (REMOVED - Now handled by WebSocket 'ride:locationUpdated')
  // void startDriverLocationUpdates() { ... }

  // Update driver marker position and info (Called by WebSocket handler)
  void updateDriverMarker() {
    if (assignedDriver.value != null) {
      // Find existing marker
      final markerIndex = markers.indexWhere(
        (m) => m.markerId.value == 'driver',
      );
      if (markerIndex != -1) {
        // Update existing marker's position
        markers[markerIndex] = markers[markerIndex].copyWith(
          positionParam: assignedDriver.value!.location,
          // TODO: Calculate rotation based on previous location
        );
      } else {
        // If marker somehow doesn't exist, add it
        addDriverMarker();
      }
      update(); // Notify GetX
      // Optionally animate camera to follow driver if needed
      // mapController?.animateCamera(CameraUpdate.newLatLng(assignedDriver.value!.location));
    }
  }

  // Calculate distance between two LatLng points (using Haversine for accuracy)
  double calculateDistance(LatLng point1, LatLng point2) {
    const double R = 6371e3; // Earth radius in metres
    final double phi1 = point1.latitude * pi / 180; // φ, λ in radians
    final double phi2 = point2.latitude * pi / 180;
    final double deltaPhi = (point2.latitude - point1.latitude) * pi / 180;
    final double deltaLambda = (point2.longitude - point1.longitude) * pi / 180;

    final double a =
        sin(deltaPhi / 2) * sin(deltaPhi / 2) +
        cos(phi1) * cos(phi2) * sin(deltaLambda / 2) * sin(deltaLambda / 2);
    final double c = 2 * atan2(sqrt(a), sqrt(1 - a));

    final double distance = R * c; // in metres
    return distance / 1000.0; // convert to km
  }

  // Cancel the current ride
  void cancelRide() async {
    print("Attempting to cancel ride. Ride ID: ${rideId.value}");
    if (rideId.value.isEmpty) {
      print("Cannot cancel: No active Ride ID found. Resetting UI.");
      _resetUIState(); // Reset UI if no ride was actually booked
      return;
    }

    // Show confirmation dialog before proceeding
    _showCancelRideConfirmationDialog();
  }

  // Shows the confirmation dialog for cancelling a ride
  void _showCancelRideConfirmationDialog() {
    Get.dialog(
      AlertDialog(
        title: const Text('Cancel Ride'),
        content: const Text(
          'Are you sure you want to cancel this ride? Cancellation fees may apply.',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(), // Close dialog
            child: const Text('Keep Ride'),
          ),
          TextButton(
            onPressed: () async {
              Get.back(); // Close dialog
              THelperFunctions.showSnackBar('Cancelling ride...'); //
              // Call API to cancel
              bool success = await _rideService.cancelRide(rideId.value); //
              if (success) {
                print("Ride Cancel API successful.");
                // UI reset will happen via 'ride:cancellationConfirmed' event from WebSocket
              } else {
                print("Ride Cancel API failed.");
                // Show error, but don't reset UI yet, wait for WebSocket confirmation or error
                THelperFunctions.showSnackBar(
                  'Failed to cancel ride. Please try again.',
                ); //
              }
            },
            child: const Text(
              'Yes, Cancel',
              style: TextStyle(color: TColors.error),
            ), //
          ),
        ],
      ),
      barrierDismissible: false, // Prevent dismissing by tapping outside
    );
  }

  // Resets UI state to initial booking screen
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
    activeRideChatId.value = ''; // Clear chat ID
    rideId.value = ''; // Clear the ride ID

    // Clear persisted ride ID from storage
    _storage.remove('active_ride_id');
    print("Cleared active_ride_id from storage.");

    // Cleanup map elements
    markers.removeWhere(
      (m) => m.markerId.value == 'destination' || m.markerId.value == 'driver',
    );
    polylines.clear();
    currentRoutePoints.clear();
    currentRouteIndex.value = 0;
    rideTypes.assignAll(_defaultRideTypes); // Reset to default ride types
    driverLocationTimer?.cancel(); // Stop any simulation timers

    _refreshPickupMarker(); // Reset pickup marker to current location

    // Adjust bottom panel
    if (panelController.isPanelOpen) {
      panelController.animatePanelToPosition(
        0.5,
        duration: const Duration(milliseconds: 300),
      ); // Adjust to default height
    }
    update(); // Notify GetX
  }

  // Force refresh pickup marker to trigger map update and center
  void _refreshPickupMarker() {
    print("Refreshing pickup marker...");
    addPickupMarker(); // Re-adds the marker based on current pickupLocation.value
    // Center map on pickup location
    if (mapController != null && pickupLocation.value != null) {
      mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(pickupLocation.value!, 16.0),
      );
    }
  }

  // Complete payment process
  void completePayment() {
    print("Payment completed.");
    isPaymentCompleted.value = true;
    update(); // Notify UI (e.g., TripCompletedWidget)
  }

  // Calculate distance between current pickup and a destination LatLng
  double calculateDistanceToDestination(LatLng destination) {
    if (pickupLocation.value == null) {
      print("Cannot calculate distance: Pickup location is null.");
      return 0.0;
    }
    return calculateDistance(
      pickupLocation.value!,
      destination,
    ); // Use the accurate Haversine version
  }

  // Select delivery suggestion (for package/freight)
  Future<void> selectDeliverySuggestion(
    PlaceSuggestion suggestion,
    TextEditingController controller,
  ) async {
    print("Selecting delivery suggestion: ${suggestion.description}");
    controller.text = suggestion.mainText; // Update text field
    destinationSuggestions.clear();
    showDestinationSuggestions.value = false;
    Get.focusScope?.unfocus();

    try {
      final placeDetails = await PlacesService.getPlaceDetails(
        suggestion.placeId,
      ); //
      if (placeDetails != null) {
        destinationLocation.value = placeDetails.location;
        destinationName.value = placeDetails.name.isNotEmpty
            ? placeDetails.name
            : suggestion.mainText;
        destinationAddress.value = placeDetails.formattedAddress;
        controller.text = destinationName.value; // Update with better name

        // Update destination stop in stops list
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

        addDestinationMarker(); // Add map marker
        await recalculateRoute(); // Calculate route for price/ETA
        // Prices will be updated by recalculateRoute -> updatePricing

        print("Delivery destination set: ${destinationName.value}");
        update(); // Notify GetX
      } else {
        THelperFunctions.showSnackBar('Could not get location details.'); //
        controller.clear();
      }
    } catch (e) {
      print('Delivery suggestion error: $e');
      THelperFunctions.showSnackBar('Error selecting delivery destination.'); //
      controller.clear();
    }
  }

  // Start trip animation (simulation - REMOVED, use updateDriverLocationOnMap from WebSocket)
  void startTripAnimation() {
    print(
      "Trip animation started (will be driven by WebSocket location updates).",
    );
    // Clear any previous simulation timer if it exists
    driverLocationTimer?.cancel();

    // The actual marker movement will now be handled by updateDriverLocationOnMap
    // when 'ride:locationUpdated' events are received.

    // We might still need a timer to check for trip completion if the backend doesn't send
    // a clear 'ride:completed' event reliably based on location, or for timeouts.
    /*
    driverLocationTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
        if (currentState.value != BookingState.tripInProgress) {
            timer.cancel();
            return;
        }
        // Check if driver is near destination based on last known location
        if (assignedDriver.value != null && destinationLocation.value != null) {
            final dist = calculateDistance(assignedDriver.value!.location, destinationLocation.value!);
            print("Distance to destination: ${dist.toStringAsFixed(3)} km");
            if (dist < 0.1) { // Within 100m
                print("Driver near destination, marking as completed.");
                timer.cancel();
                handleRideCompleted(selectedRideType.value?.price.toDouble() ?? 0.0); // Use estimated price if final not received
            }
        }
    });
    */
  }

  // Animate bottom panel to 80% height
  void animatePanelTo80Percent() {
    print("Animating panel to 80%");
    panelController.animatePanelToPosition(
      0.8,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  // --- State Transition Methods ---
  void goToDestinationSearch() {
    print("Transitioning to DestinationSearch state");
    currentState.value = BookingState.destinationSearch;
    rideTypes.assignAll(_defaultRideTypes); // Ensure default types are set
    animatePanelTo80Percent();
  }

  void goToPackageBooking() {
    print("Transitioning to PackageBooking state");
    currentState.value = BookingState.packageBooking;
    rideTypes.assignAll(_packageRideTypes); // Set package types
    animatePanelTo80Percent();
  }

  void goToFreightBooking() {
    print("Transitioning to FreightBooking state");
    currentState.value = BookingState.freightBooking;
    rideTypes.assignAll(_freightRideTypes); // Set freight types
    animatePanelTo80Percent();
  }

  // Called after destination is set (either ride, package, or freight)
  void continueToRideSelection() async {
    // Make async
    print("Continuing to RideSelection state");
    selectedRideType.value = null; // Clear previous selection
    // Prices should have been updated by selectDestination or selectDeliverySuggestion
    // If not (e.g., error), we might need a fallback or re-fetch here.
    // Let's add a check and potential refetch
    if (rideTypes.isEmpty || rideTypes.first.price == 0) {
      // Basic check if prices look invalid
      print("Prices seem invalid, attempting refetch...");
      bool pricesFetched = await _updatePricesFromApi();
      if (!pricesFetched) {
        print(
          "Failed to fetch prices again, cannot proceed to ride selection.",
        );
        // Stay in current state (destination search or package/freight booking)
        return;
      }
    }

    currentState.value = BookingState.selectRide;
    showDestinationSuggestions.value = false; // Ensure suggestions are hidden
    destinationSuggestions.clear();
    animatePanelTo80Percent();
    _ensureMapFitsRoute(); // Adjust map view
  }

  // Called from Package Booking Widget
  void continueWithPackageTypes() {
    print("Setting Package Ride Types");
    rideTypes.assignAll(_packageRideTypes); // Set package types
    continueToRideSelection(); // Proceed to selection/pricing
  }

  // Called from Freight Booking Widget
  void continueWithFreightTypes() {
    print("Setting Freight Ride Types");
    rideTypes.assignAll(_freightRideTypes); // Set freight types
    continueToRideSelection(); // Proceed to selection/pricing
  }

  // Called from DriverArrivedWidget or WebSocket 'ride:started'
  void startTrip() {
    print("Starting trip...");
    // Update state first
    currentState.value = BookingState.tripInProgress;
    // Start tracking/animation (now relies on WebSocket updates)
    startTripAnimation(); // Let this manage timers if needed for timeouts etc.
    // Optionally update panel position if needed
    // panelController.animatePanelToPosition(0.6, duration: const Duration(milliseconds: 300));
    update(); // Notify GetX
  }

  // Called from TripInProgressWidget
  void handleEmergency() {
    print("Emergency button pressed!");
    // TODO: Implement actual emergency logic (API call, contact sharing)
    THelperFunctions.showSnackBar('Emergency Action Triggered (Simulation)'); //
  }

  // Ensures map fits the current route after a short delay
  void _ensureMapFitsRoute() {
    // Add a delay to allow UI to build/update before fitting map
    Future.delayed(const Duration(milliseconds: 300), () {
      fitMapToMarkers(); // Use the method that fits pickup/destination/driver
    });
  }

  // --- WebSocket Event Handlers ---

  /// Handles the 'ride:accepted' event from WebSocketService
  void handleRideAccepted(Driver driverDetails, String chatId) {
    print(
      "RideController: Handling ride accepted. Driver: ${driverDetails.name}, ChatID: $chatId",
    );
    if (currentState.value == BookingState.searchingDriver) {
      assignedDriver.value = driverDetails;
      activeRideChatId.value = chatId; // Store the chat ID
      currentState.value = BookingState.driverAssigned;
      addDriverMarker(); // Add driver marker to map
      // Don't start simulation, wait for actual location updates
      // startDriverLocationUpdates(); // REMOVED SIMULATION
      THelperFunctions.showSnackBar(
        'Driver ${driverDetails.name} is on the way!',
      ); //
      panelController.open(); // Ensure panel is open
      _ensureMapFitsRoute(); // Fit map to include driver, pickup, destination
      update();
    } else {
      print(
        "Warning: Received ride:accepted event but current state is not searchingDriver (${currentState.value}). Ignoring.",
      );
    }
  }

  /// Handles the 'ride:rejected' event from WebSocketService
  void handleRideRejected(String message) {
    print("RideController: Handling ride rejected. Message: $message");
    if (currentState.value == BookingState.searchingDriver) {
      THelperFunctions.showSnackBar(message); //
      // Keep searching state, backend handles finding new driver
      // Optionally add a timeout mechanism here if desired
    } else {
      print(
        "Warning: Received ride:rejected event in unexpected state: ${currentState.value}",
      );
    }
  }

  /// Handles the 'ride:cancellationConfirmed' event from WebSocketService
  void handleCancellationConfirmed(String message) {
    print("RideController: Handling cancellation confirmed. Message: $message");
    THelperFunctions.showSnackBar(message); //
    _resetUIState(); // Reset UI to initial state
  }

  /// Handles the 'ride:started' event from WebSocketService
  void handleRideStarted() {
    print("RideController: Handling ride started event from WebSocket.");
    if (currentState.value == BookingState.driverArrived ||
        currentState.value == BookingState.driverAssigned) {
      // Allow starting even if 'arrived' event missed
      startTrip(); // Transition state and handle animations/timers
      THelperFunctions.showSnackBar('Your trip has started!'); //
    } else {
      print(
        "Warning: Received ride:started event in unexpected state: ${currentState.value}. Ignoring.",
      );
    }
  }

  /// Handles the 'ride:locationUpdated' event from WebSocketService
  void updateDriverLocationOnMap(LatLng newLocation) {
    // print("RideController: Updating driver location on map to $newLocation"); // Too verbose
    if (assignedDriver.value != null) {
      // Check if the driver has arrived at pickup
      if (currentState.value == BookingState.driverAssigned &&
          pickupLocation.value != null) {
        final distanceToPickup = calculateDistance(
          newLocation,
          pickupLocation.value!,
        );
        print(
          "Driver distance to pickup: ${distanceToPickup.toStringAsFixed(3)} km",
        );
        if (distanceToPickup < 0.1) {
          // Driver is within 100m of pickup
          print("Driver has arrived at pickup!");
          currentState.value = BookingState.driverArrived;
          driverLocationTimer?.cancel(); // Stop any simulation timer if running
          THelperFunctions.showSnackBar('Your driver has arrived!'); //
        }
      }
      // Update marker position
      assignedDriver.value = assignedDriver.value!.copyWith(
        location: newLocation,
      );
      updateDriverMarker(); // Update marker on the map
    }
  }

  /// Handles the 'ride:completed' event from WebSocketService
  void handleRideCompleted(double finalFare) {
    print(
      "RideController: Handling ride completed event. Final Fare: $finalFare",
    );
    // Can complete from tripInProgress or even driverArrived if start event was missed/delayed
    if (currentState.value == BookingState.tripInProgress ||
        currentState.value == BookingState.driverArrived ||
        currentState.value == BookingState.driverAssigned) {
      // Update fare if different from estimate
      if (selectedRideType.value != null &&
          selectedRideType.value!.price != finalFare.toInt()) {
        print(
          "Final fare (₦$finalFare) differs from estimate (₦${selectedRideType.value!.price}). Updating.",
        );
        selectedRideType.value = RideType(
          name: selectedRideType.value!.name,
          price: finalFare.toInt(), // Use final fare from backend
          eta: selectedRideType.value!.eta,
          icon: selectedRideType.value!.icon,
          seats: selectedRideType.value!.seats,
        );
      }
      driverLocationTimer?.cancel(); // Stop any simulation/timeout timers
      currentState.value = BookingState.tripCompleted;
      THelperFunctions.showSnackBar(
        'You have arrived at your destination! Please complete payment.',
      ); //
      panelController.open(); // Ensure panel opens fully for payment/rating
      update();
    } else {
      print(
        "Warning: Received ride:completed event in unexpected state: ${currentState.value}. Ignoring.",
      );
    }
  }
} // End of RideController class

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
