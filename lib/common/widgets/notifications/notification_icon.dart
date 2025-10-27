import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:sarri_ride/features/notifications/controllers/notification_controller.dart';
import 'package:sarri_ride/features/notifications/screens/notification_screen.dart';
import 'package:sarri_ride/utils/constants/colors.dart'; //
import 'package:badges/badges.dart' as badges;
import 'package:sarri_ride/utils/helpers/helper_functions.dart'; // Add badges package

class NotificationIconWidget extends StatelessWidget {
  const NotificationIconWidget({super.key, this.iconColor, this.onPressed});

  final Color? iconColor;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<NotificationController>();
    final dark = THelperFunctions.isDarkMode(context); //

    return Obx(
      () => badges.Badge(
        position: badges.BadgePosition.topEnd(top: -4, end: -4),
        badgeContent: Text(
          controller.unreadCount.value.toString(),
          style: const TextStyle(color: Colors.white, fontSize: 10),
        ),
        showBadge: controller.unreadCount.value > 0,
        badgeStyle: badges.BadgeStyle(
          badgeColor: TColors.error, //
          padding: const EdgeInsets.all(5),
        ),
        child: IconButton(
          icon: Icon(
            Iconsax.notification,
            color: iconColor ?? (dark ? TColors.white : TColors.black), //
          ),
          onPressed:
              onPressed ??
              () {
                Get.to(() => const NotificationScreen()); // Navigate here
              },
        ),
      ),
    );
  }
}
