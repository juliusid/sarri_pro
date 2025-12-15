import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:peerdart/peerdart.dart';
// Alias WebRTC to avoid 'navigator' conflict with GetX
import 'package:flutter_webrtc/flutter_webrtc.dart' as webrtc;
import 'package:sarri_ride/features/communication/services/call_service.dart';
import 'package:sarri_ride/features/communication/screens/incoming_call_screen.dart';
import 'package:sarri_ride/features/communication/screens/call_screen.dart'; // Active call UI
import 'package:sarri_ride/utils/helpers/helper_functions.dart';
import 'package:sarri_ride/core/services/http_service.dart'; // For ApiException

enum CallState { idle, dialing, ringing, active, ended }

class CallController extends GetxController {
  static CallController get instance => Get.find();
  final CallService _callService = Get.put(CallService());

  // --- WebRTC / Peer Variables ---
  Peer? _peer;
  MediaConnection? _mediaConnection;
  webrtc.MediaStream? _localStream;
  webrtc.MediaStream? _remoteStream;

  // --- State ---
  final Rx<CallState> callState = CallState.idle.obs;
  final RxString currentCallId = ''.obs;
  final RxString otherPartyName = ''.obs; // Name to display
  final RxBool isCaller = false.obs; // True if we started the call
  final RxBool isSpeakerOn = false.obs;
  final RxBool isMuted = false.obs;

  // Timer
  final RxInt callDurationSeconds = 0.obs;
  Timer? _durationTimer;

  @override
  void onClose() {
    _disposeCallResources();
    super.onClose();
  }

  // ===========================================================================
  // 1. MAKE A CALL (Outgoing)
  // ===========================================================================
  Future<void> startCall(
    String tripId,
    String receiverName,
    String receiverRole,
  ) async {
    if (callState.value != CallState.idle) return;

    // 1. Permission Check
    if (!await _checkPermissions()) return;

    callState.value = CallState.dialing;
    otherPartyName.value = receiverName;
    isCaller.value = true;

    // 2. Show UI
    Get.to(() => const CallScreen());

    try {
      // 3. Call API to initiate
      final data = await _callService.initiateCall(tripId);

      if (data != null) {
        currentCallId.value = data['callId'];
        final myPeerId = data['callerPeerId'];
        final remotePeerId = data['receiverPeerId'];

        // 4. Init Peer (My Phone Line)
        _initPeer(myPeerId);

        // 5. Get Microphone Access
        _localStream = await webrtc.navigator.mediaDevices.getUserMedia({
          'audio': true,
          'video': false,
        });

        // 6. Connect to Remote Peer (delay slightly for socket propagation)
        Future.delayed(const Duration(seconds: 1), () {
          if (_peer != null && !_peer!.destroyed) {
            print("Connecting to Remote Peer: $remotePeerId");
            _mediaConnection = _peer!.call(remotePeerId, _localStream!);
            _setupMediaHandlers(_mediaConnection!);
          }
        });
      }
    } catch (e) {
      // Handle "User Offline" or other API errors
      String errorMsg = "Call failed";
      if (e.toString().contains("offline")) {
        errorMsg = "User is offline";
      } else if (e is ApiException) {
        errorMsg = e.message;
      }

      THelperFunctions.showErrorSnackBar("Call Failed", errorMsg);
      _disposeCallResources();
      Get.back(); // Close screen
    }
  }

  // ===========================================================================
  // 2. RECEIVE A CALL (Incoming)
  // ===========================================================================
  void handleIncomingCall(Map<String, dynamic> data) async {
    if (callState.value != CallState.idle) return; // Line busy

    currentCallId.value = data['callId'];
    otherPartyName.value = data['caller']['name'] ?? 'Unknown';
    isCaller.value = false;
    callState.value = CallState.ringing;

    // 1. Show Incoming Screen
    Get.to(() => const IncomingCallScreen());

    // 2. Init Peer with the ID the server assigned to us (receiverPeerId)
    final myPeerId = data['receiver']['peerId'];
    _initPeer(myPeerId);

    // 3. Listen for the media connection
    _peer?.on<MediaConnection>("call").listen((call) {
      print("Incoming media connection received");
      _mediaConnection = call;
      // Wait for user to press "Accept"
    });
  }

