// lib/core/services/websocket_service.dart

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

  // --- MODIFIED updateDriverLocation METHOD ---
  void updateDriverLocation({
    required double latitude,
    required double longitude,
    required String availabilityStatus,
    required String state, // Make state required
  }) {
    // Payload must match the documentation
    final payload = {
      'latitude': latitude,
      'longitude': longitude,
      'availabilityStatus': availabilityStatus,
      'state': state, // Add the state field
    };

    // Use emitWithAck to get the server response
    emitWithAck(
      'updateLocation', //
      payload,
      ack: (response) {
        if (response is Map && response['status'] == 'success') {
          // Success, location updated.
          // print(
          //   "Location update acknowledged by server.${response}",
          // ); // Can be too noisy
        } else {
          // Handle failure
          print('Location update failed: ${response?['message']}');
        }
      },
    );
  }
  // --- END MODIFIED updateDriverLocation METHOD ---

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
      if (data is Map<String, dynamic> &&
          data['driverId'] != null &&
          data['tripId'] != null) {
        try {
          final rideController = Get.find<RideController>();

          // --- MODIFICATION: Parse the nested 'driver' object ---
          final driverData = data['driver'] as Map<String, dynamic>? ?? {};
          final vehicleData =
              driverData['vehicleDetails'] as Map<String, dynamic>? ?? {};

          // Use driverData for name, vehicle, etc.
          final String driverName =
              driverData['name'] ?? data['driverName'] ?? 'Driver';
          final String carModel = vehicleData['make'] ?? 'Vehicle';
          final String plateNumber = vehicleData['licensePlate'] ?? 'N/A';
          final double driverRating =
              (driverData['rating'] as num?)?.toDouble() ??
              4.5; // Assuming rating might be in 'driver' obj
          final String eta =
              data['eta'] ?? '...'; // ETA is still at root in example

          // Get driver location (fallback to pickup)
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
          // --- END MODIFICATION ---

          final driverDetails = Driver(
            name: driverName,
            rating: driverRating,
            carModel: carModel,
            plateNumber: plateNumber,
            eta: eta,
            location: driverLoc,
          );

          // Get chatId from the root
          final chatId = data['chatId'] as String? ?? '';
          if (chatId.isEmpty) {
            print("WS Warning: ride:accepted missing chatId.");
          }

          rideController.handleRideAccepted(driverDetails, chatId);
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
          rideController.handleRideStarted();
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
          rideController.updateDriverLocationOnMap(LatLng(lat, lng));
        } catch (e) {
          // Silently fail if ride controller isn't registered
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
          rideController.handleRideCompleted(finalFare);
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
}
