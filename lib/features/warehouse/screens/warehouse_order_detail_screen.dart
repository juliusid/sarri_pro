import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:sarri_ride/core/services/http_service.dart';
import 'package:sarri_ride/utils/constants/colors.dart';
import 'package:sarri_ride/utils/helpers/helper_functions.dart';
import 'package:sarri_ride/features/warehouse/controllers/warehouse_order_history_controller.dart';
import 'package:sarri_ride/features/warehouse/screens/client_claim_screen.dart';
import 'package:sarri_ride/features/warehouse/screens/client_return_screen.dart';
import 'package:sarri_ride/features/warehouse/screens/warehouse_qr_code_screen.dart';

class WarehouseOrderDetailScreen extends StatefulWidget {
  final Map<String, dynamic> order;

  const WarehouseOrderDetailScreen({super.key, required this.order});

  @override
  State<WarehouseOrderDetailScreen> createState() => _WarehouseOrderDetailScreenState();
}

class _WarehouseOrderDetailScreenState extends State<WarehouseOrderDetailScreen> {
  final HttpService _httpService = HttpService.instance;
  late Map<String, dynamic> _order;
  bool _isLoading = false;
  bool _isModified = false;

  @override
  void initState() {
    super.initState();
    _order = widget.order;
    _fetchOrderDetails();
  }

