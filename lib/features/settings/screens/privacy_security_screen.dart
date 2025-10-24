import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sarri_ride/utils/constants/colors.dart';
import 'package:sarri_ride/utils/constants/sizes.dart';
import 'package:sarri_ride/utils/helpers/helper_functions.dart';
import 'package:iconsax/iconsax.dart';

class PrivacySecurityScreen extends StatefulWidget {
  const PrivacySecurityScreen({super.key});

  @override
  State<PrivacySecurityScreen> createState() => _PrivacySecurityScreenState();
}

class _PrivacySecurityScreenState extends State<PrivacySecurityScreen> {
  bool _shareLocationData = true;
  bool _shareRideHistory = false;
  bool _allowMarketing = true;
  bool _enableBiometric = false;
  bool _twoFactorAuth = false;
  bool _dataEncryption = true;

  @override
  Widget build(BuildContext context) {
    final dark = THelperFunctions.isDarkMode(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy & Security'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Get.back(),
          icon: Icon(
            Iconsax.arrow_left_2,
            color: dark ? TColors.light : TColors.dark,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(TSizes.defaultSpace),
        child: Column(
          children: [
            // Header Card
            _buildHeader(context, dark),
            
            const SizedBox(height: TSizes.spaceBtwSections),
            
            // Privacy Settings
            _buildPrivacySettings(context, dark),
            
            const SizedBox(height: TSizes.spaceBtwSections),
            
            // Security Settings
            _buildSecuritySettings(context, dark),
            
            const SizedBox(height: TSizes.spaceBtwSections),
            
            // Data Management
            _buildDataManagement(context, dark),
            
            const SizedBox(height: TSizes.spaceBtwSections),
            
            // Account Actions
            _buildAccountActions(context, dark),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool dark) {
    return Container(
      padding: const EdgeInsets.all(TSizes.defaultSpace),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [TColors.info, TColors.info.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(TSizes.cardRadiusLg),
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
              Iconsax.security_safe,
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
                  'Privacy & Security',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: TColors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: TSizes.xs),
                Text(
                  'Manage your privacy preferences and security settings',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: TColors.white.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrivacySettings(BuildContext context, bool dark) {
    return Container(
      padding: const EdgeInsets.all(TSizes.defaultSpace),
      decoration: BoxDecoration(
        color: dark ? TColors.dark : Colors.white,
        borderRadius: BorderRadius.circular(TSizes.cardRadiusLg),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(dark ? 0.3 : 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Iconsax.eye,
                color: TColors.primary,
                size: TSizes.iconMd,
              ),
              const SizedBox(width: TSizes.spaceBtwItems),
              Text(
                'Privacy Settings',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: TSizes.spaceBtwItems),
          
          _buildSwitchTile(
            'Share Location Data',
            'Allow us to use your location for better service',
            Iconsax.location,
            _shareLocationData,
            (value) => setState(() => _shareLocationData = value),
            context,
          ),
          
          _buildSwitchTile(
            'Share Ride History',
            'Share anonymized ride data to improve our service',
            Iconsax.route_square,
            _shareRideHistory,
            (value) => setState(() => _shareRideHistory = value),
            context,
          ),
          
          _buildSwitchTile(
            'Marketing Communications',
            'Receive promotional offers and updates',
            Iconsax.message,
            _allowMarketing,
            (value) => setState(() => _allowMarketing = value),
            context,
          ),
        ],
      ),
    );
  }

  Widget _buildSecuritySettings(BuildContext context, bool dark) {
    return Container(
      padding: const EdgeInsets.all(TSizes.defaultSpace),
      decoration: BoxDecoration(
        color: dark ? TColors.dark : Colors.white,
        borderRadius: BorderRadius.circular(TSizes.cardRadiusLg),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(dark ? 0.3 : 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Iconsax.shield_tick,
                color: TColors.success,
                size: TSizes.iconMd,
              ),
              const SizedBox(width: TSizes.spaceBtwItems),
              Text(
                'Security Settings',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: TSizes.spaceBtwItems),
          
          _buildSwitchTile(
            'Biometric Authentication',
            'Use fingerprint or face ID for app access',
            Iconsax.finger_scan,
            _enableBiometric,
            (value) => setState(() => _enableBiometric = value),
            context,
          ),
          
          _buildSwitchTile(
            'Two-Factor Authentication',
            'Add an extra layer of security to your account',
            Iconsax.mobile,
            _twoFactorAuth,
            (value) => setState(() => _twoFactorAuth = value),
            context,
          ),
          
          _buildSwitchTile(
            'Data Encryption',
            'Encrypt your personal data on our servers',
            Iconsax.lock,
            _dataEncryption,
            (value) => setState(() => _dataEncryption = value),
            context,
            isEnabled: false, // Always enabled for security
          ),
          
          const SizedBox(height: TSizes.spaceBtwItems),
          
          // Password option
          _buildActionTile(
            'Change Password',
            'Update your account password',
            Iconsax.key,
            TColors.warning,
            () => Get.toNamed('/change-password'),
            context,
          ),
        ],
      ),
    );
  }

  Widget _buildDataManagement(BuildContext context, bool dark) {
    return Container(
      padding: const EdgeInsets.all(TSizes.defaultSpace),
      decoration: BoxDecoration(
        color: dark ? TColors.dark : Colors.white,
        borderRadius: BorderRadius.circular(TSizes.cardRadiusLg),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(dark ? 0.3 : 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Iconsax.archive,
                color: TColors.secondary,
                size: TSizes.iconMd,
              ),
              const SizedBox(width: TSizes.spaceBtwItems),
              Text(
                'Data Management',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: TSizes.spaceBtwItems),
          
          _buildActionTile(
            'Download My Data',
            'Get a copy of your personal data',
            Iconsax.document_download,
            TColors.info,
            _downloadData,
            context,
          ),
          
          _buildActionTile(
            'Data Usage Policy',
            'Learn how we use your data',
            Iconsax.document_text,
            TColors.primary,
            () => Get.toNamed('/privacy-policy'),
            context,
          ),
          
          _buildActionTile(
            'Clear Cache',
            'Remove temporary app data',
            Iconsax.trash,
            TColors.warning,
            _clearCache,
            context,
          ),
        ],
      ),
    );
  }

  Widget _buildAccountActions(BuildContext context, bool dark) {
    return Container(
      padding: const EdgeInsets.all(TSizes.defaultSpace),
      decoration: BoxDecoration(
        color: dark ? TColors.dark : Colors.white,
        borderRadius: BorderRadius.circular(TSizes.cardRadiusLg),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(dark ? 0.3 : 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Iconsax.user_remove,
                color: TColors.error,
                size: TSizes.iconMd,
              ),
              const SizedBox(width: TSizes.spaceBtwItems),
              Text(
                'Account Actions',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: TSizes.spaceBtwItems),
          
          _buildActionTile(
            'Deactivate Account',
            'Temporarily disable your account',
            Iconsax.pause,
            TColors.warning,
            _deactivateAccount,
            context,
          ),
          
          _buildActionTile(
            'Delete Account',
            'Permanently delete your account and data',
            Iconsax.trash,
            TColors.error,
            _deleteAccount,
            context,
          ),
        ],
      ),
    );
  }

  Widget _buildSwitchTile(
    String title,
    String subtitle,
    IconData icon,
    bool value,
    Function(bool) onChanged,
    BuildContext context, {
    bool isEnabled = true,
  }) {
    final dark = THelperFunctions.isDarkMode(context);
    
    return Padding(
      padding: const EdgeInsets.only(bottom: TSizes.spaceBtwItems),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(TSizes.sm),
            decoration: BoxDecoration(
              color: TColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(TSizes.cardRadiusMd),
            ),
            child: Icon(
              icon,
              color: TColors.primary,
              size: TSizes.iconSm,
            ),
          ),
          const SizedBox(width: TSizes.spaceBtwItems),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: TSizes.xs),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: dark ? TColors.lightGrey : TColors.darkGrey,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: isEnabled ? onChanged : null,
            activeColor: TColors.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildActionTile(
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap,
    BuildContext context,
  ) {
    final dark = THelperFunctions.isDarkMode(context);
    
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        padding: const EdgeInsets.all(TSizes.sm),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(TSizes.cardRadiusMd),
        ),
        child: Icon(
          icon,
          color: color,
          size: TSizes.iconMd,
        ),
      ),
      title: Text(
        title,
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
          fontWeight: FontWeight.w600,
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
        size: TSizes.iconSm,
      ),
      onTap: onTap,
    );
  }

