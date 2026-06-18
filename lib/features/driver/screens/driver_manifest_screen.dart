import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sarri_ride/utils/constants/colors.dart';
import 'package:sarri_ride/utils/helpers/helper_functions.dart';
import 'package:sarri_ride/features/driver/controllers/driver_manifest_controller.dart';
import 'package:sarri_ride/features/driver/screens/driver_qr_scanner_screen.dart';
import 'package:sarri_ride/features/driver/screens/failure_reporting_screen.dart';

class DriverManifestScreen extends StatelessWidget {
  const DriverManifestScreen({super.key});

  String _formatDate(String dateStr) {
    try {
      final dt = DateTime.parse(dateStr);
      final months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
      final weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      return '${weekdays[dt.weekday - 1]}, ${dt.day} ${months[dt.month - 1]} ${dt.year}';
    } catch (e) {
      return dateStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(DriverManifestController());
    final dark = THelperFunctions.isDarkMode(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Delivery Manifest'),
        backgroundColor: dark ? TColors.dark : TColors.white,
        foregroundColor: dark ? TColors.white : TColors.black,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => controller.fetchManifest(),
          ),
          IconButton(
            icon: const Icon(Icons.qr_code_scanner),
            tooltip: 'General Scan',
            onPressed: () => Get.to(() => const DriverQrScannerScreen()),
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.batches.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.inbox, size: 64, color: TColors.darkerGrey.withOpacity(0.5)),
                const SizedBox(height: 16),
                const Text('No active assignments or delivery manifest found.', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => controller.fetchManifest(),
                  child: const Text('Refresh Manifest'),
                )
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () => controller.fetchManifest(),
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: controller.batches.length,
            itemBuilder: (context, index) {
              final batch = controller.batches[index];
              final String batchId = batch['batchId'] ?? '';
              final String schedDateStr = batch['scheduledDate'] ?? '';
              final List<dynamic> assignedStates = batch['assignedStates'] ?? [];
              final List<dynamic> items = batch['items'] ?? [];

              return Container(
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(
                  color: dark ? TColors.darkerGrey : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    )
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Batch Header Card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: dark ? TColors.darkGrey : Colors.grey[100],
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(16),
                          topRight: Radius.circular(16),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Dispatch Saturday',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: dark ? Colors.grey[400] : Colors.grey[600],
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: TColors.primary.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '${items.length} Packages',
                                  style: TextStyle(
                                    color: TColors.primary,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _formatDate(schedDateStr),
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: assignedStates.map((state) {
                              return Chip(
                                labelPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: -4),
                                label: Text(
                                  state.toString(),
                                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                                ),
                                backgroundColor: dark ? Colors.grey[800] : Colors.grey[200],
                              );
                            }).toList(),
                          )
                        ],
                      ),
                    ),

                    // Items List
                    if (items.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(24.0),
                        child: Center(
                          child: Text(
                            'No items in transit in this batch.',
                            style: TextStyle(fontStyle: FontStyle.italic, fontSize: 13),
                          ),
                        ),
                      )
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: items.length,
                        separatorBuilder: (context, idx) => Divider(
                          height: 1,
                          color: dark ? Colors.grey[800] : Colors.grey[200],
                        ),
                        itemBuilder: (context, itemIdx) {
                          final item = items[itemIdx];
                          final String shipmentId = item['shipmentId'] ?? '';
                          final int itemIndex = item['itemIndex'] ?? 0;
                          final String desc = item['description'] ?? 'Package';
                          final double weight = (item['declaredWeight'] as num?)?.toDouble() ?? 0.0;
                          final String recipientName = item['recipientName'] ?? 'Recipient';
                          final String recipientPhone = item['recipientPhone'] ?? '';
                          final String recipientAddress = item['recipientAddress'] ?? '';
                          final String destState = item['destinationState'] ?? '';

                          return Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        desc,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    _buildStateBadge(destState),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Icon(Icons.person, size: 14, color: dark ? Colors.grey[400] : Colors.grey[600]),
                                    const SizedBox(width: 6),
                                    Text(
                                      '$recipientName ($recipientPhone)',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: dark ? Colors.grey[300] : Colors.grey[700],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Icon(Icons.location_on, size: 14, color: dark ? Colors.grey[400] : Colors.grey[600]),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        recipientAddress,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: dark ? Colors.grey[400] : Colors.grey[600],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    Icon(Icons.scale, size: 14, color: dark ? Colors.grey[400] : Colors.grey[600]),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Declared Weight: $weight kg',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: dark ? Colors.grey[400] : Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    Expanded(
                                      child: OutlinedButton.icon(
                                        onPressed: () {
                                          Get.to(() => FailureReportingScreen(
                                            shipmentId: shipmentId,
                                            itemIndex: itemIndex,
                                          ));
                                        },
                                        icon: const Icon(Icons.report_problem, size: 16),
                                        label: const Text('Failed Delivery'),
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: TColors.error,
                                          side: BorderSide(color: TColors.error.withOpacity(0.3)),
                                          padding: const EdgeInsets.symmetric(vertical: 12),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: ElevatedButton.icon(
                                        onPressed: () {
                                          Get.to(() => DriverQrScannerScreen(
                                            expectedShipmentId: shipmentId,
                                            expectedItemIndex: itemIndex,
                                          ));
                                        },
                                        icon: const Icon(Icons.qr_code_scanner, size: 16),
                                        label: const Text('Scan QR'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: TColors.primary,
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(vertical: 12),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                  ],
                ),
              );
            },
          ),
        );
      }),
    );
  }

  Widget _buildStateBadge(String stateName) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.blue[500]?.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        stateName.toUpperCase(),
        style: TextStyle(
          color: Colors.blue[600],
          fontSize: 9,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

