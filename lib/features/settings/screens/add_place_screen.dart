import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sarri_ride/utils/constants/colors.dart';
import 'package:sarri_ride/utils/constants/sizes.dart';
import 'package:sarri_ride/utils/helpers/helper_functions.dart';
import 'package:iconsax/iconsax.dart';
import '../controllers/saved_places_controller.dart';
import '../models/saved_place.dart';

class AddPlaceScreen extends StatefulWidget {
  final SavedPlace? placeToEdit;
  
  const AddPlaceScreen({super.key, this.placeToEdit});

  @override
  State<AddPlaceScreen> createState() => _AddPlaceScreenState();
}

class _AddPlaceScreenState extends State<AddPlaceScreen> {
  SavedPlacesController? controller;
  final FocusNode _addressFocusNode = FocusNode();
  bool _isEditing = false;
  bool _isControllerReady = false;

  @override
  void initState() {
    super.initState();
    _initializeController();
  }

  Future<void> _initializeController() async {
    try {
      // First try to find existing controller
      controller = Get.find<SavedPlacesController>();
    } catch (e) {
      // If not found, create a new one
      controller = Get.put(SavedPlacesController());
    }
    
    // Wait for next frame to ensure controller is ready
    await Future.delayed(Duration.zero);
    
    if (mounted && controller != null) {
      setState(() {
        _isControllerReady = true;
        _isEditing = widget.placeToEdit != null;
      });
      
      // Initialize form data
      if (_isEditing && widget.placeToEdit != null) {
        controller!.loadPlaceForEditing(widget.placeToEdit!);
      } else {
        controller!.labelController.clear();
        controller!.addressController.clear();
        controller!.selectedPlace.value = null;
        controller!.clearSearch();
      }
    }
  }

