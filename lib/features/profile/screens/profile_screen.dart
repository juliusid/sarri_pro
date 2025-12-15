import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sarri_ride/features/ride/controllers/drawer_controller.dart';
import 'package:sarri_ride/features/settings/screens/change_password_screen.dart';
import 'package:sarri_ride/features/settings/screens/edit_profile_screen.dart';
import 'package:sarri_ride/utils/constants/colors.dart';
import 'package:sarri_ride/utils/constants/sizes.dart';
import 'package:sarri_ride/utils/helpers/helper_functions.dart';
import 'package:iconsax/iconsax.dart';
// --- 1. IMPORT THE NEW CONTROLLER ---
import 'package:sarri_ride/features/profile/controllers/profile_controller.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final dark = THelperFunctions.isDarkMode(context);
    // --- 2. INITIALIZE BOTH CONTROLLERS ---
    final drawerController = Get.find<MapDrawerController>();
    final profileController = Get.put(
      ProfileController(),
    ); // Use put to create it

    return Scaffold(
      backgroundColor: dark ? TColors.dark : TColors.lightGrey,
      appBar: AppBar(
        // ... (app bar remains the same)
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Profile Header Card
            Container(
              width: double.infinity,
              margin: const EdgeInsets.all(TSizes.defaultSpace),
              padding: const EdgeInsets.all(TSizes.defaultSpace),
              decoration: BoxDecoration(
                // ... (decoration remains the same)
                gradient: LinearGradient(
                  colors: [TColors.primary, TColors.primary.withOpacity(0.8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(TSizes.cardRadiusLg),
                boxShadow: [
                  BoxShadow(
                    color: TColors.primary.withOpacity(0.3),
                    blurRadius: TSizes.md,
                    offset: const Offset(0, TSizes.sm),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // --- 3. WRAP AVATAR STACK WITH Obx FOR LOADING ---
                  Obx(
                    () => Stack(
                      children: [
                        // --- 4. WRAP CircleAvatar WITH Obx FOR IMAGE UPDATES ---
                        Obx(() {
                          final pictureUrl =
                              drawerController.fullProfile.value?.picture;
                          ImageProvider? backgroundImage;

                          if (pictureUrl != null && pictureUrl.isNotEmpty) {
                            backgroundImage = NetworkImage(pictureUrl);
                          }
                          // } else {
                          //   backgroundImage = const AssetImage(
                          //     'assets/images/placeholder_user.png',
                          //   ); // Add a placeholder asset if you want
                          // }

                          return CircleAvatar(
                            radius: TSizes.xl + TSizes.lg,
                            backgroundColor: TColors.white.withOpacity(0.2),
                            backgroundImage: backgroundImage,
                            // Show icon only if there is no image
                            child: (pictureUrl == null || pictureUrl.isEmpty)
                                ? Icon(
                                    Iconsax.user,
                                    size: TSizes.xl + TSizes.lg,
                                    color: TColors.white,
                                  )
                                : null,
                          );
                        }),

                        // --- END 4. ---
                        Positioned(
                          bottom: 0,
                          right: 0,
                          // --- 5. UPDATE onTap TO USE profileController ---
                          child: GestureDetector(
                            onTap: () =>
                                profileController.showImageSourceDialog(),
                            child: Container(
                              padding: const EdgeInsets.all(TSizes.xs),
                              decoration: BoxDecoration(
                                color: TColors.white,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: TColors.primary,
                                  width: 2,
                                ),
                              ),
                              child: Icon(
                                Iconsax.camera,
                                size: TSizes.iconSm,
                                color: TColors.primary,
                              ),
                            ),
                          ),
                        ),

                        // --- 6. ADD LOADING INDICATOR ---
                        if (profileController.isLoading.value)
                          Positioned.fill(
                            child: Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.black.withOpacity(0.4),
                              ),
                              child: const Center(
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),

                  // --- END 3. & 6. ---
                  const SizedBox(height: TSizes.spaceBtwItems),

                  // This Obx already exists and is correct
                  Obx(
                    () => Text(
                      drawerController.userName.value, // <-- Use real name
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            color: TColors.white,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                  const SizedBox(height: TSizes.xs),
                  Obx(
                    () => Text(
                      drawerController.userEmail.value, // <-- Use real email
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: TColors.white.withOpacity(0.8),
                      ),
                    ),
                  ),

                  // ... (rest of the header card)
                  const SizedBox(height: TSizes.spaceBtwItems),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: TSizes.spaceBtwItems,
                      vertical: TSizes.xs,
                    ),
                    decoration: BoxDecoration(
                      color: TColors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(TSizes.cardRadiusLg),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.star,
                          color: TColors.white,
                          size: TSizes.iconSm,
                        ),
                        const SizedBox(width: TSizes.xs),
                        Text(
                          '4.8 Rating', // This is still hardcoded
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: TColors.white,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ... (rest of the ProfileScreen)
            // Quick Stats Row
            Container(
              margin: const EdgeInsets.symmetric(
                horizontal: TSizes.defaultSpace,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      icon: Iconsax.car,
                      title: 'Total Rides',
                      value: '47', // This is still hardcoded
                      color: TColors.info,
                      dark: dark,
                      context: context,
                    ),
                  ),
                  const SizedBox(width: TSizes.spaceBtwItems),
                  Expanded(
                    child: _buildStatCard(
                      icon: Iconsax.wallet_money,
                      title: 'Total Spent',
                      value: '₦45,200', // This is still hardcoded
                      color: TColors.success,
                      dark: dark,
                      context: context,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: TSizes.spaceBtwSections),

            // Profile Options Section
            Container(
              margin: const EdgeInsets.symmetric(
                horizontal: TSizes.defaultSpace,
              ),
              padding: const EdgeInsets.all(TSizes.defaultSpace),
              decoration: BoxDecoration(
                color: dark ? TColors.dark : TColors.white,
                borderRadius: BorderRadius.circular(TSizes.cardRadiusLg),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(dark ? 0.3 : 0.1),
                    blurRadius: TSizes.md,
                    offset: const Offset(0, TSizes.sm),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Account Settings',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: dark ? TColors.white : TColors.black,
                    ),
                  ),
                  const SizedBox(height: TSizes.spaceBtwItems),
                  _buildProfileOption(
                    icon: Iconsax.user_edit,
                    title: 'Edit Profile',
                    subtitle: 'Update your personal information',
                    onTap: () => _editProfile(),
                    dark: dark,
                    context: context,
                  ),
                  _buildProfileOption(
                    icon: Iconsax.lock,
                    title: 'Change Password',
                    subtitle: 'Update your password',
                    onTap: () => _changePassword(),
                    dark: dark,
                    context: context,
                  ),
                  _buildProfileOption(
                    icon: Iconsax.notification,
                    title: 'Notifications',
                    subtitle: 'Manage notification preferences',
                    onTap: () => _manageNotifications(),
                    dark: dark,
                    context: context,
                  ),
                  _buildProfileOption(
                    icon: Iconsax.security_card,
                    title: 'Privacy & Security',
                    subtitle: 'Control your privacy settings',
                    onTap: () => _privacySettings(),
                    dark: dark,
                    context: context,
                  ),
                ],
              ),
            ),

            const SizedBox(height: TSizes.spaceBtwSections),

            // Emergency Contact Section
            Container(
              margin: const EdgeInsets.symmetric(
                horizontal: TSizes.defaultSpace,
              ),
              padding: const EdgeInsets.all(TSizes.defaultSpace),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [TColors.error, TColors.error.withOpacity(0.8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(TSizes.cardRadiusLg),
                boxShadow: [
                  BoxShadow(
                    color: TColors.error.withOpacity(0.3),
                    blurRadius: TSizes.md,
                    offset: const Offset(0, TSizes.sm),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(TSizes.md),
                    decoration: BoxDecoration(
                      color: TColors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(TSizes.cardRadiusMd),
                    ),
                    child: Icon(
                      Iconsax.call,
                      color: TColors.white,
                      size: TSizes.iconLg,
                    ),
                  ),
                  const SizedBox(width: TSizes.spaceBtwItems),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Emergency Contact',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: TColors.white,
                              ),
                        ),
                        const SizedBox(height: TSizes.xs),
                        Text(
                          'Jane Doe - Sister\n+234 901 234 5678',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: TColors.white.withOpacity(0.8)),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(TSizes.sm),
                    decoration: BoxDecoration(
                      color: TColors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(
                        TSizes.borderRadiusMd,
                      ),
                    ),
                    child: Icon(
                      Iconsax.edit_2,
                      color: TColors.white,
                      size: TSizes.iconMd,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: TSizes.spaceBtwSections),
          ],
        ),
      ),
    );
  }

  // ... (all helper methods _buildStatCard, _buildProfileOption, _editProfile, etc. remain the same) ...
  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
    required bool dark,
    required BuildContext context,
  }) {
    return Container(
      padding: const EdgeInsets.all(TSizes.defaultSpace),
      decoration: BoxDecoration(
        color: dark ? TColors.dark : TColors.white,
        borderRadius: BorderRadius.circular(TSizes.cardRadiusLg),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(dark ? 0.3 : 0.1),
            blurRadius: TSizes.md,
            offset: const Offset(0, TSizes.sm),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(TSizes.sm),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(TSizes.cardRadiusMd),
            ),
            child: Icon(icon, color: color, size: TSizes.iconLg),
          ),
          const SizedBox(height: TSizes.spaceBtwItems),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: dark ? TColors.white : TColors.black,
            ),
          ),
          const SizedBox(height: TSizes.xs),
          Text(
            title,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: dark ? TColors.lightGrey : TColors.darkGrey,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildProfileOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required bool dark,
    required BuildContext context,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: TSizes.spaceBtwItems),
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Container(
          padding: const EdgeInsets.all(TSizes.sm),
          decoration: BoxDecoration(
            color: TColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(TSizes.borderRadiusMd),
          ),
          child: Icon(icon, color: TColors.primary, size: TSizes.iconMd),
        ),
        title: Text(
          title,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w600,
            color: dark ? TColors.white : TColors.black,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: dark ? TColors.lightGrey : TColors.darkGrey,
          ),
        ),
        trailing: Icon(
          Iconsax.arrow_right_3,
          color: dark ? TColors.lightGrey : TColors.darkGrey,
          size: TSizes.iconMd,
        ),
        onTap: onTap,
      ),
    );
  }

  void _editProfile() {
    Get.to(() => const EditProfileScreen());
  }

  void _changePassword() {
    Get.to(() => const ChangePasswordScreen());
  }

  void _manageNotifications() {
    THelperFunctions.showSnackBar('Notification settings coming soon');
  }

  void _privacySettings() {
    THelperFunctions.showSnackBar('Privacy settings coming soon');
  }

  void _editEmergencyContact() {
    THelperFunctions.showSnackBar('Emergency contact edit coming soon');
  }
}
