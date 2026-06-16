import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sarri_ride/utils/constants/colors.dart';
import 'package:sarri_ride/utils/helpers/helper_functions.dart';
import 'package:sarri_ride/features/warehouse/controllers/warehouse_order_history_controller.dart';
import 'package:sarri_ride/features/warehouse/screens/warehouse_order_detail_screen.dart';
import 'package:intl/intl.dart';

class WarehouseOrderHistoryScreen extends StatelessWidget {
  const WarehouseOrderHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(WarehouseOrderHistoryController());
    final dark = THelperFunctions.isDarkMode(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Warehouse Orders'),
        backgroundColor: dark ? TColors.dark : TColors.white,
        foregroundColor: dark ? TColors.white : TColors.black,
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.orders.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.history, size: 64, color: TColors.darkerGrey.withOpacity(0.5)),
                const SizedBox(height: 16),
                const Text('No warehouse orders found.', style: TextStyle(fontSize: 16)),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: controller.orders.length,
          itemBuilder: (context, index) {
            final order = controller.orders[index];
            final date = DateTime.tryParse(order['createdAt'] ?? '');
            final formattedDate = date != null ? DateFormat.yMMMd().format(date) : 'Unknown Date';
            
            return Card(
              color: dark ? TColors.darkerGrey : Colors.white,
              margin: const EdgeInsets.only(bottom: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: InkWell(
                onTap: () => Get.to(() => WarehouseOrderDetailScreen(order: order)),
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              'ID: ${order['shipmentId'] ?? order['_id']}',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          _buildStatusBadge(order['status'] ?? 'pending'),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Icon(Icons.date_range, size: 16, color: Colors.grey),
                          const SizedBox(width: 8),
                          Text(formattedDate, style: const TextStyle(fontSize: 14)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.location_on, size: 16, color: Colors.grey),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'To: ${order['recipientDetails']?['state'] ?? 'Unknown State'}',
                              style: const TextStyle(fontSize: 14),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '₦${(order['totalCost'] ?? 0).toString()}',
                            style: TextStyle(color: TColors.primary, fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          const Text('View Details', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      }),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color bgColor;
    Color textColor = Colors.white;
    switch (status.toLowerCase()) {
      case 'in_transit':
        bgColor = Colors.blue;
        break;
      case 'delivered':
        bgColor = Colors.green;
        break;
      case 'cancelled':
      case 'returned':
        bgColor = Colors.red;
        break;
      default:
        bgColor = Colors.orange;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(8)),
      child: Text(status.toUpperCase(), style: TextStyle(color: textColor, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }
}
