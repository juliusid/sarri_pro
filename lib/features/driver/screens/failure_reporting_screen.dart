import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sarri_ride/core/services/http_service.dart';
import 'package:sarri_ride/utils/constants/colors.dart';
import 'package:sarri_ride/utils/helpers/helper_functions.dart';

class FailureReportingScreen extends StatefulWidget {
  final String qrData;
  const FailureReportingScreen({super.key, required this.qrData});

  @override
  State<FailureReportingScreen> createState() => _FailureReportingScreenState();
}

class _FailureReportingScreenState extends State<FailureReportingScreen> {
  String _selectedReason = 'Recipient not available';
  final TextEditingController _notesController = TextEditingController();
  final HttpService _httpService = HttpService.instance;
  bool _isLoading = false;

  final List<String> _reasons = [
    'Recipient not available',
    'Incorrect address',
    'Recipient refused package',
    'Package damaged',
    'Other',
  ];

  Future<void> _submitReport() async {
    setState(() => _isLoading = true);
    try {
      final response = await _httpService.post(
        '/api/warehouse/delivery/report-failure',
        body: {
          'qrData': widget.qrData,
          'reason': _selectedReason,
          'notes': _notesController.text,
        },
      );
      final data = _httpService.handleResponse(response);
      
      if (data['status'] == 'success') {
        THelperFunctions.showSuccessSnackBar('Reported', 'Issue has been logged successfully.');
        Get.until((route) => route.isFirst); // Go back to dashboard
      }
    } catch (e) {
      THelperFunctions.showErrorSnackBar('Error', 'Failed to submit report.');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Report Delivery Issue')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Reason for Failure', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),
            ..._reasons.map((reason) => RadioListTile<String>(
              title: Text(reason),
              value: reason,
              groupValue: _selectedReason,
              onChanged: (val) => setState(() => _selectedReason = val!),
              activeColor: TColors.primary,
            )),
            const SizedBox(height: 24),
            const Text('Additional Notes (Optional)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),
            TextField(
              controller: _notesController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Provide more details...',
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
                ),
                child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('Submit Report'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
