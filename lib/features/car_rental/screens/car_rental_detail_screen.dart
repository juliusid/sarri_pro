import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sarri_ride/utils/constants/colors.dart';
import 'package:sarri_ride/utils/helpers/helper_functions.dart';
import 'package:sarri_ride/features/car_rental/controllers/car_rental_booking_controller.dart';

class CarRentalDetailScreen extends StatelessWidget {
  const CarRentalDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final dark = THelperFunctions.isDarkMode(context);
    final controller = CarRentalBookingController.instance;

    return Scaffold(
      backgroundColor: dark ? const Color(0xFF1C1C1C) : Colors.white,
      body: Obx(() {
        final vehicle = controller.selectedVehicle.value;
        if (vehicle == null) {
          return const Center(child: Text('Vehicle not found'));
        }

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

        int savePercent = 0;
        if (hasDiscount) {
          final orig = double.parse(price);
          final disc = double.parse(discountedRaw);
          savePercent = (((orig - disc) / orig) * 100).round();
        }

        // Security deposit
        final depositObj = vehicle['securityDeposit'];
        final deposit = depositObj is Map && depositObj['\$numberDecimal'] != null
            ? depositObj['\$numberDecimal'].toString()
            : depositObj?.toString() ?? '0';

        final category = vehicle['category'].toString().capitalizeFirst ?? '';
        final hasImages = vehicle['images'] != null && vehicle['images'].isNotEmpty;
        final imageUrl = hasImages ? vehicle['images'][0] : null;

        return CustomScrollView(
          slivers: [
            // ── SliverAppBar with car image ────────────────────────────
            SliverAppBar(
              expandedHeight: 280,
              pinned: true,
              backgroundColor: dark ? const Color(0xFF1C1C1C) : Colors.white,
              elevation: 0,
              leading: Padding(
                padding: const EdgeInsets.all(8.0),
                child: GestureDetector(
                  onTap: () => Get.back(),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.4),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
                  ),
                ),
              ),
              flexibleSpace: FlexibleSpaceBar(
                background: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Car image or placeholder
                    if (imageUrl != null)
                      Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: dark ? const Color(0xFF242424) : Colors.grey[200],
                          child: const Center(
                            child: Icon(Icons.directions_car, size: 100, color: Colors.grey),
                          ),
                        ),
                      )
                    else
                      Container(
                        color: dark ? const Color(0xFF242424) : Colors.grey[200],
                        child: Center(
                          child: Icon(
                            Icons.directions_car,
                            size: 100,
                            color: dark ? Colors.grey[700] : Colors.grey[400],
                          ),
                        ),
                      ),

                    // Bottom gradient to blend into background
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      height: 100,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              dark ? const Color(0xFF1C1C1C) : Colors.white,
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Category pill badge (top-right, absolute)
                    Positioned(
                      top: 52,
                      right: 16,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: TColors.primary.withOpacity(0.85),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          category,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Content ────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Vehicle name
                    Text(
                      '${vehicle['make']} ${vehicle['model']} ${vehicle['year']}',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Location row
                    Row(
                      children: [
                        const Icon(Icons.location_on, color: Colors.grey, size: 16),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            '${vehicle['location']?['address'] ?? ''}, ${vehicle['location']?['city'] ?? ''}',
                            style: const TextStyle(color: Colors.grey, fontSize: 13),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // ── Pricing Card ─────────────────────────────────────
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: dark ? const Color(0xFF242424) : Colors.grey[100],
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Main price row
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '₦${hasDiscount ? discountedRaw : price}',
                                style: const TextStyle(
                                  fontSize: 30,
                                  fontWeight: FontWeight.bold,
                                  color: TColors.primary,
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Padding(
                                padding: EdgeInsets.only(bottom: 4),
                                child: Text(
                                  '/ day',
                                  style: TextStyle(color: Colors.grey, fontSize: 15),
                                ),
                              ),
                              if (hasDiscount) ...[
                                const SizedBox(width: 10),
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 4),
                                  child: Text(
                                    '₦$price',
                                    style: TextStyle(
                                      fontSize: 15,
                                      color: Colors.grey[500],
                                      decoration: TextDecoration.lineThrough,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: Colors.green.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    'Save $savePercent%',
                                    style: const TextStyle(
                                      color: Colors.green,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),

                          // Hourly rate
                          if (hourly != null) ...[
                            const SizedBox(height: 6),
                            Text(
                              'or ₦$hourly / hr',
                              style: TextStyle(color: Colors.grey[500], fontSize: 13),
                            ),
                          ],

                          Divider(
                            height: 28,
                            color: dark ? Colors.white12 : Colors.black12,
                          ),

                          // Security deposit row
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    'Security deposit',
                                    style: TextStyle(
                                      color: Colors.grey[500],
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Icon(
                                    Icons.info_outline,
                                    size: 14,
                                    color: Colors.grey[500],
                                  ),
                                ],
                              ),
                              Text(
                                '₦$deposit',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: dark ? Colors.white : Colors.black,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),

                    // Mode Toggle (commented out as requested)
                    /*
                    if (vehicle['rentalType'] == 'both') ...[
                      const Text('Rental Mode', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () => controller.rentalMode.value = 'self_drive',
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                decoration: BoxDecoration(
                                  color: controller.rentalMode.value == 'self_drive' ? TColors.primary : (dark ? const Color(0xFF242424) : Colors.grey[200]),
                                  borderRadius: const BorderRadius.horizontal(left: Radius.circular(8)),
                                ),
                                child: Center(
                                  child: Text('Self Drive', style: TextStyle(color: controller.rentalMode.value == 'self_drive' ? Colors.white : Colors.grey, fontWeight: FontWeight.bold)),
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: GestureDetector(
                              onTap: () => controller.rentalMode.value = 'chauffeur',
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                decoration: BoxDecoration(
                                  color: controller.rentalMode.value == 'chauffeur' ? TColors.primary : (dark ? const Color(0xFF242424) : Colors.grey[200]),
                                  borderRadius: const BorderRadius.horizontal(right: Radius.circular(8)),
                                ),
                                child: Center(
                                  child: Text('Chauffeur', style: TextStyle(color: controller.rentalMode.value == 'chauffeur' ? Colors.white : Colors.grey, fontWeight: FontWeight.bold)),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                    ],
                    */

                    // ── Select Dates ─────────────────────────────────────
                    const Text(
                      'Select dates',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),

                    Obx(() => Row(
                      children: [
                        Expanded(
                          child: _buildDateTimePicker(
                            context,
                            'Pickup',
                            controller.pickupDate.value,
                            controller.pickupTime.value,
                            () async {
                              final d = await showDatePicker(
                                context: context,
                                initialDate: DateTime.now(),
                                firstDate: DateTime.now(),
                                lastDate: DateTime.now().add(const Duration(days: 90)),
                              );
                              if (d != null) controller.setDates(d, controller.returnDate.value);
                            },
                            () async {
                              final t = await showTimePicker(
                                context: context,
                                initialTime: TimeOfDay.now(),
                              );
                              if (t != null) controller.setTimes(t, controller.returnTime.value);
                            },
                            dark,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: _buildDateTimePicker(
                            context,
                            'Return',
                            controller.returnDate.value,
                            controller.returnTime.value,
                            () async {
                              final first = controller.pickupDate.value ?? DateTime.now();
                              final d = await showDatePicker(
                                context: context,
                                initialDate: first,
                                firstDate: first,
                                lastDate: DateTime.now().add(const Duration(days: 90)),
                              );
                              if (d != null) controller.setDates(controller.pickupDate.value, d);
                            },
                            () async {
                              final t = await showTimePicker(
                                context: context,
                                initialTime: TimeOfDay.now(),
                              );
                              if (t != null) controller.setTimes(controller.pickupTime.value, t);
                            },
                            dark,
                          ),
                        ),
                      ],
                    )),

                    const SizedBox(height: 110), // spacing for bottom bar
                  ],
                ),
              ),
            ),
          ],
        );
      }),

      // ── Bottom bar ───────────────────────────────────────────────────
      bottomSheet: Obx(() {
        final estimatedPrice = controller.estimatedPrice.value;
        final hasPrice = estimatedPrice > 0;

        return Container(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
          decoration: BoxDecoration(
            color: dark ? const Color(0xFF242424) : Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 16,
                offset: const Offset(0, -4),
              ),
            ],
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: SafeArea(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Price info
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Total price',
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                    const SizedBox(height: 2),
                    hasPrice
                        ? Text(
                            '₦$estimatedPrice',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          )
                        : const Text(
                            'Pick a return date',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey,
                            ),
                          ),
                  ],
                ),

                // Book button
                GestureDetector(
                  onTap: hasPrice ? controller.proceedToConfirm : null,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                    decoration: BoxDecoration(
                      color: hasPrice ? TColors.primary : Colors.grey[700],
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      'Book this car',
                      style: TextStyle(
                        color: hasPrice ? Colors.white : Colors.white60,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildDateTimePicker(
    BuildContext context,
    String label,
    DateTime? date,
    TimeOfDay? time,
    VoidCallback onDateTap,
    VoidCallback onTimeTap,
    bool dark,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.grey,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),

        // Date row
        GestureDetector(
          onTap: onDateTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: dark ? const Color(0xFF2E2E2E) : Colors.grey[100],
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: dark ? Colors.white12 : Colors.black12,
                width: 1,
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_today, size: 15, color: TColors.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    date != null
                        ? '${date.day}/${date.month}/${date.year}'
                        : 'Select date',
                    style: TextStyle(
                      fontSize: 12,
                      color: date != null
                          ? (dark ? Colors.white : Colors.black)
                          : Colors.grey,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),

        // Time row
        GestureDetector(
          onTap: onTimeTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: dark ? const Color(0xFF2E2E2E) : Colors.grey[100],
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: dark ? Colors.white12 : Colors.black12,
                width: 1,
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.access_time, size: 15, color: TColors.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    time != null ? time.format(context) : 'Select time',
                    style: TextStyle(
                      fontSize: 12,
                      color: time != null
                          ? (dark ? Colors.white : Colors.black)
                          : Colors.grey,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
