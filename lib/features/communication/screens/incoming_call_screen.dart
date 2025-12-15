import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:sarri_ride/features/communication/controllers/call_controller.dart';
import 'package:sarri_ride/utils/constants/colors.dart';
import 'package:sarri_ride/utils/constants/sizes.dart';

class IncomingCallScreen extends StatelessWidget {
  const IncomingCallScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<CallController>();

    return Scaffold(
      backgroundColor: TColors.dark,
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Column(
              children: [
                const CircleAvatar(
                  radius: 60,
                  backgroundColor: TColors.darkerGrey,
                  child: Icon(Iconsax.user, size: 60, color: Colors.white),
                ),
                const SizedBox(height: TSizes.spaceBtwItems),
                Obx(
                  () => Text(
                    controller.otherPartyName.value,
                    style: Theme.of(
                      context,
                    ).textTheme.headlineMedium?.copyWith(color: Colors.white),
                  ),
                ),
                const SizedBox(height: TSizes.sm),
                const Text(
                  "Incoming Voice Call...",
                  style: TextStyle(color: Colors.white70, fontSize: 16),
                ),
              ],
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Decline
                  Column(
                    children: [
                      FloatingActionButton.large(
                        heroTag: 'decline',
                        backgroundColor: TColors.error,
                        onPressed: () => controller.rejectCall(),
                        child: const Icon(Icons.call_end, color: Colors.white),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        "Decline",
                        style: TextStyle(color: Colors.white),
                      ),
                    ],
                  ),

                  // Accept
                  Column(
                    children: [
                      FloatingActionButton.large(
                        heroTag: 'accept',
                        backgroundColor: TColors.success,
                        onPressed: () => controller.acceptCall(),
                        child: const Icon(Icons.call, color: Colors.white),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        "Accept",
                        style: TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
