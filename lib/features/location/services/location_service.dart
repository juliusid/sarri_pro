import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:sarri_ride/utils/helpers/helper_functions.dart';

class LocationService extends GetxController {
  static LocationService get instance => Get.find();

  final Rx<Position?> _currentPosition = Rx<Position?>(null);
  final RxBool _isLocationEnabled = false.obs;
  final RxBool _isLocationLoading = false.obs;
  final RxString _locationStatus = 'Available'.obs;

  // Default location (Lagos, Nigeria)
  static final Position _defaultPosition = Position(
    latitude: 6.5244,
    longitude: 3.3792,
    timestamp: DateTime.now(),
    accuracy: 0,
    altitude: 0,
    altitudeAccuracy: 0,
    heading: 0,
    headingAccuracy: 0,
    speed: 0,
    speedAccuracy: 0,
  );

  Position? get currentPosition => _currentPosition.value;
  bool get isLocationEnabled => _isLocationEnabled.value;
  bool get isLocationLoading => _isLocationLoading.value;
  String get locationStatus => _locationStatus.value;

  @override
  void onInit() {
    super.onInit();
    _currentPosition.value = _defaultPosition;
  }

  // --- THIS IS THE NEW, AWAITABLE INITIALIZATION METHOD ---
  Future<void> initialize() async {
    _isLocationLoading.value = true;
    _locationStatus.value = 'Checking permissions...';
    update(); // Notifies the splash screen UI

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _locationStatus.value = 'Location services are disabled.';
        _isLocationLoading.value = false;
        update();
        return; // Stop if location is turned off on the phone
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        _locationStatus.value = 'Requesting location permission...';
        update();
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied ||
            permission == LocationPermission.deniedForever) {
          _locationStatus.value = 'Permission denied. Using default location.';
          _isLocationLoading.value = false;
          update();
          return; // Stop if user denies permission
        }
      }

      _isLocationEnabled.value = true;
      _locationStatus.value = 'Getting your location...';
      update();

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      _currentPosition.value = position;
      _locationStatus.value = 'Location ready!';
    } catch (e) {
      _locationStatus.value = 'Could not get location. Using default.';
      print('Location error (using default): $e');
    } finally {
      _isLocationLoading.value = false;
      update(); // Final update to the UI
    }
  }

  Future<Position?> getCurrentLocation() async {
    if (!_isLocationEnabled.value) {
      return _currentPosition.value ?? _defaultPosition;
    }

    try {
      _isLocationLoading.value = true;

      final position =
          await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.medium,
            timeLimit: const Duration(seconds: 3), // Very short timeout
          ).timeout(
            const Duration(seconds: 4), // Additional timeout
            onTimeout: () => _currentPosition.value ?? _defaultPosition,
          );

      _currentPosition.value = position;
      return position;
    } catch (e) {
      // Return current position or default without showing errors
      return _currentPosition.value ?? _defaultPosition;
    } finally {
      _isLocationLoading.value = false;
    }
  }

  void ensureLocationAvailable() {
    if (_currentPosition.value == null) {
      _currentPosition.value = _defaultPosition;
    }
  }

  Position getLocationForMap() {
    return _currentPosition.value ?? _defaultPosition;
  }

  Future<bool> requestLocationPermission() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always) {
        _isLocationEnabled.value = true;
        await initialize();
        return true;
      }

      return false;
    } catch (e) {
      return false;
    }
  }

  Future<bool> isLocationServiceEnabled() async {
    try {
      return await Geolocator.isLocationServiceEnabled();
    } catch (e) {
      return false;
    }
  }

  Future<void> openLocationSettings() async {
    try {
      await Geolocator.openLocationSettings();
    } catch (e) {
      THelperFunctions.showSnackBar('Unable to open location settings');
    }
  }

  double calculateDistance(Position start, Position end) {
    try {
      return Geolocator.distanceBetween(
        start.latitude,
        start.longitude,
        end.latitude,
        end.longitude,
      );
    } catch (e) {
      return 0.0;
    }
  }

  // Force refresh location
  Future<void> refreshLocation() async {
    await initialize();
  }
}
