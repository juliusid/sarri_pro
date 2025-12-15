import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sarri_ride/features/communication/controllers/call_controller.dart';
import 'package:sarri_ride/features/ride/controllers/ride_controller.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:sarri_ride/utils/constants/colors.dart';
import 'package:sarri_ride/utils/helpers/helper_functions.dart';
import 'package:sarri_ride/features/ride/widgets/common_widgets.dart';
import 'package:sarri_ride/features/ride/widgets/driver_info_card.dart';
import 'package:sarri_ride/features/communication/screens/call_screen.dart';
import 'package:sarri_ride/features/communication/screens/message_screen.dart';
import 'package:iconsax/iconsax.dart';

class DriverArrivedWidget extends StatelessWidget {
  final Driver driver;
  final VoidCallback onStartTrip;

  const DriverArrivedWidget({
    super.key,
    required this.driver,
    required this.onStartTrip,
  });

  // Function to show call type selection dialog
  void _showCallOptionsDialog(BuildContext context) {
    final dark = THelperFunctions.isDarkMode(context);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            'Call ${driver.name}',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: dark ? TColors.white : TColors.black,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'How would you like to call the driver?',
                style: TextStyle(
                  color: dark ? TColors.lightGrey : TColors.darkGrey,
                ),
              ),
              const SizedBox(height: 20),

              // Normal Call Option
              Container(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    _makePhoneCall(driver.name);
                  },
                  icon: const Icon(Icons.phone, color: Colors.white),
                  label: const Text(
                    'Phone Call',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: TColors.success,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // In-App Call Option
              Container(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    _makeInAppCall();
                  },
                  icon: const Icon(Icons.videocam, color: Colors.white),
                  label: const Text(
                    'In-App Call',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: TColors.info,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: dark ? TColors.lightGrey : TColors.darkGrey,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // Function to make normal phone call
  void _makePhoneCall(String driverName) async {
    // Use the driver's phone number - in a real app, this would come from the driver object
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

  // Function to make in-app call (existing functionality)
  void _makeInAppCall() {
    // Use CallController to initiate the call
    // This handles the UI navigation and API call
    CallController.instance.startCall(driver.id, driver.name, 'Driver');
  }

  @override
  Widget build(BuildContext context) {
    final dark = THelperFunctions.isDarkMode(context);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: dark ? TColors.dark : TColors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          const DragHandle(),
          const SizedBox(height: 20),

          // Success icon
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: TColors.success.withOpacity(0.1),
              borderRadius: BorderRadius.circular(40),
            ),
            child: const Icon(
              Icons.check_circle,
              color: TColors.success,
              size: 40,
            ),
          ),

          const SizedBox(height: 16),

          Text(
            'Driver has arrived!',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: dark ? TColors.white : TColors.black,
            ),
          ),

          const SizedBox(height: 8),

          Text(
            '${driver.name} is waiting for you',
            style: TextStyle(
              color: dark ? TColors.lightGrey : Colors.grey[600],
              fontSize: 16,
            ),
          ),

          const SizedBox(height: 20),

          // Driver info compact
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: dark
                  ? TColors.darkerGrey.withOpacity(0.3)
                  : Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 20,
                  backgroundColor: TColors.primary,
                  child: Icon(Icons.person, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        driver.name,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: dark ? TColors.white : TColors.black,
                        ),
                      ),
                      Row(
                        children: [
                          const Icon(Icons.star, color: Colors.amber, size: 14),
                          Text(
                            ' ${driver.rating}',
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                              color: dark ? TColors.lightGrey : TColors.black,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        '${driver.carModel} • ${driver.plateNumber}',
                        style: TextStyle(
                          color: dark ? TColors.lightGrey : Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Call and Message buttons
          Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: TColors.success,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => _showCallOptionsDialog(context),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.phone, color: Colors.white, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'Call',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: TColors.info,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () {
                        // --- Get chatId from RideController ---
                        final rideController = Get.find<RideController>();
                        final chatId = rideController.activeRideChatId.value;
                        // --- End Get chatId ---
                        Get.to(
                          () => MessageScreen(
                            driverName: driver.name,
                            carModel: driver.carModel,
                            plateNumber: driver.plateNumber,
                            rating: driver.rating,
                            chatId: chatId,
                          ),
                        );
                      },
                      child: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.message, color: Colors.white, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'Message',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Start Trip Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onStartTrip,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Start Trip',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
