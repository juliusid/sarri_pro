import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:sarri_ride/features/ride/controllers/ride_controller.dart';
import 'package:sarri_ride/utils/constants/colors.dart';
import 'package:sarri_ride/utils/constants/sizes.dart';
import 'package:sarri_ride/utils/helpers/helper_functions.dart';

class PromoCodeSheet extends StatelessWidget {
  const PromoCodeSheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => const PromoCodeSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dark = THelperFunctions.isDarkMode(context);
    final controller = Get.find<RideController>();
    final textColor = dark ? TColors.white : TColors.textPrimary;
    final subtitleColor = dark ? TColors.lightGrey : TColors.textSecondary;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.all(TSizes.defaultSpace),
        decoration: BoxDecoration(
          color: dark ? TColors.dark : Colors.white,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(TSizes.cardRadiusLg),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: dark ? TColors.darkGrey : Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Promo code',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: textColor,
                  ),
                ),
                IconButton(
                  onPressed: () => Get.back(),
                  icon: Icon(Icons.close, color: subtitleColor),
                ),
              ],
            ),
            Text(
              'Apply a code to save on this ride.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: subtitleColor,
              ),
            ),
            const SizedBox(height: TSizes.spaceBtwSections),

            Obx(
              () => TextField(
                controller: controller.promoCodeController,
                textCapitalization: TextCapitalization.characters,
                enabled: !controller.isCheckingPromoCode.value,
                autofocus: true,
                style: TextStyle(color: textColor),
                decoration: InputDecoration(
                  hintText: 'Enter code',
                  hintStyle: TextStyle(color: subtitleColor),
                  prefixIcon: Icon(Iconsax.ticket_discount, color: subtitleColor),
                  filled: true,
                  fillColor: dark ? TColors.darkerGrey : Colors.grey[100],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(TSizes.inputFieldRadius),
                    borderSide: BorderSide.none,
                  ),
                  errorText: controller.promoCodeError.value.isNotEmpty
                      ? controller.promoCodeError.value
                      : null,
                ),
                onSubmitted: (_) => _handleApply(controller),
              ),
            ),
            const SizedBox(height: TSizes.spaceBtwItems),

            Obx(
              () => SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: controller.isCheckingPromoCode.value
                      ? null
                      : () => _handleApply(controller),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: TColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(TSizes.buttonRadius),
                    ),
                    elevation: 0,
                  ),
                  child: controller.isCheckingPromoCode.value
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          'Apply',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                ),
              ),
            ),
            SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
          ],
        ),
      ),
    );
  }

  Future<void> _handleApply(RideController controller) async {
    await controller.applyPromoCode();
    if (controller.hasValidPromoCode) {
      Get.back();
    }
  }
}
