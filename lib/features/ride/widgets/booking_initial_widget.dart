import 'package:flutter/material.dart';
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
    final backgroundColor = dark ? TColors.dark : Colors.grey[100];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(top: 24, left: 24, right: 24, bottom: 32),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag Handle
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
          const SizedBox(height: 24),

          // Greeting Header
          Row(
            children: [
              Text(
                'Hello there!',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: dark ? TColors.white : TColors.textPrimary,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(width: 8),
              const Text('👋', style: TextStyle(fontSize: 24)),
            ],
          ),

          const SizedBox(height: 24),

          // Service Cards (Ride & Package)
          Row(
            children: [
              Expanded(
                child: RideTypeCard(
                  title: 'Ride',
                  subtitle: 'Ride with favorite car',
                  imagePath: 'assets/images/content/car.png',
                  fallbackIcon: Icons.directions_car_filled_rounded,
                  onTap: onCarTap,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: RideTypeCard(
                  title: 'Package',
                  subtitle: 'Send items safely',
                  imagePath: 'assets/images/content/package.png',

                  fallbackIcon: Icons.local_shipping_rounded,
                  onTap: onPackageTap,
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Search Bar (Pill shaped, bottom)
          GestureDetector(
            onTap: onDestinationTap,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: dark ? TColors.darkerGrey : Colors.white,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.search_rounded,
                    color: const Color(0xFF27C073), // Bolt green-ish
                    size: 26,
                  ),
                  const SizedBox(width: 16),
                  Text(
                    'Where are you going?',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: dark ? TColors.lightGrey : TColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Recent Destinations (Optional)
          if (recentDestinations.isNotEmpty) ...[
            const SizedBox(height: 24),
            Text(
              'Recent destinations',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: dark ? TColors.white : TColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 70, // Compact height
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: recentDestinations.length,
                itemBuilder: (context, index) {
                  return RecentDestinationCard(
                    destination: recentDestinations[index],
                    onTap: () =>
                        onRecentDestinationTap(recentDestinations[index]),
                  );
                },
              ),
            ),
          ],

          const SizedBox(height: 20),
          const Center(child: LocationStatusIndicator()),
        ],
      ),
    );
  }
}
