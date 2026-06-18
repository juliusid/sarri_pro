import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:geolocator/geolocator.dart';
import 'package:sarri_ride/utils/constants/colors.dart';
import 'package:sarri_ride/utils/helpers/helper_functions.dart';
import 'package:sarri_ride/features/driver/controllers/driver_manifest_controller.dart';
import 'package:sarri_ride/features/driver/screens/pin_confirmation_screen.dart';
import 'package:sarri_ride/features/location/services/location_service.dart';

class DriverQrScannerScreen extends StatefulWidget {
  final String? expectedShipmentId;
  final int? expectedItemIndex;

  const DriverQrScannerScreen({
    super.key,
    this.expectedShipmentId,
    this.expectedItemIndex,
  });

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
        await _processScannedCode(code);
      }
    }
  }

  Future<void> _processScannedCode(String qrData) async {
    try {
      // 1. Parse JSON
      Map<String, dynamic> parsed;
      try {
        parsed = jsonDecode(qrData);
      } catch (e) {
        THelperFunctions.showErrorSnackBar('Invalid QR', 'The QR code does not contain a valid delivery payload.');
        setState(() => _isProcessing = false);
        return;
      }

      final String? shipmentId = parsed['shipmentId'];
      final int? itemIndex = parsed['itemIndex'];
      final String? hmacSignature = parsed['hmacSignature'];

      if (shipmentId == null || itemIndex == null || hmacSignature == null) {
        THelperFunctions.showErrorSnackBar('Invalid QR', 'QR payload is missing required delivery details.');
        setState(() => _isProcessing = false);
        return;
      }

      // 2. Validate expected package if specified
      if (widget.expectedShipmentId != null && widget.expectedItemIndex != null) {
        if (widget.expectedShipmentId != shipmentId || widget.expectedItemIndex != itemIndex) {
          bool proceed = await _showMismatchWarningDialog();
          if (!proceed) {
            setState(() => _isProcessing = false);
            return;
          }
        }
      }

      // 3. Fetch GPS Coordinates using LocationService
      double? lat;
      double? lng;
      try {
        final pos = await LocationService.instance.getCurrentLocation();
        if (pos != null) {
          lat = pos.latitude;
          lng = pos.longitude;
        }
      } catch (e) {
        print('Could not fetch GPS location: $e');
        // Do not block scanning completely, backend allows nullable coordinates
      }

      // 4. Submit to delivery scan endpoint
      final controller = Get.find<DriverManifestController>();
      final resData = await controller.scanDelivery(qrData, lat, lng);

      if (resData != null) {
        // Success!
        final bool geofenceViolation = resData['geofenceViolation'] ?? false;
        final num? distance = resData['distanceFromRecipient'];

        if (geofenceViolation && distance != null) {
          THelperFunctions.showSnackBar('Geofence Warning: Recipient is ${distance.round()}m away.');
        }

        // Navigate to PIN Confirm
        Get.off(() => PinConfirmationScreen(
              shipmentId: resData['shipmentId'] ?? shipmentId,
              itemIndex: resData['itemIndex'] ?? itemIndex,
              description: resData['description'] ?? 'Package',
              recipientName: resData['recipientName'] ?? 'Recipient',
              recipientPhone: resData['recipientPhone'] ?? '',
            ));
      } else {
        // Scan failed
        setState(() => _isProcessing = false);
      }
    } catch (e) {
      print('Error processing scanned QR code: $e');
      THelperFunctions.showErrorSnackBar('Scan Error', 'An unexpected error occurred during processing.');
      setState(() => _isProcessing = false);
    }
  }

  Future<bool> _showMismatchWarningDialog() async {
    return await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (context) {
            return AlertDialog(
              title: const Row(
                children: [
                  Icon(Icons.warning, color: Colors.orange),
                  SizedBox(width: 8),
                  Text('Item Mismatch'),
                ],
              ),
              content: const Text(
                'The package you scanned does not match the one you selected in your manifest.\n\n'
                'Do you want to deliver this scanned package instead?',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancel & Scan Correct'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Yes, Deliver Scanned'),
                ),
              ],
            );
          },
        ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Delivery QR'),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
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
                  'Align recipient\'s QR code within the frame',
                  style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
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

