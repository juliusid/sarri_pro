import 'dart:async';
import 'dart:convert';
import 'dart:math'; // For jitter
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sarri_ride/features/communication/controllers/chat_controller.dart';
import 'package:sarri_ride/features/notifications/controllers/notification_controller.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:google_maps_flutter/google_maps_flutter.dart';

// --- Local Imports ---
import 'package:sarri_ride/core/services/http_service.dart'; //
import 'package:sarri_ride/config/api_config.dart'; //
import 'package:sarri_ride/utils/helpers/helper_functions.dart'; //
import 'package:sarri_ride/features/ride/controllers/ride_controller.dart'; //
import 'package:sarri_ride/features/driver/controllers/trip_management_controller.dart'; //
import 'package:sarri_ride/features/authentication/screens/login/login_screen_getx.dart'; //
import 'package:sarri_ride/features/driver/controllers/trip_management_controller.dart'
    show TripRequest; //
import 'package:sarri_ride/features/ride/widgets/driver_info_card.dart'
    show Driver; //
// Add imports for ChatController, NotificationController, etc. when created

class WebSocketService extends GetxService {
  static WebSocketService get instance => Get.find();

  IO.Socket? _socket;
  final RxBool isConnected = false.obs;
  String? _cachedToken;

  int _reconnectAttempts = 0;
  final int _maxReconnectAttempts = 5;
  final Duration _initialReconnectDelay = const Duration(seconds: 2);
  Timer? _reconnectTimer;

  // --- NEW: Listener Lists ---
  final List<Function(dynamic)> _chatMessageListeners = [];
  final List<Function(dynamic)> _sentConfirmationListeners = [];

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

  void connect() {
    // --- CORRECTED CHECK: Only check if already connected ---
    if (_socket != null && _socket!.connected) {
      print('WebSocket connection attempt skipped: Already connected.');
      return;
    }
    // --- END CORRECTION ---

    if (_socket != null) {
      disconnect(); // Disconnect previous instance if exists but not connected
    }

    final httpService = HttpService.instance;
    _cachedToken = httpService.accessToken;

    if (_cachedToken == null) {
      print('WebSocket Error: Cannot connect without authentication token.');
      return;
    }

    final String socketUrl = ApiConfig.webSocketUrl;
    print('Attempting to connect WebSocket to $socketUrl');

    try {
      _socket = IO.io(socketUrl, <String, dynamic>{
        'transports': ['websocket'],
        'autoConnect': false, // Connect manually
        'forceNew': true,
        'auth': {'token': _cachedToken},
        'reconnection': false, // Handle manually
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

    // --- CORRECTED CHECK: Only check if connected ---
    if (_socket != null && _socket!.connected) {
      print("Reconnect attempt skipped: Already connected.");
      _reconnectAttempts = 0; // Reset if somehow connected
      return;
    }
    // --- END CORRECTION ---

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
        // --- CORRECTED CHECK: Check connected status again ---
        if (_socket != null && !_socket!.connected && _cachedToken != null) {
          print(
            "Retrying WebSocket connection (Attempt $_reconnectAttempts)...",
          );
          // Don't call connect() directly as it force-news, just connect the existing instance
          _socket?.connect(); // Try connecting the existing instance
        } else if (_cachedToken == null) {
          print("Reconnect cancelled: User logged out during delay.");
          _reconnectAttempts = 0;
        } else {
          print(
            "Reconnect cancelled: Socket state changed during delay (connected).",
          );
          _reconnectAttempts = 0;
        }
        // --- END CORRECTION ---
      });
    } else {
      print('WebSocket Max Reconnect Attempts Reached.');
      _reconnectAttempts = 0;
      // WidgetsBinding.instance.addPostFrameCallback((_) { // THelperFunctions.showSnackBar("Unable to connect to real-time service."); });
    }
  }

