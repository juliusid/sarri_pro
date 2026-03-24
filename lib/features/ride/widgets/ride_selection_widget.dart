import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:sarri_ride/features/ride/controllers/ride_controller.dart';
import 'package:sarri_ride/utils/constants/colors.dart';
import 'package:sarri_ride/utils/helpers/helper_functions.dart';
import 'package:get/get.dart';

class RideType {
  final String name;
  final int price;
  final String eta;
  final IconData icon;
  final int seats;

  const RideType({
    required this.name,
    required this.price,
    required this.eta,
    required this.icon,
    required this.seats,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RideType &&
          runtimeType == other.runtimeType &&
          name == other.name;

  @override
  int get hashCode => name.hashCode;
}

class RideSelectionWidget extends StatelessWidget {
  final VoidCallback onBackPressed;
  final List<RideType> rideTypes;
  final RideType? selectedRideType;
  final Function(RideType) onRideTypeSelected;
  final VoidCallback onConfirmRide;

  const RideSelectionWidget({
    super.key,
    required this.onBackPressed,
    required this.rideTypes,
    required this.selectedRideType,
    required this.onRideTypeSelected,
    required this.onConfirmRide,
  });

  @override
  Widget build(BuildContext context) {
    final dark = THelperFunctions.isDarkMode(context);
    final controller = Get.find<RideController>();
    final backgroundColor = dark ? TColors.dark : TColors.white;
    final textColor = dark ? TColors.white : TColors.textPrimary;
    final subtitleColor = dark ? TColors.lightGrey : TColors.textSecondary;

    return Container(
      padding: const EdgeInsets.only(top: 12, left: 20, right: 20, bottom: 24),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: dark ? TColors.darkGrey : Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Header
          Row(
            children: [
              IconButton(
                onPressed: onBackPressed,
                icon: Icon(Icons.arrow_back, color: textColor),
                padding: EdgeInsets.zero,
                alignment: Alignment.centerLeft,
              ),
              Text(
                'Choose a ride',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Ride List
          Expanded(
            child: Column(
              children: [
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.only(bottom: 16),
                    itemCount: rideTypes.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final rideType = rideTypes[index];
                      final isSelected = selectedRideType == rideType;

                      return GestureDetector(
                        onTap: () => onRideTypeSelected(rideType),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? TColors.primary.withOpacity(dark ? 0.2 : 0.08)
                                : (dark
                                      ? TColors.darkerGrey
                                      : Colors.transparent),
                            border: Border.all(
                              color: isSelected
                                  ? TColors.primary
                                  : (dark
                                        ? Colors.transparent
                                        : Colors.grey.withOpacity(0.2)),
                              width: isSelected ? 2 : 1,
                            ),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            children: [
                              // Image based on ride type (Car vs Package logic handled simply here)
                              Image.asset(
                                rideType.name.toLowerCase().contains('package')
                                    ? 'assets/images/content/package.png'
                                    : 'assets/images/content/car.png',
                                width: 60,
                                height: 45,
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) =>
                                    Icon(
                                      rideType.icon,
                                      size: 40,
                                      color: isSelected
                                          ? TColors.primary
                                          : subtitleColor,
                                    ),
                              ),
                              const SizedBox(width: 16),

                              // Ride Details
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      rideType.name,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        color: textColor,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Text(
                                          rideType.eta, // e.g., "6 min"
                                          style: TextStyle(
                                            color: subtitleColor,
                                            fontSize: 13,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Icon(
                                          Icons.person,
                                          size: 14,
                                          color: subtitleColor,
                                        ),
                                        const SizedBox(width: 2),
                                        Text(
                                          '${rideType.seats}',
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

                              // Price
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    '₦${rideType.price}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: textColor,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // Payment Method
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: dark ? TColors.darkerGrey : Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: InkWell(
                    onTap: () => controller.showPaymentMethodPicker(context),
                    child: Row(
                      children: [
                        Icon(Iconsax.money, color: TColors.primary, size: 24),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Payment Method',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: subtitleColor,
                                ),
                              ),
                              Obx(
                                () => Text(
                                  controller.selectedPaymentMethod.value,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                    color: textColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.arrow_forward_ios,
                          size: 14,
                          color: subtitleColor,
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Confirm Button
                if (selectedRideType != null)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: onConfirmRide,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: TColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        'Select ${selectedRideType!.name}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
