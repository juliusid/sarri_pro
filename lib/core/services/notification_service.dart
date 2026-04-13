import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:sarri_ride/config/api_config.dart';
import 'package:sarri_ride/core/services/http_service.dart';
import 'package:sarri_ride/features/driver/controllers/trip_management_controller.dart';
import 'package:sarri_ride/features/notifications/controllers/notification_controller.dart';
import 'package:sarri_ride/features/ride/controllers/ride_controller.dart';

class NotificationService extends GetxService {
  static NotificationService get instance => Get.find();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  // --- 1. INITIAL SETUP ---
  Future<void> init() async {
    // Request Permissions
    await _fcm.requestPermission(alert: true, badge: true, sound: true);

    // Create the Android Channel (Crucial for Sounds)
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'ride_notifications', // Matches Backend ID
      'Ride Alerts', // User visible name
      description: 'Notifications for ride updates',
      importance: Importance.max,
      playSound: true,

      // --- SAFE MODE: Commented out custom sound for now ---
      // Uncomment this line ONLY when you have added 'ride_booking.mp3'
      // to android/app/src/main/res/raw/
      // sound: RawResourceAndroidNotificationSound('ride_booking'),
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(channel);

    // --- LISTENERS ---

    // A. App is Open (Foreground)
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print("🔔 Foreground Notification: ${message.data['type']}");
      _handleNavigationLogic(message);
      if (Get.isRegistered<NotificationController>()) {
        final inbox = Get.find<NotificationController>();
        if (inbox.appendFromRemoteMessage(message)) {
          inbox.unreadCount.value++;
        }
      }
    });

    // B. App is in Background -> User Taps Notification
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print("🔔 Background Notification Tapped");
      _handleNavigationLogic(message);
    });
  }

  // --- 2. TOKEN HANDSHAKE ---
  Future<void> updateTokenOnBackend() async {
    // 1. Check Auth
    if (!HttpService.instance.isAuthenticated) {
      print(
        "⚠️ NotificationService: User not authenticated. Skipping token sync.",
      );
      return;
    }

    try {
      String? token = await _fcm.getToken();
      String deviceId = await _getDeviceId();

      if (token != null) {
        // 2. FIX: Construct the FULL URL using ApiConfig
        // We assume ApiConfig.baseUrl is defined (e.g., "https://api.yoursite.com")
        final String fullUrl =
            "${ApiConfig.baseUrl}/notification/update-fcm-token";

        await HttpService.instance.post(
          fullUrl,
          body: {"fcmToken": token, "deviceId": deviceId},
        );
        print("✅ FCM Token Sync sent to backend.");
      }
    } catch (e) {
      print("❌ Error updating FCM token: $e");
    }
  }

  Future<String> _getDeviceId() async {
    final DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    try {
      if (Platform.isAndroid) {
        AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
        return androidInfo.id;
      } else if (Platform.isIOS) {
        IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
        return iosInfo.identifierForVendor ?? 'ios_unknown';
      }
    } catch (_) {}
    return 'unknown_device';
  }

  // --- 3. THE ROUTING LOGIC ---
  void _handleNavigationLogic(RemoteMessage message) {
    final data = message.data;
    final String type = data['type'] ?? '';

    switch (type) {
      case 'RIDE_BOOKING':
        // For Driver: Navigate to Trip Request
        if (Get.isRegistered<TripManagementController>()) {
          Get.find<TripManagementController>().hasNewRequest.value = true;
        }
        break;

      case 'RIDE_ACCEPTED':
        // For Rider: Navigate to Map (Refresh handled by WebSocket usually)
        if (Get.isRegistered<RideController>()) {
          // RideController.instance.checkCurrentRideStatus();
        }
        break;

      case 'RIDE_STARTED':
      case 'RIDE_ENDED':
        // Just open the app, the Splash/Dashboard logic will refresh the state
        break;
    }
  }
}
