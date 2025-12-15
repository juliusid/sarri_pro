import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sarri_ride/utils/constants/colors.dart';
import 'package:sarri_ride/utils/constants/sizes.dart';
import 'package:sarri_ride/utils/helpers/helper_functions.dart';
import 'package:iconsax/iconsax.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  String selectedPeriod = 'This Month';
  bool isBalanceVisible = true;

  @override
  Widget build(BuildContext context) {
    final dark = THelperFunctions.isDarkMode(context);

    return Scaffold(
      backgroundColor: dark ? TColors.dark : TColors.lightGrey,
      appBar: AppBar(
        title: const Text('Sarri Points'),
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
            onPressed: () =>
                setState(() => isBalanceVisible = !isBalanceVisible),
            icon: Icon(
              isBalanceVisible ? Iconsax.eye_slash : Iconsax.eye,
              color: dark ? TColors.light : TColors.dark,
              size: TSizes.iconLg,
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // --- 1. ORIGINAL HEADER DESIGN (Preserved) ---
            Container(
              width: double.infinity,
              margin: const EdgeInsets.all(TSizes.defaultSpace),
              padding: const EdgeInsets.all(TSizes.defaultSpace),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [TColors.primary, TColors.primary.withOpacity(0.8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(TSizes.cardRadiusLg),
                boxShadow: [
                  BoxShadow(
                    color: TColors.primary.withOpacity(0.3),
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
                        child: Icon(
                          Iconsax.star, // Changed to Star for Points
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
                              'Available Points', // Updated Label
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(
                                    color: TColors.white.withOpacity(0.8),
                                    fontWeight: FontWeight.w500,
                                  ),
                            ),
                            const SizedBox(height: TSizes.xs),
                            Text(
                              isBalanceVisible
                                  ? '2,450 pts'
                                  : '**** pts', // Updated Value
                              style: Theme.of(context).textTheme.headlineMedium
                                  ?.copyWith(
                                    color: TColors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: TSizes.spaceBtwSections),

                  // Quick Actions (Inside Header, as per original design)
                  Row(
                    children: [
                      Expanded(
                        child: _buildQuickAction(
                          icon: Iconsax.add_circle,
                          label: 'Earn',
                          onTap: () => _earnPoints(),
                        ),
                      ),
                      const SizedBox(width: TSizes.spaceBtwItems),
                      Expanded(
                        child: _buildQuickAction(
                          icon: Iconsax.gift,
                          label: 'Redeem',
                          onTap: () => _redeemPoints(),
                        ),
                      ),
                      const SizedBox(width: TSizes.spaceBtwItems),
                      Expanded(
                        child: _buildQuickAction(
                          icon: Iconsax.export_3,
                          label: 'Transfer',
                          onTap: () => _transferPoints(),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // --- 2. NEW UI FOR BODY (Stats & History) ---

            // Stats Cards
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: TSizes.defaultSpace,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      title: 'Redeemed',
                      value: '1,200 pts',
                      icon: Iconsax.ticket_expired,
                      color: TColors.warning,
                      dark: dark,
                      context: context,
                    ),
                  ),
                  const SizedBox(width: TSizes.spaceBtwItems),
                  Expanded(
                    child: _buildStatCard(
                      title: 'Lifetime Earned',
                      value: '3,650 pts',
                      icon: Iconsax.award,
                      color: TColors.success,
                      dark: dark,
                      context: context,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: TSizes.spaceBtwSections),

            // Points History List
            Container(
              margin: const EdgeInsets.symmetric(
                horizontal: TSizes.defaultSpace,
              ),
              padding: const EdgeInsets.all(TSizes.defaultSpace),
              decoration: BoxDecoration(
                color: dark ? TColors.dark : TColors.white,
                borderRadius: BorderRadius.circular(TSizes.cardRadiusLg),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(dark ? 0.3 : 0.05),
                    blurRadius: TSizes.md,
                    offset: const Offset(0, TSizes.sm),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Points History',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: dark ? TColors.white : TColors.black,
                        ),
                      ),
                      // Simple filter text instead of dropdown for cleaner look
                      Text(
                        'Recent',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: TColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: TSizes.spaceBtwItems),

                  // Transactions list (Demo Data)
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _transactions.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final transaction = _transactions[index];
                      return _buildTransactionCard(transaction, dark, context);
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: TSizes.spaceBtwSections),

            // Rewards Info Section
            Container(
              margin: const EdgeInsets.symmetric(
                horizontal: TSizes.defaultSpace,
              ),
              padding: const EdgeInsets.all(TSizes.defaultSpace),
              decoration: BoxDecoration(
                color: dark ? TColors.dark : TColors.white,
                borderRadius: BorderRadius.circular(TSizes.cardRadiusLg),
                border: Border.all(color: TColors.grey.withOpacity(0.2)),
              ),
              child: Column(
                children: [
                  _buildSettingsOption(
                    icon: Iconsax.info_circle,
                    title: 'How it works',
                    subtitle: 'Learn how to earn points',
                    onTap: () => _showAboutPoints(),
                    dark: dark,
                    context: context,
                  ),
                  const Divider(),
                  _buildSettingsOption(
                    icon: Iconsax.gift,
                    title: 'Rewards Catalog',
                    subtitle: 'View available rewards',
                    onTap: () => _showRewards(),
                    dark: dark,
                    context: context,
                  ),
                ],
              ),
            ),

            const SizedBox(height: TSizes.spaceBtwSections),
          ],
        ),
      ),
    );
  }

  // --- WIDGET HELPERS ---

  Widget _buildQuickAction({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(TSizes.cardRadiusMd),
      child: Container(
        padding: const EdgeInsets.symmetric(
          vertical: TSizes.md,
          horizontal: TSizes.sm,
        ),
        decoration: BoxDecoration(
          color: TColors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(TSizes.cardRadiusMd),
        ),
        child: Column(
          children: [
            Icon(icon, color: TColors.white, size: 24),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                color: TColors.white,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
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
        color: dark ? TColors.darkerGrey : TColors.white,
        borderRadius: BorderRadius.circular(TSizes.cardRadiusLg),
        border: Border.all(color: TColors.grey.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 12),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: dark ? TColors.white : TColors.black,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.labelMedium?.copyWith(color: TColors.darkGrey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionCard(
    WalletTransaction transaction,
    bool dark,
    BuildContext context,
  ) {
    final isCredit = transaction.type == 'credit';
    final color = isCredit ? TColors.success : TColors.error;

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(transaction.icon, color: color, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                transaction.title,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: dark ? TColors.white : TColors.black,
                ),
              ),
              Text(
                '${transaction.date} • ${transaction.time}',
                style: Theme.of(
                  context,
                ).textTheme.labelMedium?.copyWith(color: TColors.darkGrey),
              ),
            ],
          ),
        ),
        Text(
          '${isCredit ? '+' : '-'}${transaction.amount} pts',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required bool dark,
    required BuildContext context,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: TColors.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: TColors.primary, size: 20),
      ),
      title: Text(
        title,
        style: Theme.of(
          context,
        ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(subtitle, style: Theme.of(context).textTheme.labelMedium),
      trailing: const Icon(
        Icons.arrow_forward_ios,
        size: 14,
        color: TColors.darkGrey,
      ),
      onTap: onTap,
    );
  }

  // Action Placeholders
  void _earnPoints() =>
      THelperFunctions.showSnackBar('Earn points feature coming soon');
  void _redeemPoints() =>
      THelperFunctions.showSnackBar('Redeem points feature coming soon');
  void _transferPoints() =>
      THelperFunctions.showSnackBar('Transfer points feature coming soon');
  void _showAboutPoints() =>
      THelperFunctions.showSnackBar('Info page coming soon');
  void _showRewards() =>
      THelperFunctions.showSnackBar('Rewards catalog coming soon');
}

class WalletTransaction {
  final String title;
  final String date;
  final String time;
  final String amount;
  final String type;
  final String status;
  final IconData icon;

  WalletTransaction({
    required this.title,
    required this.date,
    required this.time,
    required this.amount,
    required this.type,
    required this.status,
    required this.icon,
  });
}

// Demo Data
final List<WalletTransaction> _transactions = [
  WalletTransaction(
    title: 'Ride Completed',
    date: 'Today',
    time: '2:30 PM',
    amount: '50',
    type: 'credit',
    status: 'Completed',
    icon: Iconsax.car,
  ),
  WalletTransaction(
    title: 'Promo Reward',
    date: 'Yesterday',
    time: '10:15 AM',
    amount: '200',
    type: 'credit',
    status: 'Completed',
    icon: Iconsax.gift,
  ),
  WalletTransaction(
    title: 'Discount Used',
    date: 'Dec 15',
    time: '8:45 PM',
    amount: '500',
    type: 'debit',
    status: 'Completed',
    icon: Iconsax.ticket,
  ),
];
