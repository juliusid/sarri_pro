import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sarri_ride/core/services/http_service.dart';
import 'package:sarri_ride/utils/constants/colors.dart';
import 'package:sarri_ride/utils/helpers/helper_functions.dart';

class WarehouseQRCodeScreen extends StatefulWidget {
  final String shipmentId;

  const WarehouseQRCodeScreen({super.key, required this.shipmentId});

  @override
  State<WarehouseQRCodeScreen> createState() => _WarehouseQRCodeScreenState();
}

class _WarehouseQRCodeScreenState extends State<WarehouseQRCodeScreen> {
  final HttpService _httpService = HttpService.instance;
  bool _isLoading = true;
  List<dynamic> _qrCodes = [];

  @override
  void initState() {
    super.initState();
    _fetchQRCodes();
  }

  Future<void> _fetchQRCodes() async {
    try {
      final response = await _httpService.get('/api/warehouse/orders/${widget.shipmentId}/qrcodes');
      final data = _httpService.handleResponse(response);
      if (data['status'] == 'success') {
        setState(() {
          _qrCodes = data['data'];
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
      THelperFunctions.showErrorSnackBar('Error', 'Failed to fetch QR codes. Try again later.');
    }
  }

  Uint8List _base64ToImage(String base64String) {
    return base64Decode(base64String.split(',').last);
  }

  @override
  Widget build(BuildContext context) {
    final dark = THelperFunctions.isDarkMode(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Your QR Codes'),
        backgroundColor: dark ? TColors.dark : TColors.white,
        foregroundColor: dark ? TColors.white : TColors.black,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _qrCodes.isEmpty
              ? const Center(child: Text('No QR codes found.'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _qrCodes.length,
                  itemBuilder: (context, index) {
                    final item = _qrCodes[index];
                    return Card(
                      color: dark ? TColors.darkerGrey : Colors.white,
                      margin: const EdgeInsets.only(bottom: 24),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          children: [
                            Text(
                              item['description'] ?? 'Package',
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 16),
                            Image.memory(
                              _base64ToImage(item['qrCodeImage']),
                              width: 220,
                              height: 220,
                              fit: BoxFit.contain,
                            ),
                            const SizedBox(height: 24),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  // In a real device, save to gallery or share
                                  THelperFunctions.showSnackBar('QR Code saved to gallery (simulated)');
                                },
                                icon: const Icon(Icons.download),
                                label: const Text('Download QR Code'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: TColors.primary,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                              ),
                            )
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
