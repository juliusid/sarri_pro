// lib/core/services/websocket_service.dart

import 'dart:async';
import 'dart:convert';
import 'dart:math'; // For jitter
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sarri_ride/features/authentication/models/auth_model.dart';
import 'package:sarri_ride/features/communication/controllers/call_controller.dart';
import 'package:sarri_ride/features/communication/controllers/chat_controller.dart';
import 'package:sarri_ride/features/notifications/controllers/notification_controller.dart';
import 'package:sarri_ride/features/ride/models/ride_model.dart';
import 'package:sarri_ride/features/ride/services/ride_service.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:google_maps_flutter/google_maps_flutter.dart';

// --- Local Imports ---
import 'package:sarri_ride/core/services/http_service.dart';
import 'package:sarri_ride/config/api_config.dart';
import 'package:sarri_ride/utils/helpers/helper_functions.dart';
import 'package:sarri_ride/features/ride/controllers/ride_controller.dart';
import 'package:sarri_ride/features/driver/controllers/trip_management_controller.dart';
import 'package:sarri_ride/features/authentication/screens/login/login_screen_getx.dart';

import 'package:sarri_ride/features/driver/controllers/trip_management_controller.dart'
    show TripRequest;
import 'package:sarri_ride/features/ride/widgets/driver_info_card.dart'
    show Driver;

class WebSocketService extends GetxService {
  static WebSocketService get instance => Get.find();

  IO.Socket? _socket;
  final RxBool isConnected = false.obs;
  String? _cachedToken;

  int _reconnectAttempts = 0;
  final int _maxReconnectAttempts = 5;
  final Duration _initialReconnectDelay = const Duration(seconds: 2);
  Timer? _reconnectTimer;

  // --- Listener Lists ---
  final List<Function(dynamic)> _chatMessageListeners = [];
  final List<Function(dynamic)> _sentConfirmationListeners = [];
  final List<Function(dynamic)> _cashPaymentPendingListeners = [];
  final List<Function(dynamic)> _paymentConfirmedListeners = [];
  final List<Function(dynamic)> _walletUpdateListeners = [];
  final List<Function(dynamic)> _paymentProcessedListeners = [];
  // --- Listener Lists for Emergency ---
  final List<Function(dynamic)> _emergencyMessageListeners = [];
  final List<Function(dynamic)> _emergencyTypingListeners = [];

  @override
  void onInit() {
    super.onInit();
    print("WebSocketService Initialized");
  }

  @override
  void onClose() {
    _reconnectTimer?.cancel();
    disconnect();
    super.onClose();
  }

  // --- MODIFIED connect METHOD ---
  void connect() {
    if (_socket != null && _socket!.connected) {
      print('WebSocket connection attempt skipped: Already connected.');
      return;
    }
    if (_socket != null) {
      disconnect(); // Disconnect previous instance if exists but not connected
    }

    final httpService = HttpService.instance;
    _cachedToken = httpService.accessToken;

    if (_cachedToken == null) {
      print('WebSocket Error: Cannot connect without authentication token.');
      return;
    }

    // Use the base URL, as per the documentation screenshot
    final String socketUrl = ApiConfig.webSocketUrl; //
    print('Attempting to connect WebSocket to $socketUrl');

    try {
      _socket = IO.io(socketUrl, <String, dynamic>{
        'transports': ['websocket'],
        'autoConnect': false, // Connect manually
        'forceNew': true,
        'reconnection': false, // Handle manually
        // --- MISTAKE FIX ---
        // The token must be sent in the 'query' map, not the 'auth' map,
        // based on the documentation URL: wss://.../?token=...&EIO=4&transport=websocket
        //
        'auth': null, // Remove auth map
        'query': {
          'token': _cachedToken,
          'EIO': '4', // Explicitly add EIO=4 as seen in doc
          'transport': 'websocket', // Explicitly add transport as seen in doc
        },
        // --- END MISTAKE FIX ---
      });

      _socket?.clearListeners();
      _setupEventListeners();

      print("WebSocket connect() method called.");
      _socket!.connect();
      _reconnectAttempts = 0; // Reset attempts on manual connect
      _reconnectTimer?.cancel();
    } catch (e) {
      print('WebSocket Initialization Error: $e');
      isConnected.value = false;
      _socket = null;
    }
  }
  // --- END MODIFIED connect METHOD ---

