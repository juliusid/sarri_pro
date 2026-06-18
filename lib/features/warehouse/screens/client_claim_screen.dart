import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sarri_ride/core/services/http_service.dart';
import 'package:sarri_ride/utils/constants/colors.dart';
import 'package:sarri_ride/utils/helpers/helper_functions.dart';

class ClientClaimScreen extends StatefulWidget {
  final String shipmentId;
  final int itemIndex;
  final Map<String, dynamic> item;

  const ClientClaimScreen({
    super.key,
    required this.shipmentId,
    required this.itemIndex,
    required this.item,
  });

  @override
  State<ClientClaimScreen> createState() => _ClientClaimScreenState();
}

class _ClientClaimScreenState extends State<ClientClaimScreen> {
  final HttpService _httpService = HttpService.instance;
  final TextEditingController _reasonController = TextEditingController();
  bool _isLoading = false;

  Future<void> _submitClaim() async {
    final reasonText = _reasonController.text.trim();
    if (reasonText.isEmpty) {
      THelperFunctions.showErrorSnackBar('Error', 'Please provide a detailed reason for your claim.');
      return;
    }
    if (reasonText.length > 500) {
      THelperFunctions.showErrorSnackBar('Error', 'Reason details cannot exceed 500 characters.');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final response = await _httpService.post(
        '/api/warehouse/orders/${widget.shipmentId}/items/${widget.itemIndex}/refund',
        body: {
          'reason': reasonText,
        },
      );
      final data = _httpService.handleResponse(response);
      
      if (data['status'] == 'success') {
        THelperFunctions.showSuccessSnackBar(
          'Claim Submitted',
          'Your claim has been submitted successfully and is under review.',
        );
        Get.back(result: true); // Return true to refresh details
      }
    } catch (e) {
      String errMsg = 'Failed to submit claim request.';
      if (e is ApiException) {
        errMsg = e.message;
      }
      THelperFunctions.showErrorSnackBar('Error', errMsg);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dark = THelperFunctions.isDarkMode(context);
    final itemDesc = widget.item['description'] ?? 'Item';
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('File a Claim'),
        backgroundColor: dark ? TColors.dark : TColors.white,
        foregroundColor: dark ? TColors.white : TColors.black,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Item: $itemDesc',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: TColors.primary),
            ),
            const SizedBox(height: 8),
            Text(
              'Declared Value: ₦${widget.item['declaredValue'] ?? 0}',
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 24),
            const Text(
              'Details & Evidence Description',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _reasonController,
              maxLines: 6,
              maxLength: 500, // Enforce 500 characters limit
              decoration: InputDecoration(
                hintText: 'Please describe the damage or loss in detail (max 500 characters)...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: TColors.primary),
                ),
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
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Submit Claim'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
