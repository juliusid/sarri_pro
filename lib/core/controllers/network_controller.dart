import 'dart:async';
import 'dart:io';
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

    // Periodic verification every 5 seconds
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
      _lastRawConnectivityStatus = !results.contains(ConnectivityResult.none);

      debugPrint(
        '[NetworkController] Initial check: $_lastRawConnectivityStatus',
      );

      // Always validate on init
      await _validateWithHttpPing();
    } catch (e) {
      debugPrint('[NetworkController] Initial check failed: $e');
      isConnected.value = true;
    }
  }

  /// Handle real-time connectivity changes from stream
  void _handleConnectivityChanged(List<ConnectivityResult> results) {
    final hasRawConnection = !results.contains(ConnectivityResult.none);

    debugPrint(
      '[NetworkController] Raw connectivity changed: $hasRawConnection',
    );
    _lastRawConnectivityStatus = hasRawConnection;

    // Do not blindly trust 'false' on iOS release due to known connectivity_plus bugs.
    // Always validate actual internet access.
    _validateWithHttpPing();
  }

  /// Periodic validation combining native connectivity + HTTP check
  Future<void> _performPeriodicCheck() async {
    try {
      final results = await _connectivity.checkConnectivity();
      _lastRawConnectivityStatus = !results.contains(ConnectivityResult.none);

      _validationAttempts++;

      if (_validationAttempts % 10 == 0) {
        debugPrint(
          '[NetworkController] Periodic check #$_validationAttempts: Raw=$_lastRawConnectivityStatus, Current=${isConnected.value}',
        );
      }

      // Periodically validate to catch any missed stream events or state mismatches
      await _validateWithHttpPing();
    } catch (e) {
      if (_validationAttempts % 10 == 0) {
        debugPrint('[NetworkController] Periodic check error: $e');
      }
    }
  }

  /// Validate actual internet connectivity via DNS and HTTP fallback
  Future<void> _validateWithHttpPing() async {
    bool isOnline = false;

    try {
      // 1. Try DNS lookup first - extremely fast and reliable for checking real internet
      final result = await InternetAddress.lookup('google.com')
          .timeout(const Duration(seconds: 3));
      if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
        isOnline = true;
      }
    } catch (_) {
      // 2. Fallback to HTTP if DNS fails
      try {
        final response = await http
            .head(
              Uri.parse('https://www.google.com'),
              headers: {'User-Agent': 'SarriRide/1.0.0'},
            )
            .timeout(const Duration(seconds: 3));
        isOnline = response.statusCode < 500; // Any 2xx-4xx is online
      } catch (e) {
        debugPrint('[NetworkController] Validation checks failed: $e');
      }
    }

    if (isOnline) {
      _updateConnectionStatus(true);
    } else {
      // If validation fails entirely, fall back to raw status
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
    // TEMPORARILY DISABLED: The network banner is disabled here
    // to allow the app to pass App Store review without blocking the UI.
    return child;
  }
}
