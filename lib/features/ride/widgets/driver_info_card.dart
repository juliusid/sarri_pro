import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:sarri_ride/utils/constants/colors.dart';
import 'package:sarri_ride/utils/helpers/helper_functions.dart';

class Driver {
  final String id;
  final String name;
  final double rating;
  final String carModel;
  final String plateNumber;
  final String phoneNumber;
  final String eta;
  final LatLng location;

  Driver({
    required this.id,
    required this.name,
    required this.rating,
    required this.carModel,
    required this.plateNumber,
    required this.phoneNumber,
    required this.eta,
    required this.location,
  });

  Driver copyWith({
    String? id,
    String? name,
    double? rating,
    String? carModel,
    String? plateNumber,
    String? phoneNumber,
    String? eta,
    LatLng? location,
  }) {
    return Driver(
      id: id ?? this.id,
      name: name ?? this.name,
      rating: rating ?? this.rating,
      carModel: carModel ?? this.carModel,
      plateNumber: plateNumber ?? this.plateNumber,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      eta: eta ?? this.eta,
      location: location ?? this.location,
    );
  }
}

class DriverInfoCard extends StatelessWidget {
  final Driver driver;
  final bool isCompact;
  final VoidCallback? onCallPressed;
  final VoidCallback? onMessagePressed;

  const DriverInfoCard({
    super.key,
    required this.driver,
    this.isCompact = false,
    this.onCallPressed,
    this.onMessagePressed,
  });

  @override
  Widget build(BuildContext context) {
    final dark = THelperFunctions.isDarkMode(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: dark ? TColors.darkerGrey.withOpacity(0.3) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(dark ? 0.3 : 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: isCompact ? 20 : 30,
                backgroundColor: TColors.primary,
                child: Icon(
                  Icons.person,
                  color: Colors.white,
                  size: isCompact ? 20 : 30,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      driver.name,
                      style: TextStyle(
                        fontSize: isCompact ? 16 : 18,
                        fontWeight: FontWeight.bold,
                        color: dark ? TColors.white : TColors.black,
                      ),
                    ),
                    Row(
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 16),
                        Text(
                          ' ${driver.rating}',
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            color: dark ? TColors.lightGrey : TColors.black,
                          ),
                        ),
                        Text(
                          ' • ${driver.carModel}',
                          style: TextStyle(
                            color: dark ? TColors.lightGrey : TColors.black,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      '${driver.plateNumber} • Arriving in ${driver.eta}',
                      style: TextStyle(
                        color: dark ? TColors.lightGrey : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          if (onCallPressed != null &&
              onMessagePressed != null &&
              !isCompact) ...[
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: TColors.success,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: onCallPressed,
                        child: const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.phone, color: Colors.white, size: 20),
                              SizedBox(width: 8),
                              Text(
                                'Call',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: TColors.info,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: onMessagePressed,
                        child: const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.message,
                                color: Colors.white,
                                size: 20,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Message',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
