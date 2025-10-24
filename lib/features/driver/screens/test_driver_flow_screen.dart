import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sarri_ride/features/driver/controllers/trip_management_controller.dart';
import 'package:sarri_ride/features/driver/screens/trip_request_screen.dart';
import 'package:sarri_ride/features/driver/screens/trip_navigation_screen.dart';
import 'package:sarri_ride/utils/constants/colors.dart';
import 'package:sarri_ride/utils/constants/sizes.dart';
import 'package:sarri_ride/utils/helpers/helper_functions.dart';
import 'package:iconsax/iconsax.dart';

class TestDriverFlowScreen extends StatefulWidget {
  const TestDriverFlowScreen({super.key});

  @override
  State<TestDriverFlowScreen> createState() => _TestDriverFlowScreenState();
}

class _TestDriverFlowScreenState extends State<TestDriverFlowScreen> {
  late TripManagementController controller;

  @override
  void initState() {
    super.initState();
    controller = Get.put(TripManagementController());
  }

  @override
  Widget build(BuildContext context) {
    final dark = THelperFunctions.isDarkMode(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Driver Flow Demo'),
        leading: IconButton(
          onPressed: () => Get.back(),
          icon: Icon(
            Icons.arrow_back,
            color: dark ? TColors.white : TColors.black,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Enhanced Driver Trip Flow',
              style: Theme.of(
                context,
              ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 20),

            Text(
              'Test the complete driver-side experience with all new features:',
              style: Theme.of(context).textTheme.bodyLarge,
            ),

            const SizedBox(height: 30),

            // Current status
            Obx(
              () => Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: dark ? TColors.dark : TColors.lightGrey,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: TColors.primary.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          _getStatusIcon(),
                          color: _getStatusColor(),
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Current Status',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    Text(
                      _getStatusText(),
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w500,
                        color: _getStatusColor(),
                      ),
                    ),

                    if (controller.activeTrip.value != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Rider: ${controller.riderName.value}',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      Text(
                        'From: ${controller.pickupAddress.value}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: dark ? TColors.lightGrey : TColors.darkGrey,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'To: ${controller.destinationAddress.value}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: dark ? TColors.lightGrey : TColors.darkGrey,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(height: 30),

            // Test actions
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // Simulate trip request
                    _buildActionCard(
                      context,
                      dark,
                      'Simulate Trip Request',
                      'Generate a new trip request (NO countdown timer)',
                      Iconsax.notification,
                      TColors.primary,
                      () => _simulateTripRequest(),
                      enabled:
                          controller.driverTripStatus.value ==
                          DriverTripStatus.none,
                    ),

                    const SizedBox(height: 16),

                    // View trip request
                    _buildActionCard(
                      context,
                      dark,
                      'View Trip Request',
                      'Open the enhanced trip request screen',
                      Iconsax.eye,
                      TColors.info,
                      () => Get.to(() => const TripRequestScreen()),
                      enabled:
                          controller.driverTripStatus.value ==
                          DriverTripStatus.hasNewRequest,
                    ),

                    const SizedBox(height: 16),

                    // Accept trip
                    _buildActionCard(
                      context,
                      dark,
                      'Accept Trip',
                      'Accept the trip and start navigation to pickup',
                      Iconsax.tick_circle,
                      TColors.success,
                      () => _acceptTrip(),
                      enabled:
                          controller.driverTripStatus.value ==
                          DriverTripStatus.hasNewRequest,
                    ),

                    const SizedBox(height: 16),

                    // Navigation screen
                    _buildActionCard(
                      context,
                      dark,
                      'Trip Navigation',
                      'Open trip navigation with all states',
                      Iconsax.routing,
                      TColors.warning,
                      () => Get.to(() => const TripNavigationScreen()),
                      enabled: controller.activeTrip.value != null,
                    ),

                    const SizedBox(height: 16),

                    // Arrive at pickup
                    _buildActionCard(
                      context,
                      dark,
                      'Arrive at Pickup',
                      'Mark as arrived at pickup location',
                      Iconsax.location,
                      TColors.primary,
                      () => controller.arriveAtPickup(),
                      enabled:
                          controller.driverTripStatus.value ==
                          DriverTripStatus.drivingToPickup,
                    ),

                    const SizedBox(height: 16),

                    // Start trip
                    _buildActionCard(
                      context,
                      dark,
                      'Start Trip',
                      'Start the trip after rider gets in',
                      Iconsax.play,
                      TColors.success,
                      () => controller.startTrip(),
                      enabled:
                          controller.driverTripStatus.value ==
                          DriverTripStatus.arrivedAtPickup,
                    ),

                    const SizedBox(height: 16),

                    // Arrive at destination
                    _buildActionCard(
                      context,
                      dark,
                      'Arrive at Destination',
                      'Mark as arrived at destination',
                      Iconsax.flag,
                      TColors.info,
                      () => controller.arriveAtDestination(),
                      enabled:
                          controller.driverTripStatus.value ==
                          DriverTripStatus.tripInProgress,
                    ),

                    const SizedBox(height: 16),

                    // Complete trip
                    _buildActionCard(
                      context,
                      dark,
                      'Complete Trip',
                      'Complete trip and show payment screen',
                      Iconsax.tick_circle,
                      TColors.success,
                      () => controller.completeTrip(),
                      enabled:
                          controller.driverTripStatus.value ==
                          DriverTripStatus.arrivedAtDestination,
                    ),

                    const SizedBox(height: 30),

                    // Features info
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: TColors.info.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: TColors.info.withOpacity(0.3),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                color: TColors.info,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Enhanced Driver Features',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: dark ? TColors.white : TColors.black,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '✅ No countdown timer - manual accept/decline\n'
                            '✅ Enhanced trip request screen with rider details\n'
                            '✅ Step-by-step trip navigation\n'
                            '✅ Real-time distance and ETA updates\n'
                            '✅ Communication features (call/message rider)\n'
                            '✅ Trip completion with fare breakdown\n'
                            '✅ Multiple payment methods support\n'
                            '✅ Professional UI matching rider experience\n'
                            '✅ Multiple stops support\n'
                            '✅ Emergency assistance features',
                            style: TextStyle(
                              color: dark
                                  ? TColors.lightGrey
                                  : TColors.darkGrey,
                              fontSize: 13,
                            ),
                          ),
                        ],
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

  Widget _buildActionCard(
    BuildContext context,
    bool dark,
    String title,
    String description,
    IconData icon,
    Color color,
    VoidCallback onTap, {
    bool enabled = true,
  }) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: dark ? TColors.dark : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: enabled ? color.withOpacity(0.3) : TColors.darkGrey,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(dark ? 0.3 : 0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: enabled
                    ? color.withOpacity(0.1)
                    : TColors.darkGrey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: enabled ? color : TColors.darkGrey,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: enabled ? null : TColors.darkGrey,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: enabled
                          ? (dark ? TColors.lightGrey : TColors.darkGrey)
                          : TColors.darkGrey,
                    ),
                  ),
                ],
              ),
            ),
            if (enabled)
              Icon(Icons.arrow_forward_ios, color: color, size: 16)
            else
              Icon(Icons.lock, color: TColors.darkGrey, size: 16),
          ],
        ),
      ),
    );
  }

  void _simulateTripRequest() {
    // Force generate a trip request for demo
    controller.generateTestTripRequest();
    THelperFunctions.showSnackBar(
      'Trip request generated! Check the status above.',
    );
  }

  void _acceptTrip() async {
    await controller.acceptTripRequest();
    THelperFunctions.showSnackBar(
      'Trip accepted! Ready to navigate to pickup.',
    );
  }

  IconData _getStatusIcon() {
    switch (controller.driverTripStatus.value) {
      case DriverTripStatus.none:
        return Iconsax.car;
      case DriverTripStatus.hasNewRequest:
        return Iconsax.notification;
      case DriverTripStatus.drivingToPickup:
        return Iconsax.routing;
      case DriverTripStatus.arrivedAtPickup:
        return Iconsax.location;
      case DriverTripStatus.tripInProgress:
        return Iconsax.directbox_send;
      case DriverTripStatus.arrivedAtDestination:
        return Iconsax.flag;
      case DriverTripStatus.tripCompleted:
        return Iconsax.tick_circle;
      case DriverTripStatus.cancelled:
        return Iconsax.close_circle;
    }
  }

  Color _getStatusColor() {
    switch (controller.driverTripStatus.value) {
      case DriverTripStatus.none:
        return TColors.darkGrey;
      case DriverTripStatus.hasNewRequest:
        return TColors.warning;
      case DriverTripStatus.drivingToPickup:
        return TColors.primary;
      case DriverTripStatus.arrivedAtPickup:
        return TColors.info;
      case DriverTripStatus.tripInProgress:
        return TColors.success;
      case DriverTripStatus.arrivedAtDestination:
        return TColors.info;
      case DriverTripStatus.tripCompleted:
        return TColors.success;
      case DriverTripStatus.cancelled:
        return TColors.error;
    }
  }

  String _getStatusText() {
    switch (controller.driverTripStatus.value) {
      case DriverTripStatus.none:
        return 'Ready for trip requests';
      case DriverTripStatus.hasNewRequest:
        return 'New trip request received (no timer!)';
      case DriverTripStatus.drivingToPickup:
        return 'Driving to pickup location';
      case DriverTripStatus.arrivedAtPickup:
        return 'Arrived at pickup - waiting for rider';
      case DriverTripStatus.tripInProgress:
        return 'Trip in progress to destination';
      case DriverTripStatus.arrivedAtDestination:
        return 'Arrived at destination';
      case DriverTripStatus.tripCompleted:
        return 'Trip completed - processing payment';
      case DriverTripStatus.cancelled:
        return 'Trip was cancelled';
    }
  }
}
