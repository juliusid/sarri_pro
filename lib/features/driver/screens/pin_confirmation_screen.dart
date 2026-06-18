import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sarri_ride/utils/constants/colors.dart';
import 'package:sarri_ride/utils/helpers/helper_functions.dart';
import 'package:sarri_ride/features/driver/controllers/driver_manifest_controller.dart';
import 'package:sarri_ride/features/driver/screens/failure_reporting_screen.dart';

class PinConfirmationScreen extends StatefulWidget {
  final String shipmentId;
  final int itemIndex;
  final String description;
  final String recipientName;
  final String recipientPhone;

  const PinConfirmationScreen({
    super.key,
    required this.shipmentId,
    required this.itemIndex,
    required this.description,
    required this.recipientName,
    required this.recipientPhone,
  });

  @override
  State<PinConfirmationScreen> createState() => _PinConfirmationScreenState();
}

class _PinConfirmationScreenState extends State<PinConfirmationScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _pinController = TextEditingController();
  final TextEditingController _receivedByNameController = TextEditingController();
  String _selectedIdType = 'NIN';
  bool _isLoading = false;

  final List<String> _idTypes = [
    'NIN',
    'Passport',
    "Driver's Licence",
    "Voter's Card",
    'National ID Card',
    'Other'
  ];

  @override
  void initState() {
    super.initState();
    _receivedByNameController.text = widget.recipientName;
  }

  @override
  void dispose() {
    _pinController.dispose();
    _receivedByNameController.dispose();
    super.dispose();
  }

  Future<void> _verifyPin() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);
    try {
      final controller = Get.find<DriverManifestController>();
      final success = await controller.confirmDeliveryPIN(
        shipmentId: widget.shipmentId,
        itemIndex: widget.itemIndex,
        pin: _pinController.text.trim(),
        receivedByName: _receivedByNameController.text.trim(),
        receivedByIdType: _selectedIdType,
      );

      if (success) {
        Get.back(); // Go back to manifest list
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
        title: const Text('Confirm Delivery'),
        backgroundColor: dark ? TColors.dark : TColors.white,
        foregroundColor: dark ? TColors.white : TColors.black,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Column(
                  children: [
                    const Icon(Icons.security, size: 64, color: TColors.primary),
                    const SizedBox(height: 16),
                    Text(
                      'Confirm Receipt',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Enter recipient PIN & ID details for:\n"${widget.description}"',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: dark ? Colors.grey[400] : Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // PIN Code Input (6 digits)
              const Text('Recipient PIN (6-digit)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _pinController,
                keyboardType: TextInputType.number,
                maxLength: 6,
                obscureText: false, // Let them see the numbers to prevent typing errors
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 22, letterSpacing: 12, fontWeight: FontWeight.bold),
                decoration: InputDecoration(
                  counterText: '',
                  hintText: '000000',
                  hintStyle: TextStyle(color: Colors.grey[400], letterSpacing: 12),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                ),
                validator: (val) {
                  if (val == null || val.length != 6) {
                    return 'Please enter a 6-digit PIN';
                  }
                  if (int.tryParse(val) == null) {
                    return 'PIN must be numeric';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Received By Name
              const Text('Received By Name', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _receivedByNameController,
                decoration: InputDecoration(
                  hintText: "Enter receiver's name",
                  prefixIcon: const Icon(Icons.person),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Name is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Received By ID Type Dropdown
              const Text('Receiver Identification Type', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedIdType,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.badge),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                items: _idTypes.map((type) {
                  return DropdownMenuItem<String>(
                    value: type,
                    child: Text(type),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() => _selectedIdType = val);
                  }
                },
              ),
              const SizedBox(height: 36),

              // Confirm Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _verifyPin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: TColors.primary,
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
                      : const Text('Confirm Delivery', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 12),

              // Report Failure Button
              Center(
                child: TextButton.icon(
                  onPressed: () => Get.to(() => FailureReportingScreen(
                        shipmentId: widget.shipmentId,
                        itemIndex: widget.itemIndex,
                      )),
                  icon: const Icon(Icons.report_problem, size: 18),
                  label: const Text('Report Failed Delivery / Issue'),
                  style: TextButton.styleFrom(
                    foregroundColor: TColors.error,
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}

