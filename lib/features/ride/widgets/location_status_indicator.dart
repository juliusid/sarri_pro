import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sarri_ride/features/location/services/location_service.dart';
import 'package:sarri_ride/utils/constants/colors.dart';

class LocationStatusIndicator extends StatelessWidget {
  const LocationStatusIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<LocationService>(
      builder: (locationService) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: locationService.isLocationEnabled 
                ? TColors.success.withOpacity(0.1)
                : TColors.warning.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: locationService.isLocationEnabled 
                  ? TColors.success
                  : TColors.warning,
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                locationService.isLocationEnabled 
                    ? Icons.location_on 
                    : Icons.location_off,
                size: 16,
                color: locationService.isLocationEnabled 
                    ? TColors.success
                    : TColors.warning,
              ),
              const SizedBox(width: 6),
              Text(
                locationService.isLocationEnabled 
                    ? 'Using your location'
                    : 'Using default location (Lagos)',
                style: TextStyle(
                  fontSize: 12,
                  color: locationService.isLocationEnabled 
                      ? TColors.success
                      : TColors.warning,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
} 