import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sarri_ride/features/driver/controllers/trip_management_controller.dart';
import 'package:sarri_ride/utils/constants/colors.dart';
import 'package:sarri_ride/utils/constants/sizes.dart';
import 'package:sarri_ride/utils/helpers/helper_functions.dart';
import 'package:iconsax/iconsax.dart';

class TripRequestScreen extends StatelessWidget {
  const TripRequestScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<TripManagementController>();
    final dark = THelperFunctions.isDarkMode(context);

    return Scaffold(
      backgroundColor: dark ? TColors.dark : TColors.light,
      body: SafeArea(
        child: Obx(() {
          final request = controller.currentTripRequest.value;
          if (request == null) {
            return _buildNoRequestScreen(context, dark);
          }

          return Padding(
            padding: const EdgeInsets.all(TSizes.defaultSpace),
            child: Column(
              children: [
                // Header with countdown
                _buildHeader(context, controller, dark),

                const SizedBox(height: TSizes.spaceBtwSections),

                // Trip request card
                Expanded(child: _buildTripRequestCard(context, request, dark)),

                const SizedBox(height: TSizes.spaceBtwSections),

                // Action buttons
                _buildActionButtons(context, controller, dark),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    TripManagementController controller,
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
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(TSizes.sm),
            decoration: BoxDecoration(
              color: TColors.warning.withOpacity(0.1),
              borderRadius: BorderRadius.circular(TSizes.cardRadiusMd),
            ),
            child: Icon(
              Iconsax.clock,
              color: TColors.warning,
              size: TSizes.iconLg,
            ),
          ),
          const SizedBox(width: TSizes.spaceBtwItems),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'New Trip Request',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: TSizes.xs),
                Text(
                  'Respond within time limit',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: dark ? TColors.lightGrey : TColors.darkGrey,
                  ),
                ),
              ],
            ),
          ),
          Obx(
            () => Container(
              padding: const EdgeInsets.symmetric(
                horizontal: TSizes.md,
                vertical: TSizes.sm,
              ),
              decoration: BoxDecoration(
                color: controller.requestTimeLeft.value <= 5
                    ? TColors.error
                    : TColors.warning,
                borderRadius: BorderRadius.circular(TSizes.cardRadiusLg),
              ),
              child: Text(
                '${controller.requestTimeLeft.value}s',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: TColors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTripRequestCard(
    BuildContext context,
    TripRequest request,
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
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Rider information
            _buildRiderInfo(context, request, dark),

            const SizedBox(height: TSizes.spaceBtwItems),

            // Trip route
            _buildTripRoute(context, request, dark),

            const SizedBox(height: TSizes.spaceBtwItems),

            // Trip details
            _buildTripDetails(context, request, dark),

            const SizedBox(height: TSizes.spaceBtwItems),

            // Fare information
            _buildFareInfo(context, request, dark),
          ],
        ),
      ),
    );
  }

