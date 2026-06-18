import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:sarri_ride/core/services/http_service.dart';
import 'package:sarri_ride/utils/constants/colors.dart';
import 'package:sarri_ride/utils/helpers/helper_functions.dart';
import 'package:sarri_ride/features/payment/screens/paystack_webview_screen.dart';

class ClientReturnScreen extends StatefulWidget {
  final String shipmentId;
  final int itemIndex;
  final Map<String, dynamic> item;

  const ClientReturnScreen({
    super.key,
    required this.shipmentId,
    required this.itemIndex,
    required this.item,
  });

  @override
  State<ClientReturnScreen> createState() => _ClientReturnScreenState();
}

class _ClientReturnScreenState extends State<ClientReturnScreen> {
  final HttpService _httpService = HttpService.instance;
  bool _isLoading = false;

  Future<void> _initiateReturnPayment() async {
    setState(() => _isLoading = true);
    try {
      final response = await _httpService.post(
        '/api/warehouse/orders/${widget.shipmentId}/items/${widget.itemIndex}/return-payment',
        body: {}, // Empty body required
      );
      final data = _httpService.handleResponse(response);
      
      if (data['status'] == 'success') {
        final paymentUrl = data['data']['authorizationUrl'];
        final returnFee = data['data']['returnFee'];
        
        setState(() => _isLoading = false);
        
        // Open Paystack web view
        final result = await Get.to(() => PaystackWebViewScreen(authorizationUrl: paymentUrl));
        
        if (result == 'success') {
          THelperFunctions.showSuccessSnackBar(
            'Payment Confirmed',
            'Return fee of ₦${returnFee.toString()} processed successfully.',
          );
          Get.back(result: true); // Return true to trigger detail page refresh
        } else {
          THelperFunctions.showWarningSnackBar('Payment Incomplete', 'Return payment was not completed.');
        }
      }
    } catch (e) {
      setState(() => _isLoading = false);
      String errMsg = 'Failed to initiate return payment.';
      if (e is ApiException) {
        errMsg = e.message;
      }
      THelperFunctions.showErrorSnackBar('Error', errMsg);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dark = THelperFunctions.isDarkMode(context);
    final itemDesc = widget.item['description'] ?? 'Item';
    
    final returnDeadlineStr = widget.item['returnDeadline'];
    final returnDeadline = returnDeadlineStr != null ? DateTime.tryParse(returnDeadlineStr) : null;
    final isDeadlineExpired = returnDeadline != null && DateTime.now().isAfter(returnDeadline);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Arrange Item Return'),
        backgroundColor: dark ? TColors.dark : TColors.white,
        foregroundColor: dark ? TColors.white : TColors.black,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Return instructions info box
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDeadlineExpired ? Colors.red.withOpacity(0.1) : TColors.warning.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: isDeadlineExpired ? Colors.red : TColors.warning),
              ),
              child: Row(
                children: [
                  Icon(
                    isDeadlineExpired ? Icons.warning_amber_rounded : Icons.info_outline,
                    color: isDeadlineExpired ? Colors.red : TColors.warning,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      isDeadlineExpired
                          ? 'The return deadline has passed. This item can no longer be returned and is scheduled for disposal.'
                          : 'To return this item, you must pay a return fee representing 50% of the item\'s shipping cost (minimum ₦100).',
                      style: TextStyle(
                        color: isDeadlineExpired ? Colors.red : (dark ? TColors.white : TColors.black),
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            // Item details card
            Card(
              color: dark ? TColors.darkerGrey : Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Item Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const Divider(height: 24),
                    _buildInfoRow('Description', itemDesc),
                    _buildInfoRow('Weight', '${widget.item['declaredWeight'] ?? 0} kg'),
                    _buildInfoRow('Declared Value', '₦${widget.item['declaredValue'] ?? 0}'),
                    _buildInfoRow('Destination State', widget.item['destinationState'] ?? 'N/A'),
                    if (returnDeadline != null)
                      _buildInfoRow(
                        'Return Deadline',
                        DateFormat.yMMMd().format(returnDeadline),
                        textColor: isDeadlineExpired ? Colors.red : Colors.orange.shade800,
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            
            // Payment Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading || isDeadlineExpired ? null : _initiateReturnPayment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: TColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Initiate Return Payment'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {Color? textColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}
