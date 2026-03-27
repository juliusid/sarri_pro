import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'package:sarri_ride/features/package_delivery/models/package_delivery_model.dart';
import 'package:sarri_ride/features/ride/widgets/ride_selection_widget.dart';
import 'package:sarri_ride/utils/helpers/helper_functions.dart';

/// Holds rider-entered package details for booking `/package_delivery/book-package-delivery`.
class PackageDeliveryController extends GetxController {
  final RxString packageTypeUi = ''.obs; // UI label (e.g. "Documents", "Food")
  final RxDouble weightKg = 0.0.obs;
  final RxString specialInstructions = ''.obs;
  final RxString receiverName = ''.obs;
  final RxString receiverPhoneNumber = ''.obs;

  /// Maps UI packageType values into backend validation values.
  /// Backend allowed values: documents, small_parcel, large_parcel, fragile,
  /// electronics, food, other.
  String mapPackageTypeUiToBackend(String uiValue) {
    final v = uiValue.trim().toLowerCase();
    switch (v) {
      case 'documents':
        return 'documents';
      case 'food':
        return 'food';
      case 'electronics':
        return 'electronics';
      case 'clothing':
        // Backend doesn't have "clothing" - treat it as generic "other".
        return 'other';
      case 'other':
        return 'other';
      default:
        return 'other';
    }
  }

  /// Maps the selected ride type name into backend `category` values.
  /// Backend allowed values: bike_courier, car_delivery, Van_delivery.
  String mapRideTypeNameToBackendCategory(String rideTypeName) {
    final v = rideTypeName.trim().toLowerCase();
    if (v.contains('bike')) return 'bike_courier';
    if (v.contains('van')) return 'Van_delivery';
    return 'car_delivery'; // "Car Delivery" -> car_delivery
  }

  BookPackageRequest buildBookPackageRequest({
    required String currentLocationName,
    required String destinationName,
    required LatLng currentLocation,
    required LatLng destination,
    required String state,
    required RideType selectedRideType,
  }) {
    final backendCategory = mapRideTypeNameToBackendCategory(selectedRideType.name);
    final backendPackageType = mapPackageTypeUiToBackend(packageTypeUi.value);

    return BookPackageRequest(
      currentLocationName: currentLocationName,
      destinationName: destinationName,
      currentLocation: currentLocation,
      destination: destination,
      category: backendCategory,
      state: state,
      packageType: backendPackageType,
      weightKg: weightKg.value,
      specialInstructions: specialInstructions.value,
      receiverName: receiverName.value,
      receiverPhoneNumber: receiverPhoneNumber.value,
    );
  }

  bool validateOrShowErrors() {
    if (packageTypeUi.value.trim().isEmpty) {
      THelperFunctions.showErrorSnackBar(
        'Error',
        'Please select a package type.',
      );
      return false;
    }
    if (weightKg.value <= 0) {
      THelperFunctions.showErrorSnackBar(
        'Error',
        'Please enter a valid package weight.',
      );
      return false;
    }
    if (receiverName.value.trim().isEmpty) {
      THelperFunctions.showErrorSnackBar(
        'Error',
        'Receiver name is required.',
      );
      return false;
    }
    if (receiverPhoneNumber.value.trim().isEmpty) {
      THelperFunctions.showErrorSnackBar(
        'Error',
        'Receiver phone number is required.',
      );
      return false;
    }
    return true;
  }

  void clearPackageForm() {
    packageTypeUi.value = '';
    weightKg.value = 0.0;
    specialInstructions.value = '';
    receiverName.value = '';
    receiverPhoneNumber.value = '';
  }
}