  // ===========================================================================
  // 3. ACTIONS (User Interactions)
  // ===========================================================================

  Future<void> acceptCall() async {
    if (!await _checkPermissions()) return;

    // 1. Tell API we answered
    await _callService.answerCall(currentCallId.value);

    // 2. Get Microphone
    _localStream = await webrtc.navigator.mediaDevices.getUserMedia({
      'audio': true,
    });

    // 3. Answer WebRTC Connection
    if (_mediaConnection != null) {
      _mediaConnection!.answer(_localStream!);
      _setupMediaHandlers(_mediaConnection!);

      callState.value = CallState.active;
      _startTimer();

      // Swap screens
      Get.off(() => const CallScreen());
    } else {
      THelperFunctions.showErrorSnackBar("Error", "Connection timed out.");
      hangUp();
    }
  }

  Future<void> rejectCall() async {
    await _callService.rejectCall(currentCallId.value);
    _disposeCallResources();
    Get.back();
  }

  Future<void> hangUp() async {
    if (currentCallId.value.isNotEmpty) {
      await _callService.endCall(currentCallId.value);
    }
    _disposeCallResources();
    if (Get.currentRoute.contains('Call')) {
      Get.back();
    }
  }

  // ===========================================================================
  // 4. SOCKET EVENTS (Remote Updates)
  // ===========================================================================
  void handleCallAccepted(Map<String, dynamic> data) {
    if (data['callId'] == currentCallId.value) {
      print("Remote answered the call");
      callState.value = CallState.active;
      _startTimer();
    }
  }

  void handleCallRejected(Map<String, dynamic> data) {
    if (data['callId'] == currentCallId.value) {
      THelperFunctions.showSnackBar("Call declined");
      _disposeCallResources();
      if (Get.currentRoute.contains('Call')) Get.back();
    }
  }

  void handleCallEnded(Map<String, dynamic> data) {
    if (data['callId'] == currentCallId.value) {
      THelperFunctions.showSnackBar("Call ended");
      _disposeCallResources();
      if (Get.currentRoute.contains('Call')) Get.back();
    }
  }

  // ===========================================================================
  // 5. HELPERS
  // ===========================================================================
  void _initPeer(String peerId) {
    _peer = Peer(
      id: peerId,
      options: PeerOptions(
        host: "peerjs-server.herokuapp.com",
        port: 443,
        secure: true,
      ),
    );
    _peer?.on("error").listen((err) => print("Peer Error: $err"));
  }

  void _setupMediaHandlers(MediaConnection conn) {
    conn.on<webrtc.MediaStream>("stream").listen((event) {
      print("Audio Stream Received");
      _remoteStream = event;
      // Auto-enable speaker for ride apps
      toggleSpeaker(true);
    });

    conn.on("close").listen((event) {
      _disposeCallResources();
      if (Get.currentRoute.contains('Call')) Get.back();
    });
  }

  Future<bool> _checkPermissions() async {
    var status = await Permission.microphone.request();
    if (!status.isGranted) {
      THelperFunctions.showErrorSnackBar("Permission", "Microphone required");
      return false;
    }
    return true;
  }

  void toggleSpeaker([bool? forceOn]) {
    bool newState = forceOn ?? !isSpeakerOn.value;
    isSpeakerOn.value = newState;
    if (_localStream != null) {
      webrtc.Helper.setSpeakerphoneOn(newState);
    }
  }

  void toggleMute() {
    isMuted.value = !isMuted.value;
    if (_localStream != null && _localStream!.getAudioTracks().isNotEmpty) {
      _localStream!.getAudioTracks()[0].enabled = !isMuted.value;
    }
  }

  void _startTimer() {
    _durationTimer?.cancel();
    callDurationSeconds.value = 0;
    _durationTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      callDurationSeconds.value++;
    });
  }

  void _disposeCallResources() {
    _durationTimer?.cancel();
    _mediaConnection?.close();
    _peer?.dispose();
    _localStream?.dispose();

    _localStream = null;
    _mediaConnection = null;
    _peer = null;

    callState.value = CallState.idle;
    currentCallId.value = '';
    isCaller.value = false;
  }

  String get formattedDuration {
    int sec = callDurationSeconds.value % 60;
    int min = (callDurationSeconds.value / 60).floor();
    return "${min.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}";
  }
}
