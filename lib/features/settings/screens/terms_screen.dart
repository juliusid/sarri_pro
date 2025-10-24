import 'package:flutter/material.dart';
import 'package:sarri_ride/utils/constants/colors.dart';
import 'package:sarri_ride/utils/helpers/helper_functions.dart';

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final dark = THelperFunctions.isDarkMode(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Terms of Service'),
        backgroundColor: dark ? TColors.dark : TColors.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Text(
          _termsText,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ),
    );
  }

  static const String _termsText = 'Sample Terms of Service...\n\n1. Acceptance of Terms\nLorem ipsum dolor sit amet...';
} 