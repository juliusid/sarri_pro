import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:sarri_ride/utils/constants/colors.dart';
import 'package:sarri_ride/utils/constants/sizes.dart';
import 'package:sarri_ride/utils/helpers/helper_functions.dart';

class LocationPermissionScreen extends StatefulWidget {
  /// If true, will request permission immediately and navigate after user decides
  /// If false, just shows the educational screen
  final bool autoRequestPermission;

  const LocationPermissionScreen({
    super.key,
    this.autoRequestPermission = false,
  });

  @override
  State<LocationPermissionScreen> createState() =>
      _LocationPermissionScreenState();
}

class _LocationPermissionScreenState extends State<LocationPermissionScreen> {
  bool _isProcessing = false;

  Future<void> _handleAllowAccess() async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);

    try {
      // Request the permission directly
      final permission = await Geolocator.requestPermission();
      debugPrint('Location permission result: $permission');

      // Simple tap feedback delay
      await Future.delayed(const Duration(milliseconds: 200));

      if (mounted) {
        // Navigate back to previous screen
        Navigator.of(context).pop();
      }
    } catch (e) {
      debugPrint('Error requesting location permission: $e');
      if (mounted) {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _handleMaybeLater() async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);

    // Simple tap feedback delay
    await Future.delayed(const Duration(milliseconds: 200));

    if (mounted) {
      // Navigate back without requesting permission
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final dark = THelperFunctions.isDarkMode(context);

    return Scaffold(
      backgroundColor: dark ? TColors.dark : TColors.light,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(TSizes.defaultSpace),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Spacer(),
              // Icon Container (mimicking the 3D map icon)
              Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  color: dark ? Colors.white : Colors.grey.shade100,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Center(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Icon(
                        Icons.map_rounded,
                        size: 80,
                        color: Colors.orange.shade300,
                      ),
                      const Positioned(
                        top: 20,
                        child: Icon(
                          Icons.location_on,
                          size: 60,
                          color: Colors.redAccent,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: TSizes.spaceBtwSections),
              // Title
              Text(
                'Enable Location Access',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: TSizes.spaceBtwItems),
              // Subtitle
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: TSizes.md),
                child: Text(
                  'Enable location services to allow the app to find rides near you and navigate efficiently.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: dark ? Colors.grey.shade400 : Colors.grey.shade600,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const Spacer(),
              // Buttons
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isProcessing ? null : _handleAllowAccess,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: TColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 3,
                    disabledBackgroundColor: Colors.grey.shade400,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: _isProcessing
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Allow access',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: TSizes.spaceBtwItems),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: _isProcessing ? null : _handleMaybeLater,
                  style: TextButton.styleFrom(
                    foregroundColor: dark ? Colors.white70 : Colors.black54,
                    disabledForegroundColor: Colors.grey.shade400,
                  ),
                  child: const Text(
                    'Maybe later',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ),
              const SizedBox(height: TSizes.sm),
            ],
          ),
        ),
      ),
    );
  }
}