  void _handleAuthError() {
    print('WebSocket Auth Error detected. Clearing tokens and logging out.');
    disconnect();
    final httpService = HttpService.instance;
    httpService.clearTokens();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Get.offAll(() => const LoginScreenGetX());
      THelperFunctions.showSnackBar("Session expired. Please log in again.");
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
          print('Handling failure for joinChatRoom $chatId');
        }
      },
    );
  }

  void leaveChatRoom(String chatId) {
    print("Leaving chat room: $chatId (No specific event in docs)");
  }

  void updateDriverLocation({
    required double latitude,
    required double longitude,
    required String state,
    required String availabilityStatus,
  }) {
    final payload = {
      'latitude': latitude,
      'longitude': longitude,
      'state': state,
      'availabilityStatus': availabilityStatus,
    };
    emitWithAck(
      'updateLocation',
      payload,
      ack: (response) {
        if (response is Map && response['status'] == 'success') {
          /* Success */
        } else {
          print('Handling failure for updateLocation');
        }
      },
    );
  }

  // --- NEW: Listener Registration Methods ---
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
        if (reason == 'io server disconnect') {
          print("Disconnected by server.");
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
      if (errorString.contains('authentication') ||
          errorString.contains('unauthorized') ||
          errorString.contains('token') ||
          errorString.contains('xhr poll error')) {
        _handleAuthError();
      } else {
        _attemptReconnect();
      }
    });

    _socket!.onError((data) {
      print('WebSocket Generic Error: $data');
      isConnected.value = false;
      _attemptReconnect();
    });

    // --- App-Specific Event Listeners ---
    _listen('notification:new', (data) {
      print('[WebSocket Received] notification:new -> $data');
      try {
        // --- Call NotificationController ---
        final notificationController =
            NotificationController.instance; // Use static getter
        notificationController.handleNewNotification(data);
        // --- End Call ---
      } catch (e) {
        // Handle cases where the controller might not be found (shouldn't happen with Get.put)
        print(
          "Error finding or calling NotificationController for notification:new : $e",
        );
      }
    });
    _listen('chat:newMessage', (data) {
      print('[WS Rcvd] chat:newMessage -> $data');
      try {
        // --- Notify ChatController for global count ---
        final chatController = ChatController.instance; // Use static getter
        chatController.handleIncomingMessage(data);
        // --- End Notify ---

        // Also notify active MessageScreen if any (existing logic)
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
    _listen('chat:sent', (data) {
      print('[WebSocket Received] chat:sent -> $data');
      // Notify all registered listeners
      for (var listener in List.from(_sentConfirmationListeners)) {
        // Iterate over a copy
        try {
          listener(data);
        } catch (e) {
          print("Error in chat:sent listener: $e");
        }
      }
    });
    // Driver Ride Events
    _listen('ride:request', (data) {
      print('[WebSocket Received] ride:request -> $data');
      if (data is Map<String, dynamic> && data['rideId'] != null) {
        try {
          // --- Use Get.find to ensure controller exists ---
          final tripController = Get.find<TripManagementController>();

          // --- Parse Payload ---
          LatLng parseLatLng(dynamic locationData, LatLng fallback) {
            /* ... (Parser logic as before) ... */
            if (locationData is Map &&
                locationData['latitude'] is num &&
                locationData['longitude'] is num) {
              return LatLng(
                (locationData['latitude'] as num).toDouble(),
                (locationData['longitude'] as num).toDouble(),
              );
            }
            // Add fallback for potential List format [lng, lat] or [lat, lng] if needed
            print(
              "Warning: Could not parse LatLng from ride:request payload for key. Using fallback.",
            );
            return fallback;
          }

          LatLng pickupLoc = parseLatLng(
            data['pickupLocation'],
            const LatLng(6.52, 3.37),
          );
          LatLng destLoc = parseLatLng(
            data['destinationLocation'],
            const LatLng(6.42, 3.42),
          );

          final request = TripRequest(
            id: data['rideId'],
            riderId: data['riderId'] ?? '?',
            riderName: data['riderName'] ?? 'Rider',
            riderPhone: data['riderPhone'] ?? '',
            riderRating: (data['riderRating'] as num?)?.toDouble() ?? 4.0,
            pickupLocation: pickupLoc,
            destinationLocation: destLoc,
            pickupAddress: data['pickupAddress'] ?? 'Unknown Pickup',
            destinationAddress:
                data['destinationAddress'] ?? 'Unknown Destination',
            requestTime:
                DateTime.tryParse(data['requestTime'] ?? '') ?? DateTime.now(),
            estimatedFare: (data['price'] as num?)?.toDouble() ?? 0.0,
            estimatedDistance: (data['distanceKm'] as num?)?.toDouble() ?? 0.0,
            estimatedDuration:
                (data['estimatedDuration'] as num?)?.toInt() ??
                0, // Ensure backend sends this
            rideType: data['rideType'] ?? 'Standard',
          );
          // --- Call Controller Method ---
          tripController.showTripRequest(request);
          // --- End Call ---
        } catch (e) {
          // Catch errors if controller not found or during data processing
          print(
            "Error handling ride:request : $e. Controller might not be ready or data invalid.",
          );
          // Optionally show a generic error to the user if critical
        }
      } else {
        print("Invalid data format for ride:request");
      }
    });
    _listen('ride:accepted:ack', (data) {
      print('[WebSocket Received] ride:accepted:ack -> $data');
      if (data is Map<String, dynamic>) {
        try {
          final tripController = Get.find<TripManagementController>();
          print(
            "Driver's ride acceptance acknowledged by server. Trip ID: ${data['tripId']}",
          );
          // Currently, _proceedWithAcceptedTrip is called within the acceptTripRequest's ack.
          // If backend ONLY sends this ack AFTER accept is processed, we don't need extra handling here.
          // If this ack contains crucial info (like chatId), parse it here and maybe call a specific method in tripController.
          // tripController.handleAcceptanceAcknowledgement(data); // Example call if needed
        } catch (e) {
          print("Error handling ride:accepted:ack : $e");
        }
      } else {
        print("Invalid data format for ride:accepted:ack");
      }
    });
    _listen('ride:cancelled', (data) {
      print('[WebSocket Received] ride:cancelled -> $data');
      if (data is Map<String, dynamic> && data['rideId'] != null) {
        try {
          final tripController = Get.find<TripManagementController>();
          String reason = data['message'] ?? 'Client cancelled the ride';
          String cancelledRideId = data['rideId'];

          // Check if this cancellation applies to the current request or active trip
          if (tripController.currentTripRequest.value?.id == cancelledRideId ||
              tripController.activeTrip.value?.id == cancelledRideId) {
            print("Handling cancellation for ride ID: $cancelledRideId");
            // Call the existing cancelTrip method, which handles UI and state reset
            tripController.cancelTrip(reason);
          } else {
            print(
              "Received ride:cancelled for an irrelevant ride ID ($cancelledRideId). Ignoring.",
            );
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
      if (data is Map<String, dynamic> &&
          data['driverId'] != null &&
          data['tripId'] != null) {
        try {
          // --- Use Get.find to ensure controller exists ---
          final rideController = Get.find<RideController>();

          // --- Parse Driver Details ---
          LatLng driverLoc =
              rideController.pickupLocation.value ??
              const LatLng(6.52, 3.37); // Default
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
            name: data['driverName'] ?? 'Driver',
            rating:
                (data['driverRating'] as num?)?.toDouble() ??
                4.5, // Check actual key
            carModel: data['carModel'] ?? 'Vehicle', // Check actual key
            plateNumber: data['plateNumber'] ?? 'N/A', // Check actual key
            eta: data['eta'] ?? '...', // Check actual key
            location: driverLoc,
          );
          final chatId = data['chatId'] as String? ?? '';
          if (chatId.isEmpty) {
            print("WS Warning: ride:accepted missing chatId.");
          }

          // --- Call Controller Method ---
          rideController.handleRideAccepted(driverDetails, chatId);
          // --- End Call ---
        } catch (e) {
          print(
            "WS Error handling ride:accepted : $e. Controller might not be ready or data invalid.",
          );
        }
      } else {
        print("WS: Invalid data format for ride:accepted");
      }
    });

    _listen('ride:rejected', (data) {
      print('[WS Rcvd] ride:rejected -> $data');
      if (data is Map<String, dynamic>) {
        try {
          final rideController = Get.find<RideController>();
          String message =
              data['message'] ?? 'Driver rejected. Finding another...';
          // --- Call Controller Method ---
          rideController.handleRideRejected(message);
          // --- End Call ---
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
          // --- Call Controller Method ---
          rideController.handleCancellationConfirmed(message);
          // --- End Call ---
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
        // Check if map, payload structure varies
        try {
          final rideController = Get.find<RideController>();
          // --- Call Controller Method ---
          rideController.handleRideStarted();
          // --- End Call ---
        } catch (e) {
          print("WS Error handling ride:started : $e");
        }
      } else {
        print("WS: Invalid data format for ride:started");
      }
    });

    _listen('ride:locationUpdated', (data) {
      // print('[WS Rcvd] ride:locationUpdated -> $data'); // Verbose
      if (data is Map<String, dynamic> &&
          data['latitude'] is num &&
          data['longitude'] is num) {
        try {
          final rideController = Get.find<RideController>();
          final lat = (data['latitude'] as num).toDouble();
          final lng = (data['longitude'] as num).toDouble();
          // --- Call Controller Method ---
          rideController.updateDriverLocationOnMap(LatLng(lat, lng));
          // --- End Call ---
        } catch (e) {
          print("WS Error handling ride:locationUpdated : $e");
        }
      } // Ignore invalid data silently
    });

    _listen('ride:completed', (data) {
      print('[WS Rcvd] ride:completed -> $data');
      if (data is Map<String, dynamic>) {
        try {
          final rideController = Get.find<RideController>();
          final finalFare =
              (data['finalFare'] as num?)?.toDouble() ??
              rideController.selectedRideType.value?.price.toDouble() ??
              0.0;
          // --- Call Controller Method ---
          rideController.handleRideCompleted(finalFare);
          // --- End Call ---
        } catch (e) {
          print("WS Error handling ride:completed : $e");
        }
      } else {
        print("WS: Invalid data format for ride:completed");
      }
    });
    // --- End App-Specific Listeners ---

    print("WebSocket event listeners set up.");
  }
} // End of WebSocketService class
