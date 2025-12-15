import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:sarri_ride/features/payment/controllers/payment_controller.dart';
import 'package:sarri_ride/features/ride/controllers/ride_controller.dart';
import 'package:sarri_ride/utils/constants/colors.dart';
import 'package:sarri_ride/utils/constants/sizes.dart';
import 'package:sarri_ride/utils/helpers/helper_functions.dart';

class PaymentMethodsScreen extends StatefulWidget {
  const PaymentMethodsScreen({super.key});

  @override
  State<PaymentMethodsScreen> createState() => _PaymentMethodsScreenState();
}

class _PaymentMethodsScreenState extends State<PaymentMethodsScreen> {
  final PaymentController controller = Get.put(PaymentController());
  String selectedPaymentId = 'cash'; // Default to cash to prevent null errors

  @override
  void initState() {
    super.initState();
    controller.fetchSavedCards();

    // Auto-select default card if it exists, otherwise stay on Cash
    controller.savedCards.listen((cards) {
      if (cards.isNotEmpty && selectedPaymentId == 'cash') {
        final defaultCard = cards.firstWhereOrNull((c) => c.isDefault);
        if (defaultCard != null) {
          setState(() {
            selectedPaymentId = defaultCard.cardId;
          });
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final dark = THelperFunctions.isDarkMode(context);

    return Scaffold(
      backgroundColor: dark ? TColors.dark : TColors.lightGrey,

      // --- 1. YOUR ORIGINAL APP BAR ---
      appBar: AppBar(
        title: const Text('Payment Methods'),
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
            onPressed: () => controller.addNewCard(),
            icon: Icon(
              Iconsax.add,
              color: dark ? TColors.light : TColors.dark,
              size: TSizes.iconLg,
            ),
          ),
        ],
      ),

      body: SingleChildScrollView(
        child: Column(
          children: [
            // --- 2. YOUR ORIGINAL HEADER CARD ---
            Container(
              width: double.infinity,
              margin: const EdgeInsets.all(TSizes.defaultSpace),
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
                              'Payment Methods',
                              style: Theme.of(context).textTheme.headlineSmall
                                  ?.copyWith(
                                    color: TColors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            const SizedBox(height: TSizes.xs),
                            Text(
                              'Manage your payment options securely',
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

            // --- 3. IMPROVED LIST (CRASH PROOF) ---
            Container(
              margin: const EdgeInsets.symmetric(
                horizontal: TSizes.defaultSpace,
              ),
              decoration: BoxDecoration(
                color: dark ? TColors.dark : Colors.transparent,
                borderRadius: BorderRadius.circular(TSizes.cardRadiusLg),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 8),
                    child: Text(
                      'Select Payment Method',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: dark ? TColors.white : TColors.black,
                      ),
                    ),
                  ),

                  // The List
                  Obx(() {
                    if (controller.isLoading.value &&
                        controller.savedCards.isEmpty) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(20.0),
                          child: CircularProgressIndicator(),
                        ),
                      );
                    }

                    // Create "Cash" option manually
                    final cashOption = PaymentCardModel(
                      cardId: 'cash',
                      last4: '',
                      brand: 'Cash',
                      cardType: 'cash',
                      bank: 'Pay driver directly',
                      isDefault: false,
                      expiry: '',
                    );

                    // Combine Cash + API Cards into one list
                    // This ensures length is ALWAYS >= 1. NO CRASH.
                    final allOptions = [cashOption, ...controller.savedCards];

                    return Column(
                      children: List.generate(allOptions.length, (index) {
                        final method = allOptions[index];
                        final isLast = index == allOptions.length - 1;

                        return _buildPaymentMethodCard(
                          method,
                          dark,
                          context,
                          isLast,
                        );
                      }),
                    );
                  }),
                ],
              ),
            ),

            const SizedBox(height: TSizes.spaceBtwSections),

            // --- 4. ADD NEW CARD BUTTON ---
            Container(
              margin: const EdgeInsets.symmetric(
                horizontal: TSizes.defaultSpace,
              ),
              child: InkWell(
                onTap: () => controller.addNewCard(),
                borderRadius: BorderRadius.circular(TSizes.cardRadiusLg),
                child: Container(
                  padding: const EdgeInsets.all(TSizes.defaultSpace),
                  decoration: BoxDecoration(
                    color: dark ? TColors.darkerGrey : TColors.white,
                    borderRadius: BorderRadius.circular(TSizes.cardRadiusLg),
                    border: Border.all(
                      color: TColors.primary,
                      width: 1.5,
                      style: BorderStyle.solid,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(dark ? 0.3 : 0.05),
                        blurRadius: TSizes.md,
                        offset: const Offset(0, TSizes.sm),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Iconsax.add_circle,
                        color: TColors.primary,
                        size: TSizes.iconLg,
                      ),
                      const SizedBox(width: TSizes.spaceBtwItems),
                      Text(
                        'Add New Payment Method',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: TColors.primary,
                            ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: TSizes.spaceBtwSections),

            // --- 5. SECURITY FOOTER ---
            Container(
              margin: const EdgeInsets.symmetric(
                horizontal: TSizes.defaultSpace,
              ),
              padding: const EdgeInsets.all(TSizes.defaultSpace),
              decoration: BoxDecoration(
                color: TColors.info.withOpacity(0.1),
                borderRadius: BorderRadius.circular(TSizes.cardRadiusLg),
                border: Border.all(color: TColors.info.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(
                    Iconsax.shield_tick,
                    color: TColors.info,
                    size: TSizes.iconMd,
                  ),
                  const SizedBox(width: TSizes.spaceBtwItems),
                  Expanded(
                    child: Text(
                      'All payment information is encrypted and secured.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: dark ? TColors.lightGrey : TColors.darkGrey,
                      ),
                    ),
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

  // --- HELPER: MODERN TILE BUILDER ---
  Widget _buildPaymentMethodCard(
    PaymentCardModel method,
    bool dark,
    BuildContext context,
    bool isLast,
  ) {
    final isSelected = selectedPaymentId == method.cardId;
    final bool isCash = method.cardType == 'cash';

    IconData icon;
    Color iconColor;

    // Set Icons based on type
    if (isCash) {
      icon = Iconsax.money;
      iconColor = TColors.success;
    } else {
      icon = Iconsax.card;
      iconColor = TColors.primary;
    }

    return Container(
      margin: EdgeInsets.only(bottom: isLast ? 0 : 12),
      decoration: BoxDecoration(
        color: dark ? TColors.darkerGrey : TColors.white,
        borderRadius: BorderRadius.circular(TSizes.cardRadiusMd),
        border: Border.all(
          color: isSelected ? TColors.primary : Colors.transparent,
          width: 2,
        ),
        boxShadow: [
          if (!dark)
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(TSizes.cardRadiusMd),
          onTap: () {
            setState(() {
              selectedPaymentId = method.cardId;
            });
            // Update Ride Controller Safely
            if (Get.isRegistered<RideController>()) {
              Get.find<RideController>().selectPaymentMethod(
                isCash ? 'Cash' : method.displayName,
                cardId: isCash ? null : method.cardId,
              );
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Icon Box
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: iconColor, size: 24),
                ),
                const SizedBox(width: 16),

                // Text Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isCash ? "CASH" : method.brand.toUpperCase(),
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: TColors.darkGrey,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isCash
                            ? "Pay driver directly"
                            : "**** **** **** ${method.last4}",
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: dark ? TColors.white : TColors.black,
                            ),
                      ),
                    ],
                  ),
                ),

                // Selection Tick or Delete
                if (isSelected)
                  const Icon(
                    Iconsax.tick_circle,
                    color: TColors.primary,
                    size: 24,
                  )
                else if (!isCash)
                  IconButton(
                    icon: const Icon(
                      Iconsax.trash,
                      color: TColors.error,
                      size: 20,
                    ),
                    onPressed: () => _showDeleteConfirmation(method),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showDeleteConfirmation(PaymentCardModel method) {
    Get.dialog(
      AlertDialog(
        title: const Text('Delete Card'),
        content: Text(
          'Are you sure you want to remove ${method.brand} ending in ${method.last4}?',
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              Get.back();
              THelperFunctions.showSnackBar('Feature coming soon: Delete API');
              // controller.deleteCard(method.cardId); // Uncomment when API is ready
            },
            child: const Text('Delete', style: TextStyle(color: TColors.error)),
          ),
        ],
      ),
    );
  }
}
