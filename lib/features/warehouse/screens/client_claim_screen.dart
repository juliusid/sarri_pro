import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sarri_ride/core/services/http_service.dart';
import 'package:sarri_ride/utils/constants/colors.dart';
import 'package:sarri_ride/utils/helpers/helper_functions.dart';

class ClientClaimScreen extends StatefulWidget {
  final Map<String, dynamic> order;

  const ClientClaimScreen({super.key, required this.order});

  @override
  State<ClientClaimScreen> createState() => _ClientClaimScreenState();
}

class _ClientClaimScreenState extends State<ClientClaimScreen> {
  final HttpService _httpService = HttpService.instance;
  final TextEditingController _reasonController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  
  String _selectedReason = 'Damaged Item';
  bool _isLoading = false;
  
  final List<String> _claimReasons = [
    'Damaged Item',
    'Missing Item',
    'Wrong Item Delivered',
    'Delayed Delivery',
    'Other'
  ];

  Future<void> _submitClaim() async {
    if (_reasonController.text.isEmpty) {
      THelperFunctions.showErrorSnackBar('Error', 'Please provide details for your claim.');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final shipmentId = widget.order['shipmentId'] ?? widget.order['_id'];
      final response = await _httpService.post(
        '/api/warehouse/claims',
        body: {
          'shipmentId': shipmentId,
          'reason': _selectedReason,
          'details': _reasonController.text,
          'requestedAmount': double.tryParse(_amountController.text) ?? 0.0,
        },
      );
      final data = _httpService.handleResponse(response);
      
      if (data['status'] == 'success') {
        THelperFunctions.showSuccessSnackBar('Claim Submitted', 'Your claim has been filed successfully.');
        Get.back();
      }
    } catch (e) {
      THelperFunctions.showErrorSnackBar('Error', 'Failed to submit claim.');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('File a Claim')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Reason for Claim', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(border: Border.all(color: Colors.grey), borderRadius: BorderRadius.circular(12)),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedReason,
                  isExpanded: true,
                  items: _claimReasons.map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
                  onChanged: (val) => setState(() => _selectedReason = val!),
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text('Requested Compensation (₦)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: 'e.g. 5000',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 24),
            const Text('Details & Evidence Description', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),
            TextField(
              controller: _reasonController,
              maxLines: 5,
              decoration: InputDecoration(
                hintText: 'Please describe the issue in detail...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submitClaim,
                style: ElevatedButton.styleFrom(
                  backgroundColor: TColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('Submit Claim'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
