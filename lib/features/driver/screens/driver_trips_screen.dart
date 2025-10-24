import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sarri_ride/features/driver/controllers/driver_dashboard_controller.dart';
import 'package:sarri_ride/utils/constants/colors.dart';
import 'package:sarri_ride/utils/constants/sizes.dart';
import 'package:sarri_ride/utils/helpers/helper_functions.dart';
import 'package:iconsax/iconsax.dart';

class DriverTripsScreen extends StatefulWidget {
  const DriverTripsScreen({super.key});

  @override
  State<DriverTripsScreen> createState() => _DriverTripsScreenState();
}

class _DriverTripsScreenState extends State<DriverTripsScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final controller = Get.find<DriverDashboardController>();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
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
                _buildTripsList('all', context, dark),
                _buildTripsList('completed', context, dark),
                _buildTripsList('cancelled', context, dark),
              ],
            ),
          ),
        ],
      ),
    );
  }

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
        () => Row(
          children: [
            Expanded(
              child: _buildStatItem(
                'Total Trips',
                controller.recentTrips.length.toString(),
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
                '45',
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
                controller.averageRating.value.toStringAsFixed(1),
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

  Widget _buildStatItem(
    String title,
    String value,
    IconData icon,
    Color color,
    BuildContext context,
  ) {
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

  Widget _buildTripsList(String filter, BuildContext context, bool dark) {
    return Obx(() {
      final trips = controller.recentTrips;

      if (trips.isEmpty) {
        return _buildEmptyState(context, dark);
      }

      return ListView.separated(
        padding: const EdgeInsets.all(TSizes.defaultSpace),
        itemCount: trips.length,
        separatorBuilder: (context, index) =>
            const SizedBox(height: TSizes.spaceBtwItems),
        itemBuilder: (context, index) {
          final trip = trips[index];
          return _buildTripCard(trip, context, dark);
        },
      );
    });
  }

  Widget _buildEmptyState(BuildContext context, bool dark) {
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

  Widget _buildTripCard(
    Map<String, dynamic> trip,
    BuildContext context,
    bool dark,
  ) {
    final isCompleted = trip['status'] == 'completed';
    final statusColor = isCompleted ? TColors.success : TColors.warning;

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
                    trip['status']?.toString().toUpperCase() ?? 'UNKNOWN',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: statusColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 10,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  _formatTripDate(trip['date']),
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
                        trip['from'] ?? 'Unknown pickup',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 32),
                      Text(
                        trip['to'] ?? 'Unknown destination',
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
                        trip['riderName'] ?? 'Unknown rider',
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
                            trip['rating']?.toStringAsFixed(1) ?? '0.0',
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
                        '₦${trip['earnings']?.toStringAsFixed(0) ?? '0'}',
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
                        _buildDetailRow('Trip ID', trip['id'] ?? 'Unknown'),
                        _buildDetailRow(
                          'Date',
                          _formatFullTripDate(trip['date']),
                        ),
                        _buildDetailRow(
                          'Status',
                          trip['status']?.toString().toUpperCase() ?? 'UNKNOWN',
                        ),
                        _buildDetailRow(
                          'Duration',
                          '${(trip['duration'] ?? 25)} min',
                        ),
                        _buildDetailRow(
                          'Distance',
                          '${(trip['distance'] ?? 12.5)} km',
                        ),
                      ],
                      context,
                      dark,
                    ),

                    const SizedBox(height: TSizes.spaceBtwSections),

                    _buildDetailSection(
                      'Route',
                      [
                        _buildDetailRow('Pickup', trip['from'] ?? 'Unknown'),
                        _buildDetailRow('Destination', trip['to'] ?? 'Unknown'),
                      ],
                      context,
                      dark,
                    ),

                    const SizedBox(height: TSizes.spaceBtwSections),

                    _buildDetailSection(
                      'Rider Information',
                      [
                        _buildDetailRow('Name', trip['riderName'] ?? 'Unknown'),
                        _buildDetailRow(
                          'Rating Given',
                          '${trip['rating']?.toStringAsFixed(1) ?? '0.0'} ⭐',
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
                          'Fare',
                          '₦${trip['fare']?.toStringAsFixed(0) ?? '0'}',
                        ),
                        _buildDetailRow(
                          'Commission',
                          '₦${((trip['fare'] ?? 0) * 0.1).toStringAsFixed(0)}',
                        ),
                        _buildDetailRow(
                          'Your Earnings',
                          '₦${trip['earnings']?.toStringAsFixed(0) ?? '0'}',
                        ),
                        _buildDetailRow('Payment Method', 'Wallet'),
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

  Widget _buildDetailSection(
    String title,
    List<Widget> children,
    BuildContext context,
    bool dark,
  ) {
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

  String _formatTripDate(DateTime? date) {
    if (date == null) return 'Unknown date';

    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  String _formatFullTripDate(DateTime? date) {
    if (date == null) return 'Unknown date';

    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    return '${date.day} ${months[date.month - 1]} ${date.year}, ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}
