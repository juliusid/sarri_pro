import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:sarri_ride/features/authentication/controllers/driver_signup_controller.dart';
import 'package:sarri_ride/utils/constants/sizes.dart';
import 'package:sarri_ride/utils/validators/validation.dart';
import 'package:intl/intl.dart';

class DriverDetailsStep extends StatelessWidget {
  const DriverDetailsStep({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<DriverSignupController>();

    // Helper function to show date picker
    Future<void> selectDate(
      BuildContext context,
      TextEditingController dateController,
    ) async {
      final DateTime? picked = await showDatePicker(
        context: context,
        initialDate: DateTime.now(),
        firstDate: DateTime(1950),
        lastDate: DateTime(2101),
      );
      if (picked != null) {
        dateController.text = DateFormat('yyyy-MM-dd').format(picked);
      }
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Iconsax.arrow_left_2),
          onPressed: () => controller.previousStep(),
        ),
        title: const Text('Complete Your Profile'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(TSizes.defaultSpace),
        child: Form(
          key: controller.detailsFormKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- Personal Information ---
              Text(
                'Personal Information',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: TSizes.spaceBtwItems),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: controller.firstNameController,
                      validator: (v) =>
                          TValidator.validateEmptyText('First Name', v),
                      decoration: const InputDecoration(
                        labelText: 'First Name',
                        prefixIcon: Icon(Iconsax.user),
                      ),
                    ),
                  ),
                  const SizedBox(width: TSizes.spaceBtwInputFields),
                  Expanded(
                    child: TextFormField(
                      controller: controller.lastNameController,
                      validator: (v) =>
                          TValidator.validateEmptyText('Last Name', v),
                      decoration: const InputDecoration(
                        labelText: 'Last Name',
                        prefixIcon: Icon(Iconsax.user),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: TSizes.spaceBtwInputFields),
              TextFormField(
                controller: controller.passwordController,
                validator: TValidator.validatePassword,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  prefixIcon: Icon(Iconsax.password_check),
                ),
              ),
              const SizedBox(height: TSizes.spaceBtwInputFields),
              TextFormField(
                controller: controller.phoneNumberController,
                validator: TValidator.validatePhoneNumber,
                decoration: const InputDecoration(
                  labelText: 'Phone Number',
                  prefixIcon: Icon(Iconsax.call),
                ),
              ),
              const SizedBox(height: TSizes.spaceBtwInputFields),
              TextFormField(
                controller: controller.dobController,
                readOnly: true,
                onTap: () => selectDate(context, controller.dobController),
                decoration: const InputDecoration(
                  labelText: 'Date of Birth',
                  prefixIcon: Icon(Iconsax.calendar),
                ),
              ),
              const SizedBox(height: TSizes.spaceBtwInputFields),
              DropdownButtonFormField(
                items: ['Male', 'Female', 'Other']
                    .map(
                      (String category) => DropdownMenuItem(
                        value: category,
                        child: Text(category),
                      ),
                    )
                    .toList(),
                onChanged: (value) =>
                    controller.genderController.text = value ?? '',
                decoration: const InputDecoration(
                  labelText: 'Gender',
                  prefixIcon: Icon(Iconsax.user_octagon),
                ),
                validator: (value) =>
                    TValidator.validateEmptyText('Gender', value),
              ),

              const SizedBox(height: TSizes.spaceBtwSections),

              // --- Driving License ---
              Text(
                'Driving License',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: TSizes.spaceBtwItems),
              TextFormField(
                controller: controller.licenseNumberController,
                validator: (v) =>
                    TValidator.validateEmptyText('License Number', v),
                decoration: const InputDecoration(
                  labelText: 'License Number',
                  prefixIcon: Icon(Iconsax.card),
                ),
              ),
              const SizedBox(height: TSizes.spaceBtwInputFields),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: controller.licenseIssueDateController,
                      readOnly: true,
                      onTap: () => selectDate(
                        context,
                        controller.licenseIssueDateController,
                      ),
                      validator: (v) =>
                          TValidator.validateEmptyText('Issue Date', v),
                      decoration: const InputDecoration(
                        labelText: 'Issue Date',
                        prefixIcon: Icon(Iconsax.calendar_add),
                      ),
                    ),
                  ),
                  const SizedBox(width: TSizes.spaceBtwInputFields),
                  Expanded(
                    child: TextFormField(
                      controller: controller.licenseExpiryDateController,
                      readOnly: true,
                      onTap: () => selectDate(
                        context,
                        controller.licenseExpiryDateController,
                      ),
                      validator: (v) =>
                          TValidator.validateEmptyText('Expiry Date', v),
                      decoration: const InputDecoration(
                        labelText: 'Expiry Date',
                        prefixIcon: Icon(Iconsax.calendar_remove),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: TSizes.spaceBtwSections),

              // --- Address Details ---
              Text(
                'Address Details',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: TSizes.spaceBtwItems),
              TextFormField(
                controller: controller.currentAddressController,
                validator: (v) => TValidator.validateEmptyText('Address', v),
                decoration: const InputDecoration(
                  labelText: 'Current Address',
                  prefixIcon: Icon(Iconsax.location),
                ),
              ),
              const SizedBox(height: TSizes.spaceBtwInputFields),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: controller.currentCityController,
                      validator: (v) => TValidator.validateEmptyText('City', v),
                      decoration: const InputDecoration(labelText: 'City'),
                    ),
                  ),
                  const SizedBox(width: TSizes.spaceBtwInputFields),
                  Expanded(
                    child: TextFormField(
                      controller: controller.currentStateController,
                      validator: (v) =>
                          TValidator.validateEmptyText('State', v),
                      decoration: const InputDecoration(labelText: 'State'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: TSizes.spaceBtwInputFields),
              TextFormField(
                controller: controller.permanentAddressController,
                validator: (v) => TValidator.validateEmptyText('Address', v),
                decoration: const InputDecoration(
                  labelText: 'Permanent Address (if different)',
                  prefixIcon: Icon(Iconsax.location),
                ),
              ),

              const SizedBox(height: TSizes.spaceBtwSections),

              // --- Other Details ---
              Text(
                'Other Details',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: TSizes.spaceBtwInputFields),
              TextFormField(
                controller: controller.emergencyContactController,
                validator: TValidator.validatePhoneNumber,
                decoration: const InputDecoration(
                  labelText: 'Emergency Contact Number',
                  prefixIcon: Icon(Iconsax.call_add),
                ),
              ),

              const SizedBox(height: TSizes.spaceBtwSections),
              // --- Bank Details ---
              Text(
                'Bank Details',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: TSizes.spaceBtwItems),
              TextFormField(
                controller: controller.bankAccountNameController,
                validator: (v) =>
                    TValidator.validateEmptyText('Account Name', v),
                decoration: const InputDecoration(
                  labelText: 'Bank Account Name',
                ),
              ),
              const SizedBox(height: TSizes.spaceBtwInputFields),
              TextFormField(
                controller: controller.bankAccountNumberController,
                validator: (v) =>
                    TValidator.validateEmptyText('Account Number', v),
                decoration: const InputDecoration(
                  labelText: 'Bank Account Number',
                ),
              ),
              const SizedBox(height: TSizes.spaceBtwInputFields),
              TextFormField(
                controller: controller.bankNameController,
                validator: (v) => TValidator.validateEmptyText('Bank Name', v),
                decoration: const InputDecoration(labelText: 'Bank Name'),
              ),
              const SizedBox(height: TSizes.spaceBtwSections),
              // --- Vehicle Details ---
              Text(
                'Vehicle Details',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: TSizes.spaceBtwItems),
              TextFormField(
                controller: controller.vehicleMakeController,
                validator: (v) =>
                    TValidator.validateEmptyText('Vehicle Make', v),
                decoration: const InputDecoration(
                  labelText: 'Vehicle Make (e.g., Toyota)',
                ),
              ),
              const SizedBox(height: TSizes.spaceBtwInputFields),
              TextFormField(
                controller: controller.vehicleModelController,
                validator: (v) =>
                    TValidator.validateEmptyText('Vehicle Model', v),
                decoration: const InputDecoration(
                  labelText: 'Vehicle Model (e.g., Corolla)',
                ),
              ),
              const SizedBox(height: TSizes.spaceBtwInputFields),
              TextFormField(
                controller: controller.vehicleYearController,
                keyboardType: TextInputType.number,
                validator: (v) => TValidator.validateEmptyText('Year', v),
                decoration: const InputDecoration(labelText: 'Year'),
              ),
              const SizedBox(height: TSizes.spaceBtwInputFields),
              TextFormField(
                controller: controller.vehiclePlateController,
                validator: (v) =>
                    TValidator.validateEmptyText('License Plate', v),
                decoration: const InputDecoration(labelText: 'License Plate'),
              ),
              const SizedBox(height: TSizes.spaceBtwInputFields),
              TextFormField(
                controller: controller.vehicleSeatController, // New controller
                keyboardType: TextInputType.number,
                validator: (v) => TValidator.validateEmptyText('Seat count', v),
                decoration: const InputDecoration(labelText: 'Number of Seats'),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(TSizes.defaultSpace),
        child: SizedBox(
          width: double.infinity,
          child: Obx(
            () => ElevatedButton(
              onPressed: controller.isLoading.value
                  ? null
                  : () => controller.registerDriverDetails(),
              child: controller.isLoading.value
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Save & Continue to Documents'),
            ),
          ),
        ),
      ),
    );
  }
}
