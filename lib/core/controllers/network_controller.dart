import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

class NetworkController extends GetxController {
  static NetworkController get instance => Get.find();

  final Connectivity _connectivity = Connectivity();
  late StreamSubscription<List<ConnectivityResult>> _connectivitySubscription;
  final RxBool isConnected = true.obs;

  /// Debounce timer to avoid acting on brief connectivity flickers
  Timer? _debounceTimer;

  /// Periodic check to ensure status stays accurate
  Timer? _periodicCheckTimer;

  /// Tracks last known raw connectivity status (before debounce)
  bool _lastRawConnectivityStatus = true;

  /// Debug: tracks validation attempts
  int _validationAttempts = 0;

  @override
  void onInit() {
    super.onInit();
    _setupConnectivityListener();
    _checkInitialConnection();

    // Periodic verification every 5 seconds with HTTP validation
    // This catches edge cases in Release builds where connectivity_plus fails
    _periodicCheckTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) => _performPeriodicCheck(),
    );

    debugPrint('[NetworkController] Initialized with 5-second periodic checks');
  }

  /// Setup stream listener for real-time connectivity changes
  void _setupConnectivityListener() {
    try {
      _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
        _handleConnectivityChanged,
        onError: (error) {
          debugPrint(
            '[NetworkController] Stream error: $error - assuming connected',
          );
          // On stream error, assume we have connection (better UX)
          isConnected.value = true;
        },
      );
    } catch (e) {
      debugPrint('[NetworkController] Failed to setup listener: $e');
      isConnected.value = true;
    }
  }

  /// Check initial connection state
  Future<void> _checkInitialConnection() async {
    try {
      final results = await _connectivity.checkConnectivity();
      _lastRawConnectivityStatus =
          results.isNotEmpty && !results.contains(ConnectivityResult.none);

      debugPrint(
        '[NetworkController] Initial check: $_lastRawConnectivityStatus',
      );

      if (_lastRawConnectivityStatus) {
        // If raw connectivity says yes, validate with HTTP
        await _validateWithHttpPing();
      } else {
        // If raw connectivity says no, update immediately
        _updateConnectionStatus(false);
      }
    } catch (e) {
      debugPrint('[NetworkController] Initial check failed: $e');
      isConnected.value = true;
    }
  }

  /// Handle real-time connectivity changes from stream
  void _handleConnectivityChanged(List<ConnectivityResult> results) {
    final hasRawConnection =
        results.isNotEmpty && !results.contains(ConnectivityResult.none);

    debugPrint(
      '[NetworkController] Raw connectivity changed: $hasRawConnection',
    );
    _lastRawConnectivityStatus = hasRawConnection;

    if (!hasRawConnection) {
      // If no connectivity, update immediately (no debounce needed)
      _updateConnectionStatus(false);
    } else {
      // If connectivity available, validate before updating
      _validateWithHttpPing();
    }
  }

  /// Periodic validation combining native connectivity + HTTP check
  Future<void> _performPeriodicCheck() async {
    try {
      final results = await _connectivity.checkConnectivity();
      final hasRawConnection =
          results.isNotEmpty && !results.contains(ConnectivityResult.none);

      _validationAttempts++;

      // Log every 10th check to avoid spam
      if (_validationAttempts % 10 == 0) {
        debugPrint(
          '[NetworkController] Periodic check #$_validationAttempts: Raw=$hasRawConnection, Current=${isConnected.value}',
        );
      }

      if (!hasRawConnection) {
        _updateConnectionStatus(false);
      } else if (isConnected.value == false) {
        // If we thought we were offline but now have connectivity, validate
        await _validateWithHttpPing();
      }
      // If both are true, no change needed
    } catch (e) {
      if (_validationAttempts % 10 == 0) {
        debugPrint('[NetworkController] Periodic check error: $e');
      }
    }
  }

  /// Validate actual internet connectivity via HTTP ping
  /// Uses public endpoints as fallback (doesn't depend on your API)
  Future<void> _validateWithHttpPing() async {
    try {
      // Try a lightweight HTTP HEAD check to google.com
      // Most reliable for detecting actual internet connectivity
      final response = await http
          .head(
            Uri.parse('https://www.google.com'),
            headers: {'User-Agent': 'SarriRide/1.0.0'},
          )
          .timeout(const Duration(seconds: 5));

      final isOnline = response.statusCode < 500; // Any 2xx-4xx is online
      debugPrint(
        '[NetworkController] HTTP validation: $isOnline (${response.statusCode})',
      );
      _updateConnectionStatus(isOnline);
    } catch (e) {
      // If HTTP check times out or fails, fall back to raw connectivity
      debugPrint(
        '[NetworkController] HTTP validation failed: $e - using raw status',
      );
      _updateConnectionStatus(_lastRawConnectivityStatus);
    }
  }

  /// Update connection status with smart debounce logic
  void _updateConnectionStatus(bool hasConnection) {
    // Cancel any pending debounce timer
    _debounceTimer?.cancel();

    if (!hasConnection) {
      // Wait 3s before declaring offline to avoid false positives
      // (handles network handovers, WiFi-to-cellular, etc.)
      _debounceTimer = Timer(const Duration(seconds: 3), () {
        if (isConnected.value != false) {
          debugPrint('[NetworkController] ⚠️  Status changed: OFFLINE');
          isConnected.value = false;
        }
      });
    } else {
      // Online: update immediately for better UX
      if (isConnected.value != true) {
        debugPrint('[NetworkController] ✅ Status changed: ONLINE');
        isConnected.value = true;
      }
    }
  }

  @override
  void onClose() {
    _debounceTimer?.cancel();
    _periodicCheckTimer?.cancel();
    _connectivitySubscription.cancel();
    debugPrint('[NetworkController] Disposed');
    super.onClose();
  }
}

/// A slim, non-intrusive connectivity banner.
/// Wrap your app content with this in GetMaterialApp's builder.
class ConnectivityBanner extends StatelessWidget {
  final Widget child;
  const ConnectivityBanner({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Stack(
        children: [
          // The actual app content
          child,

          // The offline banner — slides down from top when offline
          Obx(() {
            final isConnected = NetworkController.instance.isConnected.value;
            return AnimatedPositioned(
              duration: const Duration(milliseconds: 350),
              curve: Curves.easeInOut,
              top: isConnected ? -60 : 0,
              left: 0,
              right: 0,
              child: Material(
                color: Colors.transparent,
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.only(
                    top: MediaQuery.of(context).padding.top,
                    bottom: 8,
                    left: 16,
                    right: 16,
                  ),
                  decoration: const BoxDecoration(
                    color: Color(0xFFE53935), // Material Red 600
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.wifi_off_rounded,
                        color: Colors.white,
                        size: 16,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'No internet connection',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          decoration: TextDecoration.none,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