  void disconnect() {
    _reconnectTimer?.cancel();
    if (_socket != null) {
      print("Disconnecting WebSocket...");
      _socket!.dispose();
      _socket = null;
      isConnected.value = false;
      _cachedToken = null;
      _reconnectAttempts = 0;
      print("WebSocket Disconnected");
    } else {
      print("WebSocket already disconnected or not initialized.");
    }
  }

  void _attemptReconnect() {
    _reconnectTimer?.cancel();

    if (_socket != null && _socket!.connected) {
      print("Reconnect attempt skipped: Already connected.");
      _reconnectAttempts = 0;
      return;
    }

    if (_cachedToken == null) {
      print("Cannot reconnect: No cached token available (likely logged out).");
      _reconnectAttempts = 0;
      return;
    }

    if (_reconnectAttempts < _maxReconnectAttempts) {
      _reconnectAttempts++;
      final delayInSeconds =
          (_initialReconnectDelay.inSeconds * pow(2, _reconnectAttempts - 1));
      final jitter = Random().nextDouble() * delayInSeconds * 0.5;
      final finalDelay = Duration(
        seconds: (delayInSeconds + jitter).toInt().clamp(1, 60),
      );

      print(
        'WebSocket Reconnect Attempt $_reconnectAttempts/$_maxReconnectAttempts scheduled in ${finalDelay.inSeconds} seconds...',
      );

      _reconnectTimer = Timer(finalDelay, () {
        if (_socket != null && !_socket!.connected && _cachedToken != null) {
          print(
            "Retrying WebSocket connection (Attempt $_reconnectAttempts)...",
          );
          // Re-set query params in case they are needed on reconnect
          _socket?.io.options?['query'] = {
            'token': _cachedToken,
            'EIO': '4',
            'transport': 'websocket',
          };
          _socket?.connect();
        } else if (_cachedToken == null) {
          print("Reconnect cancelled: User logged out during delay.");
          _reconnectAttempts = 0;
        } else {
          print(
            "Reconnect cancelled: Socket state changed during delay (connected).",
          );
          _reconnectAttempts = 0;
        }
      });
    } else {
      print('WebSocket Max Reconnect Attempts Reached.');
      _reconnectAttempts = 0;
      // Optionally show a snackbar
      // WidgetsBinding.instance.addPostFrameCallback((_) { THelperFunctions.showSnackBar("Unable to connect to real-time service."); });
    }
  }

