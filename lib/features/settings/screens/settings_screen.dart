import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sarri_ride/features/settings/controllers/settings_controller.dart';
import 'package:sarri_ride/utils/constants/colors.dart';
import 'package:sarri_ride/utils/constants/sizes.dart';
import 'package:sarri_ride/utils/helpers/helper_functions.dart';
import 'package:iconsax/iconsax.dart';
import 'package:sarri_ride/utils/theme/theme_controller.dart';
import 'package:sarri_ride/features/settings/screens/edit_profile_screen.dart';
import 'package:sarri_ride/features/settings/screens/change_password_screen.dart';
import 'package:sarri_ride/features/settings/screens/placeholder_screen.dart';
import 'package:sarri_ride/features/settings/screens/saved_places_screen.dart';
import 'package:sarri_ride/features/settings/screens/emergency_contacts_screen.dart';
import 'package:sarri_ride/features/settings/screens/help_support_screen.dart';
import 'package:sarri_ride/features/settings/screens/terms_screen.dart';
import 'package:sarri_ride/features/settings/screens/privacy_policy_screen.dart';
import 'package:sarri_ride/features/settings/screens/about_screen.dart';
import 'package:sarri_ride/features/settings/screens/privacy_security_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _locationEnabled = true;
  bool _autoAcceptRides = false;
  String _selectedLanguage = 'English';

  @override
  Widget build(BuildContext context) {
    final dark = THelperFunctions.isDarkMode(context);
    
    return Scaffold(
      backgroundColor: dark ? TColors.dark : TColors.lightGrey,
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Get.back(),
          icon: Icon(
            Iconsax.arrow_left_2,
            color: dark ? TColors.light : TColors.dark,
            size: TSizes.iconLg,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header Card
            Container(
              width: double.infinity,
              margin: const EdgeInsets.all(TSizes.defaultSpace),
              padding: const EdgeInsets.all(TSizes.defaultSpace),
              decoration: BoxDecoration(
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(TSizes.md),
                        decoration: BoxDecoration(
                          color: TColors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(TSizes.cardRadiusMd),
                        ),
                        child: Icon(
                          Iconsax.setting_2,
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
                              'App Settings',
                              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                color: TColors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: TSizes.xs),
                            Text(
                              'Manage your preferences and account settings',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: TColors.white.withOpacity(0.8),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // Account Settings Section
            Container(
              margin: const EdgeInsets.symmetric(horizontal: TSizes.defaultSpace),
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
                  _buildSectionHeader('Account Settings', dark),
                  const SizedBox(height: TSizes.spaceBtwItems),
                  _buildSettingItem(
                    icon: Iconsax.user_edit,
                    title: 'Edit Profile',
                    subtitle: 'Update your personal information',
                    onTap: () => Get.to(() => const EditProfileScreen()),
                    dark: dark,
                  ),
                  _buildSettingItem(
                    icon: Iconsax.lock,
                    title: 'Change Password',
                    subtitle: 'Update your password',
                    onTap: () => Get.to(() => const ChangePasswordScreen()),
                    dark: dark,
                  ),
                  _buildSettingItem(
                    icon: Iconsax.security_card,
                    title: 'Privacy & Security',
                    subtitle: 'Manage your privacy settings',
                    onTap: () => Get.to(() => const PrivacySecurityScreen()),
                    dark: dark,
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: TSizes.spaceBtwSections),
            
            // App Preferences Section
            Container(
              margin: const EdgeInsets.symmetric(horizontal: TSizes.defaultSpace),
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
                  _buildSectionHeader('App Preferences', dark),
                  const SizedBox(height: TSizes.spaceBtwItems),
                  _buildSwitchSettingItem(
                    icon: Iconsax.notification,
                    title: 'Push Notifications',
                    subtitle: 'Receive ride updates and offers',
                    value: _notificationsEnabled,
                    onChanged: (value) {
                      setState(() {
                        _notificationsEnabled = value;
                      });
                    },
                    dark: dark,
                  ),
                  _buildSwitchSettingItem(
                    icon: Iconsax.location,
                    title: 'Location Services',
                    subtitle: 'Allow app to access your location',
                    value: _locationEnabled,
                    onChanged: (value) {
                      setState(() {
                        _locationEnabled = value;
                      });
                    },
                    dark: dark,
                  ),
                  _buildSettingItem(
                    icon: Iconsax.moon,
                    title: 'Appearance',
                    subtitle: (() {
                      final mode = Get.find<ThemeController>().themeMode.value;
                      switch (mode) {
                        case ThemeMode.light:
                          return 'Light Mode';
                        case ThemeMode.dark:
                          return 'Dark Mode';
                        default:
                          return 'System Default';
                      }
                    })(),
                    onTap: _showThemeModeBottomSheet,
                    dark: dark,
                  ),
                  _buildSettingItem(
                    icon: Iconsax.global,
                    title: 'Language',
                    subtitle: _selectedLanguage,
                    onTap: () => _selectLanguage(),
                    dark: dark,
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: TSizes.spaceBtwSections),
            
            // Ride Settings Section
            Container(
              margin: const EdgeInsets.symmetric(horizontal: TSizes.defaultSpace),
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
                  _buildSectionHeader('Ride Preferences', dark),
                  const SizedBox(height: TSizes.spaceBtwItems),
                  _buildSwitchSettingItem(
                    icon: Iconsax.car,
                    title: 'Auto Accept Rides',
                    subtitle: 'Automatically accept ride requests',
                    value: _autoAcceptRides,
                    onChanged: (value) {
                      setState(() {
                        _autoAcceptRides = value;
                      });
                    },
                    dark: dark,
                  ),
                  _buildSettingItem(
                    icon: Iconsax.home,
                    title: 'Saved Places',
                    subtitle: 'Manage your home and work locations',
                    onTap: () => Get.to(() => SavedPlacesScreen()),
                    dark: dark,
                  ),
                  _buildSettingItem(
                    icon: Iconsax.call,
                    title: 'Emergency Contacts',
                    subtitle: 'Manage emergency contacts',
                    onTap: () => Get.to(() => const EmergencyContactsScreen()),
                    dark: dark,
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: TSizes.spaceBtwSections),
            
            // Support & Legal Section
            Container(
              margin: const EdgeInsets.symmetric(horizontal: TSizes.defaultSpace),
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
                  _buildSectionHeader('Support & Legal', dark),
                  const SizedBox(height: TSizes.spaceBtwItems),
                  _buildSettingItem(
                    icon: Iconsax.message_question,
                    title: 'Help & Support',
                    subtitle: 'Get help with your account',
                    onTap: () => Get.to(() => const HelpSupportScreen()),
                    dark: dark,
                  ),
                  _buildSettingItem(
                    icon: Iconsax.document_text,
                    title: 'Terms of Service',
                    subtitle: 'Read our terms and conditions',
                    onTap: () => Get.to(() => const TermsScreen()),
                    dark: dark,
                  ),
                  _buildSettingItem(
                    icon: Iconsax.shield_security,
                    title: 'Privacy Policy',
                    subtitle: 'Read our privacy policy',
                    onTap: () => Get.to(() => const PrivacyPolicyScreen()),
                    dark: dark,
                  ),
                  _buildSettingItem(
                    icon: Iconsax.info_circle,
                    title: 'About',
                    subtitle: 'App version 1.0.0',
                    onTap: () => Get.to(() => const AboutScreen()),
                    dark: dark,
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: TSizes.spaceBtwSections),
            
            // Logout Button
            Container(
              margin: const EdgeInsets.symmetric(horizontal: TSizes.defaultSpace),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _logout,
                  icon: Icon(Iconsax.logout, color: TColors.white),
                  label: const Text('Logout'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: TColors.error,
                    foregroundColor: TColors.white,
                    padding: const EdgeInsets.symmetric(vertical: TSizes.md),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(TSizes.cardRadiusLg),
                    ),
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: TSizes.spaceBtwSections),
          ],
        ),
      ),
    );
  }

   void _logout() {
    // Instantiate controller
    final controller = Get.put(SettingsController());
  
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Logout'),
          content: const Text('Are you sure you want to logout?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
                controller.logout(); // Call the controller method
              },
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSectionHeader(String title, bool dark) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.bold,
        color: dark ? TColors.white : TColors.black,
      ),
    );
  }

  Widget _buildSettingItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required bool dark,
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
          child: Icon(
            icon,
            color: TColors.primary,
            size: TSizes.iconMd,
          ),
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

  Widget _buildSwitchSettingItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    required bool dark,
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
          child: Icon(
            icon,
            color: TColors.primary,
            size: TSizes.iconMd,
          ),
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
        trailing: Switch(
          value: value,
          onChanged: onChanged,
          activeColor: TColors.primary,
        ),
      ),
    );
  }

  // Action methods
  void _selectLanguage() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final dark = THelperFunctions.isDarkMode(context);
        return Container(
          padding: const EdgeInsets.all(TSizes.defaultSpace),
          decoration: BoxDecoration(
            color: dark ? TColors.dark : TColors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(TSizes.cardRadiusLg)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Select Language',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: TSizes.spaceBtwItems),
              ...[
                'English',
                'Français',
                'Español',
                'Deutsch',
              ].map((language) => ListTile(
                title: Text(language),
                trailing: _selectedLanguage == language ? Icon(Iconsax.tick_circle, color: TColors.primary) : null,
                onTap: () {
                  setState(() {
                    _selectedLanguage = language;
                  });
                  Navigator.pop(context);
                  THelperFunctions.showSnackBar('Language changed to $language');
                },
              )).toList(),
            ],
          ),
        );
      },
    );
  }

    
  void _showThemeModeBottomSheet() {
    final themeController = Get.find<ThemeController>();
    final dark = THelperFunctions.isDarkMode(context);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(TSizes.defaultSpace),
        decoration: BoxDecoration(
          color: dark ? TColors.dark : TColors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(TSizes.cardRadiusLg)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Choose Theme',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: TSizes.spaceBtwItems),
            ListTile(
              leading: Icon(Iconsax.sun_1, color: TColors.primary),
              title: const Text('Light Mode'),
              trailing: themeController.themeMode.value == ThemeMode.light ? Icon(Iconsax.tick_circle, color: TColors.primary) : null,
              onTap: () {
                themeController.setThemeMode(ThemeMode.light);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(Iconsax.moon, color: TColors.primary),
              title: const Text('Dark Mode'),
              trailing: themeController.themeMode.value == ThemeMode.dark ? Icon(Iconsax.tick_circle, color: TColors.primary) : null,
              onTap: () {
                themeController.setThemeMode(ThemeMode.dark);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(Iconsax.mobile, color: TColors.primary),
              title: const Text('System Default'),
              trailing: themeController.themeMode.value == ThemeMode.system ? Icon(Iconsax.tick_circle, color: TColors.primary) : null,
              onTap: () {
                themeController.setThemeMode(ThemeMode.system);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}
