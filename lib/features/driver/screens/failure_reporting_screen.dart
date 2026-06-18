import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sarri_ride/utils/constants/colors.dart';
import 'package:sarri_ride/utils/helpers/helper_functions.dart';
import 'package:sarri_ride/features/driver/controllers/driver_manifest_controller.dart';

class FailureReportingScreen extends StatefulWidget {
  final String shipmentId;
  final int itemIndex;

  const FailureReportingScreen({
    super.key,
    required this.shipmentId,
    required this.itemIndex,
  });

  @override
  State<FailureReportingScreen> createState() => _FailureReportingScreenState();
}

class _FailureReportingScreenState extends State<FailureReportingScreen> {
  String _selectedReason = 'Recipient not home';
  final TextEditingController _notesController = TextEditingController();
  bool _isLoading = false;

  final List<String> _reasons = [
    'Recipient not home',
    'Incorrect address / Unreachable location',
    'Recipient refused package',
    'Package physically damaged',
    'Recipient refused to pay top-up charge',
    'Other / Custom reason',
  ];

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submitReport() async {
    setState(() => _isLoading = true);
    try {
      String fullReason = _selectedReason;
      if (_notesController.text.trim().isNotEmpty) {
        fullReason = '$fullReason: ${_notesController.text.trim()}';
      }

      final controller = Get.find<DriverManifestController>();
      final success = await controller.reportFailure(
        shipmentId: widget.shipmentId,
        itemIndex: widget.itemIndex,
        reason: fullReason,
      );
      
      if (success) {
        Get.until((route) => route.isFirst); // Go back to manifest/dashboard root
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dark = THelperFunctions.isDarkMode(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Report Delivery Issue'),
        backgroundColor: dark ? TColors.dark : TColors.white,
        foregroundColor: dark ? TColors.white : TColors.black,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Reason for Failure',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 12),
            ..._reasons.map((reason) => RadioListTile<String>(
              title: Text(
                reason,
                style: const TextStyle(fontSize: 14),
              ),
              value: reason,
              groupValue: _selectedReason,
              onChanged: (val) {
                if (val != null) {
                  setState(() => _selectedReason = val);
                }
              },
              activeColor: TColors.primary,
              contentPadding: EdgeInsets.zero,
            )),
            const SizedBox(height: 24),
            const Text(
              'Additional Notes (Optional)',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _notesController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Provide additional details or custom failure reason here...',
                hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submitReport,
                style: ElevatedButton.styleFrom(
                  backgroundColor: TColors.error,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Text(
                        'Submit Report',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

