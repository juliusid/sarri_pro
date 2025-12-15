import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:sarri_ride/features/authentication/screens/login/login_screen_getx.dart';
import 'package:sarri_ride/features/authentication/services/auth_service.dart';
import 'package:sarri_ride/utils/helpers/helper_functions.dart';
import 'package:sarri_ride/core/services/websocket_service.dart'; // <-- Import WebSocketService

class SettingsController extends GetxController {
  static SettingsController get instance => Get.find();

  /// Logs out the user
  Future<void> logout() async {
    // Show loading indicator or disable button here if you want
    print("Logout process started..."); // Optional logging

    // --- Disconnect WebSocket FIRST ---
    print("Disconnecting WebSocket...");
    WebSocketService.instance.disconnect();
    // --- END WebSocket Disconnect ---

    // Call AuthService logout (which handles token clearing via HttpService)
    print("Calling AuthService logout...");
    final result = await AuthService.instance.logout();
    print(
      "AuthService logout result: Success=${result.success}, Error=${result.error}",
    ); // Optional logging

    final storage = GetStorage(); //
    storage.remove('user_role'); // Clear the role on logout
    storage.remove('current_user_data');
    print("Cleared user_role from storage."); // Optional logging

    // Navigate regardless of API logout success, as local tokens are cleared
    Get.offAll(() => const LoginScreenGetX());

    if (result.success) {
      THelperFunctions.showSnackBar("You have been logged out.");
    } else {
      // Show error but still proceed with UI logout
      THelperFunctions.showSnackBar(
        result.error ??
            "Logout failed on server, but you are logged out locally.",
      );
    }
    print("Logout process finished."); // Optional logging
  }
}
