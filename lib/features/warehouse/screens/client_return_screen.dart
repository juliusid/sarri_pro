import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sarri_ride/core/services/http_service.dart';
import 'package:sarri_ride/utils/constants/colors.dart';
import 'package:sarri_ride/utils/helpers/helper_functions.dart';

class ClientReturnScreen extends StatefulWidget {
  final Map<String, dynamic> order;

  const ClientReturnScreen({super.key, required this.order});

  @override
  State<ClientReturnScreen> createState() => _ClientReturnScreenState();
}

class _ClientReturnScreenState extends State<ClientReturnScreen> {
  final HttpService _httpService = HttpService.instance;
  final TextEditingController _reasonController = TextEditingController();
  
  String _selectedReason = 'Defective Item';
  bool _isLoading = false;
  
  final List<String> _returnReasons = [
    'Defective Item',
    'Wrong Item Received',
    'Changed Mind',
    'Arrived Too Late',
    'Other'
  ];

  Future<void> _submitReturn() async {
    if (_reasonController.text.isEmpty) {
      THelperFunctions.showErrorSnackBar('Error', 'Please provide details for your return request.');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final shipmentId = widget.order['shipmentId'] ?? widget.order['_id'];
      final response = await _httpService.post(
        '/api/warehouse/returns',
        body: {
          'shipmentId': shipmentId,
          'reason': _selectedReason,
          'details': _reasonController.text,
        },
      );
      final data = _httpService.handleResponse(response);
      
      if (data['status'] == 'success') {
        THelperFunctions.showSuccessSnackBar('Return Requested', 'Your return request has been submitted.');
        Get.back();
      }
    } catch (e) {
      THelperFunctions.showErrorSnackBar('Error', 'Failed to submit return request.');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Request Return')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: TColors.warning.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: TColors.warning),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: TColors.warning),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Returns must be requested within 3 days of delivery. Additional shipping fees may apply.',
                      style: TextStyle(color: TColors.warning),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text('Reason for Return', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(border: Border.all(color: Colors.grey), borderRadius: BorderRadius.circular(12)),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedReason,
                  isExpanded: true,
                  items: _returnReasons.map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
                  onChanged: (val) => setState(() => _selectedReason = val!),
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text('Additional Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),
            TextField(
              controller: _reasonController,
              maxLines: 5,
              decoration: InputDecoration(
                hintText: 'Please describe why you are returning this item...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submitReturn,
                style: ElevatedButton.styleFrom(
                  backgroundColor: TColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('Submit Return Request'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
