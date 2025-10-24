import 'package:flutter/material.dart';
import 'package:sarri_ride/utils/constants/colors.dart';
import 'package:sarri_ride/utils/helpers/helper_functions.dart';

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
    
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: dark ? TColors.dark : TColors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: dark ? TColors.darkerGrey : Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              IconButton(
                onPressed: onBackPressed,
                icon: Icon(
                  Icons.arrow_back,
                  color: dark ? TColors.white : TColors.black,
                ),
              ),
              Text(
                'Choose a ride',
                style: TextStyle(
                  fontSize: 18, 
                  fontWeight: FontWeight.bold,
                  color: dark ? TColors.white : TColors.black,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Expanded(
            child: Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    itemCount: rideTypes.length,
                    itemBuilder: (context, index) {
                      final rideType = rideTypes[index];
                      final isSelected = selectedRideType == rideType;
                      
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: isSelected 
                              ? TColors.primary.withOpacity(dark ? 0.2 : 0.1)
                              : (dark ? TColors.darkerGrey.withOpacity(0.3) : Colors.white),
                          border: Border.all(
                            color: isSelected ? TColors.primary : (dark ? TColors.darkerGrey : Colors.grey[300]!),
                            width: isSelected ? 2 : 1,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: dark ? null : [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: ListTile(
                          leading: Icon(
                            rideType.icon,
                            size: 32,
                            color: isSelected ? TColors.primary : (dark ? TColors.lightGrey : Colors.grey[600]),
                          ),
                          title: Text(
                            rideType.name,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: isSelected ? TColors.primary : (dark ? TColors.white : TColors.black),
                            ),
                          ),
                          subtitle: Text(
                            '${rideType.seats} seats • ${rideType.eta}',
                            style: TextStyle(
                              color: dark ? TColors.lightGrey : Colors.grey[600],
                            ),
                          ),
                          trailing: Text(
                            '₦${rideType.price}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: isSelected ? TColors.primary : (dark ? TColors.white : TColors.black),
                            ),
                          ),
                          onTap: () => onRideTypeSelected(rideType),
                        ),
                      );
                    },
                  ),
                ),
                if (selectedRideType != null)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: onConfirmRide,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Confirm ${selectedRideType!.name} - ₦${selectedRideType!.price}',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
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