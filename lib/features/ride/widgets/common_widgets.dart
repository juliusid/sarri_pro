import 'package:flutter/material.dart';
import 'package:sarri_ride/utils/constants/colors.dart';
import 'package:sarri_ride/utils/helpers/helper_functions.dart';

/// Reusable drag handle for bottom sheets
class DragHandle extends StatelessWidget {
  const DragHandle({super.key});

  @override
  Widget build(BuildContext context) {
    final dark = THelperFunctions.isDarkMode(context);
    
    return Center(
      child: Container(
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: dark ? TColors.darkerGrey : Colors.grey[300],
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}

/// Reusable header with back button and title
class BackHeader extends StatelessWidget {
  final String title;
  final VoidCallback onBackPressed;
  final IconData? icon;
  final Color? iconColor;

  const BackHeader({
    super.key,
    required this.title,
    required this.onBackPressed,
    this.icon,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final dark = THelperFunctions.isDarkMode(context);
    
    return Row(
      children: [
        IconButton(
          onPressed: onBackPressed,
          icon: Icon(
            Icons.arrow_back,
            color: dark ? TColors.white : TColors.black,
          ),
        ),
                  if (icon != null) ...[
            Icon(
              icon!,
              color: iconColor ?? TColors.primary,
              size: 24,
            ),
            const SizedBox(width: 8),
          ],
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: dark ? TColors.white : TColors.black,
            ),
          ),
      ],
    );
  }
}

/// Reusable trip details display card
class TripDetailsCard extends StatelessWidget {
  final String pickupLocation;
  final String destinationLocation;

  const TripDetailsCard({
    super.key,
    required this.pickupLocation,
    required this.destinationLocation,
  });

  @override
  Widget build(BuildContext context) {
    final dark = THelperFunctions.isDarkMode(context);
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: dark ? TColors.darkerGrey.withOpacity(0.3) : Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.location_on, color: TColors.primary, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  pickupLocation,
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: dark ? TColors.white : TColors.black,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.flag, color: TColors.error, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  destinationLocation,
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: dark ? TColors.white : TColors.black,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Reusable location input field with autocomplete
class LocationInputField extends StatelessWidget {
  final String hintText;
  final String labelText;
  final IconData prefixIcon;
  final Color prefixIconColor;
  final TextEditingController controller;
  final Function(String) onChanged;
  final bool autofocus;

  const LocationInputField({
    super.key,
    required this.hintText,
    required this.labelText,
    required this.prefixIcon,
    required this.prefixIconColor,
    required this.controller,
    required this.onChanged,
    this.autofocus = false,
  });

  @override
  Widget build(BuildContext context) {
    final dark = THelperFunctions.isDarkMode(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          labelText,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: dark ? TColors.white : TColors.black,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          style: TextStyle(
            color: dark ? TColors.white : TColors.black,
          ),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: TextStyle(
              color: dark ? TColors.lightGrey : Colors.grey[600],
            ),
            prefixIcon: Icon(prefixIcon, color: prefixIconColor),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            filled: true,
            fillColor: dark ? TColors.darkerGrey.withOpacity(0.3) : Colors.white,
          ),
          onChanged: onChanged,
          autofocus: autofocus,
        ),
      ],
    );
  }
}

/// Success status widget
class SuccessStatusWidget extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;

  const SuccessStatusWidget({
    super.key,
    required this.title,
    required this.subtitle,
    this.icon = Icons.check_circle,
  });

  @override
  Widget build(BuildContext context) {
    final dark = THelperFunctions.isDarkMode(context);
    
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: TColors.success.withOpacity(0.1),
            borderRadius: BorderRadius.circular(40),
          ),
          child: Icon(
            icon,
            color: TColors.success,
            size: 40,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          title,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: dark ? TColors.white : TColors.black,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          style: TextStyle(
            color: dark ? TColors.lightGrey : Colors.grey[600],
            fontSize: 16,
          ),
        ),
      ],
    );
  }
} 