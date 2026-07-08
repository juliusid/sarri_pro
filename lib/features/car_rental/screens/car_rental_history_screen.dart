import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sarri_ride/utils/constants/colors.dart';
import 'package:sarri_ride/utils/helpers/helper_functions.dart';
import 'package:sarri_ride/features/car_rental/controllers/car_rental_history_controller.dart';

class CarRentalHistoryScreen extends StatelessWidget {
  const CarRentalHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final dark = THelperFunctions.isDarkMode(context);
    final controller = Get.put(CarRentalHistoryController());

    return Scaffold(
      backgroundColor: dark ? TColors.dark : Colors.white,
      appBar: AppBar(
        title: const Text('My Rentals', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Text('Track your active and past bookings', style: TextStyle(color: Colors.grey)),
          ),
          
          // Tabs
          SizedBox(
            height: 40,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 24),
              itemCount: controller.tabs.length,
              itemBuilder: (context, index) {
                final tab = controller.tabs[index];
                return Obx(() {
                  final isSelected = controller.selectedTab.value == tab;
                  return GestureDetector(
                    onTap: () => controller.selectTab(tab),
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.transparent : (dark ? TColors.darkerGrey : Colors.grey[200]),
                        borderRadius: BorderRadius.circular(20),
                        border: isSelected ? Border.all(color: Colors.orange) : null,
                      ),
                      child: Center(
                        child: Text(
                          tab,
                          style: TextStyle(
                            color: isSelected ? Colors.orange : (dark ? Colors.white70 : Colors.black87),
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ),
                    ),
                  );
                });
              },
            ),
          ),
          const SizedBox(height: 16),

          // List
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return const Center(child: CircularProgressIndicator(color: Colors.orange));
              }
              if (controller.error.value.isNotEmpty) {
                return Center(child: Text(controller.error.value, style: const TextStyle(color: Colors.red)));
              }
              if (controller.filteredBookings.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.history, size: 64, color: dark ? TColors.darkerGrey : Colors.grey[300]),
                      const SizedBox(height: 16),
                      Text('No rentals found in this category.', style: TextStyle(color: dark ? TColors.lightGrey : Colors.grey)),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                itemCount: controller.filteredBookings.length,
                itemBuilder: (context, index) {
                  final booking = controller.filteredBookings[index];
                  final status = booking['status'].toString().toLowerCase();
                  
                  if (status == 'active') return _buildActiveCard(context, booking, dark);
                  if (status == 'pending' || status == 'confirmed') return _buildUpcomingCard(context, booking, dark);
                  if (status == 'cancelled') return _buildCancelledCard(context, booking, dark);
                  return _buildCompletedCard(context, booking, dark); // completed
                },
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveCard(BuildContext context, Map<String, dynamic> booking, bool dark) {
    final vehicle = booking['vehicleId'];
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0F3A3A), Color(0xFF0D252E)],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text('${vehicle['make']} ${vehicle['model']}', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: Colors.green.withOpacity(0.2), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.green)),
                child: const Text('Active Rental', style: TextStyle(color: Colors.green, fontSize: 10, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(Icons.calendar_today, size: 14, color: Colors.grey[400]),
              const SizedBox(width: 4),
              Text('Pickup: ${DateTime.parse(booking['pickupDateTime']).toLocal().toString().substring(0, 10)}', style: TextStyle(color: Colors.grey[400], fontSize: 12)),
              const Spacer(),
              Icon(Icons.calendar_today, size: 14, color: Colors.grey[400]),
              const SizedBox(width: 4),
              Text('Return: ${DateTime.parse(booking['returnDateTime']).toLocal().toString().substring(0, 10)}', style: TextStyle(color: Colors.grey[400], fontSize: 12)),
            ],
          ),
          const SizedBox(height: 16),
          // Fake progress bar
          const Text('In Progress', style: TextStyle(color: Colors.orange, fontSize: 12)),
          const SizedBox(height: 4),
          LinearProgressIndicator(value: 0.5, backgroundColor: Colors.white24, valueColor: const AlwaysStoppedAnimation<Color>(Colors.orange), borderRadius: BorderRadius.circular(2)),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {},
                  style: OutlinedButton.styleFrom(foregroundColor: Colors.white, side: const BorderSide(color: Colors.white54)),
                  child: const Text('Contact Driver'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton(
                  onPressed: () {},
                  style: OutlinedButton.styleFrom(foregroundColor: Colors.white, side: const BorderSide(color: Colors.white54)),
                  child: const Text('View Details'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUpcomingCard(BuildContext context, Map<String, dynamic> booking, bool dark) {
    final vehicle = booking['vehicleId'];
    final priceObj = booking['totalAmount'];
    final price = priceObj is Map ? double.tryParse(priceObj['\$numberDecimal'].toString()) ?? 0 : double.tryParse(priceObj?.toString() ?? '0') ?? 0;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: dark ? TColors.darkerGrey : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: dark ? Colors.white12 : Colors.black12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('${vehicle['make']} ${vehicle['model']}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: Colors.blue.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
                child: Text(booking['status'].toString().capitalizeFirst ?? '', style: const TextStyle(color: Colors.blue, fontSize: 10, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Pickup: ${DateTime.parse(booking['pickupDateTime']).toLocal().toString().substring(0, 10)}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
              Text('₦$price', style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          if (booking['status'] == 'pending') ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Get.find<CarRentalHistoryController>().cancelBooking(booking['_id']),
                child: const Text('Cancel Booking', style: TextStyle(color: Colors.red)),
              ),
            ),
          ]
        ],
      ),
    );
  }

  Widget _buildCompletedCard(BuildContext context, Map<String, dynamic> booking, bool dark) {
    final vehicle = booking['vehicleId'];
    final priceObj = booking['totalAmount'];
    final price = priceObj is Map ? double.tryParse(priceObj['\$numberDecimal'].toString()) ?? 0 : double.tryParse(priceObj?.toString() ?? '0') ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: dark ? TColors.darkerGrey.withOpacity(0.5) : Colors.grey[100],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('${vehicle['make']} ${vehicle['model']}', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: dark ? Colors.white70 : Colors.black54)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: Colors.grey.withOpacity(0.2), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey)),
                child: const Text('Completed', style: TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text('${DateTime.parse(booking['pickupDateTime']).toLocal().toString().substring(0, 10)} - ${DateTime.parse(booking['returnDateTime']).toLocal().toString().substring(0, 10)}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('₦$price', style: TextStyle(fontWeight: FontWeight.bold, color: dark ? Colors.white70 : Colors.black54)),
              OutlinedButton(onPressed: () {}, style: OutlinedButton.styleFrom(foregroundColor: Colors.grey), child: const Text('Book Again')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCancelledCard(BuildContext context, Map<String, dynamic> booking, bool dark) {
    final vehicle = booking['vehicleId'];
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(border: Border.all(color: Colors.red), borderRadius: BorderRadius.circular(12)),
                child: const Text('Cancelled', style: TextStyle(color: Colors.red, fontSize: 10, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 8),
              Text('${vehicle['make']} ${vehicle['model']}', style: const TextStyle(fontSize: 14)),
            ],
          ),
          const Text('Refund: Computed', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