  void _handleAuthError() {
    print('WebSocket Auth Error detected. Clearing tokens and logging out.');
    disconnect();
    // Use WidgetsBinding to safely call Get/Snackbar from non-UI thread
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Check if HttpService is still registered before clearing tokens
      if (Get.isRegistered<HttpService>()) {
        HttpService.instance.clearTokens();
      }
      // Check if already on login screen
      if (Get.currentRoute != '/LoginScreenGetX') {
        Get.offAll(() => const LoginScreenGetX());
        THelperFunctions.showSnackBar("Session expired. Please log in again.");
      }
    });
  }

  void emit(String event, dynamic data) {
    if (_socket != null && _socket!.connected) {
      _socket!.emit(event, data);
    } else {
      print('Error: Cannot emit event [$event]. Socket not connected.');
      // THelperFunctions.showSnackBar("Cannot perform action: Not connected to server.");
    }
  }

  void emitWithAck(String event, dynamic data, {required Function ack}) {
    if (_socket != null && _socket!.connected) {
      _socket!.emitWithAck(
        event,
        data,
        ack: (response) {
          try {
            // Check based on server response structure
            if (response is Map && response['status'] != 'success') {
              final errorMessage =
                  response['message'] ?? 'Unknown error from server';
              print('WebSocket Ack Error for [$event]: $errorMessage');
            }
            ack(response);
          } catch (e) {
            print("Error processing Ack for event '$event': $e");
            ack({
              'status': 'error',
              'message': 'Client-side error processing ack',
            });
          }
        },
      );
    } else {
      print(
        'Error: Cannot emit event with ack [$event]. Socket not connected.',
      );
      ack({'status': 'error', 'message': 'Socket not connected'});
    }
  }

  void _listen(String event, Function(dynamic) handler) {
    if (_socket != null) {
      _socket!.on(event, (data) {
        try {
          handler(data);
        } catch (e) {
          print("Error handling WebSocket event '$event': $e");
        }
      });
    }
  }

  // --- Specific Event Emitters ---
  void joinChatRoom(String chatId) {
    if (chatId.isEmpty) {
      print("Cannot join chat room: chatId is empty.");
      return;
    }
    print("Attempting to join chat room: $chatId");
    emitWithAck(
      'joinChatRoom',
      chatId,
      ack: (response) {
        if (response is Map && response['status'] == 'success') {
          print('Successfully joined chat room: $chatId');
        } else {
          print(
            'Handling failure for joinChatRoom $chatId: ${response?['message']}',
          );
        }
      },
    );
  }

  void leaveChatRoom(String chatId) {
    // Implement leave room logic if your backend has a 'leaveChatRoom' event
    print("Leaving chat room: $chatId");
    // emit('leaveChatRoom', chatId);
  }

  void updateDriverAvailability(String status) {
    final payload = {'availabilityStatus': status};

    print("WebSocket: Emitting updateAvailability -> $payload");

    emitWithAck(
      'updateAvailability',
      payload,
      ack: (response) {
        if (response is Map && response['status'] == 'success') {
          print('Availability update confirmed by server: $status');
        } else {
          print('Availability update failed: ${response?['message']}');
          // Optional: revert UI state if failed?
        }
      },
    );
  }

  // --- MODIFIED updateDriverLocation METHOD ---
  void updateDriverLocation({
    required double latitude,
    required double longitude,
    required String availabilityStatus,
    required String state, // Make state required
    String? tripId,
    double? heading,
    double? speed,
  }) {
    // Payload must match the documentation
    final payload = {
      'latitude': latitude,
      'longitude': longitude,
      'availabilityStatus': availabilityStatus,
      'state': state, // Add the state field
      if (tripId != null) 'tripId': tripId,
      if (heading != null) 'heading': heading,
      if (speed != null) 'speed': speed,
      'category': 'luxury',
    };

    // Use emitWithAck to get the server response
    emitWithAck(
      'updateLocation', //
      payload,
      ack: (response) {
        if (response is Map && response['status'] == 'success') {
          // Success, location updated.
          print(
            "Location update acknowledged by server.${response}",
          ); // Can be too noisy
        } else {
          // Handle failure
          print('Location update failed: ${response?['message']}');
        }
      },
    );
  }

  // --- Emitters for Emergency Room ---
  void joinEmergencyRoom(String emergencyId) {
    print("Joining emergency room: emergency:$emergencyId");
    // Backend expects: socket.emit('emergency:join', { id: emergencyId })
    emitWithAck(
      'emergency:join',
      {'id': emergencyId},
      ack: (response) {
        print("Joined emergency room response: $response");
      },
    );
  }

  void leaveEmergencyRoom(String emergencyId) {
    // If backend supports explicit leave
    // emit('emergency:leave', {'id': emergencyId});
    print("Leaving emergency room: $emergencyId (Local logic)");
  }

  // --- END MODIFIED updateDriverLocation METHOD ---

  void _handleIncomingChatMessage(dynamic data) {
    try {
      // 1. Notify ChatController for global unread count
      if (Get.isRegistered<ChatController>()) {
        final chatController = ChatController.instance;
        chatController.handleIncomingMessage(data);
      }

      // 2. Notify any active screens listening to specific chats
      // (e.g., if the user is currently looking at a chat screen)
      for (var listener in List.from(_chatMessageListeners)) {
        try {
          listener(data);
        } catch (e) {
          print("WS Error in chat listener: $e");
        }
      }
    } catch (e) {
      print("WS Error handling chat message: $e");
    }
  }

  // --- 2. ADD NEW REGISTRATION METHODS ---
  void registerCashPaymentPendingListener(Function(dynamic) listener) {
    _cashPaymentPendingListeners.add(listener);
    print(
      "WebSocketService: Registered cash_payment:pending listener. Count: ${_cashPaymentPendingListeners.length}",
    );
  }

  void unregisterCashPaymentPendingListener(Function(dynamic) listener) {
    _cashPaymentPendingListeners.remove(listener);
  }

  void registerPaymentConfirmedListener(Function(dynamic) listener) {
    _paymentConfirmedListeners.add(listener);
    print(
      "WebSocketService: Registered payment:confirmed listener. Count: ${_paymentConfirmedListeners.length}",
    );
  }

  void unregisterPaymentConfirmedListener(Function(dynamic) listener) {
    _paymentConfirmedListeners.remove(listener);
  }

  void registerWalletUpdateListener(Function(dynamic) listener) {
    _walletUpdateListeners.add(listener);
  }

  void unregisterWalletUpdateListener(Function(dynamic) listener) {
    _walletUpdateListeners.remove(listener);
  }

  void registerPaymentProcessedListener(Function(dynamic) listener) {
    _paymentProcessedListeners.add(listener);
  }

  void unregisterPaymentProcessedListener(Function(dynamic) listener) {
    _paymentProcessedListeners.remove(listener);
  }

  // --- Listener Registration Methods ---
  void registerChatListener(Function(dynamic) listener) {
    _chatMessageListeners.add(listener);
    print(
      "WebSocketService: Registered chat message listener. Count: ${_chatMessageListeners.length}",
    );
  }

  void unregisterChatListener(Function(dynamic) listener) {
    _chatMessageListeners.remove(listener);
    print(
      "WebSocketService: Unregistered chat message listener. Count: ${_chatMessageListeners.length}",
    );
  }

  void registerSentListener(Function(dynamic) listener) {
    _sentConfirmationListeners.add(listener);
    print(
      "WebSocketService: Registered sent confirmation listener. Count: ${_sentConfirmationListeners.length}",
    );
  }

  void unregisterSentListener(Function(dynamic) listener) {
    _sentConfirmationListeners.remove(listener);
    print(
      "WebSocketService: Unregistered sent confirmation listener. Count: ${_sentConfirmationListeners.length}",
    );
  }

  void registerEmergencyMessageListener(Function(dynamic) listener) {
    _emergencyMessageListeners.add(listener);
  }

  void unregisterEmergencyMessageListener(Function(dynamic) listener) {
    _emergencyMessageListeners.remove(listener);
  }

  void registerEmergencyTypingListener(Function(dynamic) listener) {
    _emergencyTypingListeners.add(listener);
  }

  void unregisterEmergencyTypingListener(Function(dynamic) listener) {
    _emergencyTypingListeners.remove(listener);
  }

  // --- Setup for All Event Listeners ---
  void _setupEventListeners() {
    if (_socket == null) return;
    print("Setting up WebSocket event listeners...");

    _socket!.onConnect((_) {
      print('WebSocket Connected: ${_socket!.id}');
      isConnected.value = true;
      _reconnectAttempts = 0;
      _reconnectTimer?.cancel();
    });

    _socket!.onDisconnect((reason) {
      print('WebSocket Disconnected: $reason');
      isConnected.value = false;
      if (_cachedToken != null) {
        // Only attempt reconnect if we should be logged in
        if (reason == 'io server disconnect') {
          print("Disconnected by server (likely auth error).");
          _handleAuthError();
        } else if (reason == 'transport close' ||
            reason == 'ping timeout' ||
            reason == 'transport error') {
          print("Unexpected disconnect ($reason). Attempting reconnect...");
          _attemptReconnect();
        } else {
          print("WebSocket disconnected: $reason. Not auto-reconnecting.");
          _reconnectAttempts = 0;
          _reconnectTimer?.cancel();
        }
      } else {
        print("WebSocket disconnected while logged out.");
        _reconnectAttempts = 0;
        _reconnectTimer?.cancel();
      }
    });

    _socket!.onConnectError((data) {
      print('WebSocket Connection Error: $data');
      isConnected.value = false;
      final errorString = data.toString().toLowerCase();
      // Auth errors during connection (e.g., invalid token in query)
      if (errorString.contains('authentication') ||
          errorString.contains('unauthorized') ||
          errorString.contains('token') ||
          errorString.contains('bad request') || // Often used for bad queries
          errorString.contains('xhr poll error')) {
        _handleAuthError();
      } else {
        _attemptReconnect();
      }
    });

    _socket!.onError((data) {
      print('WebSocket Generic Error: $data');
      isConnected.value = false;
      _attemptReconnect(); // Attempt to reconnect on generic errors
    });

    // --- App-Specific Event Listeners ---
    _listen('notification:new', (data) {
      print('[WebSocket Received] notification:new -> $data');
      try {
        final notificationController = NotificationController.instance;
        notificationController.handleNewNotification(data);
      } catch (e) {
        print(
          "Error finding or calling NotificationController for notification:new : $e",
        );
      }
    });

    // 1. Handle Authentication Errors (Server -> Client)
    _listen('auth_error', (data) {
      print('[WebSocket Received] auth_error -> $data');
      // Payload example: { "message": "Authentication required", "code": "AUTH_REQUIRED" }

      String message = "Authentication error";
      if (data is Map) {
        message = data['message'] ?? "Session expired";
      }

      // Handle logout logic
      _handleAuthError();
      // Note: _handleAuthError already disconnects and redirects to login
    });

    // 2. Handle Generic Errors (Server -> Client)
    _listen('error', (data) {
      print('[WebSocket Received] error -> $data');
      // Payload example: { "message": "Invalid payload", "details": { ... } }

      String title = "Error";
      String message = "An unexpected error occurred";

      if (data is Map) {
        message = data['message'] ?? message;
        if (data['code'] != null) {
          title = "Error (${data['code']})";
        }
      } else if (data is String) {
        message = data;
      }

      // Show error to user so they aren't left wondering why nothing happened
      THelperFunctions.showErrorSnackBar(title, message);
    });

    _listen('trip:auto_reconnected', (data) async {
      print('[WS Rcvd] trip:auto_reconnected -> $data');

      if (data is! Map<String, dynamic>) return;

      final tripId = data['tripId'];
      if (tripId == null) return;

      // Check if we are already handling this trip to avoid loops
      bool isRiderActive = false;
      if (Get.isRegistered<RideController>()) {
        isRiderActive = Get.find<RideController>().rideId.value == tripId;
      }

      bool isDriverActive = false;
      if (Get.isRegistered<TripManagementController>()) {
        final driverController = Get.find<TripManagementController>();
        isDriverActive = driverController.activeTrip.value?.id == tripId;
      }

      // If UI is already showing this trip, do nothing
      if (isRiderActive || isDriverActive) {
        print(
          "WS: Already restored trip $tripId. Ignoring auto-reconnect event.",
        );
        return;
      }

      print(
        "WS: Detected active trip $tripId from socket. Forcing UI restore...",
      );

      // Determine User Role to call the right controller
      String userRole = 'client'; // Default
      if (Get.isRegistered<ClientData>(tag: 'currentUser')) {
        userRole = Get.find<ClientData>(tag: 'currentUser').role;
      }

      // Fetch full details from API because socket payload is too small (missing driver info, path, etc)
      // We reuse the RideService logic meant for Splash Screen
      try {
        final rideService = RideService.instance;
        final response = await rideService.reconnectToTrip(tripId, userRole);

        if (response.status == 'success' && response.data != null) {
          if (userRole == 'client') {
            final rideData = RiderReconnectData.fromJson(response.data!);
            final rideController = Get.put(RideController());
            await rideController.restoreRideState(rideData);
            THelperFunctions.showSuccessSnackBar(
              'Synced',
              'Trip restored from server.',
            );
          } else if (userRole == 'driver') {
            final driverData = DriverReconnectData.fromJson(response.data!);
            final tripController = Get.put(TripManagementController());
            await tripController.restoreDriverRideState(driverData);
            THelperFunctions.showSuccessSnackBar(
              'Synced',
              'Trip restored from server.',
            );
          }
        }
      } catch (e) {
        print("WS: Error auto-restoring trip from socket event: $e");
      }
    });

    _listen('trip:peer_reconnected', (data) {
      print('[WS Rcvd] trip:peer_reconnected -> $data');
      final userType = data['userType'] ?? 'The other party';
      THelperFunctions.showSnackBar('$userType has reconnected.');
    });

    _listen('chat:newMessage', (data) {
      print('[WS Rcvd] chat:newMessage -> $data');
      try {
        // Notify ChatController for global count
        final chatController = ChatController.instance;
        chatController.handleIncomingMessage(data);

        // Also notify active MessageScreen if any
        for (var listener in List.from(_chatMessageListeners)) {
          try {
            listener(data);
          } catch (e) {
            print("WS Error in chat:newMessage listener: $e");
          }
        }
      } catch (e) {
        print(
          "WS Error finding/calling ChatController for chat:newMessage : $e",
        );
      }
    });

    _listen('chat:directMessage', (data) {
      print('[WS Rcvd] chat:directMessage -> $data');
      // Reuse the same handler since the payload structure is identical
      _handleIncomingChatMessage(data);
    });

    _listen('chat:sent', (data) {
      print('[WebSocket Received] chat:sent -> $data');
      // Notify all registered listeners
      for (var listener in List.from(_sentConfirmationListeners)) {
        try {
          listener(data);
        } catch (e) {
          print("Error in chat:sent listener: $e");
        }
      }
    });

    _listen('ride:searching', (data) {
      print('[WS Rcvd] ride:searching -> $data');
      if (data is Map<String, dynamic> && data['tripId'] != null) {
        try {
          if (Get.isRegistered<RideController>()) {
            final rideController = Get.find<RideController>();
            rideController.handleRideSearching(data);
          }
        } catch (e) {
          print("WS Error handling ride:searching: $e");
        }
      }
    });

    // Driver Ride Events
    _listen('ride:request', (data) {
      print('[WebSocket Received] ride:request -> $data');
      if (data is Map<String, dynamic> && data['rideId'] != null) {
        try {
          final tripController = Get.find<TripManagementController>();

          LatLng parseLatLng(dynamic locationData, LatLng fallback) {
            if (locationData is Map) {
              // Try parsing as double, then as int, then as String
              final lat =
                  (locationData['latitude'] as num?)?.toDouble() ??
                  double.tryParse(locationData['latitude'].toString());
              final lon =
                  (locationData['longitude'] as num?)?.toDouble() ??
                  double.tryParse(locationData['longitude'].toString());

              if (lat != null && lon != null) {
                return LatLng(lat, lon);
              }
            }
            print(
              "Warning: Could not parse LatLng from ride:request payload. Using fallback.",
            );
            return fallback;
          }

          //  Look for 'dropoffLocation' first ---
          final dynamic dropoffData =
              data['dropoffLocation'] ?? data['destinationLocation'];
          LatLng destLoc = parseLatLng(
            dropoffData, // Use the new variable
            const LatLng(6.42, 3.42),
          );

          LatLng pickupLoc = parseLatLng(
            data['pickupLocation'],
            const LatLng(6.52, 3.37),
          );

          final expiresAtTimestamp =
              (data['expiresAt'] as num?)?.toInt() ??
              DateTime.now()
                  .add(const Duration(seconds: 15))
                  .millisecondsSinceEpoch;
          final expiresAt = DateTime.fromMillisecondsSinceEpoch(
            expiresAtTimestamp,
          );

          final request = TripRequest(
            id: data['rideId'],
            riderId: data['riderId'] ?? '?',
            riderName: data['riderName'] ?? 'Rider',
            riderPhone: data['riderPhone'] ?? '',
            riderRating: (data['riderRating'] as num?)?.toDouble() ?? 4.0,
            pickupLocation: pickupLoc,
            destinationLocation: destLoc,
            pickupAddress:
                data['currentLocationName'] ??
                'Unknown Pickup', // Mapped from currentLocationName
            destinationAddress:
                data['destinationName'] ?? 'Unknown Destination',
            requestTime:
                DateTime.tryParse(data['requestTime'] ?? '') ?? DateTime.now(),
            estimatedFare: (data['price'] as num?)?.toDouble() ?? 0.0,
            estimatedDistance: (data['distanceKm'] as num?)?.toDouble() ?? 0.0,
            estimatedDuration:
                (data['estimatedDuration'] as num?)?.toInt() ?? 0,
            rideType:
                data['category'] ?? 'Standard', // <-- MODIFIED: Use 'category'
            seats: (data['seats'] as num?)?.toInt() ?? 4, // <-- ADDED
            expiresAt: expiresAt, // <-- ADDED
          );
          tripController.showTripRequest(request);
        } catch (e) {
          print(
            "Error handling ride:request : $e. Controller might not be ready or data invalid.",
          );
        }
      } else {
        print("Invalid data format for ride:request");
      }
    });

    _listen('ride:accepted:ack', (data) {
      print('[WebSocket Received] ride:accepted:ack -> $data');
      // This is the acknowledgment that the driver's 'ride:accept' HTTP POST was processed.
      // The main logic (getting chatId) is now handled by the HTTP response.
      // We can use this to show a snackbar if needed.
      if (data is Map && data['message'] != null) {
        // This will show "Ride accepted successfully" from the backend
        THelperFunctions.showSuccessSnackBar("Success", data['message']);
      }
    });
    _listen('ride:cancelled', (data) {
      print('[WebSocket Received] ride:cancelled -> $data');
      if (data is Map<String, dynamic> && data['rideId'] != null) {
        try {
          // This event could be for either rider or driver, check both controllers
          if (Get.isRegistered<TripManagementController>()) {
            final tripController = Get.find<TripManagementController>();
            String reason = data['message'] ?? 'Client cancelled the ride';
            String cancelledRideId = data['rideId'];
            if (tripController.currentTripRequest.value?.id ==
                    cancelledRideId ||
                tripController.activeTrip.value?.id == cancelledRideId) {
              print(
                "Notifying TripManagementController of cancellation for ride ID: $cancelledRideId",
              );
              tripController.cancelTrip(reason);
            }
          }
          if (Get.isRegistered<RideController>()) {
            final rideController = Get.find<RideController>();
            String message = data['message'] ?? 'Your ride was cancelled.';
            String cancelledRideId = data['rideId'];
            if (rideController.rideId.value == cancelledRideId) {
              print("Notifying RideController of cancellation confirmation.");
              rideController.handleCancellationConfirmed(message);
            }
          }
        } catch (e) {
          print("Error handling ride:cancelled : $e");
        }
      } else {
        print("Invalid data format for ride:cancelled");
      }
    });

    // Client Ride Events
    _listen('ride:accepted', (data) {
      print('[WS Rcvd] ride:accepted -> $data');
      if (data is Map<String, dynamic>) {
        try {
          final rideController = Get.find<RideController>();

          final driverData = data['driver'] as Map<String, dynamic>? ?? {};
          final vehicleData =
              driverData['vehicleDetails'] as Map<String, dynamic>? ?? {};

          final String driverName =
              driverData['name'] ?? data['driverName'] ?? 'Driver';
          final String driverPhone =
              driverData['phoneNumber'] ?? data['driverPhone'] ?? '';
          final String carModel = vehicleData['make'] ?? 'Vehicle';
          final String plateNumber = vehicleData['licensePlate'] ?? 'N/A';
          final String eta = data['eta'] ?? '...';

          // --- FIX: Safe Rating Parsing ---
          double driverRating = 4.5;
          final rawRating = driverData['rating'];

          if (rawRating is num) {
            driverRating = rawRating.toDouble();
          } else if (rawRating is Map) {
            // If rating is an object { average: null, ... }
            final avg = rawRating['average'];
            if (avg is num) {
              driverRating = avg.toDouble();
            }
          }
          // --------------------------------

          LatLng driverLoc =
              rideController.pickupLocation.value ?? const LatLng(6.52, 3.37);
          if (data['driverLocation'] is Map) {
            final lat = (data['driverLocation']['latitude'] as num?)
                ?.toDouble();
            final lng = (data['driverLocation']['longitude'] as num?)
                ?.toDouble();
            if (lat != null && lng != null) {
              driverLoc = LatLng(lat, lng);
            }
          }

          final driverDetails = Driver(
            id: data['driverId'] ?? '',
            name: driverName,
            rating: driverRating,
            carModel: carModel,
            plateNumber: plateNumber,
            phoneNumber: driverPhone,
            eta: eta,
            location: driverLoc,
          );

          final chatId = data['chatId'] as String? ?? '';
          rideController.handleRideAccepted(driverDetails, chatId);
        } catch (e) {
          print("WS Error handling ride:accepted : $e");
        }
      }
    });

    _listen('ride:rejected', (data) {
      print('[WS Rcvd] ride:rejected -> $data');
      if (data is Map<String, dynamic>) {
        try {
          final rideController = Get.find<RideController>();
          String message =
              data['message'] ?? 'Driver rejected. Finding another...';
          rideController.handleRideRejected(message);
        } catch (e) {
          print("WS Error handling ride:rejected : $e");
        }
      } else {
        print("WS: Invalid data format for ride:rejected");
      }
    });

    _listen('ride:cancellationConfirmed', (data) {
      print('[WS Rcvd] ride:cancellationConfirmed -> $data');
      if (data is Map<String, dynamic>) {
        try {
          final rideController = Get.find<RideController>();
          String message = data['message'] ?? 'Ride cancelled successfully.';
          rideController.handleCancellationConfirmed(message);
        } catch (e) {
          print("WS Error handling ride:cancellationConfirmed : $e");
        }
      } else {
        print("WS: Invalid data format for ride:cancellationConfirmed");
      }
    });

    _listen('ride:started', (data) {
      print('[WS Rcvd] ride:started -> $data');
      if (data is Map<String, dynamic>) {
        try {
          final rideController = Get.find<RideController>();
          rideController.handleRideStarted(data); // <-- PASS THE DATA
        } catch (e) {
          print("WS Error handling ride:started : $e");
        }
      } else {
        print("WS: Invalid data format for ride:started");
      }
    });
    _listen('driver:location:live', (data) {
      // --- DEBUG LOGGING ---
      print('[WS Rcvd] driver:location:live -> $data');

      if (data is Map<String, dynamic> &&
          data['latitude'] != null &&
          data['longitude'] != null) {
        try {
          // Parse coordinates safely
          final lat = (data['latitude'] as num).toDouble();
          final lng = (data['longitude'] as num).toDouble();

          // Log for debugging
          print("Updating Map Marker to: $lat, $lng");
          print("Location update acknowledged by server.${data}");

          // Find controller and update
          if (Get.isRegistered<RideController>()) {
            Get.find<RideController>().updateDriverLocationOnMap(
              LatLng(lat, lng),
            );
          } else {
            print("RideController not found! Cannot update map.");
          }
        } catch (e) {
          print("Error updating driver location: $e");
        }
      } else {
        print("Invalid data format for driver:location:live");
      }
    });

    _listen('ride:completed', (data) {
      print('[WS Rcvd] ride:completed -> $data');
      if (data is Map<String, dynamic>) {
        try {
          final rideController = Get.find<RideController>();
          // Pass the entire data map to the controller
          rideController.handleRideCompleted(data);
        } catch (e) {
          print("WS Error handling ride:completed : $e");
        }
      } else {
        print("WS: Invalid data format for ride:completed");
      }
    });

    _listen('cash_payment:pending', (data) {
      print('[WS Rcvd] cash_payment:pending -> $data');
      // This event is primarily for the DRIVER
      for (var listener in List.from(_cashPaymentPendingListeners)) {
        try {
          listener(data);
        } catch (e) {
          print("WS Error in cash_payment:pending listener: $e");
        }
      }
    });

    _listen('payment:confirmed', (data) {
      print('[WS Rcvd] payment:confirmed -> $data');
      // This event is for BOTH rider and driver
      for (var listener in List.from(_paymentConfirmedListeners)) {
        try {
          listener(data);
        } catch (e) {
          print("WS Error in payment:confirmed listener: $e");
        }
      }
    });

    // Event: wallet:update
    // Triggered when balance changes (trip earning, withdrawal, etc.)
    _listen('wallet:update', (data) {
      print('[WS Rcvd] wallet:update -> $data');
      for (var listener in List.from(_walletUpdateListeners)) {
        try {
          listener(data);
        } catch (e) {
          print("WS Error in wallet:update listener: $e");
        }
      }
    });

    // Event: payment:processed
    // Triggered when a payout/transfer is confirmed by Paystack
    _listen('payment:processed', (data) {
      print('[WS Rcvd] payment:processed -> $data');
      for (var listener in List.from(_paymentProcessedListeners)) {
        try {
          listener(data);
        } catch (e) {
          print("WS Error in payment:processed listener: $e");
        }
      }
    });

    // --- CALL EVENTS ---
    _listen('call:incoming', (data) {
      print('[WS] Incoming call: $data');
      if (Get.isRegistered<CallController>()) {
        Get.find<CallController>().handleIncomingCall(data);
      }
    });

    _listen('call:answered', (data) {
      print('[WS] Call answered: $data');
      if (Get.isRegistered<CallController>()) {
        Get.find<CallController>().handleCallAccepted(data);
      }
    });

    _listen('call:rejected', (data) {
      print('[WS] Call rejected: $data');
      if (Get.isRegistered<CallController>()) {
        Get.find<CallController>().handleCallRejected(data);
      }
    });

    _listen('call:ended', (data) {
      print('[WS] Call ended: $data');
      if (Get.isRegistered<CallController>()) {
        Get.find<CallController>().handleCallEnded(data);
      }
    });
    // --- Emergency Events ---
    _listen('emergency:newMessage', (data) {
      print('[WS Rcvd] emergency:newMessage -> $data');
      for (var listener in List.from(_emergencyMessageListeners)) {
        try {
          listener(data);
        } catch (e) {
          print(e);
        }
      }
    });

    _listen('emergency:typing', (data) {
      // print('[WS Rcvd] emergency:typing');
      for (var listener in List.from(_emergencyTypingListeners)) {
        try {
          listener(data);
        } catch (e) {
          print(e);
        }
      }
    });
    // --- END MODIFIED ---
    // --- End App-Specific Listeners ---

    print("WebSocket event listeners set up.");
  }
}
