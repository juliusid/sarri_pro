import 'package:get/get.dart';

class ChatController extends GetxController {
  static ChatController get instance => Get.find();

  // Observable for total unread messages across all chats
  final RxInt totalUnreadCount = 0.obs;

  // TODO: Implement more granular tracking if needed (e.g., Map<String, int> unreadPerChat)

  @override
  void onInit() {
    super.onInit();
    // TODO: Load initial unread count from storage or API if needed
  }

  // Called by WebSocketService when a new message arrives for any chat
  void handleIncomingMessage(dynamic messageData) {
    if (messageData is Map && messageData['chatId'] != null) {
      final chatId = messageData['chatId'];
      print("ChatController: Received message for chat $chatId");

      // Basic implementation: Increment total count.
      // Better implementation: Check if the specific chat screen is active.
      // If not active, increment the count for that chat and the total count.
      bool isChatScreenActive =
          Get.currentRoute == '/MessageScreen'; // Basic check
      // More robust check: Compare active screen's chatId with incoming messageData['chatId']
      // final messageScreenController = Get.isRegistered<MessageScreenController>() ? Get.find<MessageScreenController>() : null;
      // bool isActiveChat = isChatScreenActive && messageScreenController?.chatId == chatId;

      if (!isChatScreenActive) {
        // Only increment if user is not viewing the chat
        totalUnreadCount.value++;
        print(
          "ChatController: Incremented total unread count to ${totalUnreadCount.value}",
        );
      } else {
        print(
          "ChatController: Message received while chat screen might be active. Not incrementing total count.",
        );
      }
    }
  }

  // Called when a user reads messages (e.g., opens MessageScreen)
  void markChatAsRead(String chatId) {
    print("ChatController: Marking chat $chatId as read (Placeholder)");
    // TODO: Implement logic to decrease totalUnreadCount based on the specific chat's unread count
    // For simplicity now, let's just reset the total count when *any* chat is opened.
    // This is not ideal but works as a starting point.
    if (totalUnreadCount.value > 0) {
      totalUnreadCount.value = 0; // Reset total count
      print("ChatController: Reset total unread count to 0");
    }
  }
}
