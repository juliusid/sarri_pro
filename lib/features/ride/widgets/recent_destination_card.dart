import 'package:flutter/material.dart';
import 'package:sarri_ride/utils/constants/colors.dart';
import 'package:sarri_ride/utils/helpers/helper_functions.dart';

class RecentDestinationCard extends StatelessWidget {
  final Map<String, dynamic> destination;
  final VoidCallback onTap;

  const RecentDestinationCard({
    super.key,
    required this.destination,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final dark = THelperFunctions.isDarkMode(context);
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 140,
        height: 100,
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: dark ? TColors.darkerGrey.withOpacity(0.3) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: dark ? TColors.darkerGrey : Colors.grey[300]!,
          ),
          boxShadow: [
            BoxShadow(
              color: dark 
                  ? Colors.black.withOpacity(0.3)
                  : Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: TColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                destination['icon'] as IconData,
                color: TColors.primary,
                size: 18,
              ),
            ),
            const SizedBox(height: 8),
            Flexible(
              child: Text(
                destination['name'] as String,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: dark ? TColors.white : TColors.black,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 4),
            Flexible(
              child: Text(
                destination['address'] as String,
                style: TextStyle(
                  fontSize: 12,
                  color: dark ? TColors.lightGrey : Colors.grey[600],
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
} 