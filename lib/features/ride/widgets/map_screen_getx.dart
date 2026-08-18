import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:sarri_ride/features/authentication/widgets/sign_in_update_notice.dart';
import 'package:sarri_ride/features/notifications/controllers/notification_controller.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';

import 'package:sarri_ride/features/ride/controllers/ride_controller.dart';
import 'package:sarri_ride/features/warehouse/controllers/warehouse_booking_controller.dart';
import 'package:sarri_ride/features/location/services/location_service.dart';
import 'package:sarri_ride/utils/constants/colors.dart';
import 'package:sarri_ride/utils/helpers/helper_functions.dart';

import 'package:sarri_ride/features/ride/widgets/map_screen_widgets_index.dart';
import 'package:sarri_ride/common/widgets/double_back_to_close.dart';

class MapScreenGetX extends StatelessWidget {
  const MapScreenGetX({super.key});

  // Uber-like Dark Charcoal Theme
  static const String _darkMapStyle = '''[
    {
      "elementType": "geometry",
      "stylers": [{"color": "#212121"}]
    },
    {
      "elementType": "labels.icon",
      "stylers": [{"visibility": "on"}]
    },
    {
      "elementType": "labels.text.fill",
      "stylers": [{"color": "#757575"}]
    },
    {
      "elementType": "labels.text.stroke",
      "stylers": [{"color": "#212121"}]
    },
    {
      "featureType": "administrative",
      "elementType": "geometry",
      "stylers": [{"color": "#757575"}]
    },
    {
      "featureType": "administrative.country",
      "elementType": "labels.text.fill",
      "stylers": [{"color": "#9e9e9e"}]
    },
    {
      "featureType": "administrative.locality",
      "elementType": "labels.text.fill",
      "stylers": [{"color": "#bdbdbd"}]
    },
    {
      "featureType": "poi",
      "elementType": "labels.text.fill",
      "stylers": [{"color": "#757575"}]
    },
    {
      "featureType": "poi.park",
      "elementType": "geometry",
      "stylers": [{"color": "#181818"}]
    },
    {
      "featureType": "poi.park",
      "elementType": "labels.text.fill",
      "stylers": [{"color": "#616161"}]
    },
    {
      "featureType": "poi.park",
      "elementType": "labels.text.stroke",
      "stylers": [{"color": "#1b1b1b"}]
    },
    {
      "featureType": "road",
      "elementType": "geometry.fill",
      "stylers": [{"color": "#2c2c2c"}]
    },
    {
      "featureType": "road",
      "elementType": "labels.text.fill",
      "stylers": [{"color": "#8a8a8a"}]
    },
    {
      "featureType": "road.arterial",
      "elementType": "geometry",
      "stylers": [{"color": "#373737"}]
    },
    {
      "featureType": "road.highway",
      "elementType": "geometry",
      "stylers": [{"color": "#3c3c3c"}]
    },
    {
      "featureType": "road.highway.controlled_access",
      "elementType": "geometry",
      "stylers": [{"color": "#4e4e4e"}]
    },
    {
      "featureType": "road.local",
      "elementType": "labels.text.fill",
      "stylers": [{"color": "#616161"}]
    },
    {
      "featureType": "transit",
      "elementType": "labels.text.fill",
      "stylers": [{"color": "#757575"}]
    },
    {
      "featureType": "water",
      "elementType": "geometry",
      "stylers": [{"color": "#000000"}]
    },
    {
      "featureType": "water",
      "elementType": "labels.text.fill",
      "stylers": [{"color": "#3d3d3d"}]
    }
  ]''';

  double _getMinPanelHeight(BuildContext context, BookingState state) {
    // On initial state, open the panel tall enough to show all service cards
    if (state == BookingState.initial) {
      return MediaQuery.of(context).size.height * 0.75;
    }
    return MediaQuery.of(context).size.height * 0.5;
  }

  /// The 'Choose a ride' panel's height depends on how many ride categories
  /// are on offer — with one category (the common case) a fixed 50%/90%
  /// panel left a large empty gap below the single card. Sizing it to
  /// content (clamped to a sensible range) removes that gap, and min==max
  /// so the panel opens directly to its content height instead of a
  /// draggable range it doesn't need.
  ({double min, double max}) _getSelectRidePanelHeight(
    BuildContext context,
    int rideTypeCount,
  ) {
    final screenHeight = MediaQuery.of(context).size.height;
    const double chromeHeight = 340; // header + trip settings card + confirm button + paddings
    const double itemHeight = 88; // ride card row + spacing
    final contentHeight =
        chromeHeight + (rideTypeCount.clamp(1, 4) * itemHeight);
    final height = contentHeight.clamp(
      screenHeight * 0.35,
      screenHeight * 0.75,
    );
    return (min: height, max: height);
  }

