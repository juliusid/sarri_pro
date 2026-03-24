import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:sarri_ride/app.dart';
import 'package:sarri_ride/core/controllers/network_controller.dart';
import 'package:sarri_ride/core/services/http_service.dart';
import 'package:sarri_ride/core/services/notification_service.dart'; // <--- IMPORT
import 'package:sarri_ride/utils/dependency_injection.dart';
import 'package:sarri_ride/firebase_options.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'config/api_config.dart';

// --- BACKGROUND HANDLER (Production Version) ---
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  // We keep this minimal. No spy prints needed.
  print("Background Notification received: ${message.data['type']}");
}

void main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  await dotenv.load(fileName: ".env");

  await GetStorage.init();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Register Background Handler
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Initialize Core Services
  await Get.putAsync(() => HttpService().init());

  // --- REGISTER NOTIFICATION SERVICE ---
  // We put it here so it's available everywhere
  Get.put(NotificationService());

  await DependencyInjection.init();
  ApiConfig.isProductionUrl;
  Get.put<NetworkController>(NetworkController(), permanent: true);

  runApp(const App());
}
