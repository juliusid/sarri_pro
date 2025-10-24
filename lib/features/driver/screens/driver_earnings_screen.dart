import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sarri_ride/features/driver/controllers/driver_dashboard_controller.dart';
import 'package:sarri_ride/utils/constants/colors.dart';
import 'package:sarri_ride/utils/constants/sizes.dart';
import 'package:sarri_ride/utils/helpers/helper_functions.dart';
import 'package:iconsax/iconsax.dart';

class DriverEarningsScreen extends StatelessWidget {
  const DriverEarningsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<DriverDashboardController>();
    final dark = THelperFunctions.isDarkMode(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Earnings'),
        leading: IconButton(
          onPressed: () => Get.back(),
          icon: Icon(
            Iconsax.arrow_left_2,
            color: dark ? TColors.light : TColors.dark,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(TSizes.defaultSpace),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Earnings Period Selector
            _buildPeriodSelector(context, dark),

            const SizedBox(height: TSizes.spaceBtwSections),

            // Total Earnings Card
            _buildTotalEarningsCard(context, controller, dark),

            const SizedBox(height: TSizes.spaceBtwSections),

            // Earnings Breakdown
            _buildEarningsBreakdown(context, controller, dark),

            const SizedBox(height: TSizes.spaceBtwSections),

            // Performance Metrics
            _buildPerformanceMetrics(context, controller, dark),

            const SizedBox(height: TSizes.spaceBtwSections),

            // Recent Trips Summary
            _buildRecentTripsSection(context, controller, dark),
          ],
        ),
      ),
    );
  }

  Widget _buildPeriodSelector(BuildContext context, bool dark) {
    return Container(
      padding: const EdgeInsets.all(TSizes.xs),
      decoration: BoxDecoration(
        color: dark ? TColors.cardBackgroundDark : TColors.lightGrey,
        borderRadius: BorderRadius.circular(TSizes.borderRadiusLg),
      ),
      child: Row(
        children: [
          _buildPeriodTab('Today', true, dark),
          _buildPeriodTab('Week', false, dark),
          _buildPeriodTab('Month', false, dark),
          _buildPeriodTab('All Time', false, dark),
        ],
      ),
    );
  }

  Widget _buildPeriodTab(String title, bool isSelected, bool dark) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: TSizes.sm + TSizes.xs),
        decoration: BoxDecoration(
          color: isSelected ? TColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(TSizes.borderRadiusLg),
        ),
        child: Text(
          title,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isSelected
                ? TColors.white
                : (dark ? TColors.light : TColors.dark),
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            fontSize: TSizes.fontSizeSm,
          ),
        ),
      ),
    );
  }

  Widget _buildTotalEarningsCard(
    BuildContext context,
    DriverDashboardController controller,
    bool dark,
  ) {
    return Obx(
      () => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(TSizes.defaultSpace),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [TColors.success, TColors.success.withOpacity(0.8)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(TSizes.cardRadiusLg),
          boxShadow: [
            BoxShadow(
              color: TColors.success.withOpacity(0.3),
              blurRadius: TSizes.md - TSizes.xs,
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
                  padding: const EdgeInsets.all(TSizes.sm + TSizes.xs),
                  decoration: BoxDecoration(
                    color: TColors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(
                      TSizes.borderRadiusSm + TSizes.sm,
                    ),
                  ),
                  child: Icon(
                    Iconsax.wallet_3,
                    color: TColors.white,
                    size: TSizes.iconLg,
                  ),
                ),
                const Spacer(),
                Text(
                  'Today\'s Earnings',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: TColors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: TSizes.spaceBtwItems),
            Text(
              controller.formattedTodayEarnings,
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                color: TColors.white,
                fontWeight: FontWeight.bold,
                fontSize: 36,
              ),
            ),
            const SizedBox(height: TSizes.spaceBtwItems / 2),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: TSizes.sm,
                    vertical: TSizes.xs,
                  ),
                  decoration: BoxDecoration(
                    color: TColors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(TSizes.md + TSizes.sm),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.trending_up,
                        color: TColors.white,
                        size: TSizes.iconSm,
                      ),
                      const SizedBox(width: TSizes.xs),
                      Text(
                        '+12.5%',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: TColors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: TSizes.sm),
                Text(
                  'vs yesterday',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: TColors.white.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEarningsBreakdown(
    BuildContext context,
    DriverDashboardController controller,
    bool dark,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Earnings Breakdown',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: TSizes.spaceBtwItems),
        Container(
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
          child: Column(
            children: [
              _buildBreakdownItem(
                'Ride Earnings',
                '₦25,200',
                '88.4%',
                TColors.primary,
                context,
              ),
              Divider(
                height: TSizes.spaceBtwItems * 2,
                color: dark ? TColors.darkGrey : TColors.grey,
              ),
              _buildBreakdownItem(
                'Tips',
                '₦2,100',
                '7.4%',
                TColors.success,
                context,
              ),
              Divider(
                height: TSizes.spaceBtwItems * 2,
                color: dark ? TColors.darkGrey : TColors.grey,
              ),
              _buildBreakdownItem(
                'Bonuses',
                '₦1,200',
                '4.2%',
                TColors.warning,
                context,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBreakdownItem(
    String title,
    String amount,
    String percentage,
    Color color,
    BuildContext context,
  ) {
    return Row(
      children: [
        Container(
          width: TSizes.sm,
          height: TSizes.sm,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: TSizes.spaceBtwItems),
        Expanded(
          child: Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500),
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              amount,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            Text(
              percentage,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPerformanceMetrics(
    BuildContext context,
    DriverDashboardController controller,
    bool dark,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Performance Metrics',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: TSizes.spaceBtwItems),
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                'Trips',
                controller.todayTripsCount.value.toString(),
                Iconsax.route_square,
                TColors.info,
                context,
                dark,
              ),
            ),
            const SizedBox(width: TSizes.spaceBtwItems),
            Expanded(
              child: _buildMetricCard(
                'Hours',
                '${controller.todayHours.value.toStringAsFixed(1)}h',
                Iconsax.clock,
                TColors.warning,
                context,
                dark,
              ),
            ),
          ],
        ),
        const SizedBox(height: TSizes.spaceBtwItems),
        Row(
          children: [
            Expanded(
              child: Obx(
                () => _buildMetricCard(
                  'Rating',
                  controller.averageRating.value.toStringAsFixed(1),
                  Iconsax.star1,
                  TColors.success,
                  context,
                  dark,
                ),
              ),
            ),
            const SizedBox(width: TSizes.spaceBtwItems),
            Expanded(
              child: _buildMetricCard(
                'Avg/Trip',
                '₦3,562',
                Iconsax.money_2,
                TColors.primary,
                context,
                dark,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMetricCard(
    String title,
    String value,
    IconData icon,
    Color color,
    BuildContext context,
    bool dark,
  ) {
    return Container(
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(TSizes.sm),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(TSizes.borderRadiusMd),
            ),
            child: Icon(icon, color: color, size: TSizes.iconMd),
          ),
          const SizedBox(height: TSizes.spaceBtwItems),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: TSizes.xs),
          Text(
            title,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: dark ? TColors.lightGrey : TColors.darkGrey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentTripsSection(
    BuildContext context,
    DriverDashboardController controller,
    bool dark,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recent Trips',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            TextButton(
              onPressed: () => controller.navigateToTrips(),
              child: Text(
                'View All',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: TColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: TSizes.spaceBtwItems),
        Obx(
          () => ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: controller.recentTrips.length.clamp(0, 3),
            separatorBuilder: (context, index) =>
                const SizedBox(height: TSizes.spaceBtwItems),
            itemBuilder: (context, index) {
              final trip = controller.recentTrips[index];
              return _buildTripCard(trip, context, dark);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTripCard(
    Map<String, dynamic> trip,
    BuildContext context,
    bool dark,
  ) {
    return Container(
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(TSizes.sm),
                decoration: BoxDecoration(
                  color: TColors.success.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(TSizes.borderRadiusMd),
                ),
                child: Icon(
                  Iconsax.location,
                  color: TColors.success,
                  size: TSizes.iconSm,
                ),
              ),
              const SizedBox(width: TSizes.spaceBtwItems),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      trip['from'] ?? 'Unknown location',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'to ${trip['to'] ?? 'Unknown destination'}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: dark ? TColors.lightGrey : TColors.darkGrey,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Text(
                '₦${trip['earnings']?.toStringAsFixed(0) ?? '0'}',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: TColors.success,
                ),
              ),
            ],
          ),
          const SizedBox(height: TSizes.spaceBtwItems),
          Row(
            children: [
              Icon(
                Iconsax.clock,
                size: TSizes.fontSizeSm,
                color: dark ? TColors.lightGrey : TColors.darkGrey,
              ),
              const SizedBox(width: TSizes.xs),
              Text(
                _formatTripTime(trip['date']),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: dark ? TColors.lightGrey : TColors.darkGrey,
                ),
              ),
              const Spacer(),
              Row(
                children: List.generate(5, (starIndex) {
                  final rating = trip['rating'] ?? 0.0;
                  return Icon(
                    starIndex < rating ? Icons.star : Icons.star_border,
                    size: TSizes.fontSizeSm,
                    color: TColors.warning,
                  );
                }),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatTripTime(DateTime? date) {
    if (date == null) return 'Unknown time';

    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}
