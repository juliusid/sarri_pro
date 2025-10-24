// This file serves as an index of all widget components available for the map screen
// Use this as a reference for imports when refactoring the map screen

// MAIN STATE WIDGETS (Large widgets for different booking states)
export 'package:sarri_ride/features/ride/widgets/booking_initial_widget.dart'; // Initial booking state
export 'package:sarri_ride/features/ride/widgets/destination_search_widget.dart'; // Destination search with autocomplete
export 'package:sarri_ride/features/ride/widgets/ride_selection_widget.dart'; // Ride type selection
export 'package:sarri_ride/features/ride/widgets/searching_driver_widget.dart'; // Searching for driver state
export 'package:sarri_ride/features/ride/widgets/driver_assigned_widget.dart'; // Driver assigned state
export 'package:sarri_ride/features/ride/widgets/driver_arrived_widget.dart'; // Driver arrived state
export 'package:sarri_ride/features/ride/widgets/trip_in_progress_widget.dart'; // Trip in progress state
export 'package:sarri_ride/features/ride/widgets/trip_completed_widget.dart'; // Trip completed with payment
export 'package:sarri_ride/features/ride/widgets/package_booking_widget.dart'; // Package delivery booking
export 'package:sarri_ride/features/ride/widgets/freight_booking_widget.dart'; // Freight transport booking

// UI COMPONENTS (Reusable smaller widgets)
export 'package:sarri_ride/features/ride/widgets/ride_type_card.dart'; // Individual ride type card
export 'package:sarri_ride/features/ride/widgets/recent_destination_card.dart'; // Recent destination card
export 'package:sarri_ride/features/ride/widgets/location_status_indicator.dart'; // Location status indicator
export 'package:sarri_ride/features/ride/widgets/payment_option_widget.dart'; // Payment option card
export 'package:sarri_ride/features/ride/widgets/driver_info_card.dart'; // Driver information card
// export 'package:sarri_ride/features/ride/widgets/common_widgets.dart'; // Common widgets (DragHandle, BackHeader)

// LAYOUT COMPONENTS (Complex layout widgets)
export 'package:sarri_ride/features/ride/widgets/map_drawer_widget.dart'; // Navigation drawer
export 'package:sarri_ride/features/ride/widgets/pickup_location_modal.dart'; // Pickup location selection modal

// DIALOG COMPONENTS (Dialog and modal widgets)
export 'package:sarri_ride/features/ride/widgets/payment_dialogs.dart'; // Payment confirmation dialogs

