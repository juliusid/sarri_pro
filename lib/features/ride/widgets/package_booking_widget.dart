import 'package:flutter/material.dart';
import 'package:sarri_ride/utils/constants/colors.dart';
import 'package:sarri_ride/utils/helpers/helper_functions.dart';
import 'package:sarri_ride/features/ride/widgets/common_widgets.dart';
import 'package:sarri_ride/features/location/services/places_service.dart';
import 'package:iconsax/iconsax.dart';

class PackageBookingWidget extends StatelessWidget {
  final VoidCallback onBackPressed;
  final String pickupLocation;
  final VoidCallback onChangePickup;
  final TextEditingController deliveryController;
  final Function(String) onDeliveryChanged;
  final bool showSuggestions;
  final List<PlaceSuggestion> suggestions;
  final Function(PlaceSuggestion) onSuggestionTap;
  final VoidCallback onContinue;

  const PackageBookingWidget({
    super.key,
    required this.onBackPressed,
    required this.pickupLocation,
    required this.onChangePickup,
    required this.deliveryController,
    required this.onDeliveryChanged,
    required this.showSuggestions,
    required this.suggestions,
    required this.onSuggestionTap,
    required this.onContinue,
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
          const DragHandle(),
          const SizedBox(height: 20),
          
          // Header
          BackHeader(
            title: 'Package Delivery',
            onBackPressed: onBackPressed,
            icon: Icons.local_shipping,
            iconColor: TColors.info,
          ),
          
          const SizedBox(height: 24),
          
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Pickup location
                  Text(
                    'Pickup Location',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: dark ? TColors.white : TColors.black,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: dark ? TColors.darkerGrey.withOpacity(0.3) : Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: dark ? TColors.darkerGrey : Colors.grey[300]!,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.my_location, color: TColors.primary),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            pickupLocation,
                            style: TextStyle(
                              color: dark ? TColors.white : TColors.black,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: onChangePickup,
                          child: Text(
                            'Change',
                            style: TextStyle(color: TColors.primary),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Delivery location with autocomplete
                  Text(
                    'Delivery Location',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: dark ? TColors.white : TColors.black,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: deliveryController,
                    style: TextStyle(
                      color: dark ? TColors.white : TColors.black,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Enter delivery address',
                      hintStyle: TextStyle(
                        color: dark ? TColors.lightGrey : Colors.grey[600],
                      ),
                      prefixIcon: Icon(Icons.location_on, color: TColors.error),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: dark ? TColors.darkerGrey.withOpacity(0.3) : Colors.white,
                    ),
                    onChanged: onDeliveryChanged,
                  ),
                  
                  // Suggestions list
                  if (showSuggestions && suggestions.isNotEmpty)
                    Column(
                      children: List.generate(suggestions.length, (index) {
                        final suggestion = suggestions[index];
                        return ListTile(
                          leading: Icon(
                            Icons.location_on,
                            color: dark ? TColors.lightGrey : Colors.grey,
                          ),
                          title: Text(
                            suggestion.mainText,
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                              color: dark ? TColors.white : TColors.black,
                            ),
                          ),
                          subtitle: Text(
                            suggestion.secondaryText,
                            style: TextStyle(
                              color: dark ? TColors.lightGrey : Colors.grey[600],
                            ),
                          ),
                          onTap: () => onSuggestionTap(suggestion),
                        );
                      }),
                    ),
                  
                  const SizedBox(height: 20),
                  
                  // Package details
                  Text(
                    'Package Details',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: dark ? TColors.white : TColors.black,
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  // Package type dropdown
                  DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      labelText: 'Package Type',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: dark ? TColors.darkerGrey.withOpacity(0.3) : Colors.white,
                    ),
                    items: ['Documents', 'Food', 'Electronics', 'Clothing', 'Other']
                        .map((String type) => DropdownMenuItem<String>(
                              value: type,
                              child: Text(type),
                            ))
                        .toList(),
                    onChanged: (String? newValue) {},
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Package size
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          decoration: InputDecoration(
                            labelText: 'Weight (kg)',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            filled: true,
                            fillColor: dark ? TColors.darkerGrey.withOpacity(0.3) : Colors.white,
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          decoration: InputDecoration(
                            labelText: 'Size',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            filled: true,
                            fillColor: dark ? TColors.darkerGrey.withOpacity(0.3) : Colors.white,
                          ),
                          items: ['Small', 'Medium', 'Large', 'Extra Large']
                              .map((String size) => DropdownMenuItem<String>(
                                    value: size,
                                    child: Text(size),
                                  ))
                              .toList(),
                          onChanged: (String? newValue) {},
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Special instructions
                  TextFormField(
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: 'Special Instructions (Optional)',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: dark ? TColors.darkerGrey.withOpacity(0.3) : Colors.white,
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Contact details
                  Text(
                    'Recipient Contact',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: dark ? TColors.white : TColors.black,
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          decoration: InputDecoration(
                            labelText: 'Recipient Name',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            filled: true,
                            fillColor: dark ? TColors.darkerGrey.withOpacity(0.3) : Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          decoration: InputDecoration(
                            labelText: 'Phone Number',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            filled: true,
                            fillColor: dark ? TColors.darkerGrey.withOpacity(0.3) : Colors.white,
                          ),
                          keyboardType: TextInputType.phone,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Continue button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: onContinue,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        backgroundColor: TColors.info,
                      ),
                      child: const Text(
                        'Continue',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
} 