import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:sarri_ride/features/driver/controllers/driver_dashboard_controller.dart';
import 'package:sarri_ride/utils/constants/colors.dart';
import 'package:sarri_ride/utils/constants/sizes.dart';
import 'package:sarri_ride/utils/helpers/helper_functions.dart';
import 'package:iconsax/iconsax.dart';

class DriverProfileScreen extends StatelessWidget {
  const DriverProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<DriverDashboardController>();
    final dark = THelperFunctions.isDarkMode(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        leading: IconButton(
          onPressed: () => Get.back(),
          icon: Icon(
            Iconsax.arrow_left_2,
            color: dark ? TColors.light : TColors.dark,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () => _showEditProfileDialog(context, dark),
            icon: Icon(
              Iconsax.edit,
              color: dark ? TColors.light : TColors.dark,
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(TSizes.defaultSpace),
        child: Column(
          children: [
            // Profile Header
            _buildProfileHeader(context, controller, dark),

            const SizedBox(height: TSizes.spaceBtwSections),

            // Driver Stats
            _buildDriverStats(context, controller, dark),

            const SizedBox(height: TSizes.spaceBtwSections),

            // Vehicle Information
            _buildVehicleInfo(context, controller, dark),

            const SizedBox(height: TSizes.spaceBtwSections),

            // Documents Status
            _buildDocumentsStatus(context, controller, dark),

            const SizedBox(height: TSizes.spaceBtwSections),

            // Account Settings
            _buildAccountSettings(context, dark),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader(
    BuildContext context,
    DriverDashboardController controller,
    bool dark,
  ) {
    return Obx(
      () => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(TSizes.defaultSpace),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [TColors.primary, TColors.primary.withOpacity(0.8)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(TSizes.cardRadiusLg),
        ),
        child: Column(
          children: [
            // Profile Picture
            Stack(
              children: [
                CircleAvatar(
                  radius: TSizes.xl + TSizes.lg,
                  backgroundColor: TColors.white.withOpacity(0.2),
                  child: Icon(
                    Iconsax.user,
                    size: TSizes.xl + TSizes.lg,
                    color: TColors.white,
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(TSizes.xs),
                    decoration: BoxDecoration(
                      color: TColors.success,
                      borderRadius: BorderRadius.circular(TSizes.cardRadiusLg),
                    ),
                    child: Icon(
                      Iconsax.camera,
                      size: TSizes.iconSm,
                      color: TColors.white,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: TSizes.spaceBtwItems),

            // Driver Name
            Text(
              controller.currentDriver.value?.fullName ?? 'Driver Name',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: TColors.white,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: TSizes.xs),

            // Driver ID
            Text(
              'ID: ${controller.currentDriver.value?.id ?? 'N/A'}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: TColors.white.withOpacity(0.7),
              ),
            ),

            const SizedBox(height: TSizes.spaceBtwItems),

            // Status Badge
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
                  Container(
                    width: TSizes.sm,
                    height: TSizes.sm,
                    decoration: BoxDecoration(
                      color: controller.statusColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: TSizes.xs),
                  Text(
                    controller.statusText,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
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
    );
  }

  Widget _buildDriverStats(
    BuildContext context,
    DriverDashboardController controller,
    bool dark,
  ) {
    return Container(
      padding: const EdgeInsets.all(TSizes.defaultSpace),
      decoration: BoxDecoration(
        color: dark ? TColors.cardBackgroundDark : TColors.cardBackground,
        borderRadius: BorderRadius.circular(TSizes.cardRadiusLg),
        boxShadow: [
          BoxShadow(
            color: TColors.black.withOpacity(dark ? 0.3 : 0.1),
            blurRadius: TSizes.sm,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Driver Statistics',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: TSizes.spaceBtwItems),
          Obx(
            () => Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Total Trips',
                    controller.currentDriver.value?.driverProfile?.totalTrips
                            .toString() ??
                        '0',
                    Iconsax.route_square,
                    TColors.primary,
                    context,
                    dark,
                  ),
                ),
                const SizedBox(width: TSizes.spaceBtwItems),
                Expanded(
                  child: _buildStatCard(
                    'Rating',
                    controller.averageRating.value.toStringAsFixed(1),
                    Iconsax.star1,
                    TColors.warning,
                    context,
                    dark,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: TSizes.spaceBtwItems),
          Obx(
            () => Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Total Earnings',
                    '₦${(controller.currentDriver.value?.driverProfile?.totalEarnings ?? 0).toStringAsFixed(0)}',
                    Iconsax.wallet_3,
                    TColors.success,
                    context,
                    dark,
                  ),
                ),
                const SizedBox(width: TSizes.spaceBtwItems),
                Expanded(
                  child: _buildStatCard(
                    'Acceptance Rate',
                    '${controller.acceptanceRate.value.toStringAsFixed(1)}%',
                    Iconsax.tick_circle,
                    TColors.info,
                    context,
                    dark,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
    BuildContext context,
    bool dark,
  ) {
    return Container(
      padding: const EdgeInsets.all(TSizes.md),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(TSizes.cardRadiusMd),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: TSizes.iconLg),
          const SizedBox(height: TSizes.xs),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          Text(
            title,
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildVehicleInfo(
    BuildContext context,
    DriverDashboardController controller,
    bool dark,
  ) {
    return Container(
      padding: const EdgeInsets.all(TSizes.defaultSpace),
      decoration: BoxDecoration(
        color: dark ? TColors.cardBackgroundDark : TColors.cardBackground,
        borderRadius: BorderRadius.circular(TSizes.cardRadiusLg),
        boxShadow: [
          BoxShadow(
            color: TColors.black.withOpacity(dark ? 0.3 : 0.1),
            blurRadius: TSizes.sm,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Vehicle Information',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: () => THelperFunctions.showSnackBar(
                  'Vehicle management coming soon!',
                ),
                icon: Icon(
                  Iconsax.edit,
                  size: TSizes.iconSm,
                  color: TColors.primary,
                ),
                label: Text('Edit', style: TextStyle(color: TColors.primary)),
              ),
            ],
          ),
          const SizedBox(height: TSizes.spaceBtwItems),
          Obx(() {
            final vehicle =
                controller.currentDriver.value?.driverProfile?.vehicleDetails;
            if (vehicle == null) {
              return const Text('No vehicle information available');
            }

            return Column(
              children: [
                _buildInfoRow(
                  'Make & Model',
                  vehicle.displayName,
                  Iconsax.car,
                ), // Use displayName getter
                _buildInfoRow(
                  'Year',
                  vehicle.year?.toString() ?? 'N/A',
                  Iconsax.calendar,
                ),
                _buildInfoRow(
                  'Plate Number',
                  vehicle.plateNumber ?? 'N/A',
                  Iconsax.hashtag,
                ),
                _buildInfoRow(
                  'Color',
                  vehicle.color ?? 'N/A',
                  Iconsax.colorfilter,
                ),
                _buildInfoRow(
                  'Seats',
                  '${vehicle.seats} passengers',
                  Iconsax.profile_2user,
                ),
                _buildInfoRow(
                  'Type',
                  vehicle.type.toString().split('.').last,
                  Iconsax.category,
                ), // Show vehicle type
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildDocumentsStatus(
    BuildContext context,
    DriverDashboardController controller,
    bool dark,
  ) {
    return Container(
      padding: const EdgeInsets.all(TSizes.defaultSpace),
      decoration: BoxDecoration(
        color: dark ? TColors.cardBackgroundDark : TColors.cardBackground,
        borderRadius: BorderRadius.circular(TSizes.cardRadiusLg),
        boxShadow: [
          BoxShadow(
            color: TColors.black.withOpacity(dark ? 0.3 : 0.1),
            blurRadius: TSizes.sm,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Documents',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: () => THelperFunctions.showSnackBar(
                  'Document management coming soon!',
                ),
                icon: Icon(
                  Iconsax.document_upload,
                  size: TSizes.iconSm,
                  color: TColors.primary,
                ),
                label: Text('Manage', style: TextStyle(color: TColors.primary)),
              ),
            ],
          ),
          const SizedBox(height: TSizes.spaceBtwItems),
          Obx(() {
            // Access documents/images from drivingLicense object
            final licenseInfo =
                controller.currentDriver.value?.driverProfile?.drivingLicense;
            final isVerified =
                controller.currentDriver.value?.driverProfile?.isVerified ??
                false;
            final accountStatus =
                controller.currentDriver.value?.driverProfile?.status ??
                'pending'; // 'pending', 'active', 'rejected' etc.

            // Determine overall document status based on account status and verification
            String overallStatus = accountStatus; // Start with account status
            Color statusColor = TColors.warning; // Default to pending/warning
            IconData statusIcon = Iconsax.clock;

            if (isVerified && accountStatus == 'active') {
              overallStatus = 'Approved';
              statusColor = TColors.success;
              statusIcon = Iconsax.tick_circle;
            } else if (accountStatus == 'rejected') {
              overallStatus = 'Rejected';
              statusColor = TColors.error;
              statusIcon = Iconsax.close_circle;
            } else if (accountStatus == 'pending' ||
                accountStatus == 'unverified') {
              overallStatus = 'Pending Review';
              // Keep warning color/icon
            }

            // Build document list (simplified view for now)
            List<Widget> docItems = [];

            // Example: Show overall status and specific document info if available
            docItems.add(
              _buildDocumentItemNew(
                'Overall Status',
                overallStatus,
                statusIcon,
                statusColor,
                context,
                dark,
              ),
            );

            if (licenseInfo?.issueDate != null) {
              docItems.add(
                _buildDocumentItemNew(
                  'License Issued',
                  DateFormat('dd MMM yyyy').format(licenseInfo!.issueDate!),
                  Iconsax.calendar_add,
                  TColors.info,
                  context,
                  dark,
                ),
              );
            }
            if (licenseInfo?.expiryDate != null) {
              docItems.add(
                _buildDocumentItemNew(
                  'License Expires',
                  DateFormat('dd MMM yyyy').format(licenseInfo!.expiryDate!),
                  Iconsax.calendar_remove,
                  TColors.warning,
                  context,
                  dark,
                ),
              );
            }
            // Add entries for image URLs if needed
            // if (licenseInfo?.frontsideImage != null) { /* ... */ }

            if (docItems.isEmpty) {
              return const Text('Document information not available.');
            }

            return Column(children: docItems);
          }),
        ],
      ),
    );
  }

  Widget _buildDocumentItemNew(
    String title,
    String subtitle,
    IconData icon,
    Color color,
    BuildContext context,
    bool dark,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: TSizes.spaceBtwItems),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(TSizes.sm),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(TSizes.borderRadiusMd),
            ),
            child: Icon(icon, color: color, size: TSizes.iconSm),
          ),
          const SizedBox(width: TSizes.spaceBtwItems),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          // Optional: Add view button if you have image URLs
          // IconButton( onPressed: () { /* View Image */ }, icon: Icon(Iconsax.eye, size: TSizes.iconSm, color: TColors.darkGrey,),),
        ],
      ),
    );
  }

  Widget _buildAccountSettings(BuildContext context, bool dark) {
    return Container(
      padding: const EdgeInsets.all(TSizes.defaultSpace),
      decoration: BoxDecoration(
        color: dark ? TColors.cardBackgroundDark : TColors.cardBackground,
        borderRadius: BorderRadius.circular(TSizes.cardRadiusLg),
        boxShadow: [
          BoxShadow(
            color: TColors.black.withOpacity(dark ? 0.3 : 0.1),
            blurRadius: TSizes.sm,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Account Settings',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: TSizes.spaceBtwItems),
          _buildSettingItem(
            'Personal Information',
            'Update your personal details',
            Iconsax.user_edit,
            () => THelperFunctions.showSnackBar('Personal info coming soon!'),
            context,
          ),
          _buildSettingItem(
            'Banking Details',
            'Manage payment and banking info',
            Iconsax.bank,
            () => THelperFunctions.showSnackBar('Banking details coming soon!'),
            context,
          ),
          _buildSettingItem(
            'Notifications',
            'Configure notification preferences',
            Iconsax.notification,
            () => THelperFunctions.showSnackBar('Notifications coming soon!'),
            context,
          ),
          _buildSettingItem(
            'Privacy & Security',
            'Manage your privacy settings',
            Iconsax.security_safe,
            () =>
                THelperFunctions.showSnackBar('Privacy settings coming soon!'),
            context,
          ),
          _buildSettingItem(
            'Help & Support',
            'Get help and contact support',
            Iconsax.support,
            () => THelperFunctions.showSnackBar('Help & support coming soon!'),
            context,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: TSizes.spaceBtwItems),
      child: Row(
        children: [
          Icon(icon, size: TSizes.iconSm, color: TColors.darkGrey),
          const SizedBox(width: TSizes.spaceBtwItems),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: TColors.darkGrey,
                fontSize: TSizes.fontSizeSm,
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: TSizes.fontSizeSm,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingItem(
    String title,
    String subtitle,
    IconData icon,
    VoidCallback onTap,
    BuildContext context,
  ) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        padding: const EdgeInsets.all(TSizes.sm),
        decoration: BoxDecoration(
          color: TColors.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(TSizes.borderRadiusMd),
        ),
        child: Icon(icon, color: TColors.primary, size: TSizes.iconSm),
      ),
      title: Text(
        title,
        style: Theme.of(
          context,
        ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
      trailing: Icon(
        Iconsax.arrow_right_3,
        size: TSizes.iconSm,
        color: TColors.darkGrey,
      ),
      onTap: onTap,
    );
  }

  String _getDocumentTitle(String type) {
    switch (type) {
      case 'DocumentType.driverLicense':
        return 'Driver License';
      case 'DocumentType.vehicleRegistration':
        return 'Vehicle Registration';
      case 'DocumentType.insurance':
        return 'Insurance';
      case 'DocumentType.profilePhoto':
        return 'Profile Photo';
      default:
        return 'Document';
    }
  }

  Color _getDocumentStatusColor(String status) {
    switch (status) {
      case 'DocumentStatus.approved':
        return TColors.success;
      case 'DocumentStatus.rejected':
        return TColors.error;
      case 'DocumentStatus.pending':
        return TColors.warning;
      default:
        return TColors.darkGrey;
    }
  }

  IconData _getDocumentStatusIcon(String status) {
    switch (status) {
      case 'DocumentStatus.approved':
        return Iconsax.tick_circle;
      case 'DocumentStatus.rejected':
        return Iconsax.close_circle;
      case 'DocumentStatus.pending':
        return Iconsax.clock;
      default:
        return Iconsax.document;
    }
  }

  void _showEditProfileDialog(BuildContext context, bool dark) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Profile'),
        content: const Text(
          'Profile editing feature will be implemented in the next update.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