/* 
USAGE EXAMPLE IN MAP SCREEN:

```dart
// Import all widgets
import 'package:ride_app/features/ride/screens/widgets/map_screen_widgets_index.dart';

// In the _buildBottomSheet() method, replace large widget builds with:

case BookingState.initial:
  return BookingInitialWidget(
    onDestinationTap: () => setState(() => _currentState = BookingState.destinationSearch),
    onCarTap: () => setState(() => _currentState = BookingState.destinationSearch),
    onPackageTap: () => setState(() => _currentState = BookingState.packageBooking),
    onFreightTap: () => setState(() => _currentState = BookingState.freightBooking),
    recentDestinations: _recentDestinations,
    onRecentDestinationTap: _selectDestinationFromRecent,
  );

case BookingState.destinationSearch:
  return DestinationSearchWidget(
    onBackPressed: _onBackPressed,
    pickupController: _pickupController,
    destinationController: _destinationController,
    onPickupLocationChangePressed: _showPickupLocationOptions,
    onDestinationChanged: _searchDestination,
    showDestinationSuggestions: _showDestinationSuggestions,
    destinationSuggestions: _destinationSuggestions,
    onSuggestionTap: _selectDestination,
    recentDestinations: _recentDestinations,
    onRecentDestinationTap: _selectDestinationFromRecent,
    calculateDistanceToDestination: _calculateDistanceToDestination,
  );

case BookingState.selectRide:
  return RideSelectionWidget(
    onBackPressed: _onBackPressed,
    rideTypes: _rideTypes,
    selectedRideType: _selectedRideType,
    onRideTypeSelected: _selectRideType,
    onConfirmRide: _confirmRide,
  );

case BookingState.searchingDriver:
  return SearchingDriverWidget(
    onCancel: _cancelRide,
  );

case BookingState.driverAssigned:
  return DriverAssignedWidget(
    driver: _assignedDriver!,
    pickupLocation: _pickupController.text,
    destinationLocation: _destinationController.text,
    onCancel: _cancelRide,
  );

case BookingState.driverArrived:
  return DriverArrivedWidget(
    driver: _assignedDriver!,
    onStartTrip: () => setState(() => _currentState = BookingState.tripInProgress),
  );

case BookingState.tripInProgress:
  return TripInProgressWidget(
    driver: _assignedDriver!,
    onEmergency: () => THelperFunctions.showSnackBar('Emergency contact feature will be implemented'),
  );

case BookingState.tripCompleted:
  return TripCompletedWidget(
    selectedRideType: _selectedRideType,
    isPaymentCompleted: _isPaymentCompleted,
    onPayWithWallet: () => PaymentDialogs.showWalletPayment(context, selectedRideType: _selectedRideType, onConfirm: _completePayment),
    onPayWithCard: () => PaymentDialogs.showCardPayment(context, selectedRideType: _selectedRideType, onConfirm: _completePayment),
    onPayWithCash: () => PaymentDialogs.showCashPayment(context, selectedRideType: _selectedRideType, onConfirm: _completePayment),
    onDone: _cancelRide,
  );

case BookingState.packageBooking:
  return PackageBookingWidget(
    onBackPressed: _onBackPressed,
    pickupLocation: _pickupController.text,
    onChangePickup: _showPickupLocationOptions,
    deliveryController: _packageDeliveryController,
    onDeliveryChanged: _searchDestination,
    showSuggestions: _showDestinationSuggestions,
    suggestions: _destinationSuggestions,
    onSuggestionTap: (suggestion) => _selectDeliverySuggestion(suggestion, _packageDeliveryController),
    onContinue: () {
      setState(() {
        _rideTypes = _packageRideTypes;
        _selectedRideType = null;
        _currentState = BookingState.selectRide;
        _showDestinationSuggestions = false;
        _destinationSuggestions.clear();
      });
      _animatePanelTo80Percent();
    },
  );

case BookingState.freightBooking:
  return FreightBookingWidget(
    onBackPressed: _onBackPressed,
    pickupLocation: _pickupController.text,
    onChangePickup: _showPickupLocationOptions,
    deliveryController: _freightDeliveryController,
    onDeliveryChanged: _searchDestination,
    showSuggestions: _showDestinationSuggestions,
    suggestions: _destinationSuggestions,
    onSuggestionTap: (suggestion) => _selectDeliverySuggestion(suggestion, _freightDeliveryController),
    onGetQuote: () {
      setState(() {
        _rideTypes = _freightRideTypes;
        _selectedRideType = null;
        _currentState = BookingState.selectRide;
        _showDestinationSuggestions = false;
        _destinationSuggestions.clear();
      });
      _animatePanelTo80Percent();
    },
  );
```

// Replace _buildDrawer() method with:
return MapDrawerWidget(
  onRefreshLocation: _refreshCurrentLocation,
  onLogout: () => Get.back(),
);

// Replace _showPickupLocationOptions() method with:
PickupLocationModal.show(
  context,
  onLocationSelected: _selectPickupLocation,
  onCurrentLocationPressed: _refreshCurrentLocation,
  onMapPickerPressed: () => _enableMapPicker(isPickup: true),
);

// Replace payment dialog methods with:
PaymentDialogs.showWalletPayment(context, selectedRideType: _selectedRideType, onConfirm: _completePayment);
PaymentDialogs.showCardPayment(context, selectedRideType: _selectedRideType, onConfirm: _completePayment);
PaymentDialogs.showCashPayment(context, selectedRideType: _selectedRideType, onConfirm: _completePayment);
PaymentDialogs.showCancelRideDialog(context, onConfirm: _cancelRide);
*/

/*
BENEFITS OF THIS REFACTORING:

✅ Reduces main file from 3,038 lines to approximately 1,500 lines (50% reduction)
✅ Makes each widget reusable across other screens
✅ Improves code maintainability and readability
✅ Makes testing individual components easier
✅ Follows Flutter best practices for widget composition
✅ Enables better separation of concerns
✅ Makes the codebase more scalable
✅ Improves development team collaboration
✅ Reduces merge conflicts
✅ Makes debugging easier

ADDITIONAL WIDGETS THAT CAN BE CREATED:
- MapControlButtons (location button, zoom controls)
- TripRouteInfo (route distance and time display)
- DriverLocationUpdater (handles driver movement animation)
- BookingStateManager (manages state transitions)
- MapMarkerManager (handles marker creation and updates)
- PolylineManager (handles route drawing)
- CameraPositionManager (handles map camera movements)
*/ 