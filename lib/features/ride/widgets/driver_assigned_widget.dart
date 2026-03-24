import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sarri_ride/features/communication/controllers/call_controller.dart';
import 'package:sarri_ride/features/ride/controllers/ride_controller.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:sarri_ride/utils/constants/colors.dart';
import 'package:sarri_ride/utils/helpers/helper_functions.dart';
import 'package:sarri_ride/features/ride/widgets/driver_info_card.dart';
import 'package:sarri_ride/features/communication/screens/message_screen.dart';
import 'package:iconsax/iconsax.dart';

class DriverAssignedWidget extends StatelessWidget {
  final Driver driver;
  final String pickupLocation;
  final String destinationLocation;
  final VoidCallback onCancel;

  const DriverAssignedWidget({
    super.key,
    required this.driver,
    required this.pickupLocation,
    required this.destinationLocation,
    required this.onCancel,
  });

  // Function to show call type selection dialog
  void _showCallOptionsDialog(BuildContext context) {
    final dark = THelperFunctions.isDarkMode(context);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: dark ? TColors.dark : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            'Contact ${driver.name}',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: dark ? TColors.white : TColors.black,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'How would you like to connect?',
                style: TextStyle(
                  color: dark ? TColors.lightGrey : TColors.darkGrey,
                ),
              ),
              const SizedBox(height: 24),

              // Normal Call Option
              _buildDialogButton(
                icon: Iconsax.call,
                label: "Mobile Call",
                color: TColors.success,
                onTap: () {
                  Navigator.pop(context);
                  _makePhoneCall(driver.name);
                },
              ),

              const SizedBox(height: 12),

              // In-App Call Option
              _buildDialogButton(
                icon: Iconsax.video,
                label: "App Call",
                color: TColors.primary,
                onTap: () {
                  Navigator.pop(context);
                  _makeInAppCall();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDialogButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: color.withOpacity(0.1),
          foregroundColor: color,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20),
            const SizedBox(width: 10),
            Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  // Function to make normal phone call
  void _makePhoneCall(String driverName) async {
    final phoneNumber = driver.phoneNumber;
    final Uri phoneUri = Uri(scheme: 'tel', path: phoneNumber);
    try {
      if (await canLaunchUrl(phoneUri)) {
        await launchUrl(phoneUri);
      } else {
        THelperFunctions.showSnackBar('Could not launch phone app');
      }
    } catch (e) {
      THelperFunctions.showSnackBar('Error making phone call: $e');
    }
  }

  void _makeInAppCall() {
    CallController.instance.startCall(driver.id, driver.name, 'Driver');
  }

  void _onMessagePressed() {
    final rideController = Get.find<RideController>();
    final chatId = rideController.activeRideChatId.value;
    Get.to(
      () => MessageScreen(
        driverName: driver.name,
        carModel: driver.carModel,
        plateNumber: driver.plateNumber,
        rating: driver.rating,
        chatId: chatId,
        profileImage: driver.profileImage, // Passing the profile image
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dark = THelperFunctions.isDarkMode(context);
    final backgroundColor = dark ? TColors.dark : TColors.white;
    final textColor = dark ? TColors.white : TColors.textPrimary;
    final subtitleColor = dark ? TColors.lightGrey : TColors.textSecondary;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: dark ? TColors.darkGrey : Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header: Arriving Time
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Driver is on the way",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Arriving in ${driver.eta}",
                    style: TextStyle(
                      fontSize: 14,
                      color: TColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              // Optional: Add a small live indicator?
            ],
          ),

          const SizedBox(height: 20),

          // Driver Info Card
          DriverInfoCard(
            driver: driver,
            onCallPressed: () => _showCallOptionsDialog(context),
            onMessagePressed: _onMessagePressed,
          ),

          const SizedBox(height: 24),

          // Trip Timeline Visualization
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: dark
                  ? TColors.darkerGrey.withOpacity(0.3)
                  : const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: dark ? Colors.transparent : Colors.grey[200]!,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Timeline Icons (Dot-Line-Square)
                Column(
                  children: [
                    // Start Dot
                    Container(
                      width: 8,
                      height: 8,
                      margin: const EdgeInsets.only(
                        top: 6,
                      ), // Visual alignment with text
                      decoration: BoxDecoration(
                        color: dark ? Colors.grey[400] : Colors.grey[600],
                        shape: BoxShape.circle,
                      ),
                    ),
                    // Line
                    Container(
                      width: 2,
                      height: 35, // Height spanning
                      color: dark ? Colors.grey[700] : Colors.grey[300],
                      margin: const EdgeInsets.symmetric(vertical: 4),
                    ),
                    // End Square
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: TColors.primary,
                        shape: BoxShape.rectangle,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 16),

                // Address Texts
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Pickup Text
                      Text(
                        pickupLocation,
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                          color: textColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),

                      const SizedBox(
                        height: 24,
                      ), // Matches approximate line height + spacing
                      // Destination Text
                      Text(
                        destinationLocation,
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                          color: textColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Cancel Button
          Center(
            child: InkWell(
              onTap: () => _showCancelDialog(context, onCancel),
              borderRadius: BorderRadius.circular(20),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Text(
                  'Cancel Ride',
                  style: TextStyle(
                    color: TColors.error,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showCancelDialog(BuildContext context, VoidCallback onCancel) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Cancel Ride'),
          content: const Text(
            'Are you sure you want to cancel? Fees may apply.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('No, Keep'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                onCancel();
              },
              child: const Text(
                'Yes, Cancel',
                style: TextStyle(color: TColors.error),
              ),
            ),
          ],
        );
      },
    );
  }
}
