import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:sarri_ride/utils/constants/colors.dart';
import 'package:sarri_ride/utils/helpers/helper_functions.dart';
import 'package:sarri_ride/features/driver/controllers/driver_manifest_controller.dart';

class DriverQrScannerScreen extends StatefulWidget {
  final String? batchId;
  const DriverQrScannerScreen({super.key, this.batchId});

  @override
  State<DriverQrScannerScreen> createState() => _DriverQrScannerScreenState();
}

class _DriverQrScannerScreenState extends State<DriverQrScannerScreen> {
  bool _isProcessing = false;
  final MobileScannerController _scannerController = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
  );

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) async {
    if (_isProcessing) return;

    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isNotEmpty) {
      final String? code = barcodes.first.rawValue;
      if (code != null) {
        setState(() => _isProcessing = true);
        
        if (widget.batchId != null) {
          // Update specific batch (e.g. mark as picked up or arrived)
          _showStatusUpdateDialog(code);
        } else {
          // General scan (e.g. check-in an item)
          _handleGeneralScan(code);
        }
      }
    }
  }

  void _showStatusUpdateDialog(String qrData) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: const Text('Update Batch Status'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('What is the new status of this batch?'),
              const SizedBox(height: 16),
              _buildStatusOption('In Transit', 'in_transit', qrData),
              _buildStatusOption('Arrived Destination', 'arrived_destination', qrData),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                setState(() => _isProcessing = false);
                Get.back();
              },
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatusOption(String label, String value, String qrData) {
    return ListTile(
      title: Text(label),
      leading: const Icon(Icons.local_shipping),
      onTap: () async {
        Get.back(); // close dialog
        final controller = Get.find<DriverManifestController>();
        final success = await controller.updateBatchStatus(widget.batchId!, value, qrData: qrData);
        if (success) {
          Get.back(); // close scanner
        } else {
          setState(() => _isProcessing = false);
        }
      },
    );
  }

  void _handleGeneralScan(String qrData) {
    // Process single item delivery scan (e.g., driver delivering item to the warehouse)
    // Could navigate to a PIN confirmation screen or directly call API
    THelperFunctions.showSuccessSnackBar('Scanned', 'Scanned QR: $qrData');
    
    // Simulating going to PIN screen
    Future.delayed(const Duration(seconds: 1), () {
      setState(() => _isProcessing = false);
      Get.back();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan QR Code'),
        backgroundColor: Colors.transparent,
      ),
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          MobileScanner(
            controller: _scannerController,
            onDetect: _onDetect,
          ),
          CustomPaint(
            painter: ScannerOverlayPainter(),
            child: Container(),
          ),
          if (_isProcessing)
            const Center(
              child: CircularProgressIndicator(color: TColors.primary),
            ),
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Text(
                  'Align QR code within frame',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ScannerOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black54
      ..style = PaintingStyle.fill;

    final path = Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height));
    
    final scanAreaSize = size.width * 0.7;
    final scanAreaRect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2),
      width: scanAreaSize,
      height: scanAreaSize,
    );

    path.addRRect(RRect.fromRectAndRadius(scanAreaRect, const Radius.circular(16)));
    path.fillType = PathFillType.evenOdd;

    canvas.drawPath(path, paint);

    // Draw borders
    final borderPaint = Paint()
      ..color = TColors.primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0;
      
    canvas.drawRRect(RRect.fromRectAndRadius(scanAreaRect, const Radius.circular(16)), borderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
