import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:sarri_ride/features/driver/controllers/trip_management_controller.dart';
import 'package:sarri_ride/utils/constants/colors.dart';
import 'package:sarri_ride/utils/constants/sizes.dart';
import 'package:sarri_ride/utils/constants/enums.dart';
import 'package:sarri_ride/utils/helpers/helper_functions.dart';
import 'package:iconsax/iconsax.dart';

class TripNavigationScreen extends StatelessWidget {
  const TripNavigationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<TripManagementController>();
    final dark = THelperFunctions.isDarkMode(context);

    return Scaffold(
      body: Obx(() {
        // Check if there's an active trip
        if (controller.activeTrip.value == null &&
            controller.tripStatus.value == TripStatus.none) {
          return _buildNoActiveTripScreen(context, dark);
        }

        return Stack(
          children: [
            // Google Map
            _buildMap(controller),

            // Top navigation bar
            _buildTopNavigationBar(context, controller, dark),

            // Bottom trip controls
            _buildBottomTripControls(context, controller, dark),

            // Floating action buttons
            _buildFloatingActionButtons(context, controller, dark),
          ],
        );
      }),
    );
  }

  Widget _buildNoActiveTripScreen(BuildContext context, bool dark) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(TSizes.defaultSpace),
        child: Column(
          children: [
            // Header with back button
            Row(
              children: [
                IconButton(
                  onPressed: () => Get.back(),
                  icon: Icon(
                    Iconsax.arrow_left_2,
                    color: dark ? TColors.light : TColors.dark,
                    size: TSizes.iconLg,
                  ),
                ),
                Expanded(
                  child: Text(
                    'Trip Navigation',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                SizedBox(width: TSizes.iconLg + 16), // Balance the back button
              ],
            ),

            // No active trip message
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(TSizes.xl),
                      decoration: BoxDecoration(
                        color: TColors.primary.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Iconsax.location_slash,
                        size: TSizes.xl * 2,
                        color: TColors.primary,
                      ),
                    ),

                    const SizedBox(height: TSizes.spaceBtwSections),

                    Text(
                      'No Active Trip',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),

                    const SizedBox(height: TSizes.spaceBtwItems),

                    Text(
                      'You don\'t have any active trips to navigate.\nGo online to start receiving trip requests.',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: dark ? TColors.lightGrey : TColors.darkGrey,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: TSizes.spaceBtwSections),

                    ElevatedButton.icon(
                      onPressed: () => Get.back(),
                      icon: const Icon(Iconsax.home),
                      label: const Text('Back to Dashboard'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: TColors.primary,
                        foregroundColor: TColors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: TSizes.xl,
                          vertical: TSizes.md,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMap(TripManagementController controller) {
    return Obx(
      () => GoogleMap(
        onMapCreated: (GoogleMapController mapController) {
          controller.mapController = mapController;
        },
        initialCameraPosition: CameraPosition(
          target:
              controller.driverLocation.value ?? const LatLng(6.5244, 3.3792),
          zoom: 16.0,
        ),
        markers: controller.mapMarkers,
        polylines: controller.mapPolylines,
        myLocationEnabled: true,
        myLocationButtonEnabled: false,
        zoomControlsEnabled: false,
        mapToolbarEnabled: false,
        trafficEnabled: true,
        buildingsEnabled: true,
      ),
    );
  }

  Widget _buildTopNavigationBar(
    BuildContext context,
    TripManagementController controller,
    bool dark,
  ) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        child: Container(
          margin: const EdgeInsets.all(TSizes.defaultSpace),
          padding: const EdgeInsets.all(TSizes.md),
          decoration: BoxDecoration(
            color: dark ? TColors.cardBackgroundDark : TColors.cardBackground,
            borderRadius: BorderRadius.circular(TSizes.cardRadiusLg),
            boxShadow: [
              BoxShadow(
                color: TColors.black.withOpacity(dark ? 0.4 : 0.1),
                blurRadius: TSizes.md,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Obx(
            () => Column(
              children: [
                // Navigation instruction
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(TSizes.sm),
                      decoration: BoxDecoration(
                        color: _getStatusColor(
                          controller.tripStatus.value,
                        ).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(
                          TSizes.cardRadiusMd,
                        ),
                      ),
                      child: Icon(
                        _getNavigationIcon(controller.tripStatus.value),
                        color: _getStatusColor(controller.tripStatus.value),
                        size: TSizes.iconMd,
                      ),
                    ),
                    const SizedBox(width: TSizes.spaceBtwItems),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _getStatusText(controller.tripStatus.value),
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          if (controller.navigationInstruction.value.isNotEmpty)
                            Text(
                              controller.navigationInstruction.value,
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: dark
                                        ? TColors.lightGrey
                                        : TColors.darkGrey,
                                  ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),

                // Distance and time info
                if (controller.isNavigating.value) ...[
                  const SizedBox(height: TSizes.spaceBtwItems),
                  Row(
                    children: [
                      Expanded(
                        child: _buildInfoChip(
                          '${controller.distanceToDestination.value.toStringAsFixed(1)} km',
                          'Distance',
                          Iconsax.route_square,
                          TColors.info,
                          context,
                        ),
                      ),
                      const SizedBox(width: TSizes.spaceBtwItems),
                      Expanded(
                        child: _buildInfoChip(
                          '${controller.estimatedTimeToDestination.value} min',
                          'ETA',
                          Iconsax.clock,
                          TColors.warning,
                          context,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomTripControls(
    BuildContext context,
    TripManagementController controller,
    bool dark,
  ) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.all(TSizes.defaultSpace),
        decoration: BoxDecoration(
          color: dark ? TColors.cardBackgroundDark : TColors.cardBackground,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(TSizes.cardRadiusLg),
          ),
          boxShadow: [
            BoxShadow(
              color: TColors.black.withOpacity(dark ? 0.4 : 0.1),
              blurRadius: TSizes.md,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Obx(() {
          final trip = controller.activeTrip.value;
          if (trip == null) {
            return const SizedBox.shrink();
          }

          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Rider information
              _buildRiderInfo(context, trip, dark),

              const SizedBox(height: TSizes.spaceBtwSections),

              // Action buttons based on trip status
              _buildActionButtons(context, controller, dark),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildRiderInfo(BuildContext context, ActiveTrip trip, bool dark) {
    return Row(
      children: [
        CircleAvatar(
          radius: TSizes.lg,
          backgroundColor: TColors.primary.withOpacity(0.1),
          child: Icon(
            Iconsax.user,
            color: TColors.primary,
            size: TSizes.iconMd,
          ),
        ),
        const SizedBox(width: TSizes.spaceBtwItems),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                trip.riderName,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: TSizes.xs),
              Row(
                children: [
                  Icon(Icons.star, color: TColors.warning, size: TSizes.iconSm),
                  const SizedBox(width: TSizes.xs),
                  Text(
                    trip.riderRating.toStringAsFixed(1),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: TSizes.spaceBtwItems),
                  Text(
                    trip.rideType,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: dark ? TColors.lightGrey : TColors.darkGrey,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Text(
          '₦${trip.fare.toStringAsFixed(0)}',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: TColors.success,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(
    BuildContext context,
    TripManagementController controller,
    bool dark,
  ) {
    return Obx(() {
      switch (controller.tripStatus.value) {
        case TripStatus.drivingToPickup:
          return Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _showCancelDialog(context, controller),
                  icon: Icon(Iconsax.close_circle, color: TColors.error),
                  label: Text('Cancel', style: TextStyle(color: TColors.error)),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: TSizes.md),
                    side: BorderSide(color: TColors.error),
                  ),
                ),
              ),
              const SizedBox(width: TSizes.spaceBtwItems),
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  onPressed: () => controller.contactRider(),
                  icon: Icon(Iconsax.call, color: TColors.white),
                  label: Text(
                    'Call Rider',
                    style: TextStyle(color: TColors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: TColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: TSizes.md),
                  ),
                ),
              ),
            ],
          );

        case TripStatus.arrivedAtPickup:
          return SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => controller.startTrip(),
              icon: Icon(Iconsax.play, color: TColors.white),
              label: Text(
                'Start Trip',
                style: TextStyle(
                  color: TColors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: TColors.success,
                padding: const EdgeInsets.symmetric(
                  vertical: TSizes.md + TSizes.xs,
                ),
              ),
            ),
          );

        case TripStatus.tripInProgress:
          return Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => controller.requestEmergencyAssistance(),
                  icon: Icon(Iconsax.warning_2, color: TColors.error),
                  label: Text(
                    'Emergency',
                    style: TextStyle(color: TColors.error),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: TSizes.md),
                    side: BorderSide(color: TColors.error),
                  ),
                ),
              ),
              const SizedBox(width: TSizes.spaceBtwItems),
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  onPressed: () => controller.contactRider(),
                  icon: Icon(Iconsax.call, color: TColors.white),
                  label: Text(
                    'Call Rider',
                    style: TextStyle(color: TColors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: TColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: TSizes.md),
                  ),
                ),
              ),
            ],
          );

        case TripStatus.completed:
          return SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => Get.back(),
              icon: Icon(Iconsax.tick_circle, color: TColors.white),
              label: Text(
                'Trip Completed',
                style: TextStyle(
                  color: TColors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: TColors.success,
                padding: const EdgeInsets.symmetric(
                  vertical: TSizes.md + TSizes.xs,
                ),
              ),
            ),
          );

        default:
          return const SizedBox.shrink();
      }
    });
  }

  Widget _buildFloatingActionButtons(
    BuildContext context,
    TripManagementController controller,
    bool dark,
  ) {
    return Positioned(
      right: TSizes.defaultSpace,
      top: MediaQuery.of(context).size.height * 0.4,
      child: Column(
        children: [
          FloatingActionButton(
            heroTag: 'center_location',
            onPressed: () => _centerMapOnDriver(controller),
            backgroundColor: dark
                ? TColors.cardBackgroundDark
                : TColors.cardBackground,
            child: Icon(Iconsax.location, color: TColors.primary),
          ),
          const SizedBox(height: TSizes.spaceBtwItems),
          FloatingActionButton(
            heroTag: 'navigation_info',
            onPressed: () => _showNavigationInfo(context, controller, dark),
            backgroundColor: dark
                ? TColors.cardBackgroundDark
                : TColors.cardBackground,
            child: Icon(Iconsax.info_circle, color: TColors.info),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(
    String value,
    String label,
    IconData icon,
    Color color,
    BuildContext context,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: TSizes.sm,
        vertical: TSizes.xs,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(TSizes.cardRadiusMd),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: TSizes.iconSm),
          const SizedBox(width: TSizes.xs),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                value,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              Text(
                label,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: color, fontSize: 10),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Helper methods
  Color _getStatusColor(TripStatus status) {
    switch (status) {
      case TripStatus.drivingToPickup:
        return TColors.warning;
      case TripStatus.arrivedAtPickup:
        return TColors.info;
      case TripStatus.tripInProgress:
        return TColors.success;
      case TripStatus.completed:
        return TColors.success;
      default:
        return TColors.primary;
    }
  }

  IconData _getNavigationIcon(TripStatus status) {
    switch (status) {
      case TripStatus.drivingToPickup:
        return Iconsax.location;
      case TripStatus.arrivedAtPickup:
        return Iconsax.user;
      case TripStatus.tripInProgress:
        return Iconsax.route_square;
      case TripStatus.completed:
        return Iconsax.tick_circle;
      default:
        return Iconsax.car;
    }
  }

  String _getStatusText(TripStatus status) {
    switch (status) {
      case TripStatus.drivingToPickup:
        return 'Driving to Pickup';
      case TripStatus.arrivedAtPickup:
        return 'Arrived at Pickup';
      case TripStatus.tripInProgress:
        return 'Trip in Progress';
      case TripStatus.completed:
        return 'Trip Completed';
      default:
        return 'Navigation';
    }
  }

  void _centerMapOnDriver(TripManagementController controller) {
    if (controller.driverLocation.value != null &&
        controller.mapController != null) {
      controller.mapController!.animateCamera(
        CameraUpdate.newLatLng(controller.driverLocation.value!),
      );
    }
  }

  void _showNavigationInfo(
    BuildContext context,
    TripManagementController controller,
    bool dark,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(TSizes.defaultSpace),
        decoration: BoxDecoration(
          color: dark ? TColors.dark : TColors.light,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(TSizes.cardRadiusLg),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Navigation Information',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: TSizes.spaceBtwItems),
            // Add navigation details here
            Text('Navigation details will be shown here'),
            const SizedBox(height: TSizes.spaceBtwItems),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      ),
    );
  }

  void _showCancelDialog(
    BuildContext context,
    TripManagementController controller,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Trip'),
        content: const Text(
          'Are you sure you want to cancel this trip? This may affect your driver rating.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              controller.cancelTrip('Driver cancelled');
              Get.back();
            },
            child: Text('Yes, Cancel', style: TextStyle(color: TColors.error)),
          ),
        ],
      ),
    );
  }
}