  void _downloadData() {
    final dark = THelperFunctions.isDarkMode(context);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              Iconsax.document_download,
              color: TColors.info,
              size: TSizes.iconMd,
            ),
            const SizedBox(width: TSizes.spaceBtwItems),
            const Text('Download Data'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'We\'ll prepare your data and send a download link to your email.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: dark ? TColors.lightGrey : TColors.darkGrey,
              ),
            ),
            const SizedBox(height: TSizes.spaceBtwItems),
            Text(
              'This may take a few hours to complete.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: dark ? TColors.lightGrey : TColors.darkGrey,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              THelperFunctions.showSnackBar('Data download request submitted!');
            },
            child: const Text('Request Download'),
          ),
        ],
      ),
    );
  }

  void _clearCache() {
    THelperFunctions.showSnackBar('Cache cleared successfully!');
  }

  void _deactivateAccount() {
    final dark = THelperFunctions.isDarkMode(context);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              Iconsax.warning_2,
              color: TColors.warning,
              size: TSizes.iconMd,
            ),
            const SizedBox(width: TSizes.spaceBtwItems),
            const Text('Deactivate Account'),
          ],
        ),
        content: Text(
          'Your account will be temporarily disabled. You can reactivate it anytime by logging in.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: dark ? TColors.lightGrey : TColors.darkGrey,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              THelperFunctions.showSnackBar('Account deactivation coming soon!');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: TColors.warning,
              foregroundColor: TColors.white,
            ),
            child: const Text('Deactivate'),
          ),
        ],
      ),
    );
  }

  void _deleteAccount() {
    final dark = THelperFunctions.isDarkMode(context);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              Iconsax.warning_2,
              color: TColors.error,
              size: TSizes.iconMd,
            ),
            const SizedBox(width: TSizes.spaceBtwItems),
            const Text('Delete Account'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to permanently delete your account?',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: TSizes.spaceBtwItems),
            Text(
              'This action cannot be undone. All your data will be permanently deleted.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: dark ? TColors.lightGrey : TColors.darkGrey,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              THelperFunctions.showSnackBar('Account deletion coming soon!');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: TColors.error,
              foregroundColor: TColors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
} 