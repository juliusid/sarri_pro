import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:sarri_ride/features/ride/controllers/client_trip_history_controller.dart';
import 'package:sarri_ride/features/ride/controllers/ride_controller.dart';
import 'package:sarri_ride/features/ride/models/ride_model.dart';
import 'package:sarri_ride/utils/constants/colors.dart';
import 'package:sarri_ride/utils/constants/sizes.dart';
import 'package:sarri_ride/utils/helpers/helper_functions.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';

class RideHistoryScreen extends StatelessWidget {
  const RideHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(ClientTripHistoryController());
    final dark = THelperFunctions.isDarkMode(context);

    return Scaffold(
      backgroundColor: dark ? TColors.dark : TColors.lightGrey,
      appBar: AppBar(
        title: const Text('Ride History'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Get.back(),
          icon: Icon(
            Iconsax.arrow_left_2,
            color: dark ? TColors.light : TColors.dark,
            size: TSizes.iconLg,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () => _showFilterDialog(context, dark, controller),
            icon: Icon(
              Iconsax.filter,
              color: dark ? TColors.light : TColors.dark,
              size: TSizes.iconLg,
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header Card
            Container(
              width: double.infinity,
              margin: const EdgeInsets.all(TSizes.defaultSpace),
              padding: const EdgeInsets.all(TSizes.defaultSpace),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [TColors.info, TColors.info.withOpacity(0.8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(TSizes.cardRadiusLg),
                boxShadow: [
                  BoxShadow(
                    color: TColors.info.withOpacity(0.3),
                    blurRadius: TSizes.md,
                    offset: const Offset(0, TSizes.sm),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(TSizes.md),
                        decoration: BoxDecoration(
                          color: TColors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(
                            TSizes.cardRadiusMd,
                          ),
                        ),
                        child: const Icon(
                          Iconsax.route_square,
                          color: TColors.white,
                          size: TSizes.iconLg,
                        ),
                      ),
                      const SizedBox(width: TSizes.spaceBtwItems),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Your Ride History',
                              style: Theme.of(context).textTheme.headlineSmall
                                  ?.copyWith(
                                    color: TColors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            const SizedBox(height: TSizes.xs),
                            Text(
                              'Track all your completed trips and journeys',
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(
                                    color: TColors.white.withOpacity(0.8),
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Stats Cards Row
            Container(
              margin: const EdgeInsets.symmetric(
                horizontal: TSizes.defaultSpace,
              ),
              child: Obx(
                () => controller.isLoading.value && controller.trips.isEmpty
                    ? const SizedBox(
                        height: 85,
                        child: Center(child: CircularProgressIndicator()),
                      )
                    : Row(
                        children: [
                          Expanded(
                            child: _buildStatCard(
                              title: 'Total Rides',
                              value: (controller.summary['total'] ?? 0)
                                  .toString(),
                              icon: Iconsax.car,
                              color: TColors.primary,
                              dark: dark,
                              context: context,
                            ),
                          ),
                          const SizedBox(width: TSizes.spaceBtwItems),
                          Expanded(
                            child: _buildStatCard(
                              title: 'This Month',
                              value:
                                  (controller.timePeriods['thisMonth']?['trips'] ??
                                          0)
                                      .toString(),
                              icon: Iconsax.calendar,
                              color: TColors.success,
                              dark: dark,
                              context: context,
                            ),
                          ),
                        ],
                      ),
              ),
            ),

            const SizedBox(height: TSizes.spaceBtwSections),

            // Recent Rides Section
            Container(
              margin: const EdgeInsets.symmetric(
                horizontal: TSizes.defaultSpace,
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(TSizes.cardRadiusLg),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Your Rides',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: dark ? TColors.white : TColors.black,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: TSizes.spaceBtwItems),

                  // Ride history list
                  Obx(() {
                    if (controller.isLoading.value &&
                        controller.trips.isEmpty) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (controller.trips.isEmpty) {
                      return const Center(child: Text('No trips found.'));
                    }

                    return ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: controller.hasNextPage.value
                          ? controller.trips.length + 1
                          : controller.trips.length,
                      itemBuilder: (context, index) {
                        if (index == controller.trips.length) {
                          return controller.isLoadingMore.value
                              ? const Center(
                                  child: Padding(
                                    padding: EdgeInsets.all(16.0),
                                    child: CircularProgressIndicator(),
                                  ),
                                )
                              : OutlinedButton.icon(
                                  onPressed: () => controller.loadMore(),
                                  icon: Icon(
                                    Iconsax.arrow_down,
                                    size: TSizes.iconSm,
                                  ),
                                  label: const Text('Load More Rides'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: TColors.primary,
                                    side: BorderSide(color: TColors.primary),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: TSizes.sm,
                                    ),
                                  ),
                                );
                        }

                        final trip = controller.trips[index];
                        return _buildRideCard(trip, dark, context);
                      },
                    );
                  }),
                ],
              ),
            ),

            const SizedBox(height: TSizes.spaceBtwSections),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required bool dark,
    required BuildContext context,
  }) {
    return Container(
      padding: const EdgeInsets.all(TSizes.defaultSpace),
      decoration: BoxDecoration(
        color: dark ? TColors.dark : TColors.white,
        borderRadius: BorderRadius.circular(TSizes.cardRadiusLg),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(dark ? 0.3 : 0.1),
            blurRadius: TSizes.md,
            offset: const Offset(0, TSizes.sm),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(TSizes.md),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(TSizes.cardRadiusMd),
            ),
            child: Icon(icon, color: color, size: TSizes.iconLg),
          ),
          const SizedBox(height: TSizes.spaceBtwItems),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: dark ? TColors.white : TColors.black,
            ),
          ),
          const SizedBox(height: TSizes.xs),
          Text(
            title,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: dark ? TColors.lightGrey : TColors.darkGrey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRideCard(
    Map<String, dynamic> ride,
    bool dark,
    BuildContext context,
  ) {
    final status = ride['status']?.toString() ?? 'unknown';
    final color = _getStatusColor(status);

    final dateString =
        ride['completedAt'] ?? ride['cancelledAt'] ?? ride['bookedAt'];
    final dateTime = DateTime.tryParse(dateString ?? '');

    final driverName = ride['driver']?['name'] ?? 'N/A';
    final carModel = ride['vehicle']?['model'] ?? 'Car';

    double driverRating = 4.5;
    final rawRating = ride['driver']?['rating'];

    if (rawRating is num) {
      driverRating = rawRating.toDouble();
    } else if (rawRating is Map) {
      final avg = rawRating['average'];
      if (avg is num) {
        driverRating = avg.toDouble();
      }
    }

    double price = 0.0;
    final rawPrice = ride['price'];
    if (rawPrice is num) {
      price = rawPrice.toDouble();
    } else if (rawPrice is Map && rawPrice['\$numberDecimal'] != null) {
      price = double.tryParse(rawPrice['\$numberDecimal'].toString()) ?? 0.0;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: TSizes.defaultSpace),
      padding: const EdgeInsets.all(TSizes.defaultSpace),
      decoration: BoxDecoration(
        color: dark ? TColors.dark : TColors.white,
        borderRadius: BorderRadius.circular(TSizes.cardRadiusLg),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(dark ? 0.3 : 0.1),
            blurRadius: TSizes.md,
            offset: const Offset(0, TSizes.sm),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with status
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                dateTime != null ? _formatTripDate(dateTime) : 'Unknown Date',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: dark ? TColors.white : TColors.black,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: TSizes.sm,
                  vertical: TSizes.xs,
                ),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(TSizes.cardRadiusLg),
                ),
                child: Text(
                  status.capitalizeFirst ?? status,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: TSizes.spaceBtwItems),

          // Route
          Row(
            children: [
              Column(
                children: [
                  Container(
                    width: TSizes.iconSm,
                    height: TSizes.iconSm,
                    decoration: const BoxDecoration(
                      color: TColors.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                  Container(
                    width: 2,
                    height: 30,
                    color: dark ? TColors.dark : Colors.grey[300],
                  ),
                  Container(
                    width: TSizes.iconSm,
                    height: TSizes.iconSm,
                    decoration: const BoxDecoration(
                      color: TColors.error,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: TSizes.spaceBtwItems),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ride['pickup']?['name'] ?? 'Unknown Pickup',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w500,
                        color: dark ? TColors.white : TColors.black,
                      ),
                    ),
                    const SizedBox(height: TSizes.spaceBtwItems),
                    Text(
                      ride['destination']?['name'] ?? 'Unknown Destination',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w500,
                        color: dark ? TColors.white : TColors.black,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: TSizes.spaceBtwItems),

          // Driver info and price
          Row(
            children: [
              CircleAvatar(
                radius: TSizes.iconMd,
                backgroundColor: TColors.primary,
                child: const Icon(
                  Iconsax.user,
                  color: Colors.white,
                  size: TSizes.iconMd,
                ),
              ),
              const SizedBox(width: TSizes.spaceBtwItems),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      driverName,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w500,
                        color: dark ? TColors.white : TColors.black,
                      ),
                    ),
                    Row(
                      children: [
                        const Icon(
                          Icons.star,
                          color: Colors.amber,
                          size: TSizes.iconSm,
                        ),
                        const SizedBox(width: TSizes.xs),
                        Text(
                          driverRating.toStringAsFixed(1),
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: dark
                                    ? TColors.lightGrey
                                    : TColors.darkGrey,
                              ),
                        ),
                        Text(
                          ' • $carModel',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: dark
                                    ? TColors.lightGrey
                                    : TColors.darkGrey,
                              ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // --- FIX: Force System Font for Price Text ---
              Text(
                ride['formattedPrice'] ?? '₦${price.toStringAsFixed(0)}',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: dark ? TColors.white : TColors.black,
                  fontFamily: 'Roboto', // <--- THIS IS THE FIX FOR ANDROID
                ),
              ),
              // --------------------------------------------
            ],
          ),

          const SizedBox(height: TSizes.spaceBtwItems),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _rebookRide(ride),
                  icon: const Icon(Iconsax.refresh, size: TSizes.iconSm),
                  label: const Text('Rebook'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: TColors.primary,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: TSizes.spaceBtwItems),
              OutlinedButton(
                onPressed: () => _viewDetails(ride),
                child: const Text('Details'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: dark ? TColors.lightGrey : TColors.black,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'completed':
        return TColors.success;
      case 'cancelled':
        return TColors.error;
      case 'in_progress':
        return TColors.warning;
      default:
        return TColors.info;
    }
  }

  void _rebookRide(Map<String, dynamic> ride) async {
    final rideController = Get.find<RideController>();

    final pickup = ride['pickup'];
    final destination = ride['destination'];

    if (pickup == null || destination == null) {
      THelperFunctions.showErrorSnackBar(
        'Error',
        'Missing location data for this ride.',
      );
      return;
    }

    final pickupLat = (pickup['latitude'] as num?)?.toDouble();
    final pickupLng = (pickup['longitude'] as num?)?.toDouble();
    final destLat = (destination['latitude'] as num?)?.toDouble();
    final destLng = (destination['longitude'] as num?)?.toDouble();

    if (pickupLat == null ||
        pickupLng == null ||
        destLat == null ||
        destLng == null) {
      THelperFunctions.showErrorSnackBar(
        'Error',
        'Invalid location data for this ride.',
      );
      return;
    }

    final pickupLatLng = LatLng(pickupLat, pickupLng);
    final destLatLng = LatLng(destLat, destLng);
    final pickupName = pickup['name']?.toString() ?? 'Rebook Location';
    final destName = destination['name']?.toString() ?? 'Rebook Destination';

    Get.back();

    THelperFunctions.showSnackBar('Setting up your rebook...');

    rideController.currentState.value = BookingState.destinationSearch;
    rideController.panelController.open();

    rideController.pickupLocation.value = pickupLatLng;
    rideController.pickupName.value = pickupName;
    rideController.pickupAddress.value = pickupName;
    rideController.pickupController.text = pickupName;

    rideController.destinationLocation.value = destLatLng;
    rideController.destinationName.value = destName;
    rideController.destinationAddress.value = destName;
    rideController.destinationController.text = destName;

    rideController.initializeStops();
    rideController.stops.add(
      StopPoint(
        id: 'destination',
        type: StopType.destination,
        location: destLatLng,
        name: destName,
        address: destName,
        isEditable: true,
      ),
    );
    rideController.addPickupMarker();
    rideController.addDestinationMarker();
    await rideController.drawRoute();

    bool success = await rideController.updatePricesFromApi();
    if (success) {
      rideController.currentState.value = BookingState.selectRide;
      rideController.animatePanelTo80Percent();
    } else {
      THelperFunctions.showErrorSnackBar(
        'Error',
        'Could not get new prices for this route.',
      );
    }
  }

  void _viewDetails(Map<String, dynamic> ride) {
    THelperFunctions.showSnackBar(
      'Viewing details for ride on ${ride["bookedAt"]}',
    );
  }

  String _formatTripDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final tripDay = DateTime(date.year, date.month, date.day);

    if (tripDay == today) {
      return 'Today, ${DateFormat.jm().format(date)}';
    } else if (tripDay == yesterday) {
      return 'Yesterday, ${DateFormat.jm().format(date)}';
    } else {
      return DateFormat('dd MMM, h:mm a').format(date);
    }
  }

  void _showFilterDialog(
    BuildContext context,
    bool dark,
    ClientTripHistoryController controller,
  ) {
    String selectedPeriod = controller.periodFilter.value;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: dark ? TColors.dark : TColors.white,
          title: Text(
            'Filter Rides',
            style: TextStyle(color: dark ? TColors.white : TColors.black),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildFilterOption(
                'All Time',
                'all',
                selectedPeriod,
                context,
                (val) => setDialogState(() => selectedPeriod = val!),
              ),
              _buildFilterOption(
                'Today',
                'today',
                selectedPeriod,
                context,
                (val) => setDialogState(() => selectedPeriod = val!),
              ),
              _buildFilterOption(
                'This Week',
                'this_week',
                selectedPeriod,
                context,
                (val) => setDialogState(() => selectedPeriod = val!),
              ),
              _buildFilterOption(
                'This Month',
                'this_month',
                selectedPeriod,
                context,
                (val) => setDialogState(() => selectedPeriod = val!),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: dark ? TColors.lightGrey : TColors.darkGrey,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                controller.setFiltersAndFetch(period: selectedPeriod);
                THelperFunctions.showSnackBar('Filter applied successfully');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: TColors.primary,
                foregroundColor: TColors.white,
              ),
              child: const Text('Apply'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterOption(
    String title,
    String value,
    String groupValue,
    BuildContext context,
    Function(String?) onChanged,
  ) {
    final dark = THelperFunctions.isDarkMode(context);

    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(
        title,
        style: TextStyle(color: dark ? TColors.white : TColors.black),
      ),
      leading: Radio<String>(
        value: value,
        groupValue: groupValue,
        onChanged: onChanged,
        activeColor: TColors.primary,
      ),
    );
  }
}
