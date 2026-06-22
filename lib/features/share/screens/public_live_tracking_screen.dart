import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:iconsax/iconsax.dart';
import 'package:sarri_ride/features/share/controllers/public_tracking_controller.dart';
import 'package:sarri_ride/utils/constants/colors.dart';
import 'package:sarri_ride/utils/constants/sizes.dart';

class PublicLiveTrackingScreen extends StatelessWidget {
  final String shareToken;
  const PublicLiveTrackingScreen({super.key, required this.shareToken});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(PublicTrackingController(shareToken));

    return Scaffold(
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.errorMsg.value.isNotEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Iconsax.info_circle, size: 48, color: Colors.grey),
                const SizedBox(height: TSizes.spaceBtwItems),
                Text(
                  controller.errorMsg.value,
                  style: Theme.of(context).textTheme.titleMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: TSizes.spaceBtwItems),
                ElevatedButton(
                  onPressed: () => Get.offAllNamed('/'),
                  child: const Text('Go Home'),
                ),
              ],
            ),
          );
        }

        return Stack(
          children: [
            GoogleMap(
              initialCameraPosition: CameraPosition(
                target: controller.driverLocation.value ?? const LatLng(0, 0),
                zoom: 16.0,
              ),
              zoomControlsEnabled: false,
              myLocationButtonEnabled: false,
              markers: {
                if (controller.driverLocation.value != null)
                  Marker(
                    markerId: const MarkerId('driver'),
                    position: controller.driverLocation.value!,
                    rotation: controller.driverHeading.value,
                    icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
                  ),
              },
            ),

            // Top safe area overlay
            Positioned(
              top: MediaQuery.of(context).padding.top + 10,
              left: 20,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8),
                  ],
                ),
                child: IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Get.offAllNamed('/'),
                ),
              ),
            ),

            // Bottom info card
            Positioned(
              bottom: 40,
              left: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.all(TSizes.md),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(TSizes.cardRadiusLg),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Sarriride Live Share',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: TColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'Live',
                            style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: TSizes.spaceBtwItems),
                    if (controller.tripData.value != null)
                      Row(
                        children: [
                          const Icon(Icons.location_on, color: TColors.error, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              controller.tripData.value!['destinationName'] ?? 'Unknown Destination',
                              style: Theme.of(context).textTheme.bodyMedium,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    const Divider(height: 24),
                    Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: Colors.grey[200],
                          backgroundImage: controller.driverData.value?['picture'] != null
                              ? NetworkImage(controller.driverData.value!['picture'])
                              : null,
                          child: controller.driverData.value?['picture'] == null
                              ? const Icon(Iconsax.user, color: Colors.grey)
                              : null,
                        ),
                        const SizedBox(width: TSizes.spaceBtwItems),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${controller.driverData.value?['FirstName'] ?? 'Unknown'} (Driver)',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              if (controller.driverData.value?['vehicle'] != null)
                                Text(
                                  '${controller.driverData.value!['vehicle']['make'] ?? ''} ${controller.driverData.value!['vehicle']['model'] ?? ''} • ${controller.driverData.value!['vehicle']['licensePlate'] ?? ''}',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      }),
    );
  }
}
