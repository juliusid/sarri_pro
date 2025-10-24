import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:sarri_ride/features/location/services/location_service.dart';
import 'package:sarri_ride/features/location/services/places_service.dart';
import 'package:sarri_ride/utils/constants/colors.dart';
import 'package:sarri_ride/utils/helpers/helper_functions.dart';
import 'package:iconsax/iconsax.dart';

class MapPickerScreen extends StatefulWidget {
  final LatLng? initialLocation;
  final String title;

  const MapPickerScreen({
    super.key,
    this.initialLocation,
    this.title = 'Choose Location',
  });

  @override
  State<MapPickerScreen> createState() => _MapPickerScreenState();
}

class _MapPickerScreenState extends State<MapPickerScreen> {
  GoogleMapController? _mapController;
  final LocationService _locationService = LocationService.instance;
  
  LatLng? _selectedLocation;
  String _selectedAddress = 'Loading address...';
  bool _isLoadingAddress = false;
  bool _isConfirming = false;

  // Dark map style
  static const String _darkMapStyle = '''
    [
      {
        "elementType": "geometry",
        "stylers": [
          {
            "color": "#242f3e"
          }
        ]
      },
      {
        "elementType": "labels.text.fill",
        "stylers": [
          {
            "color": "#746855"
          }
        ]
      },
      {
        "elementType": "labels.text.stroke",
        "stylers": [
          {
            "color": "#242f3e"
          }
        ]
      }
    ]
  ''';

  @override
  void initState() {
    super.initState();
    _initializeLocation();
  }

  void _initializeLocation() {
    if (widget.initialLocation != null) {
      _selectedLocation = widget.initialLocation;
    } else {
      final position = _locationService.getLocationForMap();
      _selectedLocation = LatLng(position.latitude, position.longitude);
    }
    _getAddressFromLocation(_selectedLocation!);
  }

  CameraPosition get _initialCameraPosition {
    return CameraPosition(
      target: _selectedLocation!,
      zoom: 16.0,
    );
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    final dark = THelperFunctions.isDarkMode(context);
    if (dark) {
      controller.setMapStyle(_darkMapStyle);
    }
  }

  void _onCameraMove(CameraPosition position) {
    setState(() {
      _selectedLocation = position.target;
    });
  }

  void _onCameraIdle() {
    if (_selectedLocation != null) {
      _getAddressFromLocation(_selectedLocation!);
    }
  }

  Future<void> _getAddressFromLocation(LatLng location) async {
    setState(() {
      _isLoadingAddress = true;
    });

    try {
      final address = await PlacesService.getAddressFromCoordinates(
        location.latitude,
        location.longitude,
      );
      
      setState(() {
        _selectedAddress = address ?? 'Unknown location';
        _isLoadingAddress = false;
      });
    } catch (e) {
      setState(() {
        _selectedAddress = 'Unable to get address';
        _isLoadingAddress = false;
      });
    }
  }

  void _confirmLocation() async {
    if (_selectedLocation == null) return;

    setState(() {
      _isConfirming = true;
    });

    try {
      // Get detailed place information
      final placeDetails = await PlacesService.getPlaceDetailsFromCoordinates(
        _selectedLocation!.latitude,
        _selectedLocation!.longitude,
      );

      // Return the selected location and details
      Get.back(result: {
        'location': _selectedLocation,
        'address': _selectedAddress,
        'name': placeDetails?.name ?? _selectedAddress,
        'formattedAddress': placeDetails?.formattedAddress ?? _selectedAddress,
      });
    } catch (e) {
      // Return basic information if detailed lookup fails
      Get.back(result: {
        'location': _selectedLocation,
        'address': _selectedAddress,
        'name': _selectedAddress,
        'formattedAddress': _selectedAddress,
      });
    }

    setState(() {
      _isConfirming = false;
    });
  }

  void _getCurrentLocation() async {
    try {
      await _locationService.refreshLocation();
      final position = _locationService.getLocationForMap();
      final currentLocation = LatLng(position.latitude, position.longitude);

      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(currentLocation, 16.0),
      );

      THelperFunctions.showSnackBar('Moved to current location');
    } catch (e) {
      THelperFunctions.showSnackBar('Could not get current location');
    }
  }

  @override
  Widget build(BuildContext context) {
    final dark = THelperFunctions.isDarkMode(context);
    
    return Scaffold(
      body: Stack(
        children: [
          // Google Map
          GoogleMap(
            initialCameraPosition: _initialCameraPosition,
            onMapCreated: _onMapCreated,
            onCameraMove: _onCameraMove,
            onCameraIdle: _onCameraIdle,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            compassEnabled: false,
            style: dark ? _darkMapStyle : null,
            // Remove markers to show clean map with crosshair
            markers: const {},
          ),

          // Crosshair in center
          Center(
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: TColors.primary,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: const Icon(
                Icons.location_on,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),

          // App bar
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: (dark ? TColors.dark : Colors.white).withOpacity(0.95),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Get.back(),
                      icon: Icon(
                        Icons.arrow_back,
                        color: dark ? TColors.white : TColors.black,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        widget.title,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(width: 48), // Balance the back button
                  ],
                ),
              ),
            ),
          ),

          // Current location button
          Positioned(
            top: MediaQuery.of(context).padding.top + 80,
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
              child: IconButton(
                onPressed: _getCurrentLocation,
                icon: Icon(
                  Icons.my_location,
                  color: TColors.primary,
                ),
              ),
            ),
          ),

          // Bottom sheet with address and confirm button
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: dark ? TColors.dark : Colors.white,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Drag handle
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: dark ? TColors.lightGrey : TColors.darkGrey,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 20),

                    // Selected location info
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: TColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Iconsax.location,
                            color: TColors.primary,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Selected Location',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: dark ? TColors.lightGrey : TColors.darkGrey,
                                ),
                              ),
                              const SizedBox(height: 4),
                              _isLoadingAddress
                                  ? Row(
                                      children: [
                                        SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor: AlwaysStoppedAnimation<Color>(
                                              TColors.primary,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Getting address...',
                                          style: Theme.of(context).textTheme.bodyMedium,
                                        ),
                                      ],
                                    )
                                  : Text(
                                      _selectedAddress,
                                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Confirm button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isConfirming || _isLoadingAddress ? null : _confirmLocation,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: TColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isConfirming
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Iconsax.tick_circle,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Confirm Location',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
} 