import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart'; //
import 'package:sarri_ride/core/services/websocket_service.dart'; // <-- Import WebSocketService
import 'package:sarri_ride/features/authentication/services/auth_service.dart'; //
import 'package:sarri_ride/features/driver/controllers/trip_management_controller.dart';
import 'package:sarri_ride/features/onboarding/screen/onboarding_screen.dart'; //
import 'package:sarri_ride/features/location/services/location_service.dart'; //
import 'package:sarri_ride/features/ride/controllers/ride_controller.dart'; //
import 'package:sarri_ride/features/ride/services/ride_service.dart'; //
import 'package:sarri_ride/features/ride/widgets/map_screen_getx.dart'; //
import 'package:sarri_ride/features/driver/screens/driver_dashboard_screen.dart'; // <-- Import Driver Dashboard
import 'package:sarri_ride/utils/constants/colors.dart'; //
import 'package:sarri_ride/utils/constants/image_strings.dart'; //
import 'package:sarri_ride/utils/helpers/helper_functions.dart'; //
import 'package:lottie/lottie.dart'; //

class SplashScreen extends StatefulWidget {
  //
  const SplashScreen({super.key}); //

  @override
  State<SplashScreen> createState() => _SplashScreenState(); //
}

class _SplashScreenState
    extends
        State<SplashScreen> //
    with TickerProviderStateMixin {
  //
  late AnimationController _logoController; //
  late AnimationController _fadeController; //
  late Animation<double> _logoScale; //
  late Animation<double> _fadeAnimation; //

  @override
  void initState() {
    //
    super.initState(); //
    _initializeAnimations(); //
    _initializeApp(); //
  }

  void _initializeAnimations() {
    //
    _logoController = AnimationController(
      //
      duration: const Duration(milliseconds: 1500), //
      vsync: this, //
    );

    _fadeController = AnimationController(
      //
      duration: const Duration(milliseconds: 800), //
      vsync: this, //
    );

    _logoScale = Tween<double>(begin: 0.5, end: 1.0).animate(
      //
      CurvedAnimation(parent: _logoController, curve: Curves.elasticOut), //
    );

    _fadeAnimation =
        Tween<double>(
          //
          begin: 0.0, //
          end: 1.0, //
        ).animate(
          CurvedAnimation(parent: _fadeController, curve: Curves.easeIn),
        ); //

    // Start animations
    _logoController.forward(); //
    Future.delayed(const Duration(milliseconds: 500), () {
      //
      _fadeController.forward(); //
    });
  }

  Future<void> _initializeApp() async {
    //
    // Minimum splash time
    final minimumSplashDuration = Future.delayed(const Duration(seconds: 3)); //

    // Initialize location service
    final locationService = Get.put(LocationService()); //
    await locationService.initialize(); //

    // Wait for minimum splash duration
    await minimumSplashDuration; //

    // After everything is done, check authentication and navigate.
    if (mounted) {
      //
      if (AuthService.instance.isAuthenticated) {
        //
        final storage = GetStorage(); //
        final userRole = storage.read<String>('user_role'); //
        final rideId = storage.read<String>('active_ride_id'); //

        // --- Connect WebSocket based on role ---
        if (userRole == 'driver') {
          print("SplashScreen: User is a driver, connecting WebSocket...");
          Get.put(TripManagementController(), permanent: true);
          WebSocketService.instance.connect(); // Connect the socket
        }
        // --- ADDED: Connect rider as well ---
        else if (userRole == 'client') {
          print("SplashScreen: User is a client, connecting WebSocket...");
          WebSocketService.instance.connect(); // Connect the socket
        }
        // --- END WebSocket Connect ---

        // --- Check for Active Ride (Rider Only) ---
        // Assuming only riders can have resumable rides for now
        if (userRole == 'client' && rideId != null && rideId.isNotEmpty) {
          //
          final rideService = RideService.instance; //
          final statusResponse = await rideService.checkRideStatus(rideId); //
          final activeStatuses = ['accepted', 'arrived', 'on-trip']; //

          if (statusResponse.status == 'success' && //
              statusResponse.data != null && //
              activeStatuses.contains(
                statusResponse.data!.status.toLowerCase(),
              )) {
            //
            print("SplashScreen: Restoring active ride state for rider...");
            final rideController = Get.put(RideController()); //
            await rideController.restoreRideState(statusResponse.data!); //
            Get.offAll(() => const MapScreenGetX()); //
            return; // Stop further execution
          } else {
            storage.remove('active_ride_id'); //
          }
        }
        // --- End Active Ride Check ---

        // Redirect based on ROLE
        if (userRole == 'driver') {
          //
          print("SplashScreen: Redirecting to Driver Dashboard...");
          Get.offAll(() => const DriverDashboardScreen()); //
        } else {
          // Default to rider screen
          print("SplashScreen: Redirecting to Rider Map Screen...");
          Get.offAll(() => const MapScreenGetX()); //
        }
      } else {
        // Not authenticated
        print(
          "SplashScreen: User not authenticated, redirecting to Onboarding...",
        );
        Get.offAll(() => const OnBoardingScreen()); //
      }
    }
  }

  @override
  void dispose() {
    //
    _logoController.dispose(); //
    _fadeController.dispose(); //
    super.dispose(); //
  }

  @override
  Widget build(BuildContext context) {
    //
    final dark = THelperFunctions.isDarkMode(context); //

    return Scaffold(
      //
      backgroundColor: dark ? TColors.dark : TColors.light, //
      body: Stack(
        //
        children: [
          // Background gradient
          Container(
            //
            decoration: BoxDecoration(
              //
              gradient: LinearGradient(
                //
                begin: Alignment.topLeft, //
                end: Alignment.bottomRight, //
                colors: [
                  //
                  dark ? TColors.dark : TColors.light, //
                  dark ? TColors.darkerGrey : TColors.lightGrey, //
                ],
              ),
            ),
          ),

          // Content
          Center(
            //
            child: Column(
              //
              mainAxisAlignment: MainAxisAlignment.center, //
              children: [
                // Logo with animation
                AnimatedBuilder(
                  //
                  animation: _logoScale, //
                  builder: (context, child) {
                    //
                    return Transform.scale(
                      //
                      scale: _logoScale.value, //
                      child: Container(
                        //
                        width: 120, //
                        height: 120, //
                        decoration: BoxDecoration(
                          //
                          color: Colors.white, //
                          borderRadius: BorderRadius.circular(30), //
                          boxShadow: [
                            //
                            BoxShadow(
                              //
                              color: TColors.primary.withOpacity(0.3), //
                              blurRadius: 20, //
                              offset: const Offset(0, 10), //
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.all(20), //
                        child: Image.asset(
                          //
                          dark ? TImages.darkAppLogo : TImages.lightAppLogo, //
                          fit: BoxFit.contain, //
                        ),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 40), //
                // App name
                FadeTransition(
                  //
                  opacity: _fadeAnimation, //
                  child: Text(
                    //
                    'SarriRide', // Changed App Name
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      //
                      fontWeight: FontWeight.bold, //
                      color: TColors.primary, //
                    ),
                  ),
                ),

                const SizedBox(height: 12), //
                // Tagline
                FadeTransition(
                  //
                  opacity: _fadeAnimation, //
                  child: Text(
                    //
                    'Your journey begins here', //
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      //
                      color: dark ? TColors.light : TColors.darkGrey, //
                    ),
                  ),
                ),

                const SizedBox(height: 60), //
                // Loading indicator with location status
                GetBuilder<LocationService>(
                  //
                  builder: (locationService) {
                    //
                    return FadeTransition(
                      //
                      opacity: _fadeAnimation, //
                      child: Column(
                        //
                        children: [
                          SizedBox(
                            //
                            width: 40, //
                            height: 40, //
                            child: CircularProgressIndicator(
                              //
                              strokeWidth: 3, //
                              valueColor: AlwaysStoppedAnimation<Color>(
                                //
                                TColors.primary, //
                              ),
                            ),
                          ),
                          const SizedBox(height: 20), //
                          Text(
                            //
                            locationService
                                    .isLocationLoading //
                                ? 'Getting your location...' //
                                : locationService
                                      .isLocationEnabled //
                                ? 'Location ready!' //
                                : 'Preparing your experience...', //
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium //
                                ?.copyWith(
                                  color:
                                      dark //
                                      ? TColors
                                            .lightGrey //
                                      : TColors.darkGrey, //
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
            //
            bottom: 50, //
            left: 0, //
            right: 0, //
            child: FadeTransition(
              //
              opacity: _fadeAnimation, //
              child: Row(
                //
                mainAxisAlignment: MainAxisAlignment.center, //
                children: [
                  Icon(Icons.location_on, color: TColors.primary, size: 16), //
                  const SizedBox(width: 8), //
                  Text(
                    //
                    'Secure • Reliable • Fast', //
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      //
                      color: dark ? TColors.lightGrey : TColors.darkGrey, //
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
