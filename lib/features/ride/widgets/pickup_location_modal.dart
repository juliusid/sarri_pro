import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:sarri_ride/utils/constants/colors.dart'; //
import 'package:sarri_ride/utils/helpers/helper_functions.dart'; //
import 'package:sarri_ride/features/location/services/location_service.dart'; //
import 'package:sarri_ride/features/location/services/places_service.dart'; //

class PickupLocationModal extends StatefulWidget {
  final Function(PlaceSuggestion) onLocationSelected;
  final VoidCallback onCurrentLocationPressed;
  final VoidCallback onMapPickerPressed;

  const PickupLocationModal({
    super.key,
    required this.onLocationSelected,
    required this.onCurrentLocationPressed,
    required this.onMapPickerPressed,
  });

  // --- MOVED THE STATIC METHOD HERE ---
  static void show(
    BuildContext context, {
    required Function(PlaceSuggestion) onLocationSelected,
    required VoidCallback onCurrentLocationPressed,
    required VoidCallback onMapPickerPressed,
  }) {
    final dark = THelperFunctions.isDarkMode(context); //

    showModalBottomSheet(
      context: context,
      backgroundColor: dark ? TColors.dark : Colors.white, //
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        // Pass the required arguments to the constructor
        return PickupLocationModal(
          onLocationSelected: onLocationSelected,
          onCurrentLocationPressed: onCurrentLocationPressed,
          onMapPickerPressed: onMapPickerPressed,
        );
      },
    );
  }
  // --- END OF MOVED METHOD ---

  @override
  State<PickupLocationModal> createState() => _PickupLocationModalState();
}

