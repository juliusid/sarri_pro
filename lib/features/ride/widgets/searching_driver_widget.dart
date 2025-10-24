import 'package:flutter/material.dart';
import 'package:sarri_ride/utils/constants/colors.dart';
import 'package:sarri_ride/utils/helpers/helper_functions.dart';
import 'package:sarri_ride/features/ride/widgets/common_widgets.dart';

class SearchingDriverWidget extends StatelessWidget {
  final VoidCallback onCancel;

  const SearchingDriverWidget({
    super.key,
    required this.onCancel,
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
        children: [
          const DragHandle(),
          const SizedBox(height: 20),
          const CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(TColors.primary),
          ),
          const SizedBox(height: 20),
          Text(
            'Finding your driver...',
            style: TextStyle(
              fontSize: 18, 
              fontWeight: FontWeight.bold,
              color: dark ? TColors.white : TColors.black,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'This may take a few moments',
            style: TextStyle(
              color: dark ? TColors.lightGrey : Colors.grey,
            ),
          ),
          const SizedBox(height: 20),
          TextButton(
            onPressed: onCancel,
            child: Text(
              'Cancel',
              style: TextStyle(
                color: dark ? TColors.error : TColors.error,
              ),
            ),
          ),
        ],
      ),
    );
  }
} 