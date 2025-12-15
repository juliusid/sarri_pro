import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:sarri_ride/features/payment/controllers/payment_controller.dart'; // <-- 1. IMPORT
import 'package:sarri_ride/features/payment/screens/payment_methods_screen.dart';
import 'package:sarri_ride/features/ride/controllers/ride_controller.dart';
import 'package:sarri_ride/utils/constants/colors.dart';
import 'package:sarri_ride/utils/constants/sizes.dart';
import 'package:sarri_ride/utils/helpers/helper_functions.dart';

class PaymentSelectionSheet extends StatelessWidget {
  const PaymentSelectionSheet({super.key});

  /// Static method to show the bottom sheet
  static void show(BuildContext context) {
    final dark = THelperFunctions.isDarkMode(context);
    // 2. Ensure PaymentController is available
    Get.put(PaymentController()).fetchSavedCards(); // Fetch cards on show

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true, // Allows sheet to be smaller
      builder: (_) => const PaymentSelectionSheet(), // Build the widget
    );
  }

  // --- THIS IS THE build METHOD ---
  @override
  Widget build(BuildContext context) {
    final dark = THelperFunctions.isDarkMode(context);
    final rideController = Get.find<RideController>();
    final paymentController =
        Get.find<PaymentController>(); // <-- 3. GET CONTROLLER

    return Container(
      padding: const EdgeInsets.all(TSizes.defaultSpace),
      decoration: BoxDecoration(
        color: dark ? TColors.dark : Colors.white,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(TSizes.cardRadiusLg),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min, // Make sheet fit content
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            // ... (header is unchanged)
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Choose payment method',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              IconButton(
                onPressed: () => Get.back(),
                icon: Icon(
                  Icons.close,
                  color: dark ? TColors.lightGrey : TColors.darkGrey,
                ),
              ),
            ],
          ),
          const SizedBox(height: TSizes.spaceBtwItems),
          Text(
            'Set your payment method before requesting a trip.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: dark ? TColors.lightGrey : TColors.darkGrey,
            ),
          ),
          const SizedBox(height: TSizes.spaceBtwSections),

          // --- 4. MODIFIED PAYMENT LIST ---

          // Cash Option
          Obx(
            () => ListTile(
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: dark
                      ? TColors.darkerGrey
                      : TColors.lightGrey.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(TSizes.borderRadiusSm),
                ),
                child: const Icon(Iconsax.money, color: TColors.success),
              ),
              title: Text('Cash', style: Theme.of(context).textTheme.bodyLarge),
              onTap: () {
                // Set method to 'Cash' and cardId to null
                rideController.selectPaymentMethod('Cash', cardId: null);
                Get.back();
              },
              trailing: rideController.selectedPaymentMethod.value == 'Cash'
                  ? const Icon(Iconsax.tick_circle, color: TColors.primary)
                  : null,
            ),
          ),

          const Divider(height: TSizes.spaceBtwItems),

          // Saved Cards List
          Obx(() {
            if (paymentController.isLoading.value) {
              return const Center(child: CircularProgressIndicator());
            }
            if (paymentController.savedCards.isEmpty) {
              return const SizedBox.shrink(); // No cards, only show "Add"
            }

            return ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: paymentController.savedCards.length,
              separatorBuilder: (context, index) =>
                  const Divider(height: TSizes.spaceBtwItems),
              itemBuilder: (context, index) {
                final card = paymentController.savedCards[index];

                return ListTile(
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: dark
                          ? TColors.darkerGrey
                          : TColors.lightGrey.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(
                        TSizes.borderRadiusSm,
                      ),
                    ),
                    child: Icon(
                      card.brand.toLowerCase() == 'visa'
                          ? Iconsax.card
                          : Iconsax.card,
                      color: TColors.primary,
                    ),
                  ),
                  title: Text(
                    card.displayName, // e.g., "Visa **** 4081"
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  onTap: () {
                    // Set method to name and pass the cardId
                    rideController.selectPaymentMethod(
                      card.displayName,
                      cardId: card.cardId,
                    );
                    Get.back();
                  },
                  trailing: rideController.selectedCardId.value == card.cardId
                      ? const Icon(Iconsax.tick_circle, color: TColors.primary)
                      : null,
                );
              },
            );
          }),

          const Divider(height: TSizes.spaceBtwItems),

          // Add Debit/Credit Card
          ListTile(
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: dark
                    ? TColors.darkerGrey
                    : TColors.lightGrey.withOpacity(0.5),
                borderRadius: BorderRadius.circular(TSizes.borderRadiusSm),
              ),
              child: Icon(
                Iconsax.add,
                color: dark ? TColors.white : TColors.black,
              ),
            ),
            title: Text(
              'Add debit/credit card',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            onTap: () {
              Get.back(); // Close the bottom sheet
              Get.to(
                () => const PaymentMethodsScreen(),
              ); // Go to the add card screen
            },
          ),
          // --- END 4 ---

          // Bottom padding for safe area
          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }
}
