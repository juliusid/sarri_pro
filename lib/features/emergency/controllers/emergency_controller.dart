import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sarri_ride/core/services/websocket_service.dart';
import 'package:sarri_ride/features/emergency/services/emergency_service.dart';
import 'package:sarri_ride/utils/helpers/helper_functions.dart';

class EmergencyController extends GetxController {
  static EmergencyController get instance => Get.find();

  final EmergencyService _service = Get.put(EmergencyService());
  final WebSocketService _socketService = WebSocketService.instance;

  // State
  final Rx<Map<String, dynamic>?> activeEmergency = Rx<Map<String, dynamic>?>(
    null,
  );
  final RxList<dynamic> messages = <dynamic>[].obs;
  final RxList<dynamic> typingUsers = <dynamic>[].obs;
  final RxBool isLoading = false.obs;
  final RxBool isSending = false.obs;

  // Check if user has an active emergency session
  bool get hasActiveEmergency => activeEmergency.value != null;
  String get currentEmergencyId => activeEmergency.value?['_id'] ?? '';
  String get currentEmergencyDisplayId =>
      activeEmergency.value?['emergencyId'] ?? '';

  @override
  void onInit() {
    super.onInit();
    // Register global listener for new messages to this emergency
    _socketService.registerEmergencyMessageListener(_handleNewMessage);
    _socketService.registerEmergencyTypingListener(_handleTyping);
  }

  @override
  void onClose() {
    _socketService.unregisterEmergencyMessageListener(_handleNewMessage);
    _socketService.unregisterEmergencyTypingListener(_handleTyping);
    super.onClose();
  }

  // --- Actions ---

  /// Reports a new emergency
  Future<void> reportEmergency({
    required String category,
    required String description,
    String? tripId,
  }) async {
    isLoading.value = true;
    try {
      final result = await _service.createEmergency(
        category: category,
        description: description,
        tripId: tripId,
      );

      if (result != null) {
        activeEmergency.value = result;
        messages.clear(); // Start fresh

        // Join the socket room for this emergency
        _socketService.joinEmergencyRoom(result['_id']);

        THelperFunctions.showSuccessSnackBar(
          'Alert Sent',
          'Emergency reported. Support has been notified.',
        );

        // Navigate to Emergency Chat Screen (we will build this next)
        // Get.to(() => const EmergencyChatScreen());
      } else {
        THelperFunctions.showErrorSnackBar(
          'Error',
          'Failed to report emergency.',
        );
      }
    } finally {
      isLoading.value = false;
    }
  }

  /// Loads details for an existing emergency (e.g., if re-opening app)
  Future<void> loadEmergencyDetails(String emergencyId) async {
    isLoading.value = true;
    try {
      // Join room first to ensure we get real-time updates
      _socketService.joinEmergencyRoom(emergencyId);

      final data = await _service.getEmergencyDetails(emergencyId);
      if (data != null) {
        activeEmergency.value = data['emergency'];
        if (data['messages'] != null && data['messages']['data'] != null) {
          // Load history
          messages.assignAll(data['messages']['data']);
        }
      }
    } finally {
      isLoading.value = false;
    }
  }

  /// Sends a message in the emergency chat
  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty || !hasActiveEmergency) return;

    isSending.value = true;
    try {
      // Optimistic update could be done here, but for emergency,
      // it's better to wait for confirmation or socket echo
      await _service.sendMessage(currentEmergencyId, text);
    } finally {
      isSending.value = false;
    }
  }

  // --- Socket Handlers ---

  void _handleNewMessage(dynamic data) {
    if (data is Map && data['emergency'] != null) {
      // Ensure message belongs to current active emergency
      if (data['emergency']['id'] == currentEmergencyId) {
        messages.add(data);
        // Scroll to bottom logic will be in the UI
      }
    }
  }

  void _handleTyping(dynamic data) {
    if (data is Map && data['emergencyId'] == currentEmergencyDisplayId) {
      final userId = data['userId'];
      final isTyping = data['isTyping'] == true;

      if (isTyping) {
        // Add if not present
        if (!typingUsers.any((u) => u['userId'] == userId)) {
          typingUsers.add(data);
        }
      } else {
        // Remove
        typingUsers.removeWhere((u) => u['userId'] == userId);
      }
    }
  }

  /// Leave the emergency handling (e.g., resolved)
  void closeEmergencySession() {
    if (hasActiveEmergency) {
      _socketService.leaveEmergencyRoom(currentEmergencyId);
      activeEmergency.value = null;
      messages.clear();
    }
  }
}
