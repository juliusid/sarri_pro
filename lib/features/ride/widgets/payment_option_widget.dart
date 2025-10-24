import 'package:flutter/material.dart';
import 'package:sarri_ride/utils/constants/colors.dart';
import 'package:sarri_ride/utils/helpers/helper_functions.dart';

class PaymentOptionWidget extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool isFullWidth;

  const PaymentOptionWidget({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.isFullWidth = false,
  });

  @override
  Widget build(BuildContext context) {
    final dark = THelperFunctions.isDarkMode(context);
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: dark ? TColors.darkerGrey.withOpacity(0.3) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: dark ? TColors.darkerGrey : Colors.grey[300]!,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: isFullWidth
            ? Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: TColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Icon(
                      icon,
                      color: TColors.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: dark ? TColors.white : TColors.black,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          style: TextStyle(
                            fontSize: 12,
                            color: dark ? TColors.lightGrey : Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              )
            : Column(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: TColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Icon(
                      icon,
                      color: TColors.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: dark ? TColors.white : TColors.black,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: dark ? TColors.lightGrey : Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
      ),
    );
  }
} 