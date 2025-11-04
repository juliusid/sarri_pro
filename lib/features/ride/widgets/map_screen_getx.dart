// lib/features/ride/widgets/map_screen_getx.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:sarri_ride/common/widgets/notifications/notification_icon.dart'; //
import 'package:sarri_ride/features/notifications/controllers/notification_controller.dart'; //
import 'package:sliding_up_panel/sliding_up_panel.dart';

import 'package:sarri_ride/features/ride/controllers/ride_controller.dart'; //
import 'package:sarri_ride/features/location/services/location_service.dart'; //
import 'package:sarri_ride/utils/constants/colors.dart'; //
import 'package:sarri_ride/utils/helpers/helper_functions.dart'; //

// Widget Components - Import all from index
import 'package:sarri_ride/features/ride/widgets/map_screen_widgets_index.dart'; //

class MapScreenGetX extends StatelessWidget {
  const MapScreenGetX({super.key});

  // Dark map style (as before)
  static const String _darkMapStyle = '''
    [
      { "elementType": "geometry", "stylers": [ { "color": "#242f3e" } ] },
      { "elementType": "labels.text.fill", "stylers": [ { "color": "#746855" } ] },
      { "elementType": "labels.text.stroke", "stylers": [ { "color": "#242f3e" } ] },
      { "featureType": "administrative.locality", "elementType": "labels.text.fill", "stylers": [ { "color": "#d59563" } ] },
      { "featureType": "poi", "elementType": "labels.text.fill", "stylers": [ { "color": "#d59563" } ] },
      { "featureType": "poi.park", "elementType": "geometry", "stylers": [ { "color": "#263c3f" } ] },
      { "featureType": "poi.park", "elementType": "labels.text.fill", "stylers": [ { "color": "#6b9a76" } ] },
      { "featureType": "road", "elementType": "geometry", "stylers": [ { "color": "#38414e" } ] },
      { "featureType": "road", "elementType": "geometry.stroke", "stylers": [ { "color": "#212a37" } ] },
      { "featureType": "road", "elementType": "labels.text.fill", "stylers": [ { "color": "#9ca5b3" } ] },
      { "featureType": "road.highway", "elementType": "geometry", "stylers": [ { "color": "#746855" } ] },
      { "featureType": "road.highway", "elementType": "geometry.stroke", "stylers": [ { "color": "#1f2835" } ] },
      { "featureType": "road.highway", "elementType": "labels.text.fill", "stylers": [ { "color": "#f3d19c" } ] },
      { "featureType": "transit", "elementType": "geometry", "stylers": [ { "color": "#2f3948" } ] },
      { "featureType": "transit.station", "elementType": "labels.text.fill", "stylers": [ { "color": "#d59563" } ] },
      { "featureType": "water", "elementType": "geometry", "stylers": [ { "color": "#17263c" } ] },
      { "featureType": "water", "elementType": "labels.text.fill", "stylers": [ { "color": "#515c6d" } ] },
      { "featureType": "water", "elementType": "labels.text.stroke", "stylers": [ { "color": "#17263c" } ] }
    ]
  ''';

  double _getMinPanelHeight(BuildContext context) {
    return MediaQuery.of(context).size.height * 0.5;
  }

