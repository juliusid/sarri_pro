import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:sarri_ride/app.dart';
import 'package:sarri_ride/core/services/http_service.dart';
import 'package:sarri_ride/core/services/websocket_service.dart';
import 'package:sarri_ride/features/authentication/services/auth_service.dart';
import 'package:sarri_ride/features/communication/controllers/chat_controller.dart';
import 'package:sarri_ride/features/notifications/controllers/notification_controller.dart';
import 'package:sarri_ride/features/ride/services/ride_service.dart';
import 'package:sarri_ride/features/settings/controllers/settings_controller.dart';
import 'package:sarri_ride/utils/theme/theme_controller.dart';

void main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  await GetStorage.init();

  // Initialize services
  Get.put(HttpService());
  Get.put(AuthService());
  Get.put(ThemeController());
  Get.put(WebSocketService());
  Get.put(RideService());
  Get.put(NotificationController());
  Get.put(ChatController());
  Get.put(SettingsController());

  // Initialize Google Maps
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  runApp(const App());
}
