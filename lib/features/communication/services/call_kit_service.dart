import 'package:flutter_callkit_incoming/entities/call_event.dart';
import 'package:flutter_callkit_incoming/entities/call_kit_params.dart';
import 'package:flutter_callkit_incoming/entities/android_params.dart';
import 'package:flutter_callkit_incoming/entities/ios_params.dart';
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';
import 'package:get/get.dart';
import 'package:sarri_ride/features/communication/controllers/call_controller.dart';
import 'package:uuid/uuid.dart';

class CallKitService {
  static final CallKitService instance = CallKitService._internal();

  CallKitService._internal();

  String? _currentCallkitId;

  Future<void> init() async {
    FlutterCallkitIncoming.onEvent.listen((event) {
      if (event == null) return;
      switch (event) {
        case CallEventActionCallAccept():
          _handleCallAccept(event.callKitParams.toJson());
          break;
        case CallEventActionCallDecline():
          _handleCallDecline(event.callKitParams.toJson());
          break;
        case CallEventActionCallEnded():
          _handleCallEnded(event.callKitParams.toJson());
          break;
        case CallEventActionCallTimeout():
          _handleCallTimeout({});
          break;
        default:
          break;
      }
    });
  }

  Future<void> showIncomingCall({
    required String callId,
    required String callerName,
    required String avatar,
  }) async {
    _currentCallkitId = const Uuid().v4();
    
    CallKitParams callKitParams = CallKitParams(
      id: _currentCallkitId!,
      nameCaller: callerName,
      appName: 'SarriRide',
      avatar: avatar,
      handle: 'Incoming Call',
      type: 0,
      duration: 30000,
      extra: <String, dynamic>{'callId': callId},
      headers: <String, dynamic>{'apiKey': 'sarri_ride_app', 'platform': 'flutter'},
      android: const AndroidParams(
        isCustomNotification: true,
        isShowLogo: false,
        ringtonePath: 'system_ringtone_default',
        backgroundColor: '#0955fa',
        backgroundUrl: 'assets/test.png',
        actionColor: '#4CAF50',
      ),
      ios: const IOSParams(
        iconName: 'CallKitLogo',
        handleType: '',
        supportsVideo: true,
        maximumCallGroups: 2,
        maximumCallsPerCallGroup: 1,
        audioSessionMode: 'default',
        audioSessionActive: true,
        audioSessionPreferredSampleRate: 44100.0,
        audioSessionPreferredIOBufferDuration: 0.005,
        supportsDTMF: true,
        supportsHolding: true,
        supportsGrouping: false,
        supportsUngrouping: false,
        ringtonePath: 'system_ringtone_default',
      ),
    );

    await FlutterCallkitIncoming.showCallkitIncoming(callKitParams);
  }

  Future<void> endCurrentCall() async {
    if (_currentCallkitId != null) {
      await FlutterCallkitIncoming.endCall(_currentCallkitId!);
      _currentCallkitId = null;
    }
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