class _PickupLocationModalState extends State<PickupLocationModal> {
  final TextEditingController _searchController = TextEditingController();
  List<PlaceSuggestion> _suggestions = [];
  bool _showSuggestions = false;
  bool _isLoading = false; // Added loading state

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _searchLocation(String query) async {
    if (query.length >= 3) {
      setState(() {
        _isLoading = true; // Start loading
        _showSuggestions = true; // Show loading indicator area
        _suggestions.clear();
      });
      try {
        // Use the LocationService to get the current location for biasing results
        final locationService = LocationService.instance; //
        final currentCoords = locationService.currentPosition != null
            ? LatLng(
                locationService.currentPosition!.latitude,
                locationService.currentPosition!.longitude,
              )
            : null;

        final suggestions = await PlacesService.getPlaceSuggestions(
          query,
          location: currentCoords,
        ); //
        if (mounted) {
          // Check if widget is still in the tree
          setState(() {
            _suggestions = suggestions;
            _isLoading = false; // Stop loading
          });
        }
      } catch (e) {
        print("Error searching places: $e");
        if (mounted) {
          setState(() {
            _suggestions = [];
            _showSuggestions = false; // Hide if error
            _isLoading = false; // Stop loading
          });
          THelperFunctions.showSnackBar('Error searching locations.'); //
        }
      }
    } else {
      if (mounted) {
        setState(() {
          _showSuggestions = false;
          _suggestions.clear();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final dark = THelperFunctions.isDarkMode(context); //

    return Container(
      // Allow height to adjust based on content, up to a max
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85, // Max height
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min, // Make column height fit content
        children: [
          // Drag Handle (Optional but good UX)
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: dark ? TColors.darkGrey : Colors.grey[300], //
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Change Pickup Location',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: dark ? TColors.white : TColors.black, //
            ),
          ),
          const SizedBox(height: 20),

          // Manual entry with autocomplete
          TextField(
            controller: _searchController,
            style: TextStyle(
              color: dark ? TColors.white : TColors.black, //
            ),
            decoration: InputDecoration(
              hintText: 'Enter pickup address',
              hintStyle: TextStyle(
                color: dark ? TColors.lightGrey : Colors.grey[600], //
              ),
              prefixIcon: Icon(Icons.search, color: TColors.primary), //
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: Icon(
                        Icons.clear,
                        color: dark ? TColors.lightGrey : Colors.grey[600],
                      ), //
                      onPressed: () {
                        _searchController.clear();
                        _searchLocation(''); // Clear suggestions
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none, // Remove default border
              ),
              enabledBorder: OutlineInputBorder(
                // Custom border when not focused
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: dark
                      ? TColors.darkGrey
                      : TColors.grey.withOpacity(0.5),
                ), //
              ),
              focusedBorder: OutlineInputBorder(
                // Custom border when focused
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: TColors.primary, width: 1.5), //
              ),
              filled: true,
              fillColor: dark
                  ? TColors.darkerGrey.withOpacity(0.5)
                  : Colors.grey.shade100, //
              contentPadding: const EdgeInsets.symmetric(
                vertical: 14,
              ), // Adjust padding
            ),
            onChanged: _searchLocation,
            textInputAction: TextInputAction.search,
          ),

          const SizedBox(height: 16),

          // --- Flexible area for suggestions or default options ---
          Flexible(
            // Use Flexible to allow this section to take remaining space
            child: _buildSuggestionsOrOptions(dark),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestionsOrOptions(bool dark) {
    if (_showSuggestions) {
      if (_isLoading) {
        return const Center(child: CircularProgressIndicator());
      }
      if (_suggestions.isEmpty && _searchController.text.length >= 3) {
        return const Center(child: Text('No locations found.'));
      }
      // Display Suggestions
      return ListView.separated(
        shrinkWrap: true, // Important for Column layout
        itemCount: _suggestions.length,
        separatorBuilder: (_, __) => Divider(
          height: 1,
          color: dark ? TColors.darkGrey : TColors.lightGrey,
        ), //
        itemBuilder: (context, index) {
          final suggestion = _suggestions[index];
          return ListTile(
            leading: Icon(
              Icons.location_on_outlined, // Use outline icon
              color: dark ? TColors.lightGrey : Colors.grey[600], //
            ),
            title: Text(
              suggestion.mainText,
              style: TextStyle(
                color: dark ? TColors.white : TColors.black, //
                fontWeight: FontWeight.w500,
              ),
            ),
            subtitle: suggestion.secondaryText.isNotEmpty
                ? Text(
                    suggestion.secondaryText,
                    style: TextStyle(
                      color: dark
                          ? TColors.lightGrey.withOpacity(0.7)
                          : Colors.grey[600], //
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  )
                : null,
            onTap: () {
              Navigator.pop(context); // Close the modal
              widget.onLocationSelected(
                suggestion,
              ); // Pass selected suggestion back
            },
          );
        },
      );
    } else {
      // Display Default Options (Current Location, Choose on Map)
      return Column(
        mainAxisSize: MainAxisSize.min, // Keep column height minimal
        children: [
          // Use current location option
          GetBuilder<LocationService>(
            //
            builder: (locationService) {
              return ListTile(
                leading: Icon(
                  Icons.my_location,
                  color: locationService.isLocationEnabled
                      ? TColors.primary
                      : TColors.grey, //
                ),
                title: Text(
                  'Use current location',
                  style: TextStyle(
                    color: dark ? TColors.white : TColors.black, //
                  ),
                ),
                subtitle: Text(
                  locationService.isLocationLoading
                      ? 'Getting location...'
                      : locationService.isLocationEnabled
                      ? 'GPS location detected'
                      : 'Enable location services',
                  style: TextStyle(
                    fontSize: 12,
                    color: locationService.isLocationLoading
                        ? (dark ? TColors.lightGrey : TColors.darkGrey) //
                        : locationService.isLocationEnabled
                        ? TColors
                              .success //
                        : TColors.error, //
                  ),
                ),
                onTap:
                    locationService.isLocationLoading ||
                        !locationService.isLocationEnabled
                    ? null // Disable tap if loading or disabled
                    : () {
                        Navigator.pop(context); // Close the modal
                        widget.onCurrentLocationPressed(); // Trigger callback
                      },
                enabled:
                    !locationService.isLocationLoading &&
                    locationService.isLocationEnabled,
              );
            },
          ),

          Divider(
            height: 1,
            color: dark ? TColors.darkGrey : TColors.lightGrey,
          ), //
          // Choose on map option
          ListTile(
            leading: Icon(
              Icons.map_outlined, // Use outline icon
              color: TColors.primary, //
            ),
            title: Text(
              'Choose on map',
              style: TextStyle(
                color: dark ? TColors.white : TColors.black, //
              ),
            ),
            subtitle: Text(
              'Select pickup location manually',
              style: TextStyle(
                fontSize: 12,
                color: dark ? TColors.lightGrey : Colors.grey[600], //
              ),
            ),
            onTap: () {
              Navigator.pop(context); // Close the modal
              widget.onMapPickerPressed(); // Trigger callback
            },
          ),
        ],
      );
    }
  }
} // End of _PickupLocationModalState
