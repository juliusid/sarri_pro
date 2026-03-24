import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:sarri_ride/features/driver/controllers/trip_management_controller.dart';
import 'package:sarri_ride/utils/constants/colors.dart';
import 'package:sarri_ride/utils/constants/sizes.dart';
import 'package:sarri_ride/utils/constants/enums.dart';

class WaitingForPaymentScreen extends StatelessWidget {
  const WaitingForPaymentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<TripManagementController>();

    return WillPopScope(
      onWillPop: () async => false, // Prevent returning to navigation randomly
      child: Scaffold(
        backgroundColor: TColors.cardBackgroundDark, // Immersive dark background for waiting
        body: SafeArea(
          child: Obx(() {
            // Check if payment changed to completely successful
            if (controller.tripStatus.value == TripStatus.completed) {
              return _buildSuccessView();
            }

            // Check if cash payment was requested
            if (controller.isWaitingForCash.value) {
              return _buildCashPendingView(controller);
            }

            // Default: waiting for electronic gateway or cash flag
            return _buildWaitingView();
          }),
        ),
      ),
    );
  }

  Widget _buildWaitingView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(TSizes.defaultSpace),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(TColors.primary),
              strokeWidth: 6,
            ),
            const SizedBox(height: TSizes.spaceBtwSections),
            const Text(
              'Waiting for Payment...',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: TColors.light,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: TSizes.spaceBtwItems),
            Text(
              'Please wait while the rider processes the payment on their device.',
              style: TextStyle(
                fontSize: 16,
                color: TColors.lightGrey,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCashPendingView(TripManagementController controller) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(TSizes.defaultSpace),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(TSizes.xl),
              decoration: BoxDecoration(
                color: TColors.warning.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Iconsax.money_tick,
                size: TSizes.xl * 2,
                color: TColors.warning,
              ),
            ),
            const SizedBox(height: TSizes.spaceBtwSections),
            const Text(
              'Cash Payment Requested',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: TColors.light,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: TSizes.spaceBtwItems),
            Text(
              'Collect ₦${controller.cashAmountToReceive.value.toStringAsFixed(0)} from the rider.',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: TColors.lightGrey,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: TSizes.spaceBtwSections),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: controller.isCompletingTrip.value 
                  ? null 
                  : () => controller.confirmCashPayment(),
                icon: controller.isCompletingTrip.value 
                  ? const SizedBox(
                      width: 20, 
                      height: 20, 
                      child: CircularProgressIndicator(color: TColors.white, strokeWidth: 2)
                    )
                  : const Icon(Iconsax.tick_circle, color: TColors.white),
                label: Text(
                  controller.isCompletingTrip.value ? 'Confirming...' : 'Confirm Cash Received',
                  style: const TextStyle(color: TColors.white, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: TColors.success,
                  padding: const EdgeInsets.symmetric(vertical: TSizes.md),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuccessView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(TSizes.defaultSpace),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(TSizes.xl),
              decoration: BoxDecoration(
                color: TColors.success.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Iconsax.tick_square,
                size: TSizes.xl * 2,
                color: TColors.success,
              ),
            ),
            const SizedBox(height: TSizes.spaceBtwSections),
            const Text(
              'Payment Successful!',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: TColors.light,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: TSizes.spaceBtwItems),
            const Text(
              'The trip has been concluded and your earnings have been updated.',
              style: TextStyle(
                fontSize: 16,
                color: TColors.lightGrey,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: TSizes.spaceBtwSections * 1.5),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  // Already handled by delayed _resetTripState in controller, 
                  // but we give a manual escape hatch.
                  Get.until((route) => route.settings.name == '/DriverDashboardScreen' || route.isFirst);
                },
                icon: const Icon(Iconsax.home, color: TColors.white),
                label: const Text(
                  'Back to Dashboard',
                  style: TextStyle(color: TColors.white, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: TColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: TSizes.md),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
