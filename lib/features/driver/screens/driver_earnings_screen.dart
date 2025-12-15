import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:sarri_ride/features/driver/controllers/driver_dashboard_controller.dart';
import 'package:sarri_ride/features/driver/controllers/driver_wallet_controller.dart';
import 'package:sarri_ride/features/driver/screens/driver_trips_screen.dart';
import 'package:sarri_ride/utils/constants/colors.dart';
import 'package:sarri_ride/utils/constants/sizes.dart';
import 'package:sarri_ride/utils/helpers/helper_functions.dart';
import 'package:iconsax/iconsax.dart';

class DriverEarningsScreen extends StatelessWidget {
  const DriverEarningsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // --- 2. PUT THE NEW CONTROLLER ---
    final controller = Get.put(DriverWalletController());
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
            _buildPeriodSelector(context, dark, controller),

            const SizedBox(height: TSizes.spaceBtwSections),

            // Total Earnings Card
            _buildTotalEarningsCard(context, controller, dark),

            const SizedBox(height: TSizes.spaceBtwSections),

            // Earnings Breakdown (from stats)
            _buildEarningsBreakdown(context, controller, dark),

            const SizedBox(height: TSizes.spaceBtwSections),

            // Performance Metrics (from stats)
            _buildPerformanceMetrics(context, controller, dark),

            const SizedBox(height: TSizes.spaceBtwSections),