  @override
  void dispose() {
    _addressFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dark = THelperFunctions.isDarkMode(context);
    
    if (!_isControllerReady || controller == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(_isEditing ? 'Edit Place' : 'Add Place'),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Place' : 'Add Place'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () {
            controller?.clearSearch();
            Get.back();
          },
          icon: Icon(
            Iconsax.arrow_left_2,
            color: dark ? TColors.light : TColors.dark,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => _savePlace(),
            child: Text(
              _isEditing ? 'Update' : 'Save',
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
            _buildHeader(context, dark),
            
            const SizedBox(height: TSizes.spaceBtwSections),
            
            // Form
            _buildForm(context, dark),
            
            const SizedBox(height: TSizes.spaceBtwItems),
            
            // Address Search with Autocomplete
            _buildAddressSearch(context, dark),
            
            const SizedBox(height: TSizes.spaceBtwItems),
            
            // Search Results
            _buildSearchResults(context, dark),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool dark) {
    return Container(
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
              _isEditing ? Iconsax.edit : Iconsax.location_add,
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
                  _isEditing ? 'Edit Saved Place' : 'Add New Place',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: TColors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: TSizes.xs),
                Text(
                  _isEditing 
                      ? 'Update your saved place details'
                      : 'Save a place for quick access',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: TColors.white.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForm(BuildContext context, bool dark) {
    if (controller == null) return const SizedBox.shrink();
    
    return Container(
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
            controller: controller!.labelController,
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
            onFieldSubmitted: (_) => _addressFocusNode.requestFocus(),
          ),
        ],
      ),
    );
  }

  Widget _buildAddressSearch(BuildContext context, bool dark) {
    if (controller == null) return const SizedBox.shrink();
    
    return Container(
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
            'Address',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: TSizes.spaceBtwItems),
          
          // Address Search Field
          TextFormField(
            controller: controller!.addressController,
            focusNode: _addressFocusNode,
            decoration: InputDecoration(
              labelText: 'Search for address',
              hintText: 'Start typing to search...',
              prefixIcon: Icon(
                Iconsax.search_normal,
                color: dark ? TColors.lightGrey : TColors.darkGrey,
              ),
              suffixIcon: ValueListenableBuilder<TextEditingValue>(
                valueListenable: controller!.addressController,
                builder: (context, value, child) {
                  return value.text.isNotEmpty
                      ? IconButton(
                          onPressed: () {
                            controller!.addressController.clear();
                            controller!.selectedPlace.value = null;
                            controller!.clearSearch();
                          },
                          icon: Icon(
                            Iconsax.close_circle,
                            color: dark ? TColors.lightGrey : TColors.darkGrey,
                          ),
                        )
                      : const SizedBox.shrink();
                },
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
            onChanged: (value) {
              if (value.length >= 3) {
                controller!.searchPlaces(value);
              } else {
                controller!.clearSearch();
              }
            },
            textInputAction: TextInputAction.search,
          ),
          
          // Selected Place Info
          Obx(() {
            if (controller?.selectedPlace.value != null) {
              final selectedPlace = controller!.selectedPlace.value!;
              return Container(
                margin: const EdgeInsets.only(top: TSizes.spaceBtwItems),
                padding: const EdgeInsets.all(TSizes.md),
                decoration: BoxDecoration(
                  color: TColors.success.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(TSizes.cardRadiusMd),
                  border: Border.all(color: TColors.success.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(
                      Iconsax.tick_circle,
                      color: TColors.success,
                      size: TSizes.iconMd,
                    ),
                    const SizedBox(width: TSizes.spaceBtwItems),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Place Selected',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: TColors.success,
                            ),
                          ),
                          Text(
                            '${selectedPlace.location.latitude.toStringAsFixed(6)}, ${selectedPlace.location.longitude.toStringAsFixed(6)}',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: dark ? TColors.lightGrey : TColors.darkGrey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }
            return const SizedBox.shrink();
          }),
        ],
      ),
    );
  }

  Widget _buildSearchResults(BuildContext context, bool dark) {
    if (controller == null) return const SizedBox.shrink();
    
    return Obx(() {
      if (controller!.placeSuggestions.isEmpty) {
        return const SizedBox.shrink();
      }
      
      return Container(
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
            Padding(
              padding: const EdgeInsets.all(TSizes.defaultSpace),
              child: Text(
                'Search Results',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: controller!.placeSuggestions.length,
              separatorBuilder: (context, index) => Divider(
                height: 1,
                color: dark ? TColors.darkGrey : TColors.lightGrey,
              ),
              itemBuilder: (context, index) {
                final suggestion = controller!.placeSuggestions[index];
                return ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(TSizes.sm),
                    decoration: BoxDecoration(
                      color: TColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(TSizes.cardRadiusMd),
                    ),
                    child: Icon(
                      Iconsax.location,
                      color: TColors.primary,
                      size: TSizes.iconSm,
                    ),
                  ),
                  title: Text(
                    suggestion.mainText,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: suggestion.secondaryText.isNotEmpty
                      ? Text(
                          suggestion.secondaryText,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: dark ? TColors.lightGrey : TColors.darkGrey,
                          ),
                        )
                      : null,
                  trailing: Icon(
                    Iconsax.arrow_right_3,
                    color: dark ? TColors.lightGrey : TColors.darkGrey,
                    size: TSizes.iconSm,
                  ),
                  onTap: () => _selectPlace(suggestion),
                );
              },
            ),
          ],
        ),
      );
    });
  }

  void _selectPlace(suggestion) async {
    _addressFocusNode.unfocus();
    await controller?.selectPlace(suggestion);
    controller?.clearSearch();
  }

  void _savePlace() {
    if (controller == null) return;
    
    if (_isEditing && widget.placeToEdit != null) {
      controller!.updatePlace(widget.placeToEdit!.id);
    } else {
      controller!.addPlace();
    }
    
    // Navigate back after successful save
    if (controller!.selectedPlace.value != null) {
      Get.back();
    }
  }
} 