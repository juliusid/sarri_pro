import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sarri_ride/utils/constants/colors.dart';
import 'package:sarri_ride/utils/helpers/helper_functions.dart';
import 'package:sarri_ride/features/car_rental/controllers/car_rental_booking_controller.dart';
import 'package:sarri_ride/features/payment/controllers/payment_controller.dart';

class CarRentalConfirmScreen extends StatefulWidget {
  const CarRentalConfirmScreen({super.key});

  @override
  State<CarRentalConfirmScreen> createState() => _CarRentalConfirmScreenState();
}

class _CarRentalConfirmScreenState extends State<CarRentalConfirmScreen> {
  String _selectedCardId = '';

  @override
  void initState() {
    super.initState();
    // Fetch real cards on open
    final paymentController = Get.find<PaymentController>();
    paymentController.fetchSavedCards().then((_) {
      // Auto-select default or first card
      final cards = paymentController.savedCards;
      if (cards.isNotEmpty && _selectedCardId.isEmpty) {
        final defaultCard = cards.firstWhereOrNull((c) => c.isDefault) ?? cards.first;
        setState(() => _selectedCardId = defaultCard.cardId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final dark = THelperFunctions.isDarkMode(context);
    final controller = CarRentalBookingController.instance;
    final paymentController = Get.find<PaymentController>();

    final cardBg = dark ? const Color(0xFF242424) : Colors.grey[100]!;
    final pageBg = dark ? const Color(0xFF1C1C1C) : Colors.white;

    return Scaffold(
      backgroundColor: pageBg,
      appBar: AppBar(
        title: const Text('Confirm Booking', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        // Back button matching the reference image — white rounded square
        leading: Padding(
          padding: const EdgeInsets.all(10),
          child: GestureDetector(
            onTap: () => Get.back(),
            child: Container(
              decoration: BoxDecoration(
                color: dark ? const Color(0xFF2E2E2E) : Colors.white,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                Icons.arrow_back,
                size: 20,
                color: dark ? Colors.white : Colors.black,
              ),
            ),
          ),
        ),
      ),
      body: Obx(() {
        final vehicle = controller.selectedVehicle.value;
        if (vehicle == null) return const Center(child: Text('Error: No vehicle selected'));

        final basePrice = controller.estimatedPrice.value;
        final platformFee = basePrice * 0.10;

        final depositObj = vehicle['securityDeposit'];
        final deposit = depositObj is Map
            ? double.tryParse(depositObj['\$numberDecimal'].toString()) ?? 0
            : double.tryParse(depositObj?.toString() ?? '0') ?? 0;

        final total = basePrice + platformFee + deposit;

        final pickup = controller.pickupDate.value;
        final ret = controller.returnDate.value;
        String durationLabel = '';
        if (pickup != null && ret != null) {
          final days = ret.difference(pickup).inDays;
          durationLabel = days <= 1 ? '1 day' : '$days days';
        }

        final hasImage = vehicle['images'] != null && vehicle['images'].isNotEmpty;

        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // ── Vehicle summary card ────────────────────────────────
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(16)),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        width: 72,
                        height: 56,
                        color: dark ? const Color(0xFF2E2E2E) : Colors.grey[200],
                        child: hasImage
                            ? Image.network(vehicle['images'][0], fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => const Icon(Icons.directions_car, color: Colors.grey))
                            : const Icon(Icons.directions_car, color: Colors.grey, size: 32),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${vehicle['make']} ${vehicle['model']}',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: dark ? const Color(0xFF2E2E2E) : Colors.grey[300],
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              controller.rentalMode.value == 'chauffeur' ? 'Chauffeur driven' : 'Self drive',
                              style: TextStyle(fontSize: 11, color: dark ? Colors.white70 : Colors.black54),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // ── Pricing breakdown ───────────────────────────────────
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(16)),
                child: Column(
                  children: [
                    _buildPriceRow(
                      'Base rate${durationLabel.isNotEmpty ? ' ($durationLabel)' : ''}',
                      '₦${_fmt(basePrice)}', dark: dark),
                    const SizedBox(height: 14),
                    _buildPriceRow('Platform fee (10%)', '₦${_fmt(platformFee)}', dark: dark),
                    const SizedBox(height: 14),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Text('Security deposit', style: TextStyle(color: Colors.grey[500])),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text('Refundable',
                                  style: TextStyle(color: Colors.green, fontSize: 10, fontWeight: FontWeight.w600)),
                            ),
                          ],
                        ),
                        Text('₦${_fmt(deposit)}',
                            style: TextStyle(fontWeight: FontWeight.w500, color: dark ? Colors.white : Colors.black)),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Divider(color: dark ? Colors.white12 : Colors.black12, height: 1),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total payable', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                        Text('₦${_fmt(total)}',
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: TColors.primary)),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Includes a ₦${_fmt(deposit)} refundable deposit, released within 3 business days after the car is returned.',
                      style: TextStyle(color: Colors.grey[500], fontSize: 11, height: 1.5),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // ── Cancellation policy ─────────────────────────────────
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(16)),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: TColors.primary.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.shield_outlined, color: TColors.primary, size: 20),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Cancellation policy',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          const SizedBox(height: 6),
                          Text(
                            'Free cancellation up to 48 hours before pickup. 50% refund 24–48 hours before. No refund within 24 hours.',
                            style: TextStyle(color: Colors.grey[500], fontSize: 12, height: 1.5),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // ── Pay with ────────────────────────────────────────────
              const Text('Pay with', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 14),

              Obx(() {
                if (paymentController.isLoading.value) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: CircularProgressIndicator(color: TColors.primary, strokeWidth: 2),
                    ),
                  );
                }

                final cards = paymentController.savedCards;

                if (cards.isEmpty) {
                  // No cards saved — prompt to add one
                  return GestureDetector(
                    onTap: () => Get.toNamed('/payment-methods'),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: TColors.primary.withOpacity(0.4), width: 1.5),
                      ),
                      child: Column(
                        children: [
                          Icon(Icons.add_card_outlined, color: TColors.primary, size: 32),
                          const SizedBox(height: 10),
                          const Text('No saved cards',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                          const SizedBox(height: 4),
                          Text('Tap to add a payment card in the app',
                              style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                        ],
                      ),
                    ),
                  );
                }

                // Show real saved cards
                return Column(
                  children: cards.map((card) {
                    final isSelected = _selectedCardId == card.cardId;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedCardId = card.cardId),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        decoration: BoxDecoration(
                          color: isSelected ? TColors.primary.withOpacity(0.08) : cardBg,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected ? TColors.primary : Colors.transparent,
                            width: 1.5,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? TColors.primary.withOpacity(0.12)
                                    : (dark ? const Color(0xFF2E2E2E) : Colors.grey[200]),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(Icons.credit_card,
                                  color: isSelected ? TColors.primary : Colors.grey, size: 22),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(card.displayName,
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                        color: isSelected
                                            ? TColors.primary
                                            : (dark ? Colors.white : Colors.black87),
                                      )),
                                  const SizedBox(height: 2),
                                  Text(card.displayDetails,
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: isSelected
                                            ? TColors.primary.withOpacity(0.7)
                                            : Colors.grey[500],
                                      )),
                                ],
                              ),
                            ),
                            if (card.isDefault)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: TColors.primary.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text('Default',
                                    style: TextStyle(
                                        color: TColors.primary, fontSize: 10, fontWeight: FontWeight.w600)),
                              ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                );
              }),

              // Error
              if (controller.error.value.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Text(controller.error.value,
                      style: const TextStyle(color: Colors.red, fontSize: 13)),
                ),
            ],
          ),
        );
      }),

      // ── Bottom CTA ─────────────────────────────────────────────────
      bottomSheet: Obx(() {
        final vehicle = controller.selectedVehicle.value;
        if (vehicle == null) return const SizedBox.shrink();

        final basePrice = controller.estimatedPrice.value;
        final platformFee = basePrice * 0.10;
        final depositObj = vehicle['securityDeposit'];
        final deposit = depositObj is Map
            ? double.tryParse(depositObj['\$numberDecimal'].toString()) ?? 0
            : double.tryParse(depositObj?.toString() ?? '0') ?? 0;
        final total = basePrice + platformFee + deposit;

        return Container(
          color: dark ? const Color(0xFF1C1C1C) : Colors.white,
          padding: EdgeInsets.only(
            left: 20, right: 20, top: 12,
            bottom: MediaQuery.of(context).padding.bottom + 12,
          ),
          child: SizedBox(
            width: double.infinity,
            height: 56,
            child: GestureDetector(
              onTap: controller.isSubmitting.value ? null : () => controller.submitBooking(_selectedCardId),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  color: controller.isSubmitting.value
                      ? (dark ? const Color(0xFF2E2E2E) : Colors.grey[300])
                      : TColors.primary,
                  borderRadius: BorderRadius.circular(28),
                ),
                child: Center(
                  child: controller.isSubmitting.value
                      ? Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const SizedBox(
                              width: 18, height: 18,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            ),
                            const SizedBox(width: 12),
                            Text('Processing · ₦${_fmt(total)}',
                                style: const TextStyle(
                                    color: Colors.white70, fontSize: 16, fontWeight: FontWeight.w600)),
                          ],
                        )
                      : Text('Pay ₦${_fmt(total)}',
                          style: const TextStyle(
                              color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold)),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }

  String _fmt(double v) {
    if (v == v.truncateToDouble()) return v.toInt().toString();
    return v.toStringAsFixed(2);
  }

  Widget _buildPriceRow(String label, String value, {required bool dark}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: Colors.grey[500])),
        Text(value,
            style: TextStyle(fontWeight: FontWeight.w500, color: dark ? Colors.white : Colors.black)),
      ],
    );
  }
}
