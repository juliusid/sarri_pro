import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sarri_ride/utils/constants/colors.dart';
import 'package:sarri_ride/utils/constants/sizes.dart';
import 'package:sarri_ride/utils/helpers/helper_functions.dart';
import 'package:iconsax/iconsax.dart';

class SimpleAddPlaceScreen extends StatefulWidget {
  const SimpleAddPlaceScreen({super.key});

  @override
  State<SimpleAddPlaceScreen> createState() => _SimpleAddPlaceScreenState();
}

class _SimpleAddPlaceScreenState extends State<SimpleAddPlaceScreen> {
  final TextEditingController labelController = TextEditingController();
  final TextEditingController addressController = TextEditingController();

  @override
  void dispose() {
    labelController.dispose();
    addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dark = THelperFunctions.isDarkMode(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Place'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Get.back(),
          icon: Icon(
            Iconsax.arrow_left_2,
            color: dark ? TColors.light : TColors.dark,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => _savePlace(),
            child: Text(
              'Save',
              style: TextStyle(
                color: TColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(TSizes.defaultSpace),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(TSizes.defaultSpace),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [TColors.primary, TColors.primary.withOpacity(0.8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(TSizes.cardRadiusLg),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(TSizes.md),
                    decoration: BoxDecoration(
                      color: TColors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(TSizes.cardRadiusMd),
                    ),
                    child: Icon(
                      Iconsax.location_add,
                      color: TColors.white,
                      size: TSizes.iconLg,
                    ),
                  ),
                  const SizedBox(width: TSizes.spaceBtwItems),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Add New Place',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: TColors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: TSizes.xs),
                        Text(
                          'Save a place for quick access',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: TColors.white.withOpacity(0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: TSizes.spaceBtwSections),
            
            // Form
            Container(
              padding: const EdgeInsets.all(TSizes.defaultSpace),
              decoration: BoxDecoration(
                color: dark ? TColors.dark : Colors.white,
                borderRadius: BorderRadius.circular(TSizes.cardRadiusLg),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(dark ? 0.3 : 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Place Details',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: TSizes.spaceBtwItems),
                  
                  // Label Field
                  TextFormField(
                    controller: labelController,
                    decoration: InputDecoration(
                      labelText: 'Label',
                      hintText: 'e.g., Home, Office, Gym',
                      prefixIcon: Icon(
                        Iconsax.tag,
                        color: dark ? TColors.lightGrey : TColors.darkGrey,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(TSizes.inputFieldRadius),
                        borderSide: BorderSide(color: TColors.grey),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(TSizes.inputFieldRadius),
                        borderSide: BorderSide(color: TColors.primary, width: 2),
                      ),
                    ),
                    textInputAction: TextInputAction.next,
                  ),
                  
                  const SizedBox(height: TSizes.spaceBtwItems),
                  
                  // Address Field
                  TextFormField(
                    controller: addressController,
                    decoration: InputDecoration(
                      labelText: 'Address',
                      hintText: 'Enter the full address',
                      prefixIcon: Icon(
                        Iconsax.location,
                        color: dark ? TColors.lightGrey : TColors.darkGrey,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(TSizes.inputFieldRadius),
                        borderSide: BorderSide(color: TColors.grey),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(TSizes.inputFieldRadius),
                        borderSide: BorderSide(color: TColors.primary, width: 2),
                      ),
                    ),
                    maxLines: 2,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _savePlace() {
    final label = labelController.text.trim();
    final address = addressController.text.trim();
    
    if (label.isEmpty) {
      THelperFunctions.showSnackBar('Please enter a label for this place');
      return;
    }
    
    if (address.isEmpty) {
      THelperFunctions.showSnackBar('Please enter an address');
      return;
    }
    
    // For now, just show success and go back
    THelperFunctions.showSnackBar('Place saved successfully! (Test version)');
    Get.back();
  }
} 