import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sarri_ride/features/driver/controllers/driver_dashboard_controller.dart';
import 'package:sarri_ride/utils/constants/colors.dart';
import 'package:sarri_ride/utils/constants/sizes.dart';
import 'package:sarri_ride/utils/helpers/helper_functions.dart';
import 'package:iconsax/iconsax.dart';

class DriverVehicleScreen extends StatelessWidget {
  const DriverVehicleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<DriverDashboardController>();
    final dark = THelperFunctions.isDarkMode(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Vehicle'),
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
            onPressed: () => _showEditVehicleDialog(context, dark),
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
            // Vehicle Overview Card
            _buildVehicleOverview(context, controller, dark),

            const SizedBox(height: TSizes.spaceBtwSections),

            // Vehicle Details
            _buildVehicleDetails(context, controller, dark),

            const SizedBox(height: TSizes.spaceBtwSections),

            // Vehicle Documents
            _buildVehicleDocuments(context, controller, dark),

            const SizedBox(height: TSizes.spaceBtwSections),

            // Vehicle Maintenance
            _buildMaintenanceSection(context, dark),

            const SizedBox(height: TSizes.spaceBtwSections),

            // Action Buttons
            _buildActionButtons(context, dark),
          ],
        ),
      ),
    );
  }

  Widget _buildVehicleOverview(
    BuildContext context,
    DriverDashboardController controller,
    bool dark,
  ) {
    return Obx(() {
      final vehicle = controller.currentDriver.value?.driverProfile?.vehicle;
      if (vehicle == null) {
        return _buildNoVehicleCard(context, dark);
      }

      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(TSizes.defaultSpace),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [TColors.info, TColors.info.withOpacity(0.8)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(TSizes.cardRadiusLg),
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
                    Iconsax.car,
                    color: TColors.white,
                    size: TSizes.xl,
                  ),
                ),
                const SizedBox(width: TSizes.spaceBtwItems),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        vehicle.displayName,
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(
                              color: TColors.white,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: TSizes.xs),
                      Text(
                        vehicle.plateNumber,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: TColors.white.withOpacity(0.8),
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: TSizes.spaceBtwItems),

            Row(
              children: [
                _buildVehicleInfoChip(
                  vehicle.color,
                  Iconsax.colorfilter,
                  context,
                ),
                const SizedBox(width: TSizes.spaceBtwItems),
                _buildVehicleInfoChip(
                  '${vehicle.seats} seats',
                  Iconsax.profile_2user,
                  context,
                ),
                const SizedBox(width: TSizes.spaceBtwItems),
                _buildVehicleInfoChip(
                  vehicle.type.toString().split('.').last.toUpperCase(),
                  Iconsax.car,
                  context,
                ),
              ],
            ),
          ],
        ),
      );
    });
  }

  Widget _buildNoVehicleCard(BuildContext context, bool dark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(TSizes.defaultSpace * 2),
      decoration: BoxDecoration(
        color: dark ? TColors.cardBackgroundDark : TColors.cardBackground,
        borderRadius: BorderRadius.circular(TSizes.cardRadiusLg),
        border: Border.all(
          color: TColors.primary.withOpacity(0.3),
          style: BorderStyle.solid,
        ),
      ),
      child: Column(
        children: [
          Icon(
            Iconsax.car,
            size: TSizes.xl * 2,
            color: TColors.primary.withOpacity(0.5),
          ),
          const SizedBox(height: TSizes.spaceBtwItems),
          Text(
            'No Vehicle Registered',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: TSizes.xs),
          Text(
            'Add your vehicle information to start driving',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: dark ? TColors.lightGrey : TColors.darkGrey,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: TSizes.spaceBtwItems),
          ElevatedButton.icon(
            onPressed: () => _showAddVehicleDialog(context, dark),
            icon: const Icon(Iconsax.add),
            label: const Text('Add Vehicle'),
          ),
        ],
      ),
    );
  }

  Widget _buildVehicleInfoChip(
    String label,
    IconData icon,
    BuildContext context,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: TSizes.sm,
        vertical: TSizes.xs,
      ),
      decoration: BoxDecoration(
        color: TColors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(TSizes.cardRadiusLg),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: TSizes.iconSm, color: TColors.white),
          const SizedBox(width: TSizes.xs),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: TColors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVehicleDetails(
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
            'Vehicle Details',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: TSizes.spaceBtwItems),
          Obx(() {
            final vehicle =
                controller.currentDriver.value?.driverProfile?.vehicle;
            if (vehicle == null) {
              return const Text('No vehicle information available');
            }

            return Column(
              children: [
                _buildDetailRow('Make', vehicle.make, Iconsax.car),
                _buildDetailRow('Model', vehicle.model, Iconsax.car),
                _buildDetailRow(
                  'Year',
                  vehicle.year.toString(),
                  Iconsax.calendar,
                ),
                _buildDetailRow('Color', vehicle.color, Iconsax.colorfilter),
                _buildDetailRow(
                  'Plate Number',
                  vehicle.plateNumber,
                  Iconsax.hashtag,
                ),
                _buildDetailRow(
                  'Vehicle Type',
                  vehicle.type.toString().split('.').last,
                  Iconsax.category,
                ),
                _buildDetailRow(
                  'Seating Capacity',
                  '${vehicle.seats} passengers',
                  Iconsax.profile_2user,
                ),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildVehicleDocuments(
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
                'Vehicle Documents',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: () => _showUploadDocumentDialog(context, dark),
                icon: Icon(
                  Iconsax.document_upload,
                  size: TSizes.iconSm,
                  color: TColors.primary,
                ),
                label: Text('Upload', style: TextStyle(color: TColors.primary)),
              ),
            ],
          ),
          const SizedBox(height: TSizes.spaceBtwItems),
          _buildDocumentItem(
            'Vehicle Registration',
            'Valid until Dec 2025',
            Iconsax.tick_circle,
            TColors.success,
            context,
          ),
          _buildDocumentItem(
            'Insurance Certificate',
            'Valid until Jun 2024',
            Iconsax.tick_circle,
            TColors.success,
            context,
          ),
          _buildDocumentItem(
            'Vehicle Inspection',
            'Expires in 30 days',
            Iconsax.warning_2,
            TColors.warning,
            context,
          ),
        ],
      ),
    );
  }

  Widget _buildMaintenanceSection(BuildContext context, bool dark) {
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
            'Maintenance & Service',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: TSizes.spaceBtwItems),
          _buildMaintenanceItem(
            'Last Service',
            '15 days ago',
            'Oil change and general checkup',
            Iconsax.setting_2,
            TColors.info,
            context,
          ),
          _buildMaintenanceItem(
            'Next Service Due',
            'In 45 days',
            'Scheduled maintenance',
            Iconsax.clock,
            TColors.warning,
            context,
          ),
          _buildMaintenanceItem(
            'Mileage',
            '45,230 km',
            'Total distance covered',
            Iconsax.speedometer,
            TColors.primary,
            context,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, bool dark) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => _showEditVehicleDialog(context, dark),
            icon: const Icon(Iconsax.edit),
            label: const Text('Edit Vehicle Information'),
            style: ElevatedButton.styleFrom(
              backgroundColor: TColors.primary,
              foregroundColor: TColors.white,
              padding: const EdgeInsets.symmetric(vertical: TSizes.md),
            ),
          ),
        ),
        const SizedBox(height: TSizes.spaceBtwItems),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => _showChangeVehicleDialog(context, dark),
            icon: const Icon(Iconsax.refresh),
            label: const Text('Change Vehicle'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: TSizes.md),
              side: BorderSide(color: TColors.primary),
              foregroundColor: TColors.primary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon) {
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

  Widget _buildDocumentItem(
    String title,
    String subtitle,
    IconData icon,
    Color color,
    BuildContext context,
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
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: color),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () =>
                THelperFunctions.showSnackBar('Document details coming soon!'),
            icon: Icon(
              Iconsax.eye,
              size: TSizes.iconSm,
              color: TColors.darkGrey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMaintenanceItem(
    String title,
    String value,
    String description,
    IconData icon,
    Color color,
    BuildContext context,
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
                  description,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: TColors.darkGrey),
                ),
              ],
            ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  void _showEditVehicleDialog(BuildContext context, bool dark) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Vehicle'),
        content: const Text(
          'Vehicle editing feature will be implemented in the next update.',
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

  void _showAddVehicleDialog(BuildContext context, bool dark) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Vehicle'),
        content: const Text(
          'Vehicle registration feature will be implemented in the next update.',
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

  void _showChangeVehicleDialog(BuildContext context, bool dark) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change Vehicle'),
        content: const Text(
          'Are you sure you want to change your registered vehicle? This action may require re-verification.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              THelperFunctions.showSnackBar(
                'Vehicle change feature coming soon!',
              );
            },
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }

  void _showUploadDocumentDialog(BuildContext context, bool dark) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Upload Document'),
        content: const Text(
          'Document upload feature will be implemented in the next update.',
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
