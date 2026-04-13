import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:sarri_ride/features/communication/controllers/chat_controller.dart';
import 'package:sarri_ride/features/communication/screens/message_screen.dart';
import 'package:sarri_ride/features/ride/controllers/ride_controller.dart';
import 'package:sarri_ride/utils/constants/colors.dart';
import 'package:sarri_ride/utils/constants/sizes.dart';
import 'package:sarri_ride/utils/helpers/helper_functions.dart';

class ChatListScreen extends StatelessWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final chatController = Get.find<ChatController>();
    final dark = THelperFunctions.isDarkMode(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages'),
        leading: IconButton(
          icon: Icon(
            Iconsax.arrow_left_2,
            color: dark ? TColors.white : TColors.black,
          ),
          onPressed: () => Get.back(),
        ),
      ),
      body: Obx(() {
        if (!Get.isRegistered<RideController>()) {
          return _emptyState(
            context,
            subtitle: 'Open the app from a ride to message your driver.',
          );
        }

        final rideController = Get.find<RideController>();
        final chatId = rideController.activeRideChatId.value;
        final driver = rideController.assignedDriver.value;

        if (chatId.isEmpty || driver == null) {
          return _emptyState(
            context,
            subtitle:
                'When you have an active ride, your driver chat will appear here. You can also open chat from the ride screen.',
          );
        }

        final unread = chatController.totalUnreadCount.value;

        return ListView.separated(
          padding: const EdgeInsets.symmetric(vertical: TSizes.md),
          itemCount: 1,
          separatorBuilder: (_, __) => const SizedBox.shrink(),
          itemBuilder: (context, index) {
            return ListTile(
              leading: CircleAvatar(
                backgroundColor: TColors.primary.withOpacity(0.1),
                backgroundImage: (driver.profileImage != null &&
                        driver.profileImage!.isNotEmpty)
                    ? NetworkImage(driver.profileImage!)
                    : null,
                child: (driver.profileImage == null ||
                        driver.profileImage!.isEmpty)
                    ? const Icon(
                        Iconsax.user,
                        color: TColors.primary,
                        size: 20,
                      )
                    : null,
              ),
              title: Text(
                driver.name,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: const Text(
                'Tap to open driver chat',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: unread > 0
                  ? Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: TColors.error,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        unread > 99 ? '99+' : '$unread',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    )
                  : Text(
                      'Active ride',
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: Colors.grey),
                    ),
              onTap: () {
                chatController.markChatAsRead(chatId);
                Get.to(
                  () => MessageScreen(
                    driverName: driver.name,
                    carModel: driver.carModel,
                    plateNumber: driver.plateNumber,
                    rating: driver.rating,
                    chatId: chatId,
                    profileImage: driver.profileImage,
                  ),
                );
              },
            );
          },
        );
      }),
    );
  }

  Widget _emptyState(BuildContext context, {required String subtitle}) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Iconsax.message_remove, size: 60, color: Colors.grey),
          const SizedBox(height: TSizes.spaceBtwItems),
          Text(
            'No Chats Yet',
            style: Theme.of(context).textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: TSizes.xs),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: TSizes.lg),
            child: Text(
              subtitle,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}
