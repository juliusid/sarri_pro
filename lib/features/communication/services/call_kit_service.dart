import 'package:get/get.dart';
import 'package:sarri_ride/features/communication/controllers/call_controller.dart';
// import 'package:uuid/uuid.dart';

class CallKitService {
  static final CallKitService instance = CallKitService._internal();

  CallKitService._internal();

  String? _currentCallkitId;

  Future<void> init() async {
    // Dummy init
  }

  Future<void> showIncomingCall({
    required String callId,
    required String callerName,
    required String avatar,
  }) async {
    // Dummy implementation
  }

  Future<void> endCurrentCall() async {
    // Dummy implementation
  }

  void _handleCallAccept(Map<String, dynamic> body) {
    if (Get.isRegistered<CallController>()) {
      Get.find<CallController>().acceptCall();
    }
  }

  void _handleCallDecline(Map<String, dynamic> body) {
    if (Get.isRegistered<CallController>()) {
      Get.find<CallController>().rejectCall();
    }
    _currentCallkitId = null;
  }

  void _handleCallEnded(Map<String, dynamic> body) {
    if (Get.isRegistered<CallController>()) {
      Get.find<CallController>().hangUp();
    }
    _currentCallkitId = null;
  }

  void _handleCallTimeout(Map<String, dynamic> body) {
    if (Get.isRegistered<CallController>()) {
      Get.find<CallController>().hangUp();
    }
    _currentCallkitId = null;
  }
}
