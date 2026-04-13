import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sarri_ride/features/communication/controllers/chat_controller.dart';
import 'package:sarri_ride/features/communication/screens/chat_list_screen.dart';
import 'package:sarri_ride/features/notifications/screens/notification_screen.dart';
import 'package:sarri_ride/features/ride/controllers/drawer_controller.dart';
import 'package:sarri_ride/utils/constants/colors.dart';
import 'package:sarri_ride/utils/helpers/helper_functions.dart';
import 'package:sarri_ride/features/location/services/location_service.dart';
import 'package:sarri_ride/features/profile/screens/profile_screen.dart';
import 'package:sarri_ride/features/ride/screens/history/ride_history_screen.dart';
import 'package:sarri_ride/features/payment/screens/payment_methods_screen.dart';
// PRODUCTION: Sarri Points (payment wallet_screen) has no client API yet — restore import + drawer row when backend exists.
// import 'package:sarri_ride/features/payment/screens/wallet_screen.dart';
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
    final dark = THelperFunctions.isDarkMode(context);

    // Modern Styling Colors
    final backgroundColor = dark ? TColors.dark : TColors.white;
    final textColor = dark ? TColors.white : TColors.textPrimary;
    final subtitleColor = dark ? TColors.lightGrey : TColors.textSecondary;
    final dividerColor = dark ? TColors.darkGrey : Colors.grey[200];

    return Drawer(
      backgroundColor: backgroundColor,
      surfaceTintColor: Colors.transparent, // Removes standard Material tint
      child: Column(
        children: [
          // --- CUSTOM MODERN HEADER ---
          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(
              top: 60,
              left: 24,
              bottom: 24,
              right: 24,
            ),
            decoration: BoxDecoration(
              color: dark ? TColors.darkerGrey : TColors.white,
              border: Border(bottom: BorderSide(color: dividerColor!)),
            ),
            child: Row(
              children: [
                // Profile Picture
                Obx(() {
                  final profile = drawerController.fullProfile.value;
                  final image = profile?.picture;

                  return Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: TColors.primary, width: 2),
                    ),
                    child: CircleAvatar(
                      radius: 30,
                      backgroundColor: dark ? TColors.dark : Colors.grey[200],
                      backgroundImage: (image != null && image.isNotEmpty)
                          ? NetworkImage(image)
                          : null,
                      child: (image == null || image.isEmpty)
                          ? const Icon(
                              Iconsax.user,
                              size: 28,
                              color: TColors.primary,
                            )
                          : null,
                    ),
                  );
                }),
                const SizedBox(width: 16),

                // Text Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Obx(
                        () => Text(
                          drawerController.userName.value,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Obx(
                        () => Text(
                          drawerController.userEmail.value,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 13, color: subtitleColor),
                        ),
                      ),
                      const SizedBox(height: 4),
                      InkWell(
                        onTap: () {
                          Navigator.pop(context);
                          Get.to(() => const ProfileScreen());
                        },
                        child: Text(
                          'View Profile',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: TColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // --- SCROLLABLE MENU ITEMS ---
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 12),
              children: [
                _buildDrawerItem(
                  icon: Iconsax.clock,
                  title: 'Ride History',
                  onTap: () {
                    Navigator.pop(context);
                    Get.to(() => const RideHistoryScreen());
                  },
                  dark: dark,
                  textColor: textColor,
                ),
                _buildDrawerItem(
                  icon: Iconsax.wallet,
                  title: 'Payment Methods',
                  onTap: () {
                    Navigator.pop(context);
                    Get.to(() => const PaymentMethodsScreen());
                  },
                  dark: dark,
                  textColor: textColor,
                ),
                // PRODUCTION: Sarri Points — see commented import above.
                // _buildDrawerItem(
                //   icon: Iconsax.wallet_money,
                //   title: 'My Wallet',
                //   onTap: () {
                //     Navigator.pop(context);
                //     Get.to(() => const WalletScreen());
                //   },
                //   dark: dark,
                //   textColor: textColor,
                // ),

                const SizedBox(height: 8),
                Divider(
                  height: 1,
                  color: dividerColor,
                  indent: 24,
                  endIndent: 24,
                ),
                const SizedBox(height: 8),

                // Messages
                Obx(() {
                  final unread = chatController.totalUnreadCount.value;
                  return _buildDrawerItem(
                    icon: Iconsax.message,
                    title: 'Messages',
                    onTap: () {
                      Navigator.pop(context);
                      Get.to(() => const ChatListScreen());
                    },
                    dark: dark,
                    textColor: textColor,
                    badgeCount: unread,
                  );
                }),

                // Notifications
                Obx(() {
                  final unread = notificationController.unreadCount.value;
                  return _buildDrawerItem(
                    icon: Iconsax.notification,
                    title: 'Notifications',
                    onTap: () {
                      Navigator.pop(context);
                      Get.to(() => const NotificationScreen());
                    },
                    dark: dark,
                    textColor: textColor,
                    badgeCount: unread,
                  );
                }),

                const SizedBox(height: 8),
                Divider(
                  height: 1,
                  color: dividerColor,
                  indent: 24,
                  endIndent: 24,
                ),
                const SizedBox(height: 8),

                // Location Refresh
                GetBuilder<LocationService>(
                  builder: (locationService) {
                    return _buildDrawerItem(
                      icon: Icons.my_location,
                      title: 'Refresh Location',
                      onTap: () {
                        Navigator.pop(context);
                        onRefreshLocation();
                      },
                      dark: dark,
                      textColor: textColor,
                      iconColor: locationService.isLocationEnabled
                          ? TColors.primary
                          : Colors.grey,
                      subtitle: locationService.isLocationEnabled
                          ? 'GPS Enabled'
                          : 'GPS Disabled',
                      subtitleColor: locationService.isLocationEnabled
                          ? TColors.success
                          : TColors.error,
                    );
                  },
                ),
                _buildDrawerItem(
                  icon: Iconsax.setting,
                  title: 'Settings',
                  onTap: () {
                    Navigator.pop(context);
                    Get.to(() => const SettingsScreen());
                  },
                  dark: dark,
                  textColor: textColor,
                ),
              ],
            ),
          ),

          // --- LOGOUT (Bottom) ---
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: InkWell(
              onTap: () {
                Navigator.pop(context);
                settingsController.logout();
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: TColors.error.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Iconsax.logout, color: TColors.error, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Log Out',
                      style: TextStyle(
                        color: TColors.error,
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    required bool dark,
    required Color textColor,
    Color? iconColor,
    int badgeCount = 0,
    String? subtitle,
    Color? subtitleColor,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Row(
          children: [
            // Simple Icon without container
            badges.Badge(
              showBadge: badgeCount > 0,
              badgeContent: Text(
                badgeCount.toString(),
                style: const TextStyle(color: Colors.white, fontSize: 10),
              ),
              position: badges.BadgePosition.topEnd(top: -8, end: -8),
              child: Icon(
                icon,
                size: 26,
                color:
                    iconColor ?? (dark ? TColors.lightGrey : Colors.grey[600]),
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 16,
                      color: textColor,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: subtitleColor ?? Colors.grey,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            // Removed Arrow
          ],
        ),
      ),
    );
  }
}
