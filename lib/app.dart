import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:get/get.dart';
import 'package:sarri_ride/features/authentication/screens/user_type_selection/user_type_selection_screen.dart';
import 'package:sarri_ride/features/splash/screen/splash_screen.dart';
import 'package:sarri_ride/utils/theme/theme.dart';
import 'package:sarri_ride/utils/theme/theme_controller.dart';

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _MyAppState();
}

class _MyAppState extends State<App> {
  @override
  void initState() {
    super.initState();
    initialization();
  }

  void initialization() async {
    await Future.delayed(const Duration(seconds: 3));
    FlutterNativeSplash.remove();
  }

  @override
  Widget build(BuildContext context) {
    final themeController = Get.find<ThemeController>();
    return Obx(
      () => GetMaterialApp(
        themeMode: themeController.themeMode.value,
        theme: TAppTheme.lightTheme,
        darkTheme: TAppTheme.darkTheme,
        home: const SplashScreen(),

        //  Named Routes for Deep Linking
        getPages: [
          GetPage(name: '/', page: () => const SplashScreen()),
          GetPage(
            name: '/signup',
            page: () {
              // Check for referral code parameter if needed: Get.parameters['ref']
              print(
                "Deep link received: Signup with ref ${Get.parameters['ref']}",
              );
              return const UserTypeSelectionScreen();
            },
          ),
          // You can add more: '/profile', '/wallet', etc.
        ],
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
