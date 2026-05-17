// lib/features/authentication/screens/debug/debug_snackbar_screen.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:sarri_ride/utils/constants/colors.dart';
import 'package:sarri_ride/utils/constants/sizes.dart';
import 'package:sarri_ride/utils/helpers/helper_functions.dart';

class DebugSnackbarScreen extends StatelessWidget {
  const DebugSnackbarScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final dark = THelperFunctions.isDarkMode(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('iOS Snackbar Diagnostics'),
        leading: IconButton(
          icon: const Icon(Iconsax.arrow_left_2),
          onPressed: () => Get.back(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(TSizes.defaultSpace),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Diagnostic Console',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: TSizes.spaceBtwItems),
            Text(
              'Tap each button to trigger different snackbar rendering methods. Note which ones display correctly on your physical iOS device.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: dark ? Colors.grey[400] : Colors.grey[600],
                  ),
            ),
            const SizedBox(height: TSizes.spaceBtwSections),

            // Button 1
            _buildDebugCard(
              context,
              title: '1. Current RawSnackbar (Top)',
              subtitle: 'Uses your current Get.rawSnackbar with default top settings.',
              onTap: () {
                THelperFunctions.showSuccessSnackBar(
                  'Current RawSnackbar',
                  'This is the current raw snackbar at the top.',
                );
              },
              color: Colors.red,
            ),
            const SizedBox(height: TSizes.spaceBtwItems),

            // Button 2
            _buildDebugCard(
              context,
              title: '2. Standard Get.snackbar',
              subtitle: 'Uses Get.snackbar() which natively respects safe areas.',
              onTap: () {
                Get.snackbar(
                  'Standard Get.snackbar',
                  'This uses standard Get.snackbar.',
                  snackPosition: SnackPosition.TOP,
                  backgroundColor: TColors.success.withOpacity(0.9),
                  colorText: Colors.white,
                  icon: const Icon(Iconsax.tick_circle, color: Colors.white),
                  margin: const EdgeInsets.all(15),
                );
              },
              color: Colors.green,
            ),
            const SizedBox(height: TSizes.spaceBtwItems),

            // Button 3
            _buildDebugCard(
              context,
              title: '3. RawSnackbar with Notch Margin Offset',
              subtitle: 'RawSnackbar with a top margin of 60px to bypass Dynamic Island.',
              onTap: () {
                Get.rawSnackbar(
                  title: 'RawSnackbar Offset',
                  messageText: const Text(
                    'Pushed down 60px to clear the Dynamic Island / Notch.',
                    style: TextStyle(color: Colors.white, fontSize: 14),
                  ),
                  backgroundColor: TColors.success.withOpacity(0.9),
                  icon: const Icon(Iconsax.tick_circle, color: Colors.white, size: 28),
                  margin: const EdgeInsets.only(top: 60, left: 15, right: 15),
                  borderRadius: 10,
                  duration: const Duration(seconds: 3),
                  isDismissible: true,
                  snackPosition: SnackPosition.TOP,
                );
              },
              color: Colors.purple,
            ),
            const SizedBox(height: TSizes.spaceBtwItems),

            // Button 4
            _buildDebugCard(
              context,
              title: '4. RawSnackbar at Bottom',
              subtitle: 'Renders at the bottom of the screen instead of the top.',
              onTap: () {
                Get.rawSnackbar(
                  title: 'Bottom RawSnackbar',
                  messageText: const Text(
                    'This raw snackbar is rendered at the bottom.',
                    style: TextStyle(color: Colors.white, fontSize: 14),
                  ),
                  backgroundColor: TColors.success.withOpacity(0.9),
                  icon: const Icon(Iconsax.tick_circle, color: Colors.white, size: 28),
                  margin: const EdgeInsets.all(15),
                  borderRadius: 10,
                  duration: const Duration(seconds: 3),
                  isDismissible: true,
                  snackPosition: SnackPosition.BOTTOM,
                );
              },
              color: Colors.blue,
            ),
            const SizedBox(height: TSizes.spaceBtwItems),

            // Button 5
            _buildDebugCard(
              context,
              title: '5. Native Flutter SnackBar',
              subtitle: 'Standard native ScaffoldMessenger (completely bypasses GetX).',
              onTap: () {
                final snackBar = SnackBar(
                  content: const Row(
                    children: [
                      Icon(Iconsax.tick_circle, color: Colors.white),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Native SnackBar logic works!',
                          style: TextStyle(color: Colors.white, fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                  backgroundColor: TColors.success,
                  behavior: SnackBarBehavior.floating,
                  margin: const EdgeInsets.all(15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                );
                ScaffoldMessenger.of(context).showSnackBar(snackBar);
              },
              color: Colors.orange,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDebugCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required Color color,
  }) {
    final dark = THelperFunctions.isDarkMode(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: dark ? Colors.grey[800]! : Colors.grey[300]!,
          ),
          color: dark ? Colors.grey[900]?.withOpacity(0.5) : Colors.grey[50]!,
        ),
        child: Row(
          children: [
            Container(
              width: 4,
              height: 48,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: dark ? Colors.grey[400] : Colors.grey[600],
                        ),
                  ),
                ],
              ),
            ),
            const Icon(
              Iconsax.arrow_right_3,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
