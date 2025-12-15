// lib/features/ride/widgets/map_drawer_widget.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sarri_ride/features/communication/controllers/chat_controller.dart';
import 'package:sarri_ride/features/communication/screens/chat_list_screen.dart';
import 'package:sarri_ride/features/notifications/screens/notification_screen.dart';
import 'package:sarri_ride/features/ride/controllers/drawer_controller.dart';
import 'package:sarri_ride/utils/constants/colors.dart';
import 'package:sarri_ride/features/location/services/location_service.dart';
import 'package:sarri_ride/features/profile/screens/profile_screen.dart';
import 'package:sarri_ride/features/ride/screens/history/ride_history_screen.dart';
import 'package:sarri_ride/features/payment/screens/payment_methods_screen.dart';
import 'package:sarri_ride/features/payment/screens/wallet_screen.dart';
import 'package:sarri_ride/features/settings/screens/settings_screen.dart';
import 'package:iconsax/iconsax.dart';
import 'package:sarri_ride/features/settings/controllers/settings_controller.dart';
import 'package:sarri_ride/features/notifications/controllers/notification_controller.dart';
import 'package:badges/badges.dart' as badges;

class MapDrawerWidget extends StatelessWidget {
  final VoidCallback onRefreshLocation;
  final VoidCallback onLogout;

  const MapDrawerWidget({
    super.key,
    required this.onRefreshLocation,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    // Get controllers
    final settingsController = Get.find<SettingsController>();
    final notificationController = Get.find<NotificationController>();
    final chatController = Get.find<ChatController>();
    final drawerController = Get.find<MapDrawerController>();

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          // --- DRAWER HEADER ---
          DrawerHeader(
            decoration: const BoxDecoration(color: TColors.primary),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center, // Center vertically
              children: [
                // 1. FIXED PROFILE PICTURE
                Obx(() {
                  final profile = drawerController.fullProfile.value;
                  final image = profile?.picture;

                  return CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.white,
                    // Check if we have an image URL
                    backgroundImage: (image != null && image.isNotEmpty)
                        ? NetworkImage(image)
                        : null,
                    // If no image, show the Icon as a child fallback
                    child: (image == null || image.isEmpty)
                        ? const Icon(
                            Iconsax.user,
                            size: 30,
                            color: TColors.primary,
                          )
                        : null,
                  );
                }),
                const SizedBox(height: 12),

                // 2. FIXED NAME OVERFLOW
                Obx(
                  () => Text(
                    drawerController.userName.value,
                    maxLines: 1, // Prevent wrapping
                    overflow: TextOverflow.ellipsis, // Show "..." if too long
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 4),

                // 3. FIXED EMAIL OVERFLOW
                Obx(
                  () => Text(
                    drawerController.userEmail.value,
                    maxLines: 1, // Prevent wrapping
                    overflow: TextOverflow.ellipsis, // Show "..." if too long
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: Colors.white70),
                  ),
                ),
              ],
            ),
          ),

          // --- MENU ITEMS (Unchanged) ---
          ListTile(
            leading: const Icon(Iconsax.user),
            title: const Text('Profile'),
            onTap: () {
              Navigator.pop(context);
              Get.to(() => const ProfileScreen());
            },
          ),
          ListTile(
            leading: const Icon(Iconsax.clock),
            title: const Text('Ride History'),
            onTap: () {
              Navigator.pop(context);
              Get.to(() => const RideHistoryScreen());
            },
          ),
          ListTile(
            leading: const Icon(Iconsax.wallet),
            title: const Text('Payment Methods'),
            onTap: () {
              Navigator.pop(context);
              Get.to(() => const PaymentMethodsScreen());
            },
          ),
          ListTile(
            leading: const Icon(Iconsax.wallet_money),
            title: const Text('My Wallet'),
            onTap: () {
              Navigator.pop(context);
              Get.to(() => const WalletScreen());
            },
          ),

          // Messages Item
          ListTile(
            leading: Obx(
              () => badges.Badge(
                position: badges.BadgePosition.topEnd(top: -10, end: -10),
                showBadge: chatController.totalUnreadCount.value > 0,
                badgeContent: Text(
                  chatController.totalUnreadCount.value.toString(),
                  style: const TextStyle(color: Colors.white, fontSize: 10),
                ),
                badgeStyle: const badges.BadgeStyle(
                  badgeColor: TColors.error,
                  padding: EdgeInsets.all(5),
                ),
                child: const Icon(Iconsax.message),
              ),
            ),
            title: const Text('Messages'),
            onTap: () {
              Navigator.pop(context);
              Get.to(() => const ChatListScreen());
            },
          ),

          // Notifications Item
          ListTile(
            leading: Obx(
              () => badges.Badge(
                position: badges.BadgePosition.topEnd(top: -10, end: -10),
                showBadge: notificationController.unreadCount.value > 0,
                badgeContent: Text(
                  notificationController.unreadCount.value.toString(),
                  style: const TextStyle(color: Colors.white, fontSize: 10),
                ),
                badgeStyle: const badges.BadgeStyle(
                  badgeColor: TColors.error,
                  padding: EdgeInsets.all(5),
                ),
                child: const Icon(Iconsax.notification),
              ),
            ),
            title: const Text('Notifications'),
            onTap: () {
              Navigator.pop(context); // Close drawer
              Get.to(() => const NotificationScreen());
            },
          ),

          const Divider(),

          // Location Refresh
          GetBuilder<LocationService>(
            builder: (locationService) {
              return ListTile(
                leading: Icon(
                  Icons.my_location,
                  color: locationService.isLocationEnabled
                      ? TColors.primary
                      : TColors.grey,
                ),
                title: const Text('Refresh Location'),
                subtitle: Text(
                  locationService.isLocationEnabled
                      ? 'Location enabled'
                      : 'Location disabled',
                  style: TextStyle(
                    color: locationService.isLocationEnabled
                        ? TColors.success
                        : TColors.error,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  onRefreshLocation();
                },
              );
            },
          ),
          ListTile(
            leading: const Icon(Iconsax.setting),
            title: const Text('Settings'),
            onTap: () {
              Navigator.pop(context);
              Get.to(() => const SettingsScreen());
            },
          ),

          const Divider(),

          // Logout
          ListTile(
            leading: const Icon(Iconsax.logout, color: TColors.error),
            title: const Text('Logout', style: TextStyle(color: TColors.error)),
            onTap: () {
              Navigator.pop(context);
              settingsController.logout();
            },
          ),
        ],
      ),
    );
  }
}
