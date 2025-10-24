import 'package:flutter/material.dart';
import 'package:sarri_ride/utils/constants/colors.dart';
import 'package:sarri_ride/utils/helpers/helper_functions.dart';

class PlaceholderScreen extends StatelessWidget {
  final String title;

  const PlaceholderScreen({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    final dark = THelperFunctions.isDarkMode(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: dark ? TColors.dark : TColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Text(
          '$title – Coming Soon',
          style: Theme.of(context).textTheme.headlineSmall,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
} 