  @override
  Widget build(BuildContext context) {
    // Initialize the RideController
    final rideController = Get.put(RideController());
    final notificationController =
        Get.find<NotificationController>(); // Get instance
    final dark = THelperFunctions.isDarkMode(context);
    return Scaffold(
      drawer: MapDrawerWidget(
        //
        onRefreshLocation: rideController.refreshCurrentLocation,
        onLogout: () {
          Get.back(); /* Logout handled by SettingsController */
        },
      ),
      body: Stack(
        children: [
          SlidingUpPanel(
            controller: rideController.panelController,
            minHeight: _getMinPanelHeight(context),
            maxHeight: MediaQuery.of(context).size.height * 0.9,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            parallaxEnabled: true,
            parallaxOffset: 0.5,
            body: Stack(
              children: [
                // Google Map
                Obx(
                  () => GoogleMap(
                    initialCameraPosition: rideController.initialCameraPosition,
                    onMapCreated: (GoogleMapController controller) {
                      rideController.mapController = controller;
                      if (dark) {
                        controller.setMapStyle(_darkMapStyle);
                      }
                    },
                    markers: rideController.markers.toSet(),
                    polylines: rideController.polylines.toSet(),
                    myLocationEnabled: true,
                    myLocationButtonEnabled: false,
                    zoomControlsEnabled: false,
                    style: dark ? _darkMapStyle : null,

                    // --- ADDED ---
                    buildingsEnabled: true, // Show 3D buildings
                    trafficEnabled: true, // Show live traffic
                    // --- END ADDED ---
                  ),
                ),

                // --- MODIFIED: Only Drawer Button (with dot) ---
                Positioned(
                  top: MediaQuery.of(context).padding.top + 16,
                  left: 16,
                  child: Container(
                    decoration: BoxDecoration(
                      color: dark ? TColors.dark : Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(dark ? 0.3 : 0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Builder(
                      // Needed for Scaffold context
                      builder: (context) => IconButton(
                        icon: Obx(
                          () => Stack(
                            clipBehavior: Clip.none,
                            children: [
                              Icon(
                                Icons.menu,
                                size: 24,
                                color: dark ? TColors.white : TColors.black,
                              ),
                              // Conditional Red Dot
                              if (notificationController.unreadCount.value > 0)
                                Positioned(
                                  top: -3,
                                  right: -3,
                                  child: Container(
                                    width: 8,
                                    height: 8,
                                    decoration: const BoxDecoration(
                                      color: TColors.error,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        onPressed: () => Scaffold.of(context).openDrawer(),
                      ),
                    ),
                  ),
                ),
                // --- END MODIFICATION ---
              ],
            ),
            panel: _buildBottomSheet(rideController),
            onPanelSlide: (double pos) {
              // Handle panel slide animations if needed
            },
          ),
          // --- Current Location Button (as before) ---
          Positioned(
            bottom: MediaQuery.of(context).size.height * 0.55,
            right: 16,
            child: Container(
              // ... (decoration as before) ...
              decoration: BoxDecoration(
                color: dark ? TColors.dark : Colors.white,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(dark ? 0.3 : 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: GetBuilder<LocationService>(
                builder: (locationService) {
                  return IconButton(
                    onPressed: rideController.refreshCurrentLocation,
                    icon: locationService.isLocationLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                TColors.primary,
                              ),
                            ),
                          )
                        : Icon(
                            Icons.my_location,
                            color: locationService.isLocationEnabled
                                ? TColors.primary
                                : TColors.grey,
                          ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- _buildBottomSheet (as before) ---
  Widget _buildBottomSheet(RideController controller) {
    return Obx(() {
      switch (controller.currentState.value) {
        case BookingState.initial:
          return BookingInitialWidget(
            //
            onDestinationTap: controller.goToDestinationSearch,
            onCarTap: controller.goToDestinationSearch,
            onPackageTap: controller.goToPackageBooking,
            onFreightTap: controller.goToFreightBooking,
            recentDestinations: controller.recentDestinations,
            onRecentDestinationTap: controller.selectDestinationFromRecent,
          );

        case BookingState.destinationSearch:
          return DestinationSearchWidget(
            //
            onBackPressed: controller.onBackPressed,
            pickupController: controller.pickupController,
            destinationController: controller.destinationController,
            onPickupLocationChangePressed: controller.showPickupLocationOptions,
            onDestinationChanged: controller.searchDestination,
            showDestinationSuggestions:
                controller.showDestinationSuggestions.value,
            destinationSuggestions: controller.destinationSuggestions,
            onSuggestionTap: controller.selectDestination,
            recentDestinations: controller.recentDestinations,
            onRecentDestinationTap: controller.selectDestinationFromRecent,
            calculateDistanceToDestination:
                controller.calculateDistanceToDestination,
          );

        case BookingState.selectRide:
          return RideSelectionWidget(
            //
            onBackPressed: controller.onBackPressed,
            rideTypes: controller.rideTypes,
            selectedRideType: controller.selectedRideType.value,
            onRideTypeSelected: controller.selectRideType,
            onConfirmRide: controller.confirmRide,
          );

        case BookingState.searchingDriver:
          return SearchingDriverWidget(onCancel: controller.cancelRide); //

        case BookingState.driverAssigned:
          return DriverAssignedWidget(
            //
            driver: controller.assignedDriver.value!,
            pickupLocation: controller.pickupController.text,
            destinationLocation: controller.destinationController.text,
            onCancel: controller.cancelRide,
          );

        case BookingState.driverArrived:
          return DriverArrivedWidget(
            //
            driver: controller.assignedDriver.value!,
            onStartTrip: () => print('Trip started!'),
          );

        case BookingState.tripInProgress:
          return TripInProgressWidget(
            //
            driver: controller.assignedDriver.value!,
            onEmergency: controller.handleEmergency,
          );

        case BookingState.tripCompleted:
          return TripCompletedWidget(
            //
            selectedRideType: controller.selectedRideType.value,
            isPaymentCompleted: controller.isPaymentCompleted.value,
            onPayWithWallet: () => PaymentDialogs.showWalletPayment(
              //
              Get.context!,
              selectedRideType: controller.selectedRideType.value,
              onConfirm: controller.completePayment,
            ),
            onPayWithCard: () => PaymentDialogs.showCardPayment(
              //
              Get.context!,
              selectedRideType: controller.selectedRideType.value,
              onConfirm: controller.completePayment,
            ),
            onPayWithCash: () => PaymentDialogs.showCashPayment(
              //
              Get.context!,
              selectedRideType: controller.selectedRideType.value,
              onConfirm: controller.completePayment,
            ),
            onDone: controller.cancelRide,
          );

        case BookingState.packageBooking:
          return PackageBookingWidget(
            //
            onBackPressed: controller.onBackPressed,
            pickupLocation: controller.pickupController.text,
            onChangePickup: controller.showPickupLocationOptions,
            deliveryController: controller.packageDeliveryController,
            onDeliveryChanged: controller.searchDestination,
            showSuggestions: controller.showDestinationSuggestions.value,
            suggestions: controller.destinationSuggestions,
            onSuggestionTap: (suggestion) =>
                controller.selectDeliverySuggestion(
                  suggestion,
                  controller.packageDeliveryController,
                ),
            onContinue: controller.continueWithPackageTypes,
          );

        case BookingState.freightBooking:
          return FreightBookingWidget(
            //
            onBackPressed: controller.onBackPressed,
            pickupLocation: controller.pickupController.text,
            onChangePickup: controller.showPickupLocationOptions,
            deliveryController: controller.freightDeliveryController,
            onDeliveryChanged: controller.searchDestination,
            showSuggestions: controller.showDestinationSuggestions.value,
            suggestions: controller.destinationSuggestions,
            onSuggestionTap: (suggestion) =>
                controller.selectDeliverySuggestion(
                  suggestion,
                  controller.freightDeliveryController,
                ),
            onGetQuote: controller.continueWithFreightTypes,
          );
      }
    });
  }
}
