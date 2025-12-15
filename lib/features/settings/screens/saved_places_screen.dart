import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sarri_ride/utils/constants/colors.dart';
import 'package:sarri_ride/utils/constants/sizes.dart';
import 'package:sarri_ride/utils/helpers/helper_functions.dart';
import 'package:iconsax/iconsax.dart';
import '../controllers/saved_places_controller.dart';
import '../models/saved_place.dart';
import 'add_place_screen.dart';

class SavedPlacesScreen extends StatelessWidget {
  SavedPlacesScreen({super.key});

  // Ensure controller is properly initialized - this prevents freezing issues
  final SavedPlacesController controller = Get.put(SavedPlacesController());

  @override
  Widget build(BuildContext context) {
    final dark = THelperFunctions.isDarkMode(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Saved Places'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Get.back(),
          icon: Icon(
            Iconsax.arrow_left_2,
            color: dark ? TColors.light : TColors.dark,
          ),
        ),
      ),
      body: Column(
        children: [
          // Header with Add Button
          _buildHeader(context, dark),

          // Places List
          Expanded(
            child: Obx(() {
              if (controller.savedPlaces.isEmpty) {
                return _buildEmptyState(context, dark);
              }

              return ListView.separated(
                padding: const EdgeInsets.all(TSizes.defaultSpace),
                itemCount: controller.savedPlaces.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: TSizes.spaceBtwItems),
                itemBuilder: (context, index) {
                  final place = controller.savedPlaces[index];
                  return _buildPlaceCard(place, context, dark);
                },
              );
            }),
          ),
        ],
      ),

      // Floating Action Button
      floatingActionButton: FloatingActionButton(
        onPressed: () => Get.to(() => const AddPlaceScreen()),
        backgroundColor: TColors.primary,
        child: const Icon(Iconsax.add, color: Colors.white),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool dark) {
    return Container(
      margin: const EdgeInsets.all(TSizes.defaultSpace),
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
              Iconsax.location,
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
                  'Saved Places',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: TColors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: TSizes.xs),
                Obx(
                  () => Text(
                    controller.savedPlaces.isEmpty
                        ? 'No saved places yet'
                        : '${controller.savedPlaces.length} saved place${controller.savedPlaces.length == 1 ? '' : 's'}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: TColors.white.withOpacity(0.8),
                    ),
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton.icon(
            onPressed: () => _navigateToAddPlace(),
            icon: const Icon(Iconsax.add, size: TSizes.iconSm),
            label: const Text('Add'),
            style: ElevatedButton.styleFrom(
              backgroundColor: TColors.white,
              foregroundColor: TColors.primary,
              padding: const EdgeInsets.symmetric(
                horizontal: TSizes.spaceBtwItems,
                vertical: TSizes.sm,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(TSizes.buttonRadius),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, bool dark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(TSizes.xl),
            decoration: BoxDecoration(
              color: TColors.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Iconsax.location_cross,
              size: TSizes.xl * 2,
              color: TColors.primary,
            ),
          ),
          const SizedBox(height: TSizes.spaceBtwItems),
          Text(
            'No Saved Places',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: TSizes.spaceBtwItems),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: TSizes.defaultSpace * 2,
            ),
            child: Text(
              'Save your favorite places for quick access when booking rides',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: dark ? TColors.lightGrey : TColors.darkGrey,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: TSizes.spaceBtwSections),
          ElevatedButton.icon(
            onPressed: () => Get.to(() => const AddPlaceScreen()),
            icon: const Icon(Iconsax.add),
            label: const Text('Add Your First Place'),
            style: ElevatedButton.styleFrom(
              backgroundColor: TColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: TSizes.spaceBtwSections,
                vertical: TSizes.md,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(TSizes.buttonRadius),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceCard(SavedPlace place, BuildContext context, bool dark) {
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
        children: [
          // Place Info
          Padding(
            padding: const EdgeInsets.all(TSizes.defaultSpace),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(TSizes.md),
                  decoration: BoxDecoration(
                    color: _getPlaceColor(place.label).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(TSizes.cardRadiusMd),
                  ),
                  child: Icon(
                    _getPlaceIcon(place.label),
                    color: _getPlaceColor(place.label),
                    size: TSizes.iconLg,
                  ),
                ),
                const SizedBox(width: TSizes.spaceBtwItems),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        place.label,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: TSizes.xs),
                      Text(
                        place.address,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: dark ? TColors.lightGrey : TColors.darkGrey,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: TSizes.xs),
                      Row(
                        children: [
                          Icon(
                            Iconsax.location,
                            size: TSizes.iconSm,
                            color: TColors.primary,
                          ),
                          const SizedBox(width: TSizes.xs),
                          Text(
                            '${place.lat.toStringAsFixed(4)}, ${place.lng.toStringAsFixed(4)}',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: TColors.primary),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Actions
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: TSizes.defaultSpace,
              vertical: TSizes.sm,
            ),
            decoration: BoxDecoration(
              color: dark ? TColors.darkerGrey : TColors.lightGrey,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(TSizes.cardRadiusLg),
                bottomRight: Radius.circular(TSizes.cardRadiusLg),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: TextButton.icon(
                    onPressed: () =>
                        Get.to(() => AddPlaceScreen(placeToEdit: place)),
                    icon: Icon(
                      Iconsax.edit,
                      size: TSizes.iconSm,
                      color: TColors.primary,
                    ),
                    label: Text(
                      'Edit',
                      style: TextStyle(color: TColors.primary),
                    ),
                  ),
                ),
                Container(
                  width: 1,
                  height: 30,
                  color: dark ? TColors.darkGrey : TColors.grey,
                ),
                Expanded(
                  child: TextButton.icon(
                    onPressed: () =>
                        _showDeleteConfirmation(place, context, dark),
                    icon: Icon(
                      Iconsax.trash,
                      size: TSizes.iconSm,
                      color: TColors.error,
                    ),
                    label: Text(
                      'Delete',
                      style: TextStyle(color: TColors.error),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(
    SavedPlace place,
    BuildContext context,
    bool dark,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Place'),
        content: Text('Are you sure you want to delete "${place.label}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              controller.deletePlace(place.id);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: TColors.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  IconData _getPlaceIcon(String label) {
    final lowerLabel = label.toLowerCase();
    if (lowerLabel.contains('home')) return Iconsax.home;
    if (lowerLabel.contains('work') || lowerLabel.contains('office'))
      return Iconsax.building;
    if (lowerLabel.contains('gym') || lowerLabel.contains('fitness'))
      return Iconsax.health;
    if (lowerLabel.contains('school') || lowerLabel.contains('university'))
      return Iconsax.teacher;
    if (lowerLabel.contains('hospital') || lowerLabel.contains('clinic'))
      return Iconsax.hospital;
    if (lowerLabel.contains('mall') || lowerLabel.contains('shop'))
      return Iconsax.shop;
    if (lowerLabel.contains('airport'))
      return Icons.local_airport; // You might want to add this if it's missing
    // ...
    return Iconsax.location;
  }

  Color _getPlaceColor(String label) {
    final lowerLabel = label.toLowerCase();
    if (lowerLabel.contains('home')) return TColors.success;
    if (lowerLabel.contains('work') || lowerLabel.contains('office'))
      return TColors.info;
    if (lowerLabel.contains('gym') || lowerLabel.contains('fitness'))
      return TColors.warning;
    if (lowerLabel.contains('school') || lowerLabel.contains('university'))
      return TColors.secondary;
    if (lowerLabel.contains('hospital') || lowerLabel.contains('clinic'))
      return TColors.error;
    if (lowerLabel.contains('mall') || lowerLabel.contains('shop'))
      return const Color(0xFF8B5CF6);
    if (lowerLabel.contains('restaurant') || lowerLabel.contains('cafe'))
      return const Color(0xFFEC4899);
    return TColors.primary;
  }

  // Safe navigation method to prevent freezing
  void _navigateToAddPlace() {
    try {
      print('Attempting to navigate to AddPlaceScreen...');
      THelperFunctions.showSnackBar('Opening Add Place screen...');

      // Use a delayed navigation to ensure UI is ready
      Future.delayed(const Duration(milliseconds: 100), () {
        Get.to(() => const AddPlaceScreen())
            ?.then((_) {
              print('Navigation completed successfully');
            })
            .catchError((error) {
              print('Navigation error: $error');
              THelperFunctions.showSnackBar('Error opening add place screen');
            });
      });
    } catch (e) {
      print('Error in _navigateToAddPlace: $e');
      THelperFunctions.showSnackBar('Unable to open add place screen');
    }
  }
}