  @override
  Widget build(BuildContext context) {
    // Initialize the RideController
    final rideController = Get.put(RideController());
    final notificationController = Get.find<NotificationController>();
    final dark = THelperFunctions.isDarkMode(context);

    // One-time heads-up for users still signed in from before passwords
    // were replaced by Google/Apple, so an expiring session isn't a surprise.
    SignInUpdateNotice.maybeShow(SignInNoticeSurface.home);

    // Open panel after frame renders if state is active
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (rideController.currentState.value != BookingState.initial &&
          rideController.panelController.isAttached) {
        rideController.panelController.open();
      }
    });

    return DoubleBackToCloseWidget(
      onWillPop: () {
        // Step back through the booking flow (matches the in-app back
        // arrow's controller.onBackPressed) before falling through to the
        // double-tap-to-exit behavior — otherwise the system back button
        // always tried to close the app from any screen.
        if (rideController.currentState.value != BookingState.initial) {
          rideController.onBackPressed();
          return true;
        }
        return false;
      },
      child: Scaffold(
        drawer: MapDrawerWidget(
          onRefreshLocation: rideController.refreshCurrentLocation,
          onLogout: () {
            Get.back(); /* Logout handled by SettingsController */
          },
        ),
        // Everything is now contained within the SlidingUpPanel's body
        body: Obx(() {
          final state = rideController.currentState.value;
          final rideTypeCount = rideController.rideTypes.length; // reactive read so the panel resizes once prices load
          final isSelectRide = state == BookingState.selectRide;
          final selectRideHeights = isSelectRide
              ? _getSelectRidePanelHeight(context, rideTypeCount)
              : null;
          // 'Plan your ride' (destinationSearch) should start from the
          // vertical center of the screen rather than ballooning to 90% —
          // panelController.open() always snaps to maxHeight, so it must
          // match the intended (50%) minHeight for this state too.
          final isFixedHalfHeight = state == BookingState.destinationSearch;
          final panelMinHeight =
              selectRideHeights?.min ?? _getMinPanelHeight(context, state);
          final panelMaxHeight = selectRideHeights?.max ??
              (isFixedHalfHeight
                  ? panelMinHeight
                  : MediaQuery.of(context).size.height * 0.9);
          return SlidingUpPanel(
          controller: rideController.panelController,
          minHeight: panelMinHeight,
          maxHeight: panelMaxHeight,
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
                // Add padding to the map so the 'center' and Google logo
                // respect the persistent bottom sheet area.
                padding: EdgeInsets.only(
                  bottom: panelMinHeight,
                  top: MediaQuery.of(context).padding.top + 10,
                ),
                markers: rideController.markers.toSet(),
                polylines: rideController.polylines.toSet(),
                myLocationEnabled: true,
                myLocationButtonEnabled: false,
                zoomControlsEnabled: false,
                style: dark ? _darkMapStyle : null,

                // --- CHANGED: Disabled traffic to remove green lines ---
                buildingsEnabled: true,
                trafficEnabled: false,
                // --- END CHANGED ---
              ),
            ),

            // --- Menu Button (Top Left) ---
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

            // --- Current Location Button (Moved inside body) ---
            Positioned(
              bottom: panelMinHeight + 20,
              right: 16,
              child: Container(
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
        panel: _buildBottomSheet(rideController),
        onPanelSlide: (double pos) {
          // Optional: Add paralax or fade effects here if needed
        },
        );
        }),
    ));
  }

  Widget _buildBottomSheet(RideController controller) {
    return Obx(() {
      switch (controller.currentState.value) {
        case BookingState.initial:
          return BookingInitialWidget(
            onDestinationTap: controller.goToDestinationSearch,
            onCarTap: controller.goToDestinationSearch,
            onPackageTap: controller.goToPackageBooking,
            onFreightTap: controller.goToFreightBooking,
            onWarehouseTap: controller.goToWarehouseBooking,
            onCarRentalTap: controller.goToCarRentalBooking,
            recentDestinations: controller.recentDestinations,
            onRecentDestinationTap: controller.selectDestinationFromRecent,
          );

        case BookingState.destinationSearch:
          return DestinationSearchWidget(
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
            onBackPressed: controller.onBackPressed,
            rideTypes: controller.rideTypes,
            selectedRideType: controller.selectedRideType.value,
            onRideTypeSelected: controller.selectRideType,
            onConfirmRide: controller.confirmRide,
          );

        case BookingState.searchingDriver:
          // Reuses onBackPressed rather than cancelRide directly — for
          // BookingState.searchingDriver that already shows the "Cancel
          // Ride?" confirmation dialog instead of cancelling immediately.
          return SearchingDriverWidget(onCancel: controller.onBackPressed);

        case BookingState.driverAssigned:
          return DriverAssignedWidget(
            driver: controller.assignedDriver.value!,
            pickupLocation: controller.pickupController.text,
            destinationLocation: controller.destinationController.text,
            onCancel: controller.cancelRide,
          );

        case BookingState.driverArrived:
          return DriverArrivedWidget(
            driver: controller.assignedDriver.value!,
            onStartTrip: () => print('Trip started!'),
          );

        case BookingState.tripInProgress:
          return TripInProgressWidget(
            driver: controller.assignedDriver.value!,
            onEmergency: controller.handleEmergency,
          );

        case BookingState.tripCompleted:
          return TripCompletedWidget(
            selectedRideType: controller.selectedRideType.value,
            isPaymentCompleted: controller.isPaymentCompleted.value,
            tripId: controller.rideId.value,
            onDone: controller.finishRide,
          );

        case BookingState.packageBooking:
          return PackageBookingWidget(
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

        case BookingState.warehouseBooking:
          return WarehouseBookingWidget(
            onBackPressed: controller.onBackPressed,
            onContinue: () {
              final warehouseController = Get.find<WarehouseBookingController>();
              warehouseController.createOrder();
            }
          );

        case BookingState.carRentalBooking:
          return CarRentalBookingWidget(
            onBackPressed: controller.onBackPressed,
          );
      }
    });
  }
}
