// lib/features/referral/screens/referral_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:sarri_ride/features/referral/controllers/referral_controller.dart';
import 'package:sarri_ride/features/referral/models/referral_model.dart';
import 'package:sarri_ride/utils/constants/colors.dart';
import 'package:sarri_ride/utils/constants/sizes.dart';
import 'package:sarri_ride/utils/helpers/helper_functions.dart';

class ReferralScreen extends StatelessWidget {
  const ReferralScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final dark = THelperFunctions.isDarkMode(context);
    final controller = Get.put(ReferralController());

    return Scaffold(
      backgroundColor: dark ? TColors.dark : TColors.lightGrey,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Get.back(),
          icon: Icon(Iconsax.arrow_left_2,
              color: dark ? TColors.white : TColors.black),
        ),
        title: Text('Referrals & Points',
            style:
                TextStyle(color: dark ? TColors.white : TColors.black)),
        actions: [
          IconButton(
            icon: Icon(Iconsax.refresh, color: dark ? TColors.white : TColors.black),
            onPressed: controller.loadReferralProfile,
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        if (controller.error.value.isNotEmpty) {
          return _ErrorState(
              error: controller.error.value,
              onRetry: controller.loadReferralProfile);
        }
        final ref = controller.referral.value;
        if (ref == null) {
          return _ErrorState(
              error: 'Could not load referral data.',
              onRetry: controller.loadReferralProfile);
        }
        return _ReferralBody(ref: ref, controller: controller, dark: dark);
      }),
    );
  }
}

// ─── Body ────────────────────────────────────────────────────────────────────

class _ReferralBody extends StatelessWidget {
  final ReferralModel ref;
  final ReferralController controller;
  final bool dark;

  const _ReferralBody(
      {required this.ref, required this.controller, required this.dark});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(TSizes.defaultSpace),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Hero banner
          _HeroBanner(ref: ref, controller: controller, dark: dark),
          const SizedBox(height: TSizes.spaceBtwSections),

          // Stats row
          _StatsRow(ref: ref, dark: dark, context: context),
          const SizedBox(height: TSizes.spaceBtwSections),

          // Reward card (type-dependent)
          if (ref.referralType == 'rider')
            _SarriPointsCard(ref: ref, dark: dark, context: context),
          if (ref.referralType == 'sales_person')
            _SalesDiscountCard(ref: ref, dark: dark, context: context),

          const SizedBox(height: TSizes.spaceBtwSections),

          // How it works
          _HowItWorksCard(isSalesPerson: ref.referralType == 'sales_person', dark: dark),
          const SizedBox(height: TSizes.spaceBtwSections),

          // Recent referrals
          if (ref.recentReferrals.isNotEmpty) ...[
            _ReferralHistoryList(referrals: ref.recentReferrals, dark: dark),
            const SizedBox(height: TSizes.spaceBtwSections),
          ],
        ],
      ),
    );
  }
}

// ─── Hero Banner ─────────────────────────────────────────────────────────────

class _HeroBanner extends StatelessWidget {
  final ReferralModel ref;
  final ReferralController controller;
  final bool dark;

