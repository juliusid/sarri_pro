import 'package:get/get.dart';

class NotificationController extends GetxController {
  static NotificationController get instance => Get.find();

  // Observable variable for unread count
  final RxInt unreadCount = 0.obs;

  // Method to handle incoming notification data from WebSocketService
  void handleNewNotification(dynamic notificationData) {
    print(
      "NotificationController: Handling new notification data: $notificationData",
    );
    if (notificationData is Map && notificationData['unreadCount'] is int) {
      // Update the unread count
      unreadCount.value = notificationData['unreadCount'];
      print(
        "NotificationController: Unread count updated to ${unreadCount.value}",
      );

      // TODO: Optionally process the 'notification' object within the payload
      // - Store the notification details locally?
      // - Show an in-app banner/popup?
      // final notificationDetails = notificationData['notification'];
      // if (notificationDetails is Map) {
      //   print("Notification Message: ${notificationDetails['message']}");
      // }
    } else {
      print(
        "NotificationController: Received invalid data format for notification:new",
      );
    }
  }

  // Method to mark notifications as read (example)
  void markAsRead() {
    // TODO: Implement logic to mark notifications as read, possibly call an API
    unreadCount.value = 0;
    print("NotificationController: Marked notifications as read.");
  }
}