  Widget _buildRiderInfo(BuildContext context, TripRequest request, bool dark) {
    return Row(
      children: [
        CircleAvatar(
          radius: TSizes.lg + TSizes.sm,
          backgroundColor: TColors.primary.withOpacity(0.1),
          child: Icon(
            Iconsax.user,
            color: TColors.primary,
            size: TSizes.iconLg,
          ),
        ),
        const SizedBox(width: TSizes.spaceBtwItems),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                request.riderName,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: TSizes.xs),
              Row(
                children: [
                  Icon(Icons.star, color: TColors.warning, size: TSizes.iconSm),
                  const SizedBox(width: TSizes.xs),
                  Text(
                    request.riderRating.toStringAsFixed(1),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: TSizes.spaceBtwItems),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: TSizes.sm,
                      vertical: TSizes.xs,
                    ),
                    decoration: BoxDecoration(
                      color: TColors.success.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(TSizes.cardRadiusMd),
                    ),
                    child: Text(
                      request.rideType,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: TColors.success,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: () =>
              THelperFunctions.showSnackBar('Calling ${request.riderName}...'),
          icon: Container(
            padding: const EdgeInsets.all(TSizes.sm),
            decoration: BoxDecoration(
              color: TColors.success.withOpacity(0.1),
              borderRadius: BorderRadius.circular(TSizes.cardRadiusMd),
            ),
            child: Icon(
              Iconsax.call,
              color: TColors.success,
              size: TSizes.iconSm,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTripRoute(BuildContext context, TripRequest request, bool dark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Trip Route',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: TSizes.spaceBtwItems),
        Row(
          children: [
            Column(
              children: [
                Container(
                  width: TSizes.md,
                  height: TSizes.md,
                  decoration: BoxDecoration(
                    color: TColors.success,
                    shape: BoxShape.circle,
                  ),
                ),
                Container(
                  width: 2,
                  height: TSizes.xl + TSizes.lg,
                  color: dark ? TColors.darkGrey : TColors.lightGrey,
                ),
                Container(
                  width: TSizes.md,
                  height: TSizes.md,
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
                  Container(
                    padding: const EdgeInsets.all(TSizes.sm),
                    decoration: BoxDecoration(
                      color: TColors.success.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(
                        TSizes.borderRadiusMd,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Pickup',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: TColors.success,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                        const SizedBox(height: TSizes.xs),
                        Text(
                          request.pickupAddress,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(fontWeight: FontWeight.w500),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: TSizes.spaceBtwItems),
                  Container(
                    padding: const EdgeInsets.all(TSizes.sm),
                    decoration: BoxDecoration(
                      color: TColors.error.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(
                        TSizes.borderRadiusMd,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Destination',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: TColors.error,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                        const SizedBox(height: TSizes.xs),
                        Text(
                          request.destinationAddress,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(fontWeight: FontWeight.w500),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTripDetails(
    BuildContext context,
    TripRequest request,
    bool dark,
  ) {
    return Row(
      children: [
        Expanded(
          child: _buildDetailItem(
            'Distance',
            '${request.estimatedDistance.toStringAsFixed(1)} km',
            Iconsax.route_square,
            TColors.info,
            context,
            dark,
          ),
        ),
        const SizedBox(width: TSizes.spaceBtwItems),
        Expanded(
          child: _buildDetailItem(
            'Duration',
            '${request.estimatedDuration} min',
            Iconsax.clock,
            TColors.warning,
            context,
            dark,
          ),
        ),
      ],
    );
  }

  Widget _buildDetailItem(
    String title,
    String value,
    IconData icon,
    Color color,
    BuildContext context,
    bool dark,
  ) {
    return Container(
      padding: const EdgeInsets.all(TSizes.md),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(TSizes.cardRadiusMd),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: TSizes.iconLg),
          const SizedBox(height: TSizes.sm),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
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

  Widget _buildFareInfo(BuildContext context, TripRequest request, bool dark) {
    return Container(
      padding: const EdgeInsets.all(TSizes.defaultSpace),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [TColors.success, TColors.success.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(TSizes.cardRadiusLg),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(TSizes.sm),
            decoration: BoxDecoration(
              color: TColors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(TSizes.cardRadiusMd),
            ),
            child: Icon(
              Iconsax.wallet_3,
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
                  'Estimated Fare',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: TColors.white.withOpacity(0.8),
                  ),
                ),
                const SizedBox(height: TSizes.xs),
                Text(
                  '₦${request.estimatedFare.toStringAsFixed(0)}',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: TColors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: TSizes.sm,
              vertical: TSizes.xs,
            ),
            decoration: BoxDecoration(
              color: TColors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(TSizes.cardRadiusLg),
            ),
            child: Text(
              'Cash',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: TColors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(
    BuildContext context,
    TripManagementController controller,
    bool dark,
  ) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () {
              controller.declineTripRequest();
              Get.back();
            },
            icon: Icon(Iconsax.close_circle, color: TColors.error),
            label: Text('Decline', style: TextStyle(color: TColors.error)),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: TSizes.md),
              side: BorderSide(color: TColors.error),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(TSizes.buttonRadius),
              ),
            ),
          ),
        ),
        const SizedBox(width: TSizes.spaceBtwItems),
        Expanded(
          flex: 2,
          child: ElevatedButton.icon(
            onPressed: () async {
              await controller.acceptTripRequest();
              Get.back();
            },
            icon: Icon(Iconsax.tick_circle, color: TColors.white),
            label: Text(
              'Accept Trip',
              style: TextStyle(
                color: TColors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: TColors.success,
              padding: const EdgeInsets.symmetric(vertical: TSizes.md),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(TSizes.buttonRadius),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNoRequestScreen(BuildContext context, bool dark) {
    // Auto-redirect to dashboard after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      if (Get.isRegistered<TripManagementController>()) {
        final controller = Get.find<TripManagementController>();
        if (controller.currentTripRequest.value == null) {
          Get.back();
        }
      }
    });

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(TSizes.defaultSpace),
        child: Column(
          children: [
            // Header with back button
            Row(
              children: [
                IconButton(
                  onPressed: () => Get.back(),
                  icon: Icon(
                    Iconsax.arrow_left_2,
                    color: dark ? TColors.light : TColors.dark,
                    size: TSizes.iconLg,
                  ),
                ),
                Expanded(
                  child: Text(
                    'Trip Request',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                SizedBox(width: TSizes.iconLg + 16), // Balance the back button
              ],
            ),

            // No request message
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(TSizes.xl),
                      decoration: BoxDecoration(
                        color: TColors.warning.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Iconsax.clock,
                        size: TSizes.xl * 2,
                        color: TColors.warning,
                      ),
                    ),

                    const SizedBox(height: TSizes.spaceBtwSections),

                    Text(
                      'No Active Trip Request',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),

                    const SizedBox(height: TSizes.spaceBtwItems),

                    Text(
                      'The trip request has expired or been cancelled.\nReturning to dashboard...',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: dark ? TColors.lightGrey : TColors.darkGrey,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: TSizes.spaceBtwSections),

                    // Loading indicator
                    SizedBox(
                      width: TSizes.xl,
                      height: TSizes.xl,
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          TColors.primary,
                        ),
                      ),
                    ),

                    const SizedBox(height: TSizes.spaceBtwSections),

                    ElevatedButton.icon(
                      onPressed: () => Get.back(),
                      icon: const Icon(Iconsax.home),
                      label: const Text('Back to Dashboard'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: TColors.primary,
                        foregroundColor: TColors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: TSizes.xl,
                          vertical: TSizes.md,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
