import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:sarri_ride/core/services/websocket_service.dart';
import 'package:sarri_ride/features/authentication/models/auth_model.dart';
import 'package:sarri_ride/features/authentication/screens/login/login_screen_getx.dart';
import 'package:sarri_ride/features/authentication/screens/phone_verification/phone_number_screen.dart';
// import 'package:sarri_ride/features/authentication/screens/phone_verification/phone_number_screen.dart';
import 'package:sarri_ride/features/authentication/services/auth_service.dart';
import 'package:sarri_ride/features/onboarding/screen/onboarding_screen.dart';
import 'package:sarri_ride/features/location/services/location_service.dart';
import 'package:sarri_ride/features/ride/controllers/drawer_controller.dart';
import 'package:sarri_ride/features/ride/controllers/ride_controller.dart';
import 'package:sarri_ride/features/ride/services/ride_service.dart';
import 'package:sarri_ride/features/ride/widgets/map_screen_getx.dart';
import 'package:sarri_ride/features/driver/screens/driver_dashboard_screen.dart';
import 'package:sarri_ride/utils/constants/colors.dart';
import 'package:sarri_ride/utils/constants/image_strings.dart';
import 'package:sarri_ride/utils/helpers/helper_functions.dart';
import 'package:sarri_ride/features/driver/controllers/trip_management_controller.dart';
import 'package:sarri_ride/features/ride/models/ride_model.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _fadeController;
  late Animation<double> _logoScale;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeApp();
  }

  void _initializeAnimations() {
    _logoController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _logoScale = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.elasticOut),
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeIn));

    // Start animations
    _logoController.forward();
    Future.delayed(const Duration(milliseconds: 500), () {
      _fadeController.forward();
    });
  }

  Future<void> _initializeApp() async {
    final minimumSplashDuration = Future.delayed(const Duration(seconds: 3));

    final locationService = Get.put(LocationService());
    await locationService.initialize();

    await minimumSplashDuration;

    if (mounted) {
      if (AuthService.instance.isAuthenticated) {
        final storage = GetStorage();
        final userRole = storage.read<String>('user_role');
        final activeRideId = storage.read<String>('active_ride_id');
        final storedUserData = storage.read<Map<String, dynamic>>(
          'current_user_data',
        );
        if (storedUserData != null) {
          final clientData = ClientData.fromStorage(storedUserData);
          Get.put<ClientData>(clientData, tag: 'currentUser', permanent: true);
          final drawerController = Get.find<MapDrawerController>();
          await drawerController.refreshUserData();
          print(
            "SplashScreen: Re-loaded ClientData into memory for user ${clientData.id}",
          );
        } else {
          print(
            "SplashScreen: Error - User is authenticated but no ClientData found in storage. Logging out.",
          );
          Get.offAll(() => const LoginScreenGetX());
          THelperFunctions.showErrorSnackBar("Error", "Please log in again.");
          return;
        }

        // 1. WebSocket Connect
        if (userRole == 'driver' || userRole == 'client') {
          print("SplashScreen: User is '$userRole', connecting WebSocket...");
          WebSocketService.instance.connect();
        }

        // 2. Check for Active Ride
        if (activeRideId != null &&
            activeRideId.isNotEmpty &&
            userRole != null) {
          print(
            "SplashScreen: Found active_ride_id $activeRideId for $userRole. Attempting to reconnect...",
          );

          final rideService = RideService.instance;
          final reconnectResponse = await rideService.reconnectToTrip(
            activeRideId,
            userRole,
          );

          if (reconnectResponse.status == 'success' &&
              reconnectResponse.data != null) {
            print("SplashScreen: Reconnect successful. Restoring state.");

            if (userRole == 'client') {
              try {
                final rideData = RiderReconnectData.fromJson(
                  reconnectResponse.data!,
                );
                final rideController = Get.put(RideController());
                await rideController.restoreRideState(rideData);
                Get.offAll(() => const MapScreenGetX());
                return;
              } catch (e) {
                print("Error parsing Rider reconnect data: $e");
                storage.remove('active_ride_id');
              }
            } else if (userRole == 'driver') {
              try {
                final driverData = DriverReconnectData.fromJson(
                  reconnectResponse.data!,
                );
                final tripController = Get.put(
                  TripManagementController(),
                  permanent: true,
                );
                await tripController.restoreDriverRideState(driverData);
                Get.offAll(() => const DriverDashboardScreen());
                return;
              } catch (e) {
                print("Error parsing Driver reconnect data: $e");
                storage.remove('active_ride_id');
              }
            }
          } else {
            print(
              "SplashScreen: Reconnect API failed ('${reconnectResponse.message}'). Clearing stale ride ID.",
            );
            storage.remove('active_ride_id');
          }
        }

        print(
          "SplashScreen: No active ride. Proceeding with normal navigation.",
        );

        final drawerController = Get.find<MapDrawerController>();
        final profile = drawerController.fullProfile.value;

        if (userRole == 'client' &&
            (profile == null || profile.phoneNumberVerified == false)) {
          print(
            "SPLASH: Phone number missing or not verified. Forcing verification.",
          );
          Get.offAll(() => const PhoneNumberScreen());
          THelperFunctions.showSnackBar(
            'Please verify your phone number to continue.',
          );
        } else if (userRole == 'driver') {
          if (!Get.isRegistered<TripManagementController>()) {
            Get.put(TripManagementController(), permanent: true);
          }
          Get.offAll(() => const DriverDashboardScreen());
        } else {
          Get.offAll(() => const MapScreenGetX());
        }
      } else {
        print(
          "SplashScreen: User not authenticated, redirecting to Onboarding...",
        );
        Get.offAll(() => const OnBoardingScreen());
        FlutterNativeSplash.remove();
      }
    }
  }

  @override
  void dispose() {
    _logoController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dark = THelperFunctions.isDarkMode(context);

    return Scaffold(
      backgroundColor: dark ? TColors.dark : TColors.light,
      body: Stack(
        children: [
          // Background gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  dark ? TColors.dark : TColors.light,
                  dark ? TColors.darkerGrey : TColors.lightGrey,
                ],
              ),
            ),
          ),

          // Content
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // --- 1. UPDATED: LOGO ONLY (NO WHITE BOX) ---
                AnimatedBuilder(
                  animation: _logoScale,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _logoScale.value,
                      child: Image.asset(
                        // Using the full logos directly
                        dark ? TImages.darkAppLogo : TImages.lightAppLogo,
                        width: 200, // Increased size
                        height: 200,
                        fit: BoxFit.contain,
                      ),
                    );
                  },
                ),

                // --- END UPDATE ---

                // --- 2. REMOVED THE 'SarriRide' TEXT HERE ---
                const SizedBox(height: 40),

                // Tagline (Kept as requested)
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: Text(
                    'Your journey begins here',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: dark ? TColors.light : TColors.darkGrey,
                    ),
                  ),
                ),

                const SizedBox(height: 60),

                // Loading indicator with location status (Kept)
                GetBuilder<LocationService>(
                  builder: (locationService) {
                    return FadeTransition(
                      opacity: _fadeAnimation,
                      child: Column(
                        children: [
                          const SizedBox(
                            width: 40,
                            height: 40,
                            child: CircularProgressIndicator(
                              strokeWidth: 3,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                TColors.primary,
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            locationService.isLocationLoading
                                ? 'Getting your location...'
                                : locationService.isLocationEnabled
                                ? 'Location ready!'
                                : 'Preparing your experience...',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: dark
                                      ? TColors.lightGrey
                                      : TColors.darkGrey,
                                ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

          // Bottom decoration
          Positioned(
            bottom: 50,
            left: 0,
            right: 0,
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.location_on,
                    color: TColors.primary,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Secure • Reliable • Fast',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: dark ? TColors.lightGrey : TColors.darkGrey,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
