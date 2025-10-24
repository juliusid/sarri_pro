import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:sarri_ride/utils/constants/colors.dart';
import 'package:sarri_ride/utils/helpers/helper_functions.dart';
import 'package:sarri_ride/features/location/services/places_service.dart';

class DestinationSearchWidget extends StatelessWidget {
  final VoidCallback onBackPressed;
  final TextEditingController pickupController;
  final TextEditingController destinationController;
  final VoidCallback onPickupLocationChangePressed;
  final Function(String) onDestinationChanged;
  final bool showDestinationSuggestions;
  final List<PlaceSuggestion> destinationSuggestions;
  final Function(PlaceSuggestion) onSuggestionTap;
  final List<Map<String, dynamic>> recentDestinations;
  final Function(Map<String, dynamic>) onRecentDestinationTap;
  final Function(LatLng) calculateDistanceToDestination;

  const DestinationSearchWidget({
    super.key,
    required this.onBackPressed,
    required this.pickupController,
    required this.destinationController,
    required this.onPickupLocationChangePressed,
    required this.onDestinationChanged,
    required this.showDestinationSuggestions,
    required this.destinationSuggestions,
    required this.onSuggestionTap,
    required this.recentDestinations,
    required this.onRecentDestinationTap,
    required this.calculateDistanceToDestination,
  });

  @override
  Widget build(BuildContext context) {
    final dark = THelperFunctions.isDarkMode(context);
    
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: dark ? TColors.dark : TColors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: dark ? TColors.darkGrey : Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          
          // Header with back button
          Row(
            children: [
              IconButton(
                onPressed: onBackPressed,
                icon: Icon(
                  Icons.arrow_back,
                  color: dark ? TColors.white : TColors.black,
                ),
              ),
              Text(
                'Choose a ride',
                style: TextStyle(
                  fontSize: 18, 
                  fontWeight: FontWeight.bold,
                  color: dark ? TColors.white : TColors.black,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          // Pickup location with change option
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: dark ? TColors.darkerGrey.withOpacity(0.3) : Colors.white,
              border: Border.all(
                color: dark ? TColors.darkerGrey : Colors.grey[300]!,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.my_location, color: TColors.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Pickup Location',
                        style: TextStyle(
                          fontSize: 12,
                          color: dark ? TColors.lightGrey : Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        pickupController.text,
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          color: dark ? TColors.white : TColors.black,
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: onPickupLocationChangePressed,
                  child: Text(
                    'Change',
                    style: TextStyle(color: TColors.primary),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Destination input with enhanced autocomplete
          TextField(
            controller: destinationController,
            style: TextStyle(
              color: dark ? TColors.white : TColors.black,
            ),
            decoration: InputDecoration(
              hintText: 'Where to?',
              hintStyle: TextStyle(
                color: dark ? TColors.lightGrey : Colors.grey[600],
              ),
              prefixIcon: const Icon(Icons.location_on, color: Colors.red),
              suffixIcon: destinationController.text.isNotEmpty
                  ? IconButton(
                      icon: Icon(
                        Icons.clear,
                        color: dark ? TColors.lightGrey : Colors.grey[600],
                      ),
                      onPressed: () {
                        destinationController.clear();
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: dark ? TColors.darkerGrey : Colors.grey[300]!,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: dark ? TColors.darkGrey : Colors.grey[300]!,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: TColors.primary,
                  width: 2,
                ),
              ),
              filled: true,
              fillColor: dark ? TColors.darkerGrey.withOpacity(0.3) : Colors.white,
            ),
            onChanged: onDestinationChanged,
            autofocus: true,
          ),
          
          const SizedBox(height: 20),
          
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Show autocomplete suggestions if available
                  if (showDestinationSuggestions && destinationSuggestions.isNotEmpty) ...[
                    Text(
                      'Suggestions',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: dark ? TColors.white : TColors.black,
                      ),
                    ),
                    const SizedBox(height: 12),
                    
                    ...List.generate(destinationSuggestions.length, (index) {
                      final suggestion = destinationSuggestions[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                          leading: Icon(
                            Icons.location_on,
                            color: dark ? TColors.lightGrey : Colors.grey,
                          ),
                          title: Text(
                            suggestion.mainText,
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                              color: dark ? TColors.white : TColors.black,
                            ),
                          ),
                          subtitle: Text(
                            suggestion.secondaryText,
                            style: TextStyle(
                              color: dark ? TColors.lightGrey : Colors.grey[600],
                            ),
                          ),
                          onTap: () => onSuggestionTap(suggestion),
                        ),
                      );
                    }),
                  ] else if (destinationController.text.isEmpty) ...[
                    // Show recent searches when input is empty
                    Text(
                      'Recent searches',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: dark ? TColors.white : TColors.black,
                      ),
                    ),
                    const SizedBox(height: 12),
                    
                    // Recent destinations as quick options
                    ...List.generate(recentDestinations.length.clamp(0, 3), (index) {
                      final destination = recentDestinations[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                          leading: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: TColors.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Icon(
                              destination['icon'] as IconData,
                              color: TColors.primary,
                              size: 20,
                            ),
                          ),
                          title: Text(
                            destination['name'] as String,
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                              color: dark ? TColors.white : TColors.black,
                            ),
                          ),
                          subtitle: Text(
                            destination['address'] as String,
                            style: TextStyle(
                              color: dark ? TColors.lightGrey : Colors.grey[600],
                            ),
                          ),
                          trailing: Text(
                            '~${calculateDistanceToDestination(destination['location'] as LatLng).toStringAsFixed(1)} km',
                            style: TextStyle(
                              color: dark ? TColors.lightGrey : Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                          onTap: () => onRecentDestinationTap(destination),
                        ),
                      );
                    }),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
} 