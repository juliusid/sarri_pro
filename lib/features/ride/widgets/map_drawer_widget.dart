import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sarri_ride/features/communication/controllers/chat_controller.dart';
import 'package:sarri_ride/features/communication/screens/chat_list_screen.dart';
import 'package:sarri_ride/features/communication/screens/message_screen.dart';
import 'package:sarri_ride/features/notifications/screens/notification_screen.dart';
import 'package:sarri_ride/features/ride/controllers/ride_controller.dart';
import 'package:sarri_ride/utils/constants/colors.dart'; //
import 'package:sarri_ride/features/location/services/location_service.dart'; //
import 'package:sarri_ride/features/profile/screens/profile_screen.dart'; //
import 'package:sarri_ride/features/ride/screens/history/ride_history_screen.dart'; //
import 'package:sarri_ride/features/payment/screens/payment_methods_screen.dart'; //
import 'package:sarri_ride/features/payment/screens/wallet_screen.dart'; //
import 'package:sarri_ride/features/settings/screens/settings_screen.dart'; //
import 'package:iconsax/iconsax.dart';
import 'package:sarri_ride/features/settings/controllers/settings_controller.dart'; //
// --- Import Notification Controller & Badges ---
import 'package:sarri_ride/features/notifications/controllers/notification_controller.dart'; //
import 'package:badges/badges.dart' as badges;
import 'package:sarri_ride/utils/helpers/helper_functions.dart'; // For snackbar

class MapDrawerWidget extends StatelessWidget {
  final VoidCallback onRefreshLocation;
  final VoidCallback
  onLogout; // This callback might not be needed if SettingsController handles it

  const MapDrawerWidget({
    super.key,
    required this.onRefreshLocation,
    required this.onLogout, // Keep for now, might remove later
  });

  @override
  Widget build(BuildContext context) {
    // Get controllers
    final settingsController =
        Get.find<SettingsController>(); // Use find since it's put elsewhere
    final notificationController =
        Get.find<NotificationController>(); // Get notification controller
    final chatController = Get.find<ChatController>();
    // TODO: Get user info from a UserController or AuthService instead of hardcoding
    final userName = "John Doe"; // Placeholder
    final userEmail = "john@example.com"; // Placeholder

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          // Drawer Header
          DrawerHeader(
            decoration: const BoxDecoration(color: TColors.primary),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.white,
                  child: Icon(Iconsax.user, size: 30, color: TColors.primary),
                ),
                const SizedBox(height: 16),
                Text(
                  userName,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(color: Colors.white),
                ),
                Text(
                  userEmail,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: Colors.white70),
                ),
              ],
            ),
          ),

          // Menu Items
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

          // --- ADDED MESSAGES ITEM ---
          ListTile(
            leading: Obx(
              () => badges.Badge(
                // Wrap leading icon/badge logic in Obx
                position: badges.BadgePosition.topEnd(top: -10, end: -10),
                // Show badge only if count > 0
                showBadge: chatController.totalUnreadCount.value > 0,
                badgeContent: Text(
                  chatController.totalUnreadCount.value.toString(),
                  style: const TextStyle(color: Colors.white, fontSize: 10),
                ),
                badgeStyle: const badges.BadgeStyle(
                  badgeColor: TColors.error,
                  padding: EdgeInsets.all(5),
                ),
                child: const Icon(Iconsax.message), // Messages Icon
              ),
            ),
            title: const Text('Messages'),
            onTap: () {
              Navigator.pop(context); // Close drawer
              Get.to(
                () => const ChatListScreen(),
              ); // Navigate to Chat List Screen
            },
          ),

          // --- ADDED NOTIFICATION ITEM ---
          ListTile(
            leading: Obx(
              () => badges.Badge(
                // Wrap leading icon/badge logic in Obx
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
              Get.to(() => const NotificationScreen()); // Navigate here
            },
          ),

          // --- END NOTIFICATION ITEM ---
          const Divider(),

          // Location Refresh (as before)
          GetBuilder<LocationService>(
            builder: (locationService) {
              return ListTile(
                /* ... */
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
            leading: const Icon(
              Iconsax.logout,
              color: TColors.error,
            ), // Add color
            title: const Text(
              'Logout',
              style: TextStyle(color: TColors.error),
            ), // Add color
            onTap: () {
              Navigator.pop(context); // Close the drawer first
              settingsController
                  .logout(); // Call logout from SettingsController
            },
          ),
        ],
      ),
    );
  }
}
