import 'dart:async';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:get/get.dart';
import 'dart:ui' as ui;

class MapMarkerService extends GetxService {
  static MapMarkerService get instance => Get.find();

  // Initialize with null, but we will try to fill them
  BitmapDescriptor? driverIcon;
  BitmapDescriptor? pickupIcon;
  BitmapDescriptor? destinationIcon;
  BitmapDescriptor? currentLocationIcon;

  // --- CHANGED: Return Future<MapMarkerService> for Get.putAsync ---
  Future<MapMarkerService> init() async {
    print("Initializing MapMarkerService...");
    try {
      // Load all icons in parallel for speed
      final results = await Future.wait([
        _loadSafeIcon('assets/icons/maps/car (1).png', 70),
        _loadSafeIcon('assets/icons/maps/Map pin (3).png', 80),
        _loadSafeIcon('assets/icons/maps/Map pin (4).png', 80),
        _loadSafeIcon('assets/icons/maps/currentLocation.png', 100),
      ]);

      driverIcon = results[0];
      pickupIcon = results[1];
      destinationIcon = results[2];
      currentLocationIcon = results[3];

      print("MapMarkerService: All icons loaded.");
    } catch (e) {
      // Catch global errors (like platform channel issues)
      print("CRITICAL ERROR loading map markers: $e");
      // Fallback defaults to prevent crash
      driverIcon ??= BitmapDescriptor.defaultMarker;
      pickupIcon ??= BitmapDescriptor.defaultMarkerWithHue(
        BitmapDescriptor.hueGreen,
      );
      destinationIcon ??= BitmapDescriptor.defaultMarkerWithHue(
        BitmapDescriptor.hueRed,
      );
      currentLocationIcon ??= BitmapDescriptor.defaultMarkerWithHue(
        BitmapDescriptor.hueBlue,
      );
    }
    // --- CRITICAL: Must return 'this' for Get.putAsync ---
    return this;
  }

  // Helper to safely load icon or return default on error
  Future<BitmapDescriptor> _loadSafeIcon(String path, int width) async {
    try {
      final bytes = await _getBytesFromAsset(path, width);
      return BitmapDescriptor.fromBytes(bytes);
    } catch (e) {
      print(
        "Warning: Could not load asset '$path'. Using default marker. Error: $e",
      );
      return BitmapDescriptor.defaultMarker;
    }
  }

  Future<Uint8List> _getBytesFromAsset(String path, int width) async {
    ByteData data = await rootBundle.load(path);
    ui.Codec codec = await ui.instantiateImageCodec(
      data.buffer.asUint8List(),
      targetWidth: width,
    );
    ui.FrameInfo fi = await codec.getNextFrame();
    return (await fi.image.toByteData(
      format: ui.ImageByteFormat.png,
    ))!.buffer.asUint8List();
  }
}
