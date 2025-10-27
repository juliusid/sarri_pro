import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:sarri_ride/features/notifications/controllers/notification_controller.dart';
import 'package:sarri_ride/utils/constants/colors.dart';
import 'package:sarri_ride/utils/constants/sizes.dart';
import 'package:sarri_ride/utils/helpers/helper_functions.dart';
import 'package:intl/intl.dart'; // For date formatting

// Placeholder Model - Replace with actual model if backend provides more details
class AppNotification {
  final String id;
  final String message;
  final String type; // e.g., 'ride_update', 'promo', 'system'
  final DateTime timestamp;
  final bool isRead;

  AppNotification({
    required this.id,
    required this.message,
    required this.type,
    required this.timestamp,
    this.isRead = false,
  });
}

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final notificationController = Get.find<NotificationController>();
    final dark = THelperFunctions.isDarkMode(context);

    // --- Placeholder Data ---
    // TODO: Replace this with actual notifications fetched or stored by NotificationController
    final RxList<AppNotification> notifications = <AppNotification>[
      AppNotification(
        id: '1',
        message: 'Your driver John Doe has arrived!',
        type: 'ride_update',
        timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
      ),
      AppNotification(
        id: '2',
        message: 'Ride completed. Fare: ₦3200',
        type: 'ride_update',
        timestamp: DateTime.now().subtract(const Duration(hours: 1)),
        isRead: true,
      ),
      AppNotification(
        id: '3',
        message: 'Get 20% off your next 3 rides! Use code RIDE20.',
        type: 'promo',
        timestamp: DateTime.now().subtract(const Duration(days: 1)),
      ),
      AppNotification(
        id: '4',
        message: 'System maintenance scheduled for Sunday 2 AM.',
        type: 'system',
        timestamp: DateTime.now().subtract(const Duration(days: 2)),
        isRead: true,
      ),
    ].obs;
    // --- End Placeholder ---

    // Mark as read when screen is opened (can be moved to onInit if using StatefulWidget/GetxController for screen)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notificationController.markAsRead();
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        leading: IconButton(
          icon: Icon(
            Iconsax.arrow_left_2,
            color: dark ? TColors.white : TColors.black,
          ),
          onPressed: () => Get.back(),
        ),
        actions: [
          IconButton(
            icon: Icon(
              Iconsax.trash,
              color: dark ? TColors.white : TColors.black,
            ),
            tooltip: 'Clear All',
            onPressed: () {
              // TODO: Implement clear all logic
              notifications.clear(); // Placeholder action
              THelperFunctions.showSnackBar(
                'Cleared all notifications (placeholder)',
              );
            },
          ),
          const SizedBox(width: TSizes.sm),
        ],
      ),
      body: Obx(
        // Use Obx to rebuild list when notifications change (if they become reactive)
        () {
          if (notifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Iconsax.notification_bing, size: 60, color: Colors.grey),
                  const SizedBox(height: TSizes.spaceBtwItems),
                  Text(
                    'No Notifications Yet',
                    style: Theme.of(context).textTheme.headlineSmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: TSizes.xs),
                  Text(
                    'Important updates will appear here.',
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
            padding: const EdgeInsets.symmetric(vertical: TSizes.md),
            itemCount: notifications.length,
            separatorBuilder: (_, __) => Divider(
              height: 0,
              indent: 70,
              color: dark ? TColors.darkGrey : TColors.grey,
            ),
            itemBuilder: (context, index) {
              final notification = notifications[index];
              return ListTile(
                leading: _getNotificationIcon(notification.type),
                title: Text(
                  notification.message,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: notification.isRead
                        ? FontWeight.normal
                        : FontWeight.bold,
                  ),
                ),
                subtitle: Text(
                  _formatTimestamp(notification.timestamp),
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: Colors.grey),
                ),
                trailing: !notification.isRead
                    ? Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: TColors.primary,
                          shape: BoxShape.circle,
                        ),
                      )
                    : null,
                onTap: () {
                  // TODO: Handle notification tap (e.g., navigate to linked content)
                  print("Tapped notification: ${notification.id}");
                  // Mark as read visually (update actual state in controller later)
                  // notifications[index] = AppNotification(... notification.copyWith(isRead: true) ...);
                  // notificationController.markSingleAsRead(notification.id); // Example controller method
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _getNotificationIcon(String type) {
    IconData iconData;
    Color color;
    switch (type.toLowerCase()) {
      case 'ride_update':
        iconData = Iconsax.location;
        color = TColors.primary;
        break;
      case 'promo':
        iconData = Iconsax.discount_shape;
        color = TColors.success;
        break;
      case 'system':
        iconData = Iconsax.info_circle;
        color = TColors.info;
        break;
      default:
        iconData = Iconsax.notification;
        color = TColors.warning;
    }
    return CircleAvatar(
      backgroundColor: color.withOpacity(0.1),
      child: Icon(iconData, color: color, size: 20),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inSeconds < 60) return 'Just now';
    if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
    if (difference.inHours < 24) return '${difference.inHours}h ago';
    if (difference.inDays == 1) return 'Yesterday';
    // Use intl package for more robust date formatting
    return DateFormat('dd MMM yyyy').format(timestamp);
  }
}
