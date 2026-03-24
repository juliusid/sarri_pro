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
        final isEnabled = locationService.isLocationEnabled;

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isEnabled
                ? TColors.success.withOpacity(0.1)
                : TColors.warning.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isEnabled ? Icons.my_location_rounded : Icons.location_disabled,
                size: 14,
                color: isEnabled ? TColors.success : TColors.warning,
              ),
              const SizedBox(width: 6),
              Text(
                isEnabled ? 'GPS Active' : 'Default Location',
                style: TextStyle(
                  fontSize: 11,
                  color: isEnabled ? TColors.success : TColors.warning,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
