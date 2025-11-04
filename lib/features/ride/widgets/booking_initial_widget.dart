import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sarri_ride/features/location/services/location_service.dart';
import 'package:sarri_ride/utils/constants/colors.dart';
import 'package:sarri_ride/utils/helpers/helper_functions.dart';
import 'package:sarri_ride/features/ride/widgets/ride_type_card.dart';
import 'package:sarri_ride/features/ride/widgets/recent_destination_card.dart';
import 'package:sarri_ride/features/ride/widgets/location_status_indicator.dart';

class BookingInitialWidget extends StatelessWidget {
  final VoidCallback onDestinationTap;
  final VoidCallback onCarTap;
  final VoidCallback onPackageTap;
  final VoidCallback onFreightTap;
  final List<Map<String, dynamic>> recentDestinations;
  final Function(Map<String, dynamic>) onRecentDestinationTap;

  const BookingInitialWidget({
    super.key,
    required this.onDestinationTap,
    required this.onCarTap,
    required this.onPackageTap,
    required this.onFreightTap,
    required this.recentDestinations,
    required this.onRecentDestinationTap,
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
                color: dark ? TColors.darkerGrey : Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Where are you going input (disabled)
          GestureDetector(
            onTap: onDestinationTap,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: dark
                    ? TColors.darkerGrey.withOpacity(0.3)
                    : Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: dark ? TColors.darkerGrey : Colors.grey[300]!,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.search,
                    color: dark ? TColors.lightGrey : Colors.grey[600],
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Where are you going?',
                      style: TextStyle(
                        color: dark ? TColors.lightGrey : Colors.grey[600],
                        fontSize: 16,
                      ),
                    ),
                  ),
                  Icon(Icons.location_on, color: TColors.primary, size: 20),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Choose a ride title
          Text(
            'Choose a ride',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: dark ? TColors.white : TColors.black,
            ),
          ),

          const SizedBox(height: 16),

          // Ride type options
          Row(
            children: [
              Expanded(
                child: RideTypeCard(
                  title: 'Car',
                  icon: Icons.directions_car,
                  color: TColors.primary,
                  onTap: onCarTap,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: RideTypeCard(
                  title: 'Package',
                  icon: Icons.local_shipping,
                  color: TColors.info,
                  onTap: onPackageTap,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: RideTypeCard(
                  title: 'Freight',
                  icon: Icons.local_shipping_outlined,
                  color: TColors.warning,
                  onTap: onFreightTap,
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Recent destinations section
          Text(
            'Recent destinations',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: dark ? TColors.white : TColors.black,
            ),
          ),

          const SizedBox(height: 12),

          // Recent destinations list
          SizedBox(
            height: 120,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: recentDestinations.length,
              itemBuilder: (context, index) {
                final destination = recentDestinations[index];
                return RecentDestinationCard(
                  destination: destination,
                  onTap: () => onRecentDestinationTap(destination),
                );
              },
            ),
          ),

          const SizedBox(height: 20),

          // Location status indicator
          const LocationStatusIndicator(),
        ],
      ),
    );
  }
}