  const _HeroBanner(
      {required this.ref, required this.controller, required this.dark});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(TSizes.defaultSpace),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [TColors.primary, TColors.primary.withOpacity(0.75)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(TSizes.cardRadiusLg),
        boxShadow: [
          BoxShadow(
            color: TColors.primary.withOpacity(0.35),
            blurRadius: TSizes.md,
            offset: const Offset(0, TSizes.sm),
          ),
        ],
      ),
      child: Column(
        children: [
          // Tier badge
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: TSizes.md, vertical: TSizes.xs),
            decoration: BoxDecoration(
              color: controller.tierColor.withOpacity(0.25),
              borderRadius: BorderRadius.circular(TSizes.cardRadiusLg),
              border: Border.all(color: controller.tierColor.withOpacity(0.6)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.star, color: controller.tierColor, size: TSizes.iconSm),
                const SizedBox(width: 4),
                Text(
                  '${controller.tierDisplayName} Tier',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: TColors.white,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(height: TSizes.spaceBtwItems),

          // Referral code
          Text(
            ref.referralCode ?? '—',
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  color: TColors.white,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 4,
                ),
          ),
          const SizedBox(height: TSizes.xs),
          Text(
            'Your Referral Code',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: TColors.white.withOpacity(0.8),
                ),
          ),

          const SizedBox(height: TSizes.spaceBtwItems),

          // Copy + Share buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    Clipboard.setData(
                        ClipboardData(text: ref.referralCode ?? ''));
                    THelperFunctions.showSnackBar('Code copied!');
                  },
                  icon: const Icon(Iconsax.copy, color: Colors.white, size: 16),
                  label: const Text('Copy Code',
                      style: TextStyle(color: Colors.white)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.white54),
                  ),
                ),
              ),
              const SizedBox(width: TSizes.spaceBtwItems),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: controller.shareReferralCode,
                  icon: const Icon(Iconsax.share, size: 16),
                  label: const Text('Share Link'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: TColors.white,
                    foregroundColor: TColors.primary,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Stats Row ────────────────────────────────────────────────────────────────

class _StatsRow extends StatelessWidget {
  final ReferralModel ref;
  final bool dark;
  final BuildContext context;

  const _StatsRow(
      {required this.ref, required this.dark, required this.context});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _StatTile(
          label: 'Referred',
          value: '${ref.totalReferrals}',
          icon: Iconsax.people,
          color: TColors.info,
          dark: dark,
        ),
        const SizedBox(width: TSizes.spaceBtwItems),
        _StatTile(
          label: 'Completed',
          value: '${ref.completedReferrals}',
          icon: Iconsax.tick_circle,
          color: TColors.success,
          dark: dark,
        ),
        const SizedBox(width: TSizes.spaceBtwItems),
        _StatTile(
          label: 'Pending',
          value: '${ref.pendingReferrals}',
          icon: Iconsax.timer_1,
          color: TColors.warning,
          dark: dark,
        ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final bool dark;

  const _StatTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.dark,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(TSizes.md),
        decoration: BoxDecoration(
          color: dark ? TColors.dark : TColors.white,
          borderRadius: BorderRadius.circular(TSizes.cardRadiusMd),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(dark ? 0.3 : 0.07),
              blurRadius: 8,
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: TSizes.iconMd),
            const SizedBox(height: TSizes.xs),
            Text(
              value,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: dark ? TColors.white : TColors.black,
                  ),
            ),
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: dark ? TColors.lightGrey : TColors.darkGrey,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Sarri Points Card (Rider) ────────────────────────────────────────────────

class _SarriPointsCard extends StatelessWidget {
  final ReferralModel ref;
  final bool dark;
  final BuildContext context;

  const _SarriPointsCard(
      {required this.ref, required this.dark, required this.context});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(TSizes.defaultSpace),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFFFF8C00),
            const Color(0xFFFFB300),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(TSizes.cardRadiusLg),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF8C00).withOpacity(0.35),
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
              const Icon(Icons.stars_rounded, color: Colors.white, size: 28),
              const SizedBox(width: TSizes.sm),
              Text(
                'Sarri Points Wallet',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
          const SizedBox(height: TSizes.spaceBtwItems),
          Text(
            '${ref.availablePoints}',
            style: Theme.of(context).textTheme.displayMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
          ),
          Text(
            'Sarri Points  ≈  ₦${ref.nairaBalance.toStringAsFixed(0)}',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.white.withOpacity(0.9),
                ),
          ),
          const SizedBox(height: TSizes.spaceBtwItems),
          Row(
            children: [
              _PointPill(
                label: 'Total Earned',
                value: '${ref.totalPoints} pts',
              ),
              const SizedBox(width: TSizes.sm),
              _PointPill(
                label: 'Used',
                value: '${ref.usedPoints} pts',
              ),
              const SizedBox(width: TSizes.sm),
              _PointPill(
                label: 'Rate',
                value: '1pt = ₦${ref.pointToNairaRate.toStringAsFixed(0)}',
              ),
            ],
          ),
          const SizedBox(height: TSizes.spaceBtwItems),
          Container(
            padding: const EdgeInsets.all(TSizes.sm),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(TSizes.cardRadiusMd),
            ),
            child: Row(
              children: [
                const Icon(Iconsax.info_circle, color: Colors.white, size: 16),
                const SizedBox(width: TSizes.xs),
                Expanded(
                  child: Text(
                    'Points work like a wallet — choose to apply them at checkout when booking a ride.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.white,
                        ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PointPill extends StatelessWidget {
  final String label;
  final String value;

  const _PointPill({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.25),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12),
              textAlign: TextAlign.center,
            ),
            Text(
              label,
              style:
                  TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 9),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Sales Person Discount Card ────────────────────────────────────────────────

class _SalesDiscountCard extends StatelessWidget {
  final ReferralModel ref;
  final bool dark;
  final BuildContext context;

  const _SalesDiscountCard(
      {required this.ref, required this.dark, required this.context});

  @override
  Widget build(BuildContext context) {
    final discountPct = ref.individualDiscountPercent?.toStringAsFixed(0) ??
        ref.effectiveDiscountPercent.toStringAsFixed(0);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(TSizes.defaultSpace),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6A1B9A), Color(0xFF9C27B0)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(TSizes.cardRadiusLg),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6A1B9A).withOpacity(0.35),
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
              const Icon(Icons.local_offer_rounded,
                  color: Colors.white, size: 28),
              const SizedBox(width: TSizes.sm),
              Text(
                'Sales Person Benefits',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
          const SizedBox(height: TSizes.spaceBtwItems),
          Text(
            '$discountPct%',
            style: Theme.of(context).textTheme.displayMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
          ),
          Text(
            ref.individualDiscountPercent != null
                ? 'Custom ride discount (set by admin)'
                : 'Ride discount (global rate)',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.white.withOpacity(0.9),
                ),
          ),
          const SizedBox(height: TSizes.spaceBtwItems),
          _PointPill(
            label: 'Referral Rides',
            value: '${ref.totalDiscountRidesEarned}',
          ),
          const SizedBox(height: TSizes.spaceBtwItems),
          Container(
            padding: const EdgeInsets.all(TSizes.sm),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(TSizes.cardRadiusMd),
            ),
            child: Row(
              children: [
                const Icon(Iconsax.info_circle, color: Colors.white, size: 16),
                const SizedBox(width: TSizes.xs),
                Expanded(
                  child: Text(
                    'Your discount is applied when booking rides. More referrals = continued discount.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.white,
                        ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── How It Works ─────────────────────────────────────────────────────────────

class _HowItWorksCard extends StatelessWidget {
  final bool isSalesPerson;
  final bool dark;

  const _HowItWorksCard({required this.isSalesPerson, required this.dark});

  @override
  Widget build(BuildContext context) {
    final steps = isSalesPerson
        ? [
            ('Share your code', Iconsax.share, 'Send your referral code or link to others'),
            ('They sign up & ride', Iconsax.car, 'The person you refer registers and completes rides'),
            ('You get discounts', Icons.local_offer_rounded, 'Receive a % discount on your own rides after each of their rides'),
          ]
        : [
            ('Share your code', Iconsax.share, 'Send your referral code or link to others'),
            ('They sign up & ride', Iconsax.car, 'The person you refer registers and completes rides'),
            ('Earn Sarri Points', Icons.stars_rounded, 'Earn ${5} pts per ride — redeemable as ₦1 per point at checkout'),
          ];

    return Container(
      padding: const EdgeInsets.all(TSizes.defaultSpace),
      decoration: BoxDecoration(
        color: dark ? TColors.dark : TColors.white,
        borderRadius: BorderRadius.circular(TSizes.cardRadiusLg),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(dark ? 0.3 : 0.07),
            blurRadius: 12,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'How It Works',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: dark ? TColors.white : TColors.black,
                ),
          ),
          const SizedBox(height: TSizes.spaceBtwItems),
          ...steps.asMap().entries.map((e) => Padding(
                padding:
                    const EdgeInsets.only(bottom: TSizes.spaceBtwItems),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: TColors.primary.withOpacity(0.12),
                      child: Text(
                        '${e.key + 1}',
                        style: TextStyle(
                          color: TColors.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    const SizedBox(width: TSizes.spaceBtwItems),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            e.value.$1,
                            style:
                                Theme.of(context).textTheme.bodyLarge?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: dark
                                          ? TColors.white
                                          : TColors.black,
                                    ),
                          ),
                          Text(
                            e.value.$3,
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: dark
                                          ? TColors.lightGrey
                                          : TColors.darkGrey,
                                    ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}

// ─── Referral History List ────────────────────────────────────────────────────

class _ReferralHistoryList extends StatelessWidget {
  final List<ReferralHistoryItem> referrals;
  final bool dark;

  const _ReferralHistoryList(
      {required this.referrals, required this.dark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(TSizes.defaultSpace),
      decoration: BoxDecoration(
        color: dark ? TColors.dark : TColors.white,
        borderRadius: BorderRadius.circular(TSizes.cardRadiusLg),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(dark ? 0.3 : 0.07),
            blurRadius: 12,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Recent Referrals',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: dark ? TColors.white : TColors.black,
                ),
          ),
          const SizedBox(height: TSizes.spaceBtwItems),
          ...referrals.map((r) => _HistoryTile(item: r, dark: dark)),
        ],
      ),
    );
  }
}

class _HistoryTile extends StatelessWidget {
  final ReferralHistoryItem item;
  final bool dark;

  const _HistoryTile({required this.item, required this.dark});

  Color get _statusColor {
    switch (item.status) {
      case 'completed': return TColors.success;
      case 'active':    return TColors.info;
      case 'pending':   return TColors.warning;
      default:          return TColors.darkGrey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: TSizes.spaceBtwItems),
      padding: const EdgeInsets.all(TSizes.md),
      decoration: BoxDecoration(
        color: dark
            ? TColors.darkGrey.withOpacity(0.3)
            : TColors.lightGrey,
        borderRadius: BorderRadius.circular(TSizes.cardRadiusMd),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: TColors.primary.withOpacity(0.12),
            child: Text(
              item.name.isNotEmpty ? item.name[0].toUpperCase() : '?',
              style: TextStyle(
                color: TColors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: TSizes.spaceBtwItems),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: dark ? TColors.white : TColors.black,
                      ),
                ),
                Text(
                  '${item.totalRidesCompleted} rides completed',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: dark ? TColors.lightGrey : TColors.darkGrey,
                      ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _statusColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _statusColor.withOpacity(0.4)),
                ),
                child: Text(
                  item.status.capitalize!,
                  style: TextStyle(
                    color: _statusColor,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (item.pointsEarned > 0)
                Text(
                  '+${item.pointsEarned} pts',
                  style: TextStyle(
                    color: const Color(0xFFFF8C00),
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Error State ─────────────────────────────────────────────────────────────

class _ErrorState extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;

  const _ErrorState({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(TSizes.defaultSpace),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Iconsax.warning_2, size: 56, color: Colors.orange),
            const SizedBox(height: TSizes.spaceBtwItems),
            Text(error, textAlign: TextAlign.center),
            const SizedBox(height: TSizes.spaceBtwItems),
            ElevatedButton(
              onPressed: onRetry,
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }
}
