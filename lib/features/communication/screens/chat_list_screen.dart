import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import 'package:sarri_ride/features/communication/controllers/chat_controller.dart';
import 'package:sarri_ride/utils/constants/colors.dart';
import 'package:sarri_ride/utils/constants/sizes.dart';
import 'package:sarri_ride/utils/helpers/helper_functions.dart';

// Placeholder Model - Replace with actual chat list item model
class ChatListItem {
  final String chatId;
  final String participantName;
  final String lastMessage;
  final DateTime lastMessageTime;
  final int unreadCount;
  final bool isDriver; // To show correct avatar

  ChatListItem({
    required this.chatId,
    required this.participantName,
    required this.lastMessage,
    required this.lastMessageTime,
    this.unreadCount = 0,
    required this.isDriver,
  });
}

class ChatListScreen extends StatelessWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final chatController = Get.find<ChatController>();
    final dark = THelperFunctions.isDarkMode(context);

    // --- Placeholder Data ---
    // TODO: Replace with actual chat list fetched/managed by ChatController
    final RxList<ChatListItem> chats = <ChatListItem>[
      ChatListItem(
        chatId: 'chat123',
        participantName: 'Driver John D.',
        lastMessage: 'Okay, see you soon!',
        lastMessageTime: DateTime.now().subtract(Duration(minutes: 10)),
        unreadCount: 0,
        isDriver: true,
      ),
      ChatListItem(
        chatId: 'chat456',
        participantName: 'Support Team',
        lastMessage: 'Please provide your ride ID...',
        lastMessageTime: DateTime.now().subtract(Duration(hours: 2)),
        unreadCount: 1,
        isDriver: false,
      ), // Assuming support isn't a driver avatar
    ].obs;
    // --- End Placeholder ---

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
        // Optionally add search or other actions
      ),
      body: Obx(() {
        if (chats.isEmpty) {
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
                Text(
                  'Your conversations will appear here.',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }
        return ListView.separated(
          itemCount: chats.length,
          separatorBuilder: (_, __) => Divider(
            height: 0,
            indent: 70,
            color: dark ? TColors.darkGrey : TColors.grey,
          ),
          itemBuilder: (context, index) {
            final chat = chats[index];
            return ListTile(
              leading: CircleAvatar(
                backgroundColor: TColors.primary.withOpacity(0.1),
                child: Icon(
                  chat.isDriver
                      ? Iconsax.support
                      : Iconsax.user, // Use support icon for driver?
                  color: TColors.primary,
                  size: 20,
                ),
              ),
              title: Text(
                chat.participantName,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                chat.lastMessage,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _formatTimestamp(chat.lastMessageTime),
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: Colors.grey),
                  ),
                  if (chat.unreadCount > 0) ...[
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: TColors.error,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        chat.unreadCount.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              onTap: () {
                // TODO: Navigate to the specific MessageScreen for this chat
                print("Tapped chat: ${chat.chatId}");
                THelperFunctions.showSnackBar(
                  'Navigating to chat ${chat.chatId} - Pending Implementation',
                );
                // Example Navigation:
                // Get.to(() => MessageScreen(
                //    driverName: chat.participantName, // Need full driver details
                //    carModel: '...', // Need full driver details
                //    plateNumber: '...', // Need full driver details
                //    rating: 4.5, // Need full driver details
                //    chatId: chat.chatId,
                // ));
                // chatController.markChatAsRead(chat.chatId);
              },
            );
          },
        );
      }),
    );
  }

  // Copied from NotificationScreen - make a shared utility?
  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    if (difference.inSeconds < 60)
      return '${difference.inSeconds}s ago'; // More granular for recent
    if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
    if (difference.inHours < 24) return '${difference.inHours}h ago';
    if (difference.inDays == 1) return 'Yesterday';
    return DateFormat('dd/MM/yy').format(timestamp); // Shorter date format
  }
}