            // Recent Transactions
            _buildRecentTransactionsSection(context, controller, dark),
          ],
        ),
      ),
    );
  }

  // --- 3. UPDATE PERIOD SELECTOR TO CALL CONTROLLER ---
  Widget _buildPeriodSelector(
    BuildContext context,
    bool dark,
    DriverWalletController controller,
  ) {
    // We'll need to make this stateful or add RxString to controller
    // For now, let's just make it call the controller
    return Container(
      padding: const EdgeInsets.all(TSizes.xs),
      decoration: BoxDecoration(
        color: dark ? TColors.cardBackgroundDark : TColors.lightGrey,
        borderRadius: BorderRadius.circular(TSizes.borderRadiusLg),
      ),
      child: Row(
        children: [
          _buildPeriodTab(
            'Today',
            false,
            dark,
            () => controller.fetchWalletStatistics('today'),
          ),
          _buildPeriodTab(
            'Week',
            false,
            dark,
            () => controller.fetchWalletStatistics('week'),
          ),
          _buildPeriodTab(
            'Month',
            true,
            dark,
            () => controller.fetchWalletStatistics('month'),
          ),
          _buildPeriodTab(
            'All Time',
            false,
            dark,
            () => controller.fetchWalletStatistics('all'),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodTab(
    String title,
    bool isSelected,
    bool dark,
    VoidCallback onTap,
  ) {
    return Expanded(
      child: GestureDetector(
        // Use GestureDetector to get onTap
        onTap: onTap,
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
      ),
    );
  }
  // --- END 3 ---

  // --- 4. UPDATE EARNINGS CARD ---
  Widget _buildTotalEarningsCard(
    BuildContext context,
    DriverWalletController controller,
    bool dark,
  ) {
    return Obx(
      () => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(TSizes.defaultSpace),
        decoration: BoxDecoration(
          // ... (decoration is unchanged)
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
        child: controller.isLoadingStats.value
            ? const Center(
                child: CircularProgressIndicator(color: Colors.white),
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    // ... (icon is unchanged)
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
                        '${(controller.walletStats['period'] as String?)?.capitalizeFirst ?? '...'} Earnings',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: TColors.white,
                              fontWeight: FontWeight.w500,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: TSizes.spaceBtwItems),
                  Text(
                    // Use formatted string from API or format it
                    controller
                            .walletStats['statistics']?['trip_earning']?['total']
                            ?.toStringAsFixed(2) ??
                        '₦0.00',
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
                          borderRadius: BorderRadius.circular(
                            TSizes.md + TSizes.sm,
                          ),
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
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
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

  // --- 5. UPDATE BREAKDOWN CARD ---
  Widget _buildEarningsBreakdown(
    BuildContext context,
    DriverWalletController controller,
    bool dark,
  ) {
    return Obx(
      () => Container(
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
        child: controller.isLoadingStats.value
            ? const Center(child: CircularProgressIndicator())
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Earnings Breakdown (by Type)',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: TSizes.spaceBtwItems),

                  // This is an example. You'd loop over controller.walletStats['statistics']
                  _buildBreakdownItem(
                    'Trip Earnings',
                    (controller.walletStats['statistics']?['trip_earning']?['total'] ??
                            0.0)
                        .toStringAsFixed(2),
                    '${(controller.walletStats['statistics']?['trip_earning']?['count'] ?? 0)} trips',
                    TColors.primary,
                    context,
                  ),
                  Divider(
                    height: TSizes.spaceBtwItems * 2,
                    color: dark ? TColors.darkGrey : TColors.grey,
                  ),
                  _buildBreakdownItem(
                    'Bonuses',
                    (controller.walletStats['statistics']?['bonus']?['total'] ??
                            0.0)
                        .toStringAsFixed(2),
                    '${(controller.walletStats['statistics']?['bonus']?['count'] ?? 0)} bonuses',
                    TColors.success,
                    context,
                  ),
                  Divider(
                    height: TSizes.spaceBtwItems * 2,
                    color: dark ? TColors.darkGrey : TColors.grey,
                  ),
                  _buildBreakdownItem(
                    'Withdrawals',
                    (controller.walletStats['statistics']?['withdrawal']?['total'] ??
                            0.0)
                        .toStringAsFixed(2),
                    '${(controller.walletStats['statistics']?['withdrawal']?['count'] ?? 0)} withdrawals',
                    TColors.warning,
                    context,
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildBreakdownItem(
    String title,
    String amount,
    String percentage, // We'll reuse this as 'count'
    Color color,
    BuildContext context,
  ) {
    // ... (widget is unchanged, but 'percentage' is now 'count')
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
              "₦$amount", // Add currency
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            Text(
              percentage, // This is now the 'count'
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

  // --- 6. UPDATE PERFORMANCE METRICS ---
  Widget _buildPerformanceMetrics(
    BuildContext context,
    DriverWalletController controller,
    bool dark,
  ) {
    return Obx(
      () => Container(
        child: controller.isLoadingStats.value
            ? const Center(child: CircularProgressIndicator())
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Performance Metrics',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: TSizes.spaceBtwItems),
                  Row(
                    children: [
                      Expanded(
                        child: _buildMetricCard(
                          'Total Trips',
                          (controller.walletStats['totalTrips'] ?? 0)
                              .toString(),
                          Iconsax.route_square,
                          TColors.info,
                          context,
                          dark,
                        ),
                      ),
                      const SizedBox(width: TSizes.spaceBtwItems),
                      Expanded(
                        child: _buildMetricCard(
                          'Total Earnings',
                          (controller.walletStats['totalEarnings'] ?? 0.0)
                              .toStringAsFixed(0),
                          Iconsax.money_2,
                          TColors.primary,
                          context,
                          dark,
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

  Widget _buildMetricCard(
    String title,
    String value,
    IconData icon,
    Color color,
    BuildContext context,
    bool dark,
  ) {
    // ... (widget is unchanged)
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
            title.contains('Earnings')
                ? '₦$value'
                : value, // Add currency if earnings
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

  // --- 7. REPLACE RECENT TRIPS WITH TRANSACTIONS ---
  Widget _buildRecentTransactionsSection(
    BuildContext context,
    DriverWalletController controller,
    bool dark,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recent Transactions',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            TextButton(
              onPressed: () => Get.to(
                () => const DriverTripsScreen(),
              ), // Link to full history
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
        Obx(() {
          if (controller.isLoadingTransactions.value &&
              controller.transactions.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          if (controller.transactions.isEmpty) {
            return const Center(child: Text("No transactions found."));
          }

          return ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: controller.transactions.length.clamp(0, 5), // Show max 5
            separatorBuilder: (context, index) =>
                const SizedBox(height: TSizes.spaceBtwItems),
            itemBuilder: (context, index) {
              final tx = controller.transactions[index];
              return _buildTransactionCard(tx, context, dark);
            },
          );
        }),
      ],
    );
  }

  Widget _buildTransactionCard(
    WalletTransaction tx,
    BuildContext context,
    bool dark,
  ) {
    // Determine color and icon based on type
    Color color;
    IconData icon;
    bool isCredit = false;

    switch (tx.type) {
      case 'trip_earning':
        color = TColors.success;
        icon = Iconsax.money_recive;
        isCredit = true;
        break;
      case 'withdrawal':
        color = TColors.error;
        icon = Iconsax.money_send;
        isCredit = false;
        break;
      case 'cash_payment': // This is a debit (commission owed)
        color = TColors.warning;
        icon = Iconsax.wallet_minus;
        isCredit = false;
        break;
      case 'debt_settlement':
        color = TColors.info;
        icon = Iconsax.wallet_add;
        isCredit = true;
        break;
      default:
        color = TColors.darkGrey;
        icon = Iconsax.wallet;
    }

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
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(TSizes.borderRadiusMd),
                ),
                child: Icon(icon, color: color, size: TSizes.iconSm),
              ),
              const SizedBox(width: TSizes.spaceBtwItems),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tx.description,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _formatTxDate(tx.date),
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
                '${isCredit ? '+' : '-'}₦${tx.amount.toStringAsFixed(0)}',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatTxDate(DateTime? date) {
    if (date == null) return 'Unknown time';
    return DateFormat('dd MMM yyyy, h:mm a').format(date);
  }
}