  Future<void> _fetchOrderDetails() async {
    setState(() => _isLoading = true);
    try {
      final shipmentId = _order['shipmentId'] ?? _order['_id'];
      final response = await _httpService.get('/api/warehouse/orders/$shipmentId');
      final data = _httpService.handleResponse(response);
      if (data['status'] == 'success') {
        setState(() {
          _order = data['data'];
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
      print('Error fetching order details: $e');
    }
  }

  void _confirmCancelOrder(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Order'),
        content: const Text(
          'Are you sure you want to cancel this order? If you have paid, a Paystack refund will be automatically processed.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final controller = Get.put(WarehouseOrderHistoryController());
              final shipmentId = _order['shipmentId'] ?? _order['_id'];
              final success = await controller.cancelOrder(shipmentId);
              if (success) {
                _isModified = true;
                Get.back(result: true); // Return to history screen and reload list
              }
            },
            child: const Text('Yes, Cancel', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dark = THelperFunctions.isDarkMode(context);
    final status = (_order['status'] ?? 'pending').toString().toUpperCase();
    final items = _order['items'] as List<dynamic>? ?? [];

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop && _isModified) {
          // If we modified order state (cancelled, return paid, claims filed), tell history list to refresh
          Get.back(result: true);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Order Details'),
          backgroundColor: dark ? TColors.dark : TColors.white,
          foregroundColor: dark ? TColors.white : TColors.black,
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _fetchOrderDetails,
            ),
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildStatusHeader(status),
                    const SizedBox(height: 24),
                    _buildSectionTitle('Tracking & Info'),
                    _buildInfoCard(dark, [
                      _buildInfoRow('Shipment ID', _order['shipmentId'] ?? _order['_id'] ?? 'N/A'),
                      _buildInfoRow('Date', _formatDate(_order['createdAt'])),
                      _buildInfoRow('Total Price', '₦${_order['totalPrice'] ?? 0}'),
                      _buildInfoRow('Payment Status', (_order['paymentStatus'] ?? 'pending').toString().toUpperCase()),
                    ]),
                    
                    // View QR Codes Button
                    if (_order['paymentStatus'] == 'paid') ...[
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () => Get.to(
                            () => WarehouseQRCodeScreen(shipmentId: _order['shipmentId'] ?? _order['_id']),
                          ),
                          icon: const Icon(Icons.qr_code_2_rounded),
                          label: const Text('View QR Codes'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: TColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                    ],

                    const SizedBox(height: 24),
                    _buildSectionTitle('Recipient Details'),
                    _buildInfoCard(dark, [
                      _buildInfoRow('Name', _order['recipientDetails']?['name'] ?? 'N/A'),
                      _buildInfoRow('Phone', _order['recipientDetails']?['phone'] ?? 'N/A'),
                      _buildInfoRow('Address', _order['recipientDetails']?['address'] ?? 'N/A'),
                      _buildInfoRow('State', _order['recipientDetails']?['state'] ?? 'N/A'),
                    ]),
                    const SizedBox(height: 24),
                    _buildSectionTitle('Items (${items.length})'),
                    ...items.asMap().entries.map((entry) {
                      final index = entry.key;
                      final item = entry.value;
                      return _buildItemCard(dark, item, index, status);
                    }),
                    
                    const SizedBox(height: 32),
                    
                    // Cancel Order Button
                    if (status == 'PENDING_DROPOFF') ...[
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () => _confirmCancelOrder(context),
                          icon: const Icon(Icons.cancel_outlined, color: Colors.red),
                          label: const Text('Cancel Order', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.red),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildStatusHeader(String status) {
    Color color;
    IconData icon;
    switch (status) {
      case 'DELIVERED':
        color = Colors.green;
        icon = Icons.check_circle;
        break;
      case 'IN_TRANSIT':
        color = Colors.blue;
        icon = Icons.local_shipping;
        break;
      case 'CANCELLED':
      case 'RETURNED':
        color = Colors.red;
        icon = Icons.cancel;
        break;
      default:
        color = Colors.orange;
        icon = Icons.hourglass_empty;
    }
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(width: 16),
          Text(
            status,
            style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildInfoCard(bool dark, List<Widget> children) {
    return Card(
      color: dark ? TColors.darkerGrey : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(children: children),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 120, child: Text(label, style: const TextStyle(color: Colors.grey))),
          Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }

  Widget _buildItemCard(bool dark, Map<String, dynamic> item, int index, String orderStatus) {
    final itemStatus = (item['status'] ?? orderStatus).toString().toUpperCase();
    final itemReturnStatus = (item['returnStatus'] ?? 'NONE').toString().toUpperCase();
    
    // Check Delivered Date for Damage Claims (24 hours)
    final deliveredAtStr = item['deliveredAt'];
    final deliveredAt = deliveredAtStr != null ? DateTime.tryParse(deliveredAtStr) : null;
    final claimWindowExpires = deliveredAt?.add(const Duration(hours: 24));
    final isDamageClaimExpired = claimWindowExpires != null && DateTime.now().isAfter(claimWindowExpires);

    // Check Return Deadline for Return Payments (7 days)
    final returnDeadlineStr = item['returnDeadline'];
    final returnDeadline = returnDeadlineStr != null ? DateTime.tryParse(returnDeadlineStr) : null;
    final isReturnDeadlineExpired = returnDeadline != null && DateTime.now().isAfter(returnDeadline);

    return Card(
      color: dark ? TColors.darkerGrey : Colors.white,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    item['description'] ?? 'Item',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    itemStatus,
                    style: const TextStyle(fontSize: 11, color: Colors.blue, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            _buildItemDetailRow('Weight:', '${item['declaredWeight']} kg'),
            _buildItemDetailRow('Declared Value:', '₦${item['declaredValue']}'),
            _buildItemDetailRow('Destination State:', item['destinationState'] ?? 'N/A'),
            
            if (itemReturnStatus != 'NONE')
              _buildItemDetailRow('Return Status:', itemReturnStatus),

            // --- Phase 4 Claims & Returns Actions per Item ---
            
            // 1. Damage Claim Action (Item DELIVERED)
            if (itemStatus == 'DELIVERED') ...[
              const SizedBox(height: 12),
              if (deliveredAt != null && claimWindowExpires != null) ...[
                ObxValue<RxBool>((isExpired) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: isExpired.value ? Colors.red.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isExpired.value ? Icons.error_outline : Icons.timer_outlined,
                          size: 16,
                          color: isExpired.value ? Colors.red : Colors.orange,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ClaimCountdownTimer(
                            expirationTime: claimWindowExpires,
                            onExpired: () => isExpired.value = true,
                          ),
                        ),
                      ],
                    ),
                  );
                }, isDamageClaimExpired.obs),
                const SizedBox(height: 8),
              ],
              
              if (!isDamageClaimExpired) ...[
                SizedBox(
                  width: double.infinity,
                  child: TextButton.icon(
                    onPressed: () => _openClaimScreen(item, index),
                    icon: const Icon(Icons.report_problem_outlined, size: 18),
                    label: const Text('File Damage Claim'),
                    style: TextButton.styleFrom(
                      foregroundColor: TColors.error,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ],

            // 2. Loss Claim Action (Item RETURN_PENDING)
            if (itemStatus == 'RETURN_PENDING') ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: TextButton.icon(
                  onPressed: () => _openClaimScreen(item, index),
                  icon: const Icon(Icons.report_problem_outlined, size: 18),
                  label: const Text('File Loss Claim'),
                  style: TextButton.styleFrom(
                    foregroundColor: TColors.error,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],

            // 3. Initiate Return Fee Payment (Item returnStatus = RETURN_PENDING)
            if (itemReturnStatus == 'RETURN_PENDING') ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isReturnDeadlineExpired ? Colors.red.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isReturnDeadlineExpired ? Colors.red.withOpacity(0.3) : Colors.orange.withOpacity(0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          isReturnDeadlineExpired ? Icons.delete_outline : Icons.info_outline,
                          color: isReturnDeadlineExpired ? Colors.red : Colors.orange,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            isReturnDeadlineExpired
                                ? 'Return deadline has passed. Item will be disposed of.'
                                : 'Pay return fee by ${_formatDeadline(returnDeadline)} or item will be disposed of.',
                            style: TextStyle(
                              color: isReturnDeadlineExpired ? Colors.red : Colors.orange.shade800,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (!isReturnDeadlineExpired) ...[
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () => _openReturnPaymentScreen(item, index),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: TColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: const Text('Pay Return Fee'),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildItemDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
        ],
      ),
    );
  }

  void _openClaimScreen(Map<String, dynamic> item, int index) async {
    final shipmentId = _order['shipmentId'] ?? _order['_id'];
    final result = await Get.to(() => ClientClaimScreen(
          shipmentId: shipmentId,
          itemIndex: index,
          item: item,
        ));
    if (result == true) {
      _isModified = true;
      _fetchOrderDetails();
    }
  }

  void _openReturnPaymentScreen(Map<String, dynamic> item, int index) async {
    final shipmentId = _order['shipmentId'] ?? _order['_id'];
    final result = await Get.to(() => ClientReturnScreen(
          shipmentId: shipmentId,
          itemIndex: index,
          item: item,
        ));
    if (result == true) {
      _isModified = true;
      _fetchOrderDetails();
    }
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return 'N/A';
    final date = DateTime.tryParse(dateStr);
    if (date == null) return 'N/A';
    return DateFormat.yMMMd().add_jm().format(date);
  }

  String _formatDeadline(DateTime? date) {
    if (date == null) return 'N/A';
    return DateFormat.yMMMd().format(date);
  }
}

class ClaimCountdownTimer extends StatefulWidget {
  final DateTime expirationTime;
  final VoidCallback onExpired;

  const ClaimCountdownTimer({
    super.key,
    required this.expirationTime,
    required this.onExpired,
  });

  @override
  State<ClaimCountdownTimer> createState() => _ClaimCountdownTimerState();
}

class _ClaimCountdownTimerState extends State<ClaimCountdownTimer> {
  late Timer _timer;
  Duration _timeLeft = Duration.zero;

  @override
  void initState() {
    super.initState();
    _updateTimeLeft();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _updateTimeLeft();
    });
  }

  void _updateTimeLeft() {
    final now = DateTime.now();
    final diff = widget.expirationTime.difference(now);
    if (diff.isNegative) {
      _timeLeft = Duration.zero;
      _timer.cancel();
      widget.onExpired();
    } else {
      setState(() {
        _timeLeft = diff;
      });
    }
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_timeLeft == Duration.zero) {
      return const Text(
        'Claim window expired',
        style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 12),
      );
    }

    final hours = _timeLeft.inHours.toString().padLeft(2, '0');
    final minutes = (_timeLeft.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (_timeLeft.inSeconds % 60).toString().padLeft(2, '0');

    return Text(
      'Claim window expires in: $hours:$minutes:$seconds',
      style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 12),
    );
  }
}
