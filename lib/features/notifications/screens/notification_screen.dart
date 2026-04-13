import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import 'package:sarri_ride/features/notifications/controllers/notification_controller.dart';
import 'package:sarri_ride/utils/constants/colors.dart';
import 'package:sarri_ride/utils/constants/sizes.dart';
import 'package:sarri_ride/utils/helpers/helper_functions.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Get.find<NotificationController>().markAsRead();
    });
  }

  @override
  Widget build(BuildContext context) {
    final notificationController = Get.find<NotificationController>();
    final dark = THelperFunctions.isDarkMode(context);

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
          Obx(() {
            final empty = notificationController.items.isEmpty;
            return IconButton(
              icon: Icon(
                Iconsax.trash,
                color: empty
                    ? Colors.grey
                    : (dark ? TColors.white : TColors.black),
              ),
              tooltip: 'Clear All',
              onPressed: empty
                  ? null
                  : () {
                      notificationController.clearAll();
                      THelperFunctions.showSnackBar('All notifications cleared');
                    },
            );
          }),
          const SizedBox(width: TSizes.sm),
        ],
      ),
      body: Obx(() {
        final notifications = notificationController.items;
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
                  'Ride updates and alerts will appear here.',
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
                notificationController.markSingleRead(notification.id);
              },
            );
          },
        );
      }),
    );
  }

  Widget _getNotificationIcon(String type) {
    IconData iconData;
    Color color;
    switch (type.toLowerCase()) {
      case 'ride_update':
      case 'ride_booking':
      case 'ride_accepted':
      case 'ride_started':
      case 'ride_ended':
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
    return DateFormat('dd MMM yyyy').format(timestamp);
  }
}
