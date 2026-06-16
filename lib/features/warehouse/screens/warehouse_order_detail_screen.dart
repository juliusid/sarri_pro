import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sarri_ride/utils/constants/colors.dart';
import 'package:sarri_ride/utils/helpers/helper_functions.dart';
import 'package:sarri_ride/features/warehouse/screens/client_claim_screen.dart';
import 'package:sarri_ride/features/warehouse/screens/client_return_screen.dart';
import 'package:intl/intl.dart';

class WarehouseOrderDetailScreen extends StatelessWidget {
  final Map<String, dynamic> order;

  const WarehouseOrderDetailScreen({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    final dark = THelperFunctions.isDarkMode(context);
    final status = (order['status'] ?? 'pending').toLowerCase();
    final items = order['items'] as List<dynamic>? ?? [];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Order Details'),
        backgroundColor: dark ? TColors.dark : TColors.white,
        foregroundColor: dark ? TColors.white : TColors.black,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatusHeader(status),
            const SizedBox(height: 24),
            _buildSectionTitle('Tracking & Info'),
            _buildInfoCard(dark, [
              _buildInfoRow('Shipment ID', order['shipmentId'] ?? order['_id'] ?? 'N/A'),
              _buildInfoRow('Date', _formatDate(order['createdAt'])),
              _buildInfoRow('Total Cost', '₦${order['totalCost'] ?? 0}'),
            ]),
            const SizedBox(height: 24),
            _buildSectionTitle('Recipient Details'),
            _buildInfoCard(dark, [
              _buildInfoRow('Name', order['recipientDetails']?['name'] ?? 'N/A'),
              _buildInfoRow('Phone', order['recipientDetails']?['phone'] ?? 'N/A'),
              _buildInfoRow('Address', order['recipientDetails']?['address'] ?? 'N/A'),
              _buildInfoRow('State', order['recipientDetails']?['state'] ?? 'N/A'),
            ]),
            const SizedBox(height: 24),
            _buildSectionTitle('Items (${items.length})'),
            ...items.map((item) => _buildItemCard(dark, item, status)).toList(),
            
            const SizedBox(height: 32),
            if (status == 'delivered') ...[
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Get.to(() => ClientReturnScreen(order: order)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: TColors.primary,
                    side: const BorderSide(color: TColors.primary),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('Request Return'),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Get.to(() => ClientClaimScreen(order: order)),
                  style: TextButton.styleFrom(foregroundColor: TColors.error),
                  child: const Text('Report Issue / File Claim'),
                ),
              ),
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildStatusHeader(String status) {
    Color color;
    IconData icon;
    switch (status) {
      case 'delivered':
        color = Colors.green;
        icon = Icons.check_circle;
        break;
      case 'in_transit':
        color = Colors.blue;
        icon = Icons.local_shipping;
        break;
      case 'cancelled':
      case 'returned':
        color = Colors.red;
        icon = Icons.cancel;
        break;
      default:
        color = Colors.orange;
        icon = Icons.hourglass_empty;
    }
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(width: 16),
          Text(
            status.toUpperCase(),
            style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildInfoCard(bool dark, List<Widget> children) {
    return Card(
      color: dark ? TColors.darkerGrey : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(children: children),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 100, child: Text(label, style: const TextStyle(color: Colors.grey))),
          Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }

  Widget _buildItemCard(bool dark, Map<String, dynamic> item, String orderStatus) {
    final itemStatus = item['status'] ?? orderStatus;
    return Card(
      color: dark ? TColors.darkerGrey : Colors.white,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(child: Text(item['description'] ?? 'Item', style: const TextStyle(fontWeight: FontWeight.bold))),
                Text(itemStatus.toUpperCase(), style: const TextStyle(fontSize: 12, color: Colors.blue)),
              ],
            ),
            const SizedBox(height: 8),
            Text('Weight: ${item['declaredWeight']} kg', style: const TextStyle(fontSize: 14)),
            Text('Value: ₦${item['declaredValue']}', style: const TextStyle(fontSize: 14)),
          ],
        ),
      ),
    );
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return 'N/A';
    final date = DateTime.tryParse(dateStr);
    if (date == null) return 'N/A';
    return DateFormat.yMMMd().add_jm().format(date);
  }
}
