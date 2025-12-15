import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:sarri_ride/features/communication/controllers/call_controller.dart';
import 'package:sarri_ride/utils/constants/colors.dart';
import 'package:sarri_ride/utils/constants/sizes.dart';

class ActiveCallScreen extends StatelessWidget {
  const ActiveCallScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<CallController>();

    return Scaffold(
      backgroundColor: TColors.dark,
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(flex: 1),

            // Profile & Status
            Column(
              children: [
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: TColors.darkerGrey,
                    border: Border.all(
                      color: TColors.primary.withOpacity(0.5),
                      width: 2,
                    ),
                  ),
                  child: const Icon(
                    Iconsax.user,
                    size: 60,
                    color: Colors.white,
                  ),
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

                Obx(() {
                  if (controller.callState.value == CallState.dialing) {
                    return const Text(
                      "Calling...",
                      style: TextStyle(color: Colors.grey, fontSize: 18),
                    );
                  } else if (controller.callState.value == CallState.active) {
                    // <--- FIXED HERE
                    return Text(
                      controller.formattedDuration,
                      style: const TextStyle(
                        color: TColors.success,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    );
                  } else {
                    return const Text(
                      "Connecting...",
                      style: TextStyle(color: Colors.grey, fontSize: 18),
                    );
                  }
                }),
              ],
            ),

            const Spacer(flex: 2),

            // Controls
            Container(
              padding: const EdgeInsets.only(bottom: 50, left: 30, right: 30),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Mute
                  Obx(
                    () => _buildCircleButton(
                      icon: controller.isMuted.value
                          ? Icons.mic_off
                          : Icons.mic,
                      color: controller.isMuted.value
                          ? Colors.white
                          : Colors.grey,
                      bgColor: controller.isMuted.value
                          ? Colors.grey.withOpacity(0.5)
                          : Colors.transparent,
                      onTap: () => controller.toggleMute(),
                    ),
                  ),

                  // Hangup
                  FloatingActionButton.large(
                    backgroundColor: TColors.error,
                    onPressed: () => controller.hangUp(),
                    child: const Icon(
                      Icons.call_end,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),

                  // Speaker
                  Obx(
                    () => _buildCircleButton(
                      icon: controller.isSpeakerOn.value
                          ? Icons.volume_up
                          : Icons.volume_off,
                      color: controller.isSpeakerOn.value
                          ? Colors.white
                          : Colors.grey,
                      bgColor: controller.isSpeakerOn.value
                          ? Colors.grey.withOpacity(0.5)
                          : Colors.transparent,
                      onTap: () => controller.toggleSpeaker(),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCircleButton({
    required IconData icon,
    required Color color,
    required Color bgColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: bgColor,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.grey.withOpacity(0.3)),
        ),
        child: Icon(icon, color: color, size: 28),
      ),
    );
  }
}
