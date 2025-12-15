import 'package:get/get.dart';
import 'package:share_plus/share_plus.dart'; // Native share sheet
import 'package:sarri_ride/features/ride/controllers/ride_controller.dart';
import 'package:sarri_ride/features/share/services/share_service.dart';
import 'package:sarri_ride/utils/helpers/helper_functions.dart';

class ShareController extends GetxController {
  static ShareController get instance => Get.find();

  final ShareService _service = Get.put(ShareService());
  // Use lazy lookup for RideController to avoid init issues if called early
  RideController get _rideController => Get.find<RideController>();

  final RxBool isSharing = false.obs;

  /// Generates a link and opens the native share sheet
  Future<void> shareTrip() async {
    // Check if ride ID is valid
    if (!Get.isRegistered<RideController>() ||
        _rideController.rideId.value.isEmpty) {
      THelperFunctions.showSnackBar("No active trip to share.");
      return;
    }

    isSharing.value = true;
    try {
      final token = await _service.createShareLink(
        _rideController.rideId.value,
      );

      if (token != null) {
        // Construct the full URL
        final String shareUrl = "https://sarriride.app/share/$token";

        // Open the native iOS/Android share sheet
        // 'subject' is used primarily for Email apps
        await Share.share(
          'Follow my ride on Sarri: $shareUrl',
          subject: 'Track my ride',
        );
      } else {
        THelperFunctions.showErrorSnackBar(
          'Error',
          'Could not generate share link.',
        );
      }
    } catch (e) {
      print("Share error: $e");
      THelperFunctions.showSnackBar("An error occurred while sharing.");
    } finally {
      isSharing.value = false;
    }
  }
}
