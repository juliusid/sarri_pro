import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sarri_ride/utils/constants/colors.dart';
import 'package:sarri_ride/utils/helpers/helper_functions.dart';
import 'package:sarri_ride/features/car_rental/controllers/car_rental_booking_controller.dart';

class CarRentalBookingWidget extends StatelessWidget {
  final VoidCallback onBackPressed;

  const CarRentalBookingWidget({
    super.key,
    required this.onBackPressed,
  });

  @override
  Widget build(BuildContext context) {
    final dark = THelperFunctions.isDarkMode(context);
    final controller = Get.put(CarRentalBookingController());

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(top: 16),
      decoration: BoxDecoration(
        color: dark ? const Color(0xFF1C1C1C) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                GestureDetector(
                  onTap: onBackPressed,
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: dark ? const Color(0xFF242424) : Colors.grey[100],
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.arrow_back,
                      size: 18,
                      color: dark ? Colors.white : Colors.black,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Text(
                  'Rent a Car',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () {
                    Get.snackbar(
                      'Search',
                      'Search feature coming soon!',
                      snackPosition: SnackPosition.BOTTOM,
                    );
                  },
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: dark ? const Color(0xFF242424) : Colors.grey[100],
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.search,
                      size: 18,
                      color: dark ? Colors.white : Colors.black,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Vehicle List
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return const Center(
                  child: CircularProgressIndicator(color: TColors.primary),
                );
              }

              if (controller.error.value.isNotEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
                      const SizedBox(height: 16),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Text(
                          controller.error.value,
                          style: const TextStyle(color: Colors.red),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: controller.fetchVehicles,
                        child: const Text(
                          'Retry',
                          style: TextStyle(color: TColors.primary, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                );
              }

              if (controller.filteredVehicles.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: dark ? const Color(0xFF242424) : Colors.grey[100],
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 72,
                            height: 72,
                            decoration: BoxDecoration(
                              color: TColors.primary.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.house_outlined,
                              size: 36,
                              color: TColors.primary,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No Vehicles Available',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'More cars joining soon',
                            style: TextStyle(
                              color: dark ? Colors.grey[400] : Colors.grey[600],
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                itemCount: controller.filteredVehicles.length,
                itemBuilder: (context, index) {
                  final vehicle = controller.filteredVehicles[index];

                  // Daily rate
                  final priceObj = vehicle['dailyRate'];
                  final price = priceObj is Map && priceObj['\$numberDecimal'] != null
                      ? priceObj['\$numberDecimal'].toString()
                      : priceObj.toString();

                  // Hourly rate
                  final hourlyObj = vehicle['hourlyRate'];
                  final hourly = hourlyObj is Map && hourlyObj['\$numberDecimal'] != null
                      ? hourlyObj['\$numberDecimal'].toString()
                      : hourlyObj?.toString();

                  // Discounted rate
                  final discountedObj = vehicle['discountedRate'];
                  final discountedRaw = discountedObj is Map && discountedObj['\$numberDecimal'] != null
                      ? discountedObj['\$numberDecimal'].toString()
                      : discountedObj?.toString();
                  final hasDiscount = discountedRaw != null &&
                      double.tryParse(discountedRaw) != null &&
                      double.parse(discountedRaw) > 0 &&
                      double.parse(discountedRaw) < double.parse(price);

                  // Save percentage
                  int savePercent = 0;
                  if (hasDiscount) {
                    final orig = double.parse(price);
                    final disc = double.parse(discountedRaw!);
                    savePercent = (((orig - disc) / orig) * 100).round();
                  }

                  final category = vehicle['category'].toString();
                  final hasImages = vehicle['images'] != null && vehicle['images'].isNotEmpty;
                  final imageUrl = hasImages ? vehicle['images'][0] : null;

                  return GestureDetector(
                    onTap: () => controller.proceedToDetail(vehicle['_id']),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 18),
                      decoration: BoxDecoration(
                        color: dark ? const Color(0xFF242424) : Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(dark ? 0.3 : 0.08),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ── Image area ─────────────────────────────────
                          ClipRRect(
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                            child: Stack(
                              children: [
                                // Image or placeholder
                                Container(
                                  width: double.infinity,
                                  height: 170,
                                  color: dark ? const Color(0xFF1C1C1C) : Colors.grey[100],
                                  child: imageUrl != null
                                      ? Image.network(
                                          imageUrl,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) => const Center(
                                            child: Icon(
                                              Icons.directions_car,
                                              size: 60,
                                              color: Colors.grey,
                                            ),
                                          ),
                                        )
                                      : Center(
                                          child: Icon(
                                            Icons.directions_car,
                                            size: 60,
                                            color: dark ? Colors.grey[700] : Colors.grey[400],
                                          ),
                                        ),
                                ),
                                // Category badge (top-left)
                                Positioned(
                                  top: 12,
                                  left: 12,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.55),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      category.capitalizeFirst ?? category,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: 0.3,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // ── Details section ────────────────────────────
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Vehicle name
                                Text(
                                  '${vehicle['make']} ${vehicle['model']}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 8),

                                // Pricing row
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    // Main price (discounted if available, else daily)
                                    Text(
                                      '₦${hasDiscount ? discountedRaw : price}/day',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 17,
                                        color: TColors.primary,
                                      ),
                                    ),
                                    if (hasDiscount) ...[
                                      const SizedBox(width: 8),
                                      Text(
                                        '₦$price',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Colors.grey[500],
                                          decoration: TextDecoration.lineThrough,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Colors.green.withOpacity(0.15),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          'Save $savePercent%',
                                          style: const TextStyle(
                                            color: Colors.green,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),

                                // Hourly rate
                                if (hourly != null) ...[
                                  const SizedBox(height: 3),
                                  Text(
                                    'or ₦$hourly/hr',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[500],
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 12),

                                // Available badge + Book Now button
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    // Available pill
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                      decoration: BoxDecoration(
                                        color: Colors.green.withOpacity(0.12),
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                          color: Colors.green.withOpacity(0.4),
                                          width: 1,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Container(
                                            width: 6,
                                            height: 6,
                                            decoration: const BoxDecoration(
                                              color: Colors.green,
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                          const SizedBox(width: 5),
                                          const Text(
                                            'Available',
                                            style: TextStyle(
                                              color: Colors.green,
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                    // Book Now button
                                    GestureDetector(
                                      onTap: () => controller.proceedToDetail(vehicle['_id']),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                                        decoration: BoxDecoration(
                                          color: TColors.primary,
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: const Text(
                                          'Book now',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            }),
          ),
        ],
      ),
    );
  }
}
