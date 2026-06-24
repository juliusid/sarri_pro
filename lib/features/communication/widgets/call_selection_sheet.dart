import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:sarri_ride/utils/constants/colors.dart';
import 'package:sarri_ride/utils/helpers/helper_functions.dart';

class CallSelectionSheet {
  static void show({
    required BuildContext context,
    required String contactName,
    required VoidCallback onMobileCall,
    required VoidCallback onInAppCall,
  }) {
    final dark = THelperFunctions.isDarkMode(context);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.only(top: 16, bottom: 32, left: 24, right: 24),
          decoration: BoxDecoration(
            color: dark ? TColors.dark : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag handle
              Container(
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                  color: dark ? Colors.grey[800] : Colors.grey[300],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 24),

              // Title
              Text(
                'Contact $contactName',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: dark ? Colors.white : TColors.darkerGrey,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Choose how you want to connect',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: dark ? Colors.grey[400] : Colors.grey[600],
                    ),
              ),
              const SizedBox(height: 32),

              // Mobile Call Option
              _buildCallOption(
                context: context,
                icon: Iconsax.call5,
                title: 'Mobile Call',
                subtitle: 'Standard carrier charges may apply',
                color: TColors.success,
                onTap: () {
                  Navigator.pop(context);
                  onMobileCall();
                },
                dark: dark,
              ),

              const SizedBox(height: 16),

              // In-App Call Option
              _buildCallOption(
                context: context,
                icon: Iconsax.video5,
                title: 'In-App Call',
                subtitle: 'Free data call over internet',
                color: TColors.primary,
                onTap: () {
                  Navigator.pop(context);
                  THelperFunctions.showSnackBar('In-App Calling is coming soon! Please use Mobile Call.');
                },
                dark: dark,
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  static Widget _buildCallOption({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
    required bool dark,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(dark ? 0.15 : 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: color.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: dark ? Colors.white : TColors.darkerGrey,
                          fontSize: 16,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: dark ? Colors.grey[400] : Colors.grey[600],
                        ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              color: color.withOpacity(0.7),
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}
