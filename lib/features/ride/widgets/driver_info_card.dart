import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:iconsax/iconsax.dart';
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
  final String? profileImage; // Added profile image

  Driver({
    required this.id,
    required this.name,
    required this.rating,
    required this.carModel,
    required this.plateNumber,
    required this.phoneNumber,
    required this.eta,
    required this.location,
    this.profileImage,
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
    String? profileImage,
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
      profileImage: profileImage ?? this.profileImage,
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
    final cardColor = dark
        ? TColors.darkerGrey.withOpacity(0.3)
        : Colors.grey[50];
    final textColor = dark ? TColors.white : TColors.textPrimary;
    final subtitleColor = dark ? TColors.lightGrey : TColors.textSecondary;

    // Handle rating display
    final bool isNewDriver =
        driver.rating == 0.0 ||
        driver.rating ==
            5.0; // Assuming 5.0 default means new if count is 0, but logical check here
    // Based on payload, null average means 0 count.

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: dark ? Colors.transparent : Colors.grey.withOpacity(0.2),
        ),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // --- PROFILE IMAGE ---
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: TColors.primary, width: 2),
                ),
                child: CircleAvatar(
                  radius: isCompact ? 22 : 28,
                  backgroundColor: Colors.grey[300],
                  backgroundImage:
                      (driver.profileImage != null &&
                          driver.profileImage!.isNotEmpty)
                      ? NetworkImage(driver.profileImage!)
                      : null,
                  child:
                      (driver.profileImage == null ||
                          driver.profileImage!.isEmpty)
                      ? Icon(
                          Iconsax.user,
                          color: Colors.grey[600],
                          size: isCompact ? 20 : 24,
                        )
                      : null,
                ),
              ),
              const SizedBox(width: 16),

              // --- NAME & RATING ---
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      driver.name,
                      style: TextStyle(
                        fontSize: isCompact ? 16 : 18,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.amber.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Iconsax.star1,
                                color: Colors.amber,
                                size: 12,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                driver.rating == 0.0
                                    ? 'New'
                                    : driver.rating.toStringAsFixed(1),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: Colors.amber,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          driver.carModel,
                          style: TextStyle(
                            color: subtitleColor,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // --- PLATE NUMBER ---
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: dark ? Colors.black26 : Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: dark ? Colors.grey[700]! : Colors.grey[300]!,
                  ),
                ),
                child: Text(
                  driver.plateNumber.toUpperCase(),
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.bold,
                    color: textColor,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ],
          ),

          // --- ACTION BUTTONS (Only if not compact) ---
          if (!isCompact &&
              (onCallPressed != null || onMessagePressed != null)) ...[
            const SizedBox(height: 16),
            Divider(
              height: 1,
              color: dark ? Colors.grey[800] : Colors.grey[200],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                if (onCallPressed != null)
                  Expanded(
                    child: _buildActionButton(
                      icon: Iconsax.call,
                      label: "Call",
                      color: TColors.success,
                      onTap: onCallPressed!,
                      dark: dark,
                    ),
                  ),
                if (onCallPressed != null && onMessagePressed != null)
                  const SizedBox(width: 12),
                if (onMessagePressed != null)
                  Expanded(
                    child: _buildActionButton(
                      icon: Iconsax.message,
                      label: "Message",
                      color: TColors.primary,
                      onTap: onMessagePressed!,
                      dark: dark,
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
    required bool dark,
  }) {
    return Material(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          alignment: Alignment.center,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
