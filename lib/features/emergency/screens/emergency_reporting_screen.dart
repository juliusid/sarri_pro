import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:sarri_ride/features/emergency/controllers/emergency_controller.dart';
import 'package:sarri_ride/features/emergency/screens/emergency_chat_screen.dart';
import 'package:sarri_ride/utils/constants/colors.dart';
import 'package:sarri_ride/utils/constants/sizes.dart';
import 'package:sarri_ride/utils/helpers/helper_functions.dart';
import 'package:sarri_ride/common/widgets/loading_button.dart';

class EmergencyReportingScreen extends StatefulWidget {
  final String? tripId;
  const EmergencyReportingScreen({super.key, this.tripId});

  @override
  State<EmergencyReportingScreen> createState() =>
      _EmergencyReportingScreenState();
}

class _EmergencyReportingScreenState extends State<EmergencyReportingScreen> {
  final EmergencyController controller = Get.put(EmergencyController());
  final TextEditingController descriptionController = TextEditingController();

  // Categories from your guide
  final List<String> categories = [
    'Accident',
    'Kidnapping',
    'Shooting',
    'Rape',
    'Sexual Harassment',
    'Other',
  ];

  String selectedCategory = 'Accident';

  @override
  Widget build(BuildContext context) {
    final dark = THelperFunctions.isDarkMode(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Report Emergency',
          style: TextStyle(color: TColors.error),
        ),
        leading: IconButton(
          icon: const Icon(Iconsax.close_circle, color: TColors.error),
          onPressed: () => Get.back(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(TSizes.defaultSpace),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Warning Banner
            Container(
              padding: const EdgeInsets.all(TSizes.md),
              decoration: BoxDecoration(
                color: TColors.error.withOpacity(0.1),
                borderRadius: BorderRadius.circular(TSizes.cardRadiusMd),
                border: Border.all(color: TColors.error),
              ),
              child: Row(
                children: [
                  const Icon(Iconsax.warning_2, color: TColors.error),
                  const SizedBox(width: TSizes.spaceBtwItems),
                  Expanded(
                    child: Text(
                      'Only use this for real emergencies. False reporting may lead to account suspension.',
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: TColors.error),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: TSizes.spaceBtwSections),

            Text(
              'What happened?',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: TSizes.spaceBtwItems),

            // Category Chips
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: categories.map((category) {
                final isSelected = selectedCategory == category;
                return ChoiceChip(
                  label: Text(category),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() => selectedCategory = category);
                    }
                  },
                  selectedColor: TColors.error,
                  labelStyle: TextStyle(
                    color: isSelected
                        ? Colors.white
                        : (dark ? Colors.white : Colors.black),
                  ),
                  backgroundColor: dark
                      ? TColors.darkerGrey
                      : TColors.lightGrey,
                );
              }).toList(),
            ),

            const SizedBox(height: TSizes.spaceBtwSections),

            // Description
            TextFormField(
              controller: descriptionController,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Additional Details',
                hintText: 'Please describe the situation...',
                alignLabelWithHint: true,
              ),
            ),

            const SizedBox(height: TSizes.spaceBtwSections * 2),

            // Submit Button
            SizedBox(
              width: double.infinity,
              child: Obx(
                () => LoadingElevatedButton(
                  text: 'REQUEST HELP',
                  isLoading: controller.isLoading.value,
                  backgroundColor: TColors.error,
                  foregroundColor: Colors.white,
                  onPressed: _submitEmergency,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _submitEmergency() async {
    if (selectedCategory.isEmpty) {
      THelperFunctions.showSnackBar('Please select a category');
      return;
    }

    // Default description if empty
    String description = descriptionController.text.trim();
    if (description.isEmpty) {
      description = 'Emergency reported via app: $selectedCategory';
    }

    await controller.reportEmergency(
      category: selectedCategory.toLowerCase().replaceAll(' ', '_'),
      description: description,
      tripId: widget.tripId,
    );

    // If successful (activeEmergency is set), go to chat
    if (controller.hasActiveEmergency) {
      Get.off(() => const EmergencyChatScreen());
    }
  }
}
