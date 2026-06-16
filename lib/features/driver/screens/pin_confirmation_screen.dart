import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sarri_ride/core/services/http_service.dart';
import 'package:sarri_ride/utils/constants/colors.dart';
import 'package:sarri_ride/utils/helpers/helper_functions.dart';
import 'package:sarri_ride/features/driver/screens/failure_reporting_screen.dart';

class PinConfirmationScreen extends StatefulWidget {
  final String qrData; // Can be item ID or shipment ID
  const PinConfirmationScreen({super.key, required this.qrData});

  @override
  State<PinConfirmationScreen> createState() => _PinConfirmationScreenState();
}

class _PinConfirmationScreenState extends State<PinConfirmationScreen> {
  final TextEditingController _pinController = TextEditingController();
  final HttpService _httpService = HttpService.instance;
  bool _isLoading = false;

  Future<void> _verifyPin() async {
    if (_pinController.text.length < 4) {
      THelperFunctions.showErrorSnackBar('Error', 'Please enter a valid PIN.');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final response = await _httpService.post(
        '/api/warehouse/delivery/verify-pin',
        body: {'qrData': widget.qrData, 'pin': _pinController.text},
      );
      final data = _httpService.handleResponse(response);
      
      if (data['status'] == 'success') {
        THelperFunctions.showSuccessSnackBar('Success', 'Delivery confirmed!');
        Get.back(); // Go back to dashboard/manifest
      }
    } catch (e) {
      THelperFunctions.showErrorSnackBar('Error', 'Invalid PIN or delivery failed.');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dark = THelperFunctions.isDarkMode(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Confirm Delivery')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.security, size: 80, color: TColors.primary),
            const SizedBox(height: 24),
            Text(
              'Enter the recipient\'s 4-digit PIN to confirm delivery.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 32),
            TextField(
              controller: _pinController,
              keyboardType: TextInputType.number,
              maxLength: 4,
              obscureText: true,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 24, letterSpacing: 8),
              decoration: InputDecoration(
                counterText: '',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _verifyPin,
                style: ElevatedButton.styleFrom(
                  backgroundColor: TColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('Confirm Delivery'),
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => Get.to(() => FailureReportingScreen(qrData: widget.qrData)),
              child: const Text('Report Issue / Delivery Failed', style: TextStyle(color: TColors.error)),
            )
          ],
        ),
      ),
    );
  }
}
