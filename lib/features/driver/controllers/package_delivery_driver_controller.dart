import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:sarri_ride/features/package_delivery/services/package_delivery_service.dart';
import 'package:sarri_ride/features/location/services/location_service.dart';
import 'package:sarri_ride/utils/helpers/helper_functions.dart';

enum PackageDeliveryDriverStep {
  request,
  accepted,
  pickupConfirmed,
  started,
  arrived,
  awaitingDeliveryConfirmation,
  delivered,
}

/// Driver-side controller for handling `/package_delivery/*` lifecycle.
/// It is intentionally minimal: it enables accept -> pickup confirm -> start -> arrive -> delivery confirm.
class PackageDeliveryDriverController extends GetxController {
  final Rx<PackageDeliveryDriverStep> step =
      PackageDeliveryDriverStep.request.obs;

  final RxString tripId = ''.obs;
  final RxString rideId = ''.obs;

  final RxString pickupCode = ''.obs;
  final RxString destinationName = ''.obs;
  final RxString currentLocationName = ''.obs;

  final RxString receiverName = ''.obs;
  final RxString receiverPhoneNumber = ''.obs;

  final RxString specialInstructions = ''.obs;

  final Rx<LatLng?> pickupLocation = Rx<LatLng?>(null);
  final Rx<LatLng?> dropoffLocation = Rx<LatLng?>(null);

  PackageDeliveryService get _packageDeliveryService {
    if (Get.isRegistered<PackageDeliveryService>()) {
      return PackageDeliveryService.instance;
    }
    return Get.put(PackageDeliveryService(), permanent: false);
  }
  final LocationService _locationService = LocationService.instance;

  void reset() {
    step.value = PackageDeliveryDriverStep.request;
    tripId.value = '';
    rideId.value = '';
    pickupCode.value = '';
    destinationName.value = '';
    currentLocationName.value = '';
    receiverName.value = '';
    receiverPhoneNumber.value = '';
    specialInstructions.value = '';
    pickupLocation.value = null;
    dropoffLocation.value = null;
    update();
  }

  /// ride:request payload for package deliveries includes:
  /// `tripId`, `rideId`, `pickupCode`, `pickupLocation`, `dropoffLocation`,
  /// `currentLocationName`, `destinationName`, `ReceiverName`, `ReceiverPhoneNumber`,
  /// `specialInstructions`, etc.
  void setFromRideRequestPayload(Map<String, dynamic> data) {
    reset();

    tripId.value = data['tripId']?.toString() ?? '';
    rideId.value = data['rideId']?.toString() ?? tripId.value;

    pickupCode.value = data['pickupCode']?.toString() ?? '';
    currentLocationName.value =
        data['currentLocationName']?.toString() ?? 'Pickup';
    destinationName.value =
        data['destinationName']?.toString() ?? 'Dropoff';

    receiverName.value = data['ReceiverName']?.toString() ?? '';
    receiverPhoneNumber.value =
        data['ReceiverPhoneNumber']?.toString() ?? '';
    specialInstructions.value = data['specialInstructions']?.toString() ?? '';

    pickupLocation.value = _parseLatLng(data['pickupLocation']);
    dropoffLocation.value = _parseLatLng(data['dropoffLocation'] ?? data['destinationLocation']);
    step.value = PackageDeliveryDriverStep.request;
  }

  Future<void> acceptRequest() async {
    if (rideId.value.isEmpty) return;
    final ok = await _packageDeliveryService.acceptPackageDeliveryRequest(
      rideId.value,
    );
    if (!ok) return;
    step.value = PackageDeliveryDriverStep.accepted;
    update();
  }

  Future<void> rejectRequest() async {
    if (rideId.value.isEmpty) return;
    final ok =
        await _packageDeliveryService.rejectPackageDeliveryRequest(rideId.value);
    if (!ok) return;
    reset();
  }

  Future<void> confirmPickup() async {
    if (tripId.value.isEmpty) return;
    final ok = await _packageDeliveryService.confirmPickupWithCode(
      tripId: tripId.value,
      pickupCode: pickupCode.value,
    );
    if (!ok) return;
    step.value = PackageDeliveryDriverStep.pickupConfirmed;
    update();
  }

  Future<void> startTrip() async {
    if (tripId.value.isEmpty) return;
    final pos = _locationService.getLocationForMap();
    final ok = await _packageDeliveryService.startPackageDeliveryTrip(
      tripId: tripId.value,
      lat: pos.latitude,
      lng: pos.longitude,
    );
    if (!ok) return;
    step.value = PackageDeliveryDriverStep.started;
    update();
  }

  Future<void> arriveAtDropoff() async {
    if (tripId.value.isEmpty) return;
    final pos = _locationService.getLocationForMap();
    final ok = await _packageDeliveryService.arriveAtPackageDropoff(
      tripId: tripId.value,
      lat: pos.latitude,
      lng: pos.longitude,
    );
    if (!ok) return;
    step.value = PackageDeliveryDriverStep.arrived;
    update();
  }

  Future<void> confirmDeliveryWithCode(String deliveryCode) async {
    if (tripId.value.isEmpty) return;
    if (deliveryCode.trim().length != 6) {
      THelperFunctions.showErrorSnackBar(
        'Error',
        'Delivery code must be 6 digits.',
      );
      return;
    }
    final ok = await _packageDeliveryService.confirmPackageDeliveryWithCode(
      tripId: tripId.value,
      deliveryCode: deliveryCode.trim(),
    );
    if (!ok) return;
    step.value = PackageDeliveryDriverStep.delivered;
    update();
    // Close this flow; the app will open `WaitingForPaymentScreen` when
    // the backend emits `package:delivered`.
    Get.back();
  }

  LatLng? _parseLatLng(dynamic locationData) {
    if (locationData is Map) {
      final lat = (locationData['latitude'] as num?)?.toDouble() ??
          double.tryParse(locationData['latitude'].toString());
      final lng = (locationData['longitude'] as num?)?.toDouble() ??
          double.tryParse(locationData['longitude'].toString());
      if (lat != null && lng != null) {
        return LatLng(lat, lng);
      }
    }
    return null;
  }
}

