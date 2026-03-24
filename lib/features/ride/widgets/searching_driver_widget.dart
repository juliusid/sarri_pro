import 'package:flutter/material.dart';
import 'package:sarri_ride/utils/constants/colors.dart';
import 'package:sarri_ride/utils/helpers/helper_functions.dart';

class SearchingDriverWidget extends StatelessWidget {
  final VoidCallback onCancel;

  const SearchingDriverWidget({super.key, required this.onCancel});

  @override
  Widget build(BuildContext context) {
    final dark = THelperFunctions.isDarkMode(context);
    final backgroundColor = dark ? TColors.dark : TColors.white;
    final textColor = dark ? TColors.white : TColors.textPrimary;
    final subtitleColor = dark ? TColors.lightGrey : TColors.textSecondary;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
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
        mainAxisSize: MainAxisSize.min,
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
          const SizedBox(height: 40),

          // Radar/Pulse Animation Centerpiece
          Stack(
            alignment: Alignment.center,
            children: [
              // Outer decorative ring
              Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: TColors.primary.withOpacity(0.1),
                    width: 1,
                  ),
                ),
              ),
              // Inner background circle
              Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: TColors.primary.withOpacity(0.05),
                ),
              ),
              // Active Progress Ring
              SizedBox(
                width: 140,
                height: 140,
                child: CircularProgressIndicator(
                  strokeWidth: 4,
                  valueColor: AlwaysStoppedAnimation<Color>(TColors.primary),
                  backgroundColor: TColors.primary.withOpacity(0.1),
                ),
              ),
              // Center Car Image
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: dark ? TColors.darkerGrey : Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(20),
                child: Image.asset(
                  'assets/images/car.png',
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) =>
                      Icon(Icons.local_taxi, size: 40, color: TColors.primary),
                ),
              ),
            ],
          ),

          const SizedBox(height: 30),

          // Status Text
          Text(
            'Finding your ride...',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: textColor,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Connecting you with nearby drivers',
            style: TextStyle(fontSize: 15, color: subtitleColor),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 40),

          // Cancel Button
          GestureDetector(
            onTap: onCancel,
            child: Column(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: dark ? TColors.darkerGrey : Colors.grey[100],
                  ),
                  child: Icon(
                    Icons.close,
                    color: dark ? TColors.white : Colors.black54,
                    size: 24,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Cancel',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: subtitleColor,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }
}
