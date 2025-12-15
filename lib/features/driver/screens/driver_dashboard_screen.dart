import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart'; //
import 'package:sarri_ride/common/widgets/loading_button.dart';
// --- Local Imports ---
import 'package:sarri_ride/features/driver/controllers/driver_dashboard_controller.dart'; //
import 'package:sarri_ride/features/driver/controllers/trip_management_controller.dart'; //
import 'package:sarri_ride/features/driver/screens/trip_navigation_screen.dart'; //
import 'package:sarri_ride/features/driver/screens/document_upload/document_upload_screen.dart'; //
import 'package:sarri_ride/features/driver/widgets/verification_banner.dart'; //
import 'package:sarri_ride/common/widgets/notifications/notification_icon.dart'; //
import 'package:sarri_ride/utils/constants/colors.dart'; //
import 'package:sarri_ride/utils/constants/sizes.dart'; //
import 'package:sarri_ride/utils/constants/enums.dart'; //
import 'package:sarri_ride/utils/helpers/helper_functions.dart'; //

class DriverDashboardScreen extends StatelessWidget {
  //
  const DriverDashboardScreen({super.key}); //

  @override
  Widget build(BuildContext context) {
    //
    final controller = Get.put(DriverDashboardController()); //
    final tripController = Get.put(TripManagementController()); //
    final dark = THelperFunctions.isDarkMode(context); //

    return Scaffold(
      //
      appBar: AppBar(
        //
        backgroundColor: Colors.transparent, //
        elevation: 0, //
        title: Text(
          //
          'Dashboard', //
          style: Theme.of(
            context,
          ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold), //
        ),
        actions: const [
          //
          NotificationIconWidget(), //
          SizedBox(width: TSizes.sm), //
        ],
      ),
      body: SafeArea(
        //
        top: false, //
        child: SingleChildScrollView(
          //
          child: Column(
            //
            crossAxisAlignment: CrossAxisAlignment.start, //
            children: [
              // -- CONDITIONAL VERIFICATION BANNER --
              Obx(() {
                //
                final status = controller.driverOperationalStatus.value; //
                print("Dashboard UI: Driver operational status = $status"); //

                if (status == 'unverified') {
                  //
                  return VerificationBanner(
                    //
                    title: 'Verification Required', //
                    message:
                        'Please upload your documents to get full access.', //
                    buttonText: 'Start Verification', //
                    bannerColor: TColors.warning, //
                    iconData: Iconsax.warning_2, //
                    onButtonPressed: () =>
                        Get.to(() => const DocumentUploadScreen()), //
                  );
                } else if (status == 'pending') {
                  return VerificationBanner(
                    //
                    title: 'Verification Pending',
                    message:
                        'Your account is pending admin verification. You cannot receive trip requests yet.', // Message from API
                    bannerColor: TColors.info, // Use Info color for pending
                    iconData: Iconsax.clock, // Clock icon
                    // No button needed for pending
                  );
                } else if (status == 'rejected') {
                  //
                  return VerificationBanner(
                    //
                    title: 'Documents Rejected', //
                    message:
                        'There was an issue with your documents. Please review and resubmit them.', //
                    buttonText: 'Resubmit Documents', //
                    bannerColor: TColors.error, //
                    iconData: Iconsax.close_circle, //
                    onButtonPressed: () =>
                        Get.to(() => const DocumentUploadScreen()), //
                  );
                } else if (status == 'in_progress') {
                  //
                  return VerificationBanner(
                    //
                    title: 'Verification In Progress', //
                    message:
                        'Your documents are currently under review. We will notify you once completed. Thank you for your patience.', //
                    bannerColor: TColors.success, //
                    iconData: Iconsax.clock, //
                  );
                } else if (status == 'unknown') {
                  //
                  return const SizedBox.shrink(); //
                } else if (status == 'error') {
                  //
                  return const SizedBox.shrink(); //
                } else {
                  //
                  return const SizedBox.shrink(); //
                }
              }),

              // -- END BANNER --
              Padding(
                //
                padding: const EdgeInsets.all(TSizes.defaultSpace), //
                child: Column(
                  //
                  crossAxisAlignment: CrossAxisAlignment.start, //
                  children: [
                    _buildHeader(context, controller, dark), //
                    const SizedBox(height: TSizes.spaceBtwSections), //
                    Obx(
                      //
                      () =>
                          tripController
                              .hasActiveTrip //
                          ? _buildActiveTripCard(
                              context,
                              tripController,
                              dark,
                            ) //
                          : const SizedBox.shrink(), //
                    ),
                    _buildStatusCard(context, controller, dark), //
                    const SizedBox(height: TSizes.spaceBtwSections), //
                    _buildTodayEarningsCard(context, controller, dark), //
                    const SizedBox(height: TSizes.spaceBtwSections), //
                    _buildQuickActions(context, controller, dark), //
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(
    //
    BuildContext context, //
    DriverDashboardController controller, //
    bool dark, //
  ) {
    return Obx(
      //
      () => Row(
        //
        children: [
          Expanded(
            //
            child: Column(
              //
              crossAxisAlignment: CrossAxisAlignment.start, //
              children: [
                Text(
                  //
                  'Welcome Back,', //
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    //
                    color: dark ? TColors.lightGrey : TColors.darkGrey, //
                  ),
                ),
                const SizedBox(height: TSizes.xs), //
                Text(
                  //
                  controller.currentDriver.value?.firstName ?? 'Driver', //
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    //
                    fontWeight: FontWeight.bold, //
                  ),
                  maxLines: 1, //
                  overflow: TextOverflow.ellipsis, //
                ),
              ],
            ),
          ),
          GestureDetector(
            //
            onTap: () => controller.navigateToProfile(), //
            child: CircleAvatar(
              //
              radius: TSizes.lg + 4.0, //
              backgroundColor: TColors.primary.withOpacity(0.1), //
              child: Icon(
                //
                Iconsax.user, //
                color: TColors.primary, //
                size: TSizes.iconLg, //
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveTripCard(
    //
    BuildContext context, //
    TripManagementController tripController, //
    bool dark, //
  ) {
    return Obx(() {
      //
      final trip = tripController.activeTrip.value; //
      if (trip == null) return const SizedBox.shrink(); //

      return Container(
        //
        margin: const EdgeInsets.only(bottom: TSizes.spaceBtwSections), //
        padding: const EdgeInsets.all(TSizes.defaultSpace), //
        decoration: BoxDecoration(
          //
          gradient: LinearGradient(
            //
            colors: [TColors.info, TColors.info.withOpacity(0.8)], //
            begin: Alignment.topLeft, //
            end: Alignment.bottomRight, //
          ),
          borderRadius: BorderRadius.circular(TSizes.cardRadiusLg), //
          boxShadow: [
            //
            BoxShadow(
              //
              color: TColors.info.withOpacity(0.3), //
              blurRadius: TSizes.sm, //
              offset: const Offset(0, 2), //
            ),
          ],
        ),
        child: Column(
          //
          crossAxisAlignment: CrossAxisAlignment.start, //
          children: [
            Row(
              //
              children: [
                Container(
                  //
                  padding: const EdgeInsets.all(TSizes.sm), //
                  decoration: BoxDecoration(
                    //
                    color: TColors.white.withOpacity(0.2), //
                    borderRadius: BorderRadius.circular(TSizes.cardRadiusMd), //
                  ),
                  child: Icon(
                    //
                    Iconsax.car, //
                    color: TColors.white, //
                    size: TSizes.iconMd, //
                  ),
                ),
                const SizedBox(width: TSizes.spaceBtwItems), //
                Expanded(
                  //
                  child: Column(
                    //
                    crossAxisAlignment: CrossAxisAlignment.start, //
                    children: [
                      Text(
                        //
                        'Active Trip', //
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium //
                            ?.copyWith(
                              color: TColors.white, //
                              fontWeight: FontWeight.bold, //
                            ),
                      ),
                      Text(
                        //
                        _getTripStatusText(tripController.tripStatus.value), //
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          //
                          color: TColors.white.withOpacity(0.8), //
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  //
                  padding: const EdgeInsets.symmetric(
                    //
                    horizontal: TSizes.sm, //
                    vertical: TSizes.xs, //
                  ),
                  decoration: BoxDecoration(
                    //
                    color: TColors.white.withOpacity(0.2), //
                    borderRadius: BorderRadius.circular(TSizes.cardRadiusLg), //
                  ),
                  child: Text(
                    //
                    '₦${trip.fare.toStringAsFixed(0)}', //
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      //
                      color: TColors.white, //
                      fontWeight: FontWeight.bold, //
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: TSizes.spaceBtwItems), //

            Row(
              //
              children: [
                CircleAvatar(
                  //
                  radius: TSizes.md, //
                  backgroundColor: TColors.white.withOpacity(0.2), //
                  child: Icon(
                    //
                    Iconsax.user, //
                    color: TColors.white, //
                    size: TSizes.iconSm, //
                  ),
                ),
                const SizedBox(width: TSizes.spaceBtwItems), //
                Expanded(
                  //
                  child: Text(
                    //
                    trip.riderName, //
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      //
                      color: TColors.white, //
                      fontWeight: FontWeight.w600, //
                    ),
                  ),
                ),
                Row(
                  //
                  mainAxisSize: MainAxisSize.min, //
                  children: [
                    Icon(
                      Icons.star,
                      color: TColors.white,
                      size: TSizes.iconSm,
                    ), //
                    const SizedBox(width: TSizes.xs), //
                    Text(
                      //
                      trip.riderRating.toStringAsFixed(1), //
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        //
                        color: TColors.white, //
                        fontWeight: FontWeight.w600, //
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: TSizes.spaceBtwItems), //

            SizedBox(
              //
              width: double.infinity, //
              child: ElevatedButton.icon(
                //
                onPressed: () => Get.to(() => const TripNavigationScreen()), //
                icon: Icon(Iconsax.location, color: TColors.info), //
                label: Text(
                  //
                  'Navigate', //
                  style: TextStyle(
                    //
                    color: TColors.info, //
                    fontWeight: FontWeight.bold, //
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  //
                  backgroundColor: TColors.white, //
                  padding: const EdgeInsets.symmetric(vertical: TSizes.sm), //
                  shape: RoundedRectangleBorder(
                    //
                    borderRadius: BorderRadius.circular(TSizes.buttonRadius), //
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  // --- UPDATED STATUS CARD WIDGET ---
  Widget _buildStatusCard(
    BuildContext context,
    DriverDashboardController controller,
    bool dark,
  ) {
    return Obx(
      () => Container(
        width: double.infinity,
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
          children: [
            // Status Indicator Row
            Row(
              children: [
                Container(
                  width: TSizes.sm + TSizes.xs,
                  height: TSizes.sm + TSizes.xs,
                  decoration: BoxDecoration(
                    color: controller.statusColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: TSizes.spaceBtwItems),
                Expanded(
                  child: Text(
                    controller.statusText,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: TSizes.spaceBtwItems),
            // Action Button(s)
            controller.isOnBreak.value
                ? // Show End Break Button
                  LoadingElevatedButton(
                    isLoading: controller.isLoadingStatus.value,
                    text: 'End Break',
                    icon: Iconsax.play,
                    onPressed: () => controller.endBreak(),
                    backgroundColor: TColors.warning,
                    foregroundColor: TColors.white,
                  )
                : // Show Go Online/Offline and Take Break Buttons
                  Row(
                    children: [
                      Expanded(
                        child: LoadingElevatedButton(
                          isLoading: controller.isLoadingStatus.value,
                          text: controller.isOnline.value
                              ? 'Go Offline'
                              : 'Go Online',
                          loadingText: controller.isOnline.value
                              ? 'Going Offline...'
                              : 'Going Online...',
                          backgroundColor: controller.isOnline.value
                              ? TColors.error
                              : TColors.success,
                          foregroundColor: TColors.white,
                          onPressed: controller.toggleDriverStatus,
                        ),
                      ),
                      // Show Take Break button only if driver is online and NOT on a trip
                      if (controller.isOnline.value &&
                          !controller.hasActiveTrip) ...[
                        const SizedBox(width: TSizes.spaceBtwItems),
                        LoadingOutlinedButton(
                          isLoading: controller.isLoadingStatus.value,
                          text: 'Break',
                          icon: Iconsax.coffee,
                          foregroundColor: TColors.secondary,
                          onPressed: () =>
                              _showBreakDurationDialog(context, controller),
                        ),
                      ],
                    ],
                  ),
          ],
        ),
      ),
    );
  }
  // --- END UPDATED STATUS CARD ---

  // --- ADD BREAK DURATION DIALOG HELPER ---
  void _showBreakDurationDialog(
    BuildContext context,
    DriverDashboardController controller,
  ) {
    //
    int selectedDuration = 30; //
    final dark = THelperFunctions.isDarkMode(context); //

    Get.dialog(
      //
      AlertDialog(
        //
        title: const Text('Select Break Duration'), //
        content: StatefulBuilder(
          //
          builder: (BuildContext context, StateSetter setState) {
            //
            return Column(
              //
              mainAxisSize: MainAxisSize.min, //
              children: <Widget>[
                //
                RadioListTile<int>(
                  //
                  title: const Text('15 Minutes'), //
                  value: 15, //
                  groupValue: selectedDuration, //
                  onChanged: (int? value) {
                    //
                    setState(() {
                      selectedDuration = value!;
                    }); //
                  },
                  activeColor: TColors.primary, //
                ),
                RadioListTile<int>(
                  //
                  title: const Text('30 Minutes'), //
                  value: 30, //
                  groupValue: selectedDuration, //
                  onChanged: (int? value) {
                    //
                    setState(() {
                      selectedDuration = value!;
                    }); //
                  },
                  activeColor: TColors.primary, //
                ),
                RadioListTile<int>(
                  //
                  title: const Text('60 Minutes'), //
                  value: 60, //
                  groupValue: selectedDuration, //
                  onChanged: (int? value) {
                    //
                    setState(() {
                      selectedDuration = value!;
                    }); //
                  },
                  activeColor: TColors.primary, //
                ),
                RadioListTile<int>(
                  //
                  title: const Text('120 Minutes'), //
                  value: 120, //
                  groupValue: selectedDuration, //
                  onChanged: (int? value) {
                    //
                    setState(() {
                      selectedDuration = value!;
                    }); //
                  },
                  activeColor: TColors.primary, //
                ),
              ],
            );
          },
        ),
        actions: <Widget>[
          //
          TextButton(
            //
            child: Text(
              'Cancel',
              style: TextStyle(
                color: dark ? TColors.lightGrey : TColors.darkGrey,
              ),
            ), //
            onPressed: () {
              Get.back();
            }, //
          ),
          ElevatedButton(
            //
            child: const Text('Start Break'), //
            style: ElevatedButton.styleFrom(
              backgroundColor: TColors.primary,
            ), //
            onPressed: () {
              //
              Get.back(); // Close dialog
              controller.startBreak(selectedDuration); // Call controller method
            },
          ),
        ],
      ),
    );
  }
  // --- END DIALOG ---

  Widget _buildTodayEarningsCard(
    //
    BuildContext context, //
    DriverDashboardController controller, //
    bool dark, //
  ) {
    return Obx(
      //
      () => Container(
        //
        width: double.infinity, //
        padding: const EdgeInsets.all(TSizes.defaultSpace), //
        decoration: BoxDecoration(
          //
          gradient: LinearGradient(
            //
            colors: [TColors.primary, TColors.primary.withOpacity(0.8)], //
            begin: Alignment.topLeft, //
            end: Alignment.bottomRight, //
          ),
          borderRadius: BorderRadius.circular(TSizes.cardRadiusLg), //
        ),
        child: Column(
          //
          crossAxisAlignment: CrossAxisAlignment.start, //
          children: [
            Text(
              //
              'Today\'s Earnings', //
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                //
                color: TColors.white, //
                fontWeight: FontWeight.w600, //
              ),
            ),
            const SizedBox(height: TSizes.spaceBtwItems), //
            Text(
              //
              controller.formattedTodayEarnings, //
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                //
                color: TColors.white, //
                fontWeight: FontWeight.bold, //
              ),
            ),
            const SizedBox(height: TSizes.spaceBtwItems), //
            Row(
              //
              children: [
                Text(
                  //
                  'Trips: ${controller.todayTripsCount.value}', //
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    //
                    color: TColors.white.withOpacity(0.7), //
                  ),
                ),
                const SizedBox(width: TSizes.spaceBtwItems), //
                Text(
                  //
                  'Hours: ${controller.todayHours.value.toStringAsFixed(1)}h', //
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    //
                    color: TColors.white.withOpacity(0.7), //
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions(
    //
    BuildContext context, //
    DriverDashboardController controller, //
    bool dark, //
  ) {
    return Column(
      //
      crossAxisAlignment: CrossAxisAlignment.start, //
      children: [
        Text(
          //
          'Quick Actions', //
          style: Theme.of(
            //
            context, //
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold), //
        ),
        const SizedBox(height: TSizes.spaceBtwItems), //
        GridView.count(
          //
          shrinkWrap: true, //
          physics: const NeverScrollableScrollPhysics(), //
          crossAxisCount: 2, //
          crossAxisSpacing: TSizes.spaceBtwItems, //
          mainAxisSpacing: TSizes.spaceBtwItems, //
          childAspectRatio: 1.8, //
          children: [
            _buildActionCard(
              //
              context,
              'Earnings',
              Iconsax.chart,
              TColors.success,
              () => controller.navigateToEarnings(),
              dark,
            ), //
            _buildActionCard(
              //
              context,
              'Trips',
              Iconsax.route_square,
              TColors.info,
              () => controller.navigateToTrips(),
              dark,
            ), //
            _buildActionCard(
              //
              context,
              'Vehicle',
              Iconsax.car,
              TColors.warning,
              () => controller.navigateToVehicle(),
              dark,
            ), //
            _buildActionCard(
              //
              context,
              'Profile',
              Iconsax.user,
              TColors.secondary,
              () => controller.navigateToProfile(),
              dark,
            ), //
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard(
    //
    BuildContext context, //
    String title, //
    IconData icon, //
    Color color, //
    VoidCallback onTap, //
    bool dark, //
  ) {
    return GestureDetector(
      //
      onTap: onTap, //
      child: Container(
        //
        padding: const EdgeInsets.all(TSizes.sm), //
        decoration: BoxDecoration(
          //
          color: dark ? TColors.cardBackgroundDark : TColors.cardBackground, //
          borderRadius: BorderRadius.circular(TSizes.cardRadiusLg), //
          border: Border.all(color: color.withOpacity(0.2)), //
          boxShadow: [
            //
            BoxShadow(
              //
              color: TColors.black.withOpacity(dark ? 0.3 : 0.1), //
              blurRadius: TSizes.xs, //
              offset: const Offset(0, 2), //
            ),
          ],
        ),
        child: Column(
          //
          mainAxisAlignment: MainAxisAlignment.center, //
          mainAxisSize: MainAxisSize.min, //
          children: [
            Flexible(
              //
              child: Container(
                //
                width: TSizes.xl + TSizes.sm, //
                height: TSizes.xl + TSizes.sm, //
                decoration: BoxDecoration(
                  //
                  color: color.withOpacity(0.1), //
                  borderRadius: BorderRadius.circular(TSizes.md + TSizes.xs), //
                ),
                child: Icon(icon, color: color, size: TSizes.iconMd), //
              ),
            ),
            const SizedBox(height: TSizes.xs + 2), //
            Flexible(
              //
              child: Text(
                //
                title, //
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  //
                  fontWeight: FontWeight.w600, //
                  fontSize: TSizes.fontSizeSm - 2, //
                ),
                textAlign: TextAlign.center, //
                maxLines: 1, //
                overflow: TextOverflow.ellipsis, //
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getTripStatusText(TripStatus status) {
    //
    switch (status) {
      //
      case TripStatus.accepted:
        return 'Trip Accepted'; //
      case TripStatus.drivingToPickup:
        return 'Driving to Pickup'; //
      case TripStatus.arrivedAtPickup:
        return 'Arrived at Pickup'; //
      case TripStatus.tripInProgress:
        return 'Trip in Progress'; //
      case TripStatus.completed:
        return 'Trip Completed'; //
      default:
        return 'Unknown Status'; //
    }
  }
} // End Class
