import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sarri_ride/utils/constants/colors.dart';
import 'package:sarri_ride/utils/helpers/helper_functions.dart';
import 'package:sarri_ride/features/ride/widgets/common_widgets.dart';
import 'package:sarri_ride/features/warehouse/controllers/warehouse_booking_controller.dart';

class WarehouseBookingWidget extends StatelessWidget {
  final VoidCallback onBackPressed;
  final VoidCallback onContinue;

  const WarehouseBookingWidget({
    super.key,
    required this.onBackPressed,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    final dark = THelperFunctions.isDarkMode(context);
    final controller = Get.put(WarehouseBookingController());

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
          
          BackHeader(
            title: 'Send to Warehouse',
            onBackPressed: onBackPressed,
            icon: Icons.warehouse_rounded,
            iconColor: TColors.primary,
          ),
          
          const SizedBox(height: 24),
          
          Expanded(
            child: SingleChildScrollView(
              child: Obx(
                () => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Step 1: Drop-off Warehouse
                    _buildSectionTitle('1. Select Drop-off Hub', dark),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      decoration: _inputDecoration(dark, 'Drop-off Warehouse'),
                      value: controller.selectedWarehouseId.value.isEmpty ? null : controller.selectedWarehouseId.value,
                      hint: const Text('Select a hub near you'),
                      items: controller.warehouses.map((w) {
                        return DropdownMenuItem<String>(
                          value: w['_id'] as String,
                          child: Text('${w['name']} (${w['city']})'),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          controller.fetchPricingRoutes(val);
                        }
                      },
                    ),

                    const SizedBox(height: 20),

                    // Step 2: Destination State
                    _buildSectionTitle('2. Destination State', dark),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      decoration: _inputDecoration(dark, 'Destination State'),
                      value: controller.selectedDestinationState.value.isEmpty ? null : controller.selectedDestinationState.value,
                      hint: const Text('Where is the package going?'),
                      items: controller.pricingRoutes.map((r) {
                        return DropdownMenuItem<String>(
                          value: r['destinationState'] as String,
                          child: Text(r['destinationState']),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          controller.selectedDestinationState.value = val;
                          controller.calculatePrice();
                        }
                      },
                    ),

                    const SizedBox(height: 20),

                    // Step 3: Sender Details
                    _buildSectionTitle('3. Sender Details', dark),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: controller.senderName,
                      decoration: _inputDecoration(dark, 'Sender Name'),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: controller.senderPhone,
                      decoration: _inputDecoration(dark, 'Sender Phone'),
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: controller.senderAddress,
                      decoration: _inputDecoration(dark, 'Sender Address'),
                    ),

                    const SizedBox(height: 20),

                    // Step 4: Recipient Details
                    _buildSectionTitle('4. Recipient Details', dark),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: controller.recipientName,
                      decoration: _inputDecoration(dark, 'Recipient Name'),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: controller.recipientPhone,
                      decoration: _inputDecoration(dark, 'Recipient Phone'),
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: controller.recipientAddress,
                      decoration: _inputDecoration(dark, 'Recipient Address'),
                    ),

                    const SizedBox(height: 20),

                    // Step 5: Package Details
                    _buildSectionTitle('5. Package Details', dark),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: controller.itemDescription,
                      decoration: _inputDecoration(dark, 'Description (e.g., Box of clothes)'),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: controller.itemDeclaredWeight,
                            decoration: _inputDecoration(dark, 'Weight (kg)'),
                            keyboardType: TextInputType.number,
                            onChanged: (_) => controller.calculatePrice(),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: controller.itemDeclaredValue,
                            decoration: _inputDecoration(dark, 'Declared Value (₦)'),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(child: TextFormField(controller: controller.itemLength, decoration: _inputDecoration(dark, 'Length (cm)'), keyboardType: TextInputType.number)),
                        const SizedBox(width: 8),
                        Expanded(child: TextFormField(controller: controller.itemWidth, decoration: _inputDecoration(dark, 'Width (cm)'), keyboardType: TextInputType.number)),
                        const SizedBox(width: 8),
                        Expanded(child: TextFormField(controller: controller.itemHeight, decoration: _inputDecoration(dark, 'Height (cm)'), keyboardType: TextInputType.number)),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Step 6: Prohibited Items
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: dark ? TColors.darkerGrey : Colors.red.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Prohibited Items:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
                          const SizedBox(height: 8),
                          if (controller.prohibitedItems.isEmpty)
                            const Text('Loading list...')
                          else
                            ...controller.prohibitedItems.map((item) => Text('• $item', style: const TextStyle(fontSize: 12))),
                          
                          Row(
                            children: [
                              Checkbox(
                                value: controller.prohibitedItemsAcknowledged.value,
                                onChanged: controller.acknowledgeProhibitedItems,
                                activeColor: TColors.primary,
                              ),
                              const Expanded(
                                child: Text('I confirm my package does not contain any of these prohibited items.', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Price Estimate
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: TColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Estimated Price', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          Text(
                            '₦${controller.estimatedPrice.value.toStringAsFixed(2)}',
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: TColors.primary),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Continue button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          if (controller.validateForm()) {
                            onContinue();
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          backgroundColor: TColors.primary,
                        ),
                        child: const Text(
                          'Continue to Payment',
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
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, bool dark) {
    return Text(
      title,
      style: TextStyle(
        fontWeight: FontWeight.w600,
        fontSize: 16,
        color: dark ? TColors.white : TColors.black,
      ),
    );
  }

  InputDecoration _inputDecoration(bool dark, String label) {
    return InputDecoration(
      labelText: label,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      filled: true,
      fillColor: dark ? TColors.darkerGrey.withOpacity(0.3) : Colors.white,
    );
  }
}
