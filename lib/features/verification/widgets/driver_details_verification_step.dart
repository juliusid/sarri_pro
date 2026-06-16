// lib/features/verification/widgets/driver_details_verification_step.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:sarri_ride/common/widgets/loading_button.dart';
import 'package:sarri_ride/features/verification/controllers/driver_verification_controller.dart';
import 'package:sarri_ride/utils/constants/colors.dart';
import 'package:sarri_ride/utils/constants/sizes.dart';
import 'package:sarri_ride/utils/helpers/helper_functions.dart';
import 'package:sarri_ride/utils/validators/validation.dart';

class DriverDetailsVerificationStep extends StatefulWidget {
  final DriverVerificationController controller;

  const DriverDetailsVerificationStep({super.key, required this.controller});

  @override
  State<DriverDetailsVerificationStep> createState() => _DriverDetailsVerificationStepState();
}

class _DriverDetailsVerificationStepState extends State<DriverDetailsVerificationStep> {

  DriverVerificationController get c => widget.controller;

  @override
  Widget build(BuildContext context) {
    final dark = THelperFunctions.isDarkMode(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(TSizes.defaultSpace),
      child: Form(
        key: c.detailsFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: TSizes.spaceBtwItems),

            // ── Header ─────────────────────────────────────────────────
            Text(
              'Almost there!',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: TSizes.xs),
            Text(
              'Tell us about your vehicle.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: dark ? TColors.lightGrey : TColors.darkGrey,
                  ),
            ),

            const SizedBox(height: TSizes.spaceBtwSections),

            // ── Section: Service Type ──────────────────────────────────
            _SectionLabel(label: 'Service Type', dark: dark),
            const SizedBox(height: TSizes.spaceBtwItems),

            Obx(() => Row(
                  children: [
                    Expanded(
                      child: _ServiceTypeCard(
                        label: 'Ride Hailing',
                        icon: Iconsax.car,
                        value: 'ride_hailing',
                        isSelected:
                            c.selectedDriverType.value == 'ride_hailing',
                        onTap: () =>
                            c.selectedDriverType.value = 'ride_hailing',
                        dark: dark,
                      ),
                    ),
                    const SizedBox(width: TSizes.spaceBtwItems),
                    Expanded(
                      child: _ServiceTypeCard(
                        label: 'Package Delivery',
                        icon: Iconsax.box,
                        value: 'delivery',
                        isSelected: c.selectedDriverType.value == 'delivery',
                        onTap: () => c.selectedDriverType.value = 'delivery',
                        dark: dark,
                      ),
                    ),
                  ],
                )),

            const SizedBox(height: TSizes.spaceBtwSections),

            // ── Section: Vehicle Details ───────────────────────────────
            _SectionLabel(label: 'Vehicle Details', dark: dark),
            const SizedBox(height: TSizes.spaceBtwItems),

            // Make + Model
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: c.vehicleMakeController,
                    validator: (v) =>
                        TValidator.validateEmptyText('Vehicle make', v),
                    textCapitalization: TextCapitalization.words,
                    decoration: InputDecoration(
                      labelText: 'Make',
                      hintText: 'Toyota',
                      prefixIcon: Icon(Iconsax.car,
                          color: dark ? TColors.light : TColors.dark,
                          size: TSizes.iconMd),
                    ),
                  ),
                ),
                const SizedBox(width: TSizes.spaceBtwItems),
                Expanded(
                  child: TextFormField(
                    controller: c.vehicleModelController,
                    validator: (v) =>
                        TValidator.validateEmptyText('Vehicle model', v),
                    textCapitalization: TextCapitalization.words,
                    decoration: InputDecoration(
                      labelText: 'Model',
                      hintText: 'Corolla',
                      prefixIcon: Icon(Iconsax.car,
                          color: dark ? TColors.light : TColors.dark,
                          size: TSizes.iconMd),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: TSizes.spaceBtwInputFields),

            // Plate + Year
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: c.vehiclePlateController,
                    validator: (v) =>
                        TValidator.validateEmptyText('License plate', v),
                    textCapitalization: TextCapitalization.characters,
                    decoration: InputDecoration(
                      labelText: 'License plate',
                      hintText: 'ABC-123-XY',
                      prefixIcon: Icon(Iconsax.document_text,
                          color: dark ? TColors.light : TColors.dark,
                          size: TSizes.iconMd),
                    ),
                  ),
                ),
                const SizedBox(width: TSizes.spaceBtwItems),
                Expanded(
                  child: TextFormField(
                    controller: c.vehicleYearController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Year',
                      hintText: '2020',
                      prefixIcon: Icon(Iconsax.calendar,
                          color: dark ? TColors.light : TColors.dark,
                          size: TSizes.iconMd),
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return null; // optional
                      final year = int.tryParse(v);
                      if (year == null || year < 2000 || year > 2026) {
                        return 'Enter a valid year (2000–2026)';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: TSizes.spaceBtwInputFields),

            // Seats
            TextFormField(
              controller: c.vehicleSeatController,
              keyboardType: TextInputType.number,
              validator: (v) => TValidator.validateEmptyText('Seats', v),
              decoration: InputDecoration(
                labelText: 'Number of seats',
                hintText: '4',
                prefixIcon: Icon(Iconsax.people,
                    color: dark ? TColors.light : TColors.dark,
                    size: TSizes.iconMd),
              ),
            ),

            const SizedBox(height: TSizes.spaceBtwSections),

            // ── KYC note ──────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: TColors.primary.withOpacity(0.06),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: TColors.primary.withOpacity(0.25), width: 1),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Iconsax.info_circle,
                      color: TColors.primary, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'License, address & bank details can be added later during KYC verification.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: TColors.primary,
                          ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: TSizes.spaceBtwItems),

            // ── Terms & Conditions ─────────────────────────────────────
            Obx(() => GestureDetector(
                  onTap: () => c.privacyPolicy.toggle(),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SizedBox(
                        height: 24,
                        width: 24,
                        child: Checkbox(
                          value: c.privacyPolicy.value,
                          onChanged: (v) =>
                              c.privacyPolicy.value = v ?? false,
                          activeColor: TColors.primary,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: RichText(
                          text: TextSpan(
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(
                                  color: dark
                                      ? TColors.lightGrey
                                      : TColors.darkGrey,
                                ),
                            children: [
                              const TextSpan(text: 'I agree to the '),
                              TextSpan(
                                text: 'Terms & Conditions',
                                style: const TextStyle(
                                  color: TColors.primary,
                                  fontWeight: FontWeight.w600,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                              const TextSpan(text: ' and '),
                              TextSpan(
                                text: 'Privacy Policy',
                                style: const TextStyle(
                                  color: TColors.primary,
                                  fontWeight: FontWeight.w600,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                )),

            const SizedBox(height: TSizes.spaceBtwSections),

            // ── Submit Button ─────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              child: Obx(() => LoadingElevatedButton(
                    isLoading: c.isLoading.value,
                    text: 'Complete Setup',
                    loadingText: 'Setting up...',
                    onPressed: c.registerDriverDetails,
                    backgroundColor: TColors.primary,
                    foregroundColor: TColors.white,
                  )),
            ),

            const SizedBox(height: TSizes.spaceBtwItems),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String label;
  final bool dark;

  const _SectionLabel({required this.label, required this.dark});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: dark ? TColors.lightGrey : TColors.darkGrey,
            letterSpacing: 0.5,
          ),
    );
  }
}

class _ServiceTypeCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final String value;
  final bool isSelected;
  final VoidCallback onTap;
  final bool dark;

  const _ServiceTypeCard({
    required this.label,
    required this.icon,
    required this.value,
    required this.isSelected,
    required this.onTap,
    required this.dark,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? TColors.primary.withOpacity(0.1)
              : (dark ? TColors.darkerGrey : TColors.white),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? TColors.primary : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected
                  ? TColors.primary
                  : (dark ? TColors.lightGrey : TColors.darkGrey),
              size: 28,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight:
                        isSelected ? FontWeight.w600 : FontWeight.normal,
                    color: isSelected
                        ? TColors.primary
                        : (dark ? TColors.lightGrey : TColors.darkGrey),
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
