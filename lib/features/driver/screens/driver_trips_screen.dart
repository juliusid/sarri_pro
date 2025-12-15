import 'package:flutter/material.dart';
import 'package:get/get.dart';
// --- 1. IMPORT THE NEW CONTROLLER ---
import 'package:sarri_ride/features/driver/controllers/driver_trip_history_controller.dart';
import 'package:sarri_ride/utils/constants/colors.dart';
import 'package:sarri_ride/utils/constants/sizes.dart';
import 'package:sarri_ride/utils/helpers/helper_functions.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart'; // For formatting dates

class DriverTripsScreen extends StatefulWidget {
  const DriverTripsScreen({super.key});

  @override
  State<DriverTripsScreen> createState() => _DriverTripsScreenState();
}

class _DriverTripsScreenState extends State<DriverTripsScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  // --- 2. GET THE NEW CONTROLLER ---
  final controller = Get.put(DriverTripHistoryController());

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    // --- 3. ADD LISTENER TO TAB CONTROLLER ---
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        // Check which tab is selected and call the controller
        switch (_tabController.index) {
          case 0: // All Trips
            controller.setFiltersAndFetch(status: 'all');
            break;
          case 1: // Completed
            controller.setFiltersAndFetch(status: 'completed');
            break;
          case 2: // Cancelled
            controller.setFiltersAndFetch(status: 'cancelled');
            break;
        }
      }
    });
    // --- END 3 ---
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dark = THelperFunctions.isDarkMode(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Trip History'),
        leading: IconButton(
          onPressed: () => Get.back(),
          icon: Icon(
            Iconsax.arrow_left_2,
            color: dark ? TColors.light : TColors.dark,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () => _showFilterDialog(context, dark),
            icon: Icon(
              Iconsax.filter,
              color: dark ? TColors.light : TColors.dark,
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'All Trips'),
            Tab(text: 'Completed'),
            Tab(text: 'Cancelled'),
          ],
          labelColor: TColors.primary,
          unselectedLabelColor: dark ? TColors.lightGrey : TColors.darkGrey,
          indicatorColor: TColors.primary,
        ),
      ),
      body: Column(
        children: [
          // Trip Statistics Card
          _buildTripStatsCard(context, dark),

          // Trip List
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildTripsList(context, dark), // No filter needed here
                _buildTripsList(context, dark),
                _buildTripsList(context, dark),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- 4. UPDATE STATS CARD TO USE CONTROLLER ---
  Widget _buildTripStatsCard(BuildContext context, bool dark) {
    return Container(
      margin: const EdgeInsets.all(TSizes.defaultSpace),
      padding: const EdgeInsets.all(TSizes.defaultSpace),
      decoration: BoxDecoration(
        color: dark ? TColors.cardBackgroundDark : TColors.cardBackground,
        borderRadius: BorderRadius.circular(TSizes.cardRadiusLg),
        boxShadow: [
          BoxShadow(
            color: TColors.black.withOpacity(dark ? 0.3 : 0.1),
            blurRadius: TSizes.sm,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Obx(
        // Wrap with Obx to listen to changes
        () => controller.isLoading.value && controller.trips.isEmpty
            ? const Center(
                child: SizedBox(height: 70, child: CircularProgressIndicator()),
              ) // Show loader
            : Row(
                children: [
                  Expanded(
                    child: _buildStatItem(
                      'Total Trips',
                      // Use summary data, default to 0
                      (controller.summary['total'] ?? 0).toString(),
                      Iconsax.route_square,
                      TColors.primary,
                      context,
                    ),
                  ),
                  Container(
                    width: 1,
                    height: TSizes.xl + TSizes.sm,
                    color: dark ? TColors.darkGrey : TColors.lightGrey,
                  ),
                  Expanded(
                    child: _buildStatItem(
                      'This Week',
                      // Use timePeriods data, default to 0
                      (controller.timePeriods['thisWeek']?['trips'] ?? 0)
                          .toString(),
                      Iconsax.calendar,
                      TColors.success,
                      context,
                    ),
                  ),
                  Container(
                    width: 1,
                    height: TSizes.xl + TSizes.sm,
                    color: dark ? TColors.darkGrey : TColors.lightGrey,
                  ),
                  Expanded(
                    child: _buildStatItem(
                      'Rating',
                      // Use ratings data, default to 0.0
                      (controller.ratings['averageRating'] ?? 0.0)
                          .toStringAsFixed(1),
                      Iconsax.star1,
                      TColors.warning,
                      context,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
  // --- END 4 ---

  Widget _buildStatItem(
    String title,
    String value,
    IconData icon,
    Color color,
    BuildContext context,
  ) {
    // ... (This widget is unchanged)
    return Column(
      children: [
        Icon(icon, color: color, size: TSizes.iconLg),
        const SizedBox(height: TSizes.sm),
        Text(
          value,
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: TSizes.xs),
        Text(
          title,
          style: Theme.of(context).textTheme.bodySmall,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  // --- 5. UPDATE TRIPS LIST TO USE CONTROLLER ---
  Widget _buildTripsList(BuildContext context, bool dark) {
    return Obx(() {
      if (controller.isLoading.value && controller.trips.isEmpty) {
        return const Center(child: CircularProgressIndicator());
      }

      if (controller.trips.isEmpty) {
        return _buildEmptyState(context, dark);
      }

      // Use ListView.builder for performance
      return ListView.builder(
        padding: const EdgeInsets.all(TSizes.defaultSpace),
        // Add +1 for the "Load More" button if it has a next page
        itemCount: controller.hasNextPage.value
            ? controller.trips.length + 1
            : controller.trips.length,
        itemBuilder: (context, index) {
          // Check if this is the "Load More" button
          if (index == controller.trips.length) {
            return controller.isLoadingMore.value
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: CircularProgressIndicator(),
                    ),
                  )
                : OutlinedButton(
                    onPressed: () => controller.loadMore(),
                    child: const Text('Load More'),
                  );
          }

          // This is a normal trip card
          final trip = controller.trips[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: TSizes.spaceBtwItems),
            child: _buildTripCard(trip, context, dark),
          );
        },
      );
    });
  }
  // --- END 5 ---

  Widget _buildEmptyState(BuildContext context, bool dark) {
    // ... (This widget is unchanged)
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: TColors.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Iconsax.route_square, size: 64, color: TColors.primary),
          ),
          const SizedBox(height: TSizes.spaceBtwItems),
          Text(
            'No trips found',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: TSizes.spaceBtwItems / 2),
          Text(
            'Your completed trips will appear here',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: dark ? TColors.lightGrey : TColors.darkGrey,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // --- 6. CRITICAL: UPDATE TRIP CARD TO PARSE NEW JSON ---
  Widget _buildTripCard(
    Map<String, dynamic> trip,
    BuildContext context,
    bool dark,
  ) {
    final status = trip['status']?.toString() ?? 'unknown';
    final isCompleted = status == 'completed';
    final statusColor = isCompleted
        ? TColors.success
        : (status == 'cancelled' ? TColors.error : TColors.warning);

    // Parse date, fallback to bookedAt if completedAt/cancelledAt is null
    DateTime? tripDate = DateTime.tryParse(
      trip['completedAt'] ?? trip['cancelledAt'] ?? trip['bookedAt'] ?? '',
    );

    return GestureDetector(
      onTap: () => _showTripDetails(trip, context, dark),
      child: Container(
        padding: const EdgeInsets.all(TSizes.defaultSpace),
        decoration: BoxDecoration(
          color: dark ? TColors.dark : Colors.white,
          borderRadius: BorderRadius.circular(TSizes.cardRadiusLg),
          border: Border.all(color: statusColor.withOpacity(0.2), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(dark ? 0.3 : 0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Trip Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    status.toUpperCase(),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: statusColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 10,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  _formatTripDate(tripDate), // Use formatted date
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: dark ? TColors.lightGrey : TColors.darkGrey,
                  ),
                ),
              ],
            ),

            const SizedBox(height: TSizes.spaceBtwItems),

            // Trip Route
            Row(
              children: [
                Column(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: TColors.success,
                        shape: BoxShape.circle,
                      ),
                    ),
                    Container(
                      width: 2,
                      height: 32,
                      color: dark ? TColors.darkGrey : TColors.lightGrey,
                    ),
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
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
                        trip['pickup']?['name'] ??
                            'Unknown pickup', // USE NEW KEY
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 32),
                      Text(
                        trip['destination']?['name'] ??
                            'Unknown destination', // USE NEW KEY
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: TSizes.spaceBtwItems),

            // Trip Details
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Rider',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: dark ? TColors.lightGrey : TColors.darkGrey,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        trip['client']?['name'] ??
                            'Unknown rider', // USE NEW KEY
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        'Rating',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: dark ? TColors.lightGrey : TColors.darkGrey,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.star, size: 16, color: TColors.warning),
                          const SizedBox(width: 2),
                          Text(
                            (trip['rating'] as num?)?.toStringAsFixed(1) ??
                                'N/A', // USE NEW KEY
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Earnings',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: dark ? TColors.lightGrey : TColors.darkGrey,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        // Use formatted string OR the raw number
                        trip['formattedEarnings'] ??
                            '₦${(trip['driverEarnings'] as num?)?.toStringAsFixed(0) ?? '0'}', // USE NEW KEY
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: TColors.success,
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
    );
  }
  // --- END 6 ---

  // --- 7. CRITICAL: UPDATE DETAILS MODAL TO PARSE NEW JSON ---
  void _showTripDetails(
    Map<String, dynamic> trip,
    BuildContext context,
    bool dark,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: BoxDecoration(
          color: dark ? TColors.dark : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: dark ? TColors.darkGrey : TColors.lightGrey,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Header
            Padding(
              padding: const EdgeInsets.all(TSizes.defaultSpace),
              child: Row(
                children: [
                  Text(
                    'Trip Details',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),

            // Trip Details Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: TSizes.defaultSpace,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDetailSection(
                      'Trip Information',
                      [
                        _buildDetailRow('Trip ID', trip['tripId'] ?? 'Unknown'),
                        _buildDetailRow(
                          'Date',
                          _formatFullTripDate(
                            DateTime.tryParse(trip['bookedAt'] ?? ''),
                          ),
                        ),
                        _buildDetailRow(
                          'Status',
                          trip['status']?.toString().toUpperCase() ?? 'UNKNOWN',
                        ),
                        _buildDetailRow(
                          'Duration',
                          '${(trip['tripDuration'] ?? 'N/A')} min',
                        ),
                        _buildDetailRow(
                          'Distance',
                          '${(trip['distanceKm'] as num?)?.toStringAsFixed(2) ?? 'N/A'} km',
                        ),
                      ],
                      context,
                      dark,
                    ),

                    const SizedBox(height: TSizes.spaceBtwSections),

                    _buildDetailSection(
                      'Route',
                      [
                        _buildDetailRow(
                          'Pickup',
                          trip['pickup']?['name'] ?? 'Unknown',
                        ),
                        _buildDetailRow(
                          'Destination',
                          trip['destination']?['name'] ?? 'Unknown',
                        ),
                      ],
                      context,
                      dark,
                    ),

                    const SizedBox(height: TSizes.spaceBtwSections),

                    _buildDetailSection(
                      'Rider Information',
                      [
                        _buildDetailRow(
                          'Name',
                          trip['client']?['name'] ?? 'Unknown',
                        ),
                        _buildDetailRow(
                          'Rating Given',
                          (trip['rating'] as num?)?.toStringAsFixed(1) ??
                              'Not Rated',
                        ),
                        _buildDetailRow(
                          'Review',
                          trip['clientReview']?.toString() ?? 'No review',
                        ),
                      ],
                      context,
                      dark,
                    ),

                    const SizedBox(height: TSizes.spaceBtwSections),

                    _buildDetailSection(
                      'Payment Details',
                      [
                        _buildDetailRow(
                          'Total Fare',
                          trip['formattedPrice'] ??
                              '₦${(trip['price'] as num?)?.toStringAsFixed(2) ?? '0'}',
                        ),
                        _buildDetailRow(
                          'App Commission',
                          trip['formattedCommission'] ??
                              '₦${(trip['commission'] as num?)?.toStringAsFixed(2) ?? '0'}',
                        ),
                        _buildDetailRow(
                          'Your Earnings',
                          trip['formattedEarnings'] ??
                              '₦${(trip['driverEarnings'] as num?)?.toStringAsFixed(2) ?? '0'}',
                        ),
                        _buildDetailRow(
                          'Payment Method',
                          trip['paymentMethod'] ?? 'N/A',
                        ),
                        _buildDetailRow(
                          'Payment Status',
                          trip['paymentStatus'] ?? 'N/A',
                        ),
                      ],
                      context,
                      dark,
                    ),

                    const SizedBox(height: TSizes.spaceBtwSections),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  // --- END 7 ---

  Widget _buildDetailSection(
    String title,
    List<Widget> children,
    BuildContext context,
    bool dark,
  ) {
    // ... (This widget is unchanged)
    return Container(
      padding: const EdgeInsets.all(TSizes.defaultSpace),
      decoration: BoxDecoration(
        color: dark ? TColors.darkerGrey : TColors.lightGrey,
        borderRadius: BorderRadius.circular(TSizes.cardRadiusLg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: TSizes.spaceBtwItems),
          ...children,
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    // ... (This widget is unchanged)
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  void _showFilterDialog(BuildContext context, bool dark) {
    // ... (This widget is unchanged for now)
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter Trips'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Last 7 days'),
              leading: Radio(value: 1, groupValue: 1, onChanged: (value) {}),
            ),
            ListTile(
              title: const Text('Last 30 days'),
              leading: Radio(value: 2, groupValue: 1, onChanged: (value) {}),
            ),
            ListTile(
              title: const Text('Last 3 months'),
              leading: Radio(value: 3, groupValue: 1, onChanged: (value) {}),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }

  // --- 8. UPDATE DATE FORMATTING LOGIC ---
  String _formatTripDate(DateTime? date) {
    if (date == null) return 'Unknown date';

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final tripDay = DateTime(date.year, date.month, date.day);

    if (tripDay == today) {
      return 'Today';
    } else if (tripDay == yesterday) {
      return 'Yesterday';
    } else if (now.difference(date).inDays < 7) {
      return DateFormat('EEEE').format(date); // e.g., 'Tuesday'
    } else {
      return DateFormat('dd MMM yyyy').format(date); // e.g., '07 Nov 2025'
    }
  }

  String _formatFullTripDate(DateTime? date) {
    if (date == null) return 'Unknown date';
    // e.g., 07 Nov 2025, 6:03 PM
    return DateFormat('dd MMM yyyy, h:mm a').format(date);
  }

  // --- END 8 ---
}
