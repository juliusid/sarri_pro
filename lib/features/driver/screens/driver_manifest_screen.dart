import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sarri_ride/utils/constants/colors.dart';
import 'package:sarri_ride/utils/helpers/helper_functions.dart';
import 'package:sarri_ride/features/driver/controllers/driver_manifest_controller.dart';
import 'package:sarri_ride/features/driver/screens/driver_qr_scanner_screen.dart';

class DriverManifestScreen extends StatelessWidget {
  const DriverManifestScreen({super.key});

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
            icon: const Icon(Icons.qr_code_scanner),
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
                const Text('No assigned batches yet.', style: TextStyle(fontSize: 16)),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: controller.batches.length,
          itemBuilder: (context, index) {
            final batch = controller.batches[index];
            final route = batch['route'] ?? {};
            return Card(
              color: dark ? TColors.darkerGrey : Colors.white,
              margin: const EdgeInsets.only(bottom: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Batch #${batch['batchNumber'] ?? 'Unknown'}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        _buildStatusBadge(batch['status'] ?? 'pending'),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text('From: ${route['originWarehouse']?['city'] ?? 'Unknown'}', style: const TextStyle(fontSize: 14)),
                    const SizedBox(height: 4),
                    Text('To: ${route['destinationWarehouse']?['city'] ?? 'Unknown'}', style: const TextStyle(fontSize: 14)),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('${batch['itemCount'] ?? 0} items', style: TextStyle(color: TColors.primary, fontWeight: FontWeight.bold)),
                        ElevatedButton(
                          onPressed: () {
                            Get.to(() => DriverQrScannerScreen(batchId: batch['_id']));
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: TColors.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: const Text('Scan & Update'),
                        ),
                      ],
                    ),
                  ],
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
    switch (status) {
      case 'in_transit':
        bgColor = Colors.blue;
        break;
      case 'arrived_destination':
        bgColor = Colors.orange;
        break;
      case 'completed':
        bgColor = Colors.green;
        break;
      default:
        bgColor = Colors.grey;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(8)),
      child: Text(status.toUpperCase(), style: TextStyle(color: textColor, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }
}
