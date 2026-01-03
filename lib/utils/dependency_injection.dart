import 'package:get/get.dart';
import 'package:sarri_ride/core/services/http_service.dart';
import 'package:sarri_ride/core/services/websocket_service.dart';
import 'package:sarri_ride/core/services/map_marker_service.dart';
import 'package:sarri_ride/features/authentication/services/auth_service.dart';
import 'package:sarri_ride/features/ride/services/ride_service.dart';
import 'package:sarri_ride/features/driver/services/driver_trip_service.dart';
import 'package:sarri_ride/features/communication/services/chat_service.dart';
import 'package:sarri_ride/utils/theme/theme_controller.dart';

// Controllers (Lazy Loaded)
import 'package:sarri_ride/features/communication/controllers/call_controller.dart';
import 'package:sarri_ride/features/communication/controllers/chat_controller.dart';
import 'package:sarri_ride/features/notifications/controllers/notification_controller.dart';
import 'package:sarri_ride/features/payment/controllers/payment_controller.dart';
import 'package:sarri_ride/features/settings/controllers/settings_controller.dart';
import 'package:sarri_ride/features/ride/controllers/drawer_controller.dart';

class DependencyInjection {
  static Future<void> init() async {
    print("Starting Dependency Injection...");

    // 1. Core Services (Permanent, Initialized Immediately)
    if (!Get.isRegistered<HttpService>()) {
      Get.put(HttpService(), permanent: true);
    }

    Get.put(AuthService(), permanent: true);
    Get.put(ThemeController(), permanent: true);
    Get.put(WebSocketService(), permanent: true);

    // 2. Map Marker Service (Async)
    // We wrap this to ensure main() doesn't hang if this fails
    try {
      await Get.putAsync<MapMarkerService>(() => MapMarkerService().init());
    } catch (e) {
      print("DI Error: Failed to init MapMarkerService: $e");
      // Put a dummy one so dependent controllers don't crash
      Get.put(MapMarkerService());
    }

    // 3. Feature Services
    Get.put(RideService(), permanent: true); // Rider Service
    Get.put(DriverTripService(), permanent: true); // Driver Service
    Get.put(ChatService());

    // 4. Controllers (Lazy Put - Only load when used)
    Get.lazyPut(() => NotificationController(), fenix: true);
    Get.lazyPut(() => ChatController(), fenix: true);
    Get.lazyPut(() => SettingsController(), fenix: true);
    Get.lazyPut(() => MapDrawerController(), fenix: true);
    Get.lazyPut(() => CallController(), fenix: true);
    Get.lazyPut(() => PaymentController(), fenix: true);

    print("Dependency Injection Completed.");
  }
}
