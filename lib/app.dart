import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:get/get.dart';
import 'package:app_links/app_links.dart';
import 'dart:async';
import 'package:sarri_ride/core/services/notification_service.dart'; // <--- IMPORT
import 'package:sarri_ride/features/splash/screen/splash_screen.dart';
import 'package:sarri_ride/features/authentication/screens/user_type_selection/user_type_selection_screen.dart';
import 'package:sarri_ride/features/share/screens/public_live_tracking_screen.dart';
import 'package:sarri_ride/utils/theme/theme.dart';
import 'package:sarri_ride/utils/theme/theme_controller.dart';
import 'package:upgrader/upgrader.dart';

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _MyAppState();
}

class _MyAppState extends State<App> {
  late AppLinks _appLinks;
  StreamSubscription<Uri>? _linkSubscription;

  @override
  void initState() {
    super.initState();
    initialization();
    _initAppLinks();

    // --- ACTIVATE NOTIFICATIONS ---
    NotificationService.instance.init();
  }

  void initialization() async {
    FlutterNativeSplash.remove();
  }

  Future<void> _initAppLinks() async {
    _appLinks = AppLinks();

    // Handle initial link (opened while app was closed)
    final initialUri = await _appLinks.getInitialLink();
    if (initialUri != null) {
      _handleDeepLink(initialUri);
    }

    // Handle links opened while app is in background/foreground
    _linkSubscription = _appLinks.uriLinkStream.listen((uri) {
      _handleDeepLink(uri);
    }, onError: (err) {
      print('AppLinks Error: $err');
    });
  }

  void _handleDeepLink(Uri uri) {
    print('Deep Link Received: $uri');
    // Example: https://sarri-r-ide.vercel.app/share/xyz123
    if (uri.pathSegments.isNotEmpty && uri.pathSegments.first == 'share') {
      if (uri.pathSegments.length > 1) {
        final shareToken = uri.pathSegments[1];
        // Wait a small delay to ensure GetMaterialApp is ready
        Future.delayed(const Duration(milliseconds: 500), () {
          Get.toNamed('/share/$shareToken');
        });
      }
    }
  }

  @override
  void dispose() {
    _linkSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // ... No changes to build method ...
    final themeController = Get.find<ThemeController>();
    return Obx(
      () => GetMaterialApp(
        themeMode: themeController.themeMode.value,
        theme: TAppTheme.lightTheme,
        darkTheme: TAppTheme.darkTheme,
        home: const SplashScreen(),
        builder: (context, child) {
          return UpgradeAlert(
            upgrader: Upgrader(),
            // This ensures the update prompt isn't forcefully blocking the user
            showIgnore: true,
            showLater: true,
            child: child ?? const SizedBox.shrink(),
          );
        },
        getPages: [
          GetPage(name: '/', page: () => const SplashScreen()),
          GetPage(name: '/signup', page: () => const UserTypeSelectionScreen()),
          GetPage(
            name: '/share/:token',
            page: () => PublicLiveTrackingScreen(
              shareToken: Get.parameters['token'] ?? '',
            ),
          ),
        ],
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
