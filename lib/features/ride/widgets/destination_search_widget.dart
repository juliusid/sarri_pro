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
    final backgroundColor = dark ? TColors.dark : TColors.white;
    final inputFillColor = dark ? TColors.darkerGrey : const Color(0xFFF5F5F5);
    final textColor = dark ? TColors.white : TColors.textPrimary;
    final hintColor = dark ? TColors.lightGrey : TColors.textSecondary;

    return Container(
      color: backgroundColor,
      child: SafeArea(
        child: Column(
          children: [
            // --- HEADER & INPUTS ---
            Container(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              decoration: BoxDecoration(
                color: backgroundColor,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Back Button & Title
                  Row(
                    children: [
                      InkWell(
                        onTap: onBackPressed,
                        borderRadius: BorderRadius.circular(20),
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Icon(
                            Icons.arrow_back,
                            color: textColor,
                            size: 24,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        "Plan your ride",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: textColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // INPUT GROUP
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Visual Connector (Timeline)
                      Padding(
                        padding: const EdgeInsets.only(
                          top: 14,
                          right: 12,
                          left: 4,
                        ),
                        child: Column(
                          children: [
                            // Start Dot
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: dark
                                    ? Colors.grey[400]
                                    : Colors.grey[600],
                                shape: BoxShape.circle,
                              ),
                            ),
                            // Line
                            Container(
                              width: 2,
                              height:
                                  45, // Height spanning the distance between inputs
                              color: dark ? Colors.grey[700] : Colors.grey[300],
                              margin: const EdgeInsets.symmetric(vertical: 4),
                            ),
                            // End Square
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: TColors.primary,
                                shape: BoxShape.rectangle,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Input Fields Container
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: inputFillColor,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: dark
                                  ? Colors.transparent
                                  : Colors.grey.withOpacity(0.2),
                            ),
                          ),
                          child: Column(
                            children: [
                              // Pickup Input (Touchable)
                              InkWell(
                                onTap: onPickupLocationChangePressed,
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(12),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 14,
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          pickupController.text.isEmpty
                                              ? "Current Location"
                                              : pickupController.text,
                                          style: TextStyle(
                                            color: pickupController.text.isEmpty
                                                ? TColors.primary
                                                : textColor,
                                            fontSize: 15,
                                            fontWeight: FontWeight.w500,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              // Divider
                              Divider(
                                height: 1,
                                color: dark ? TColors.dark : Colors.grey[300],
                              ),

                              // Destination Input (Actual TextField)
                              TextField(
                                controller: destinationController,
                                autofocus: true,
                                onChanged: onDestinationChanged,
                                style: TextStyle(
                                  color: textColor,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                ),
                                decoration: InputDecoration(
                                  hintText: "Where to?",
                                  hintStyle: TextStyle(color: hintColor),
                                  border: InputBorder.none,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 14,
                                  ),
                                  isDense: true,
                                  suffixIcon:
                                      destinationController.text.isNotEmpty
                                      ? GestureDetector(
                                          onTap: () {
                                            destinationController.clear();
                                            onDestinationChanged('');
                                          },
                                          child: Icon(
                                            Icons.cancel,
                                            size: 18,
                                            color: hintColor,
                                          ),
                                        )
                                      : null,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Add Stop Button (Optional, can be added later)
                      // const SizedBox(width: 8),
                      // IconButton(icon: Icon(Icons.add, color: textColor), onPressed: (){}),
                    ],
                  ),
                ],
              ),
            ),

            // --- SUGGESTIONS LIST ---
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  if (showDestinationSuggestions &&
                      destinationSuggestions.isNotEmpty) ...[
                    // AUTOCOMPLETE RESULTS
                    ...destinationSuggestions.map((suggestion) {
                      return _buildLocationItem(
                        context,
                        icon: Icons.location_on_rounded,
                        title: suggestion.mainText,
                        subtitle: suggestion.secondaryText,
                        onTap: () => onSuggestionTap(suggestion),
                        dark: dark,
                      );
                    }),
                  ] else ...[
                    // RECENT SEARCHES
                    if (recentDestinations.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
                        child: Text(
                          'Recent',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                      ),

                    ...recentDestinations.map((destination) {
                      final dist = calculateDistanceToDestination(
                        destination['location'] as LatLng,
                      );
                      return _buildLocationItem(
                        context,
                        icon: destination['icon'] as IconData? ?? Icons.history,
                        title: destination['name'] as String,
                        subtitle: destination['address'] as String,
                        trailing: '${dist.toStringAsFixed(1)} km',
                        onTap: () => onRecentDestinationTap(destination),
                        dark: dark,
                      );
                    }),

                    // FALLBACK / EMPTY STATE (Optional)
                    if (recentDestinations.isEmpty &&
                        destinationController.text.isEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 40),
                        child: Center(
                          child: Column(
                            children: [
                              Icon(
                                Icons.map_outlined,
                                size: 48,
                                color: hintColor.withOpacity(0.5),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                "Search for a destination",
                                style: TextStyle(color: hintColor),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    String? trailing,
    required VoidCallback onTap,
    required bool dark,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: dark ? TColors.darkerGrey : const Color(0xFFEEEEEE),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 22,
                color: dark ? TColors.lightGrey : Colors.grey[700],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      color: dark ? TColors.white : TColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: dark ? TColors.lightGrey : TColors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: 8),
              Text(
                trailing,
                style: TextStyle(
                  fontSize: 12,
                  color: dark ? TColors.lightGrey : TColors.textSecondary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
