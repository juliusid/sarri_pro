import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class NetworkController extends GetxController {
  static NetworkController get instance => Get.find();

  final Connectivity _connectivity = Connectivity();
  late StreamSubscription<List<ConnectivityResult>> _connectivitySubscription;
  final RxBool isConnected = true.obs;

  @override
  void onInit() {
    super.onInit();
    // Subscribe to connection changes
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
      _updateConnectionStatus,
    );
    // Check initial status
    _checkInitialConnection();
  }

  Future<void> _checkInitialConnection() async {
    final results = await _connectivity.checkConnectivity();
    _updateConnectionStatus(results);
  }

  void _updateConnectionStatus(List<ConnectivityResult> results) {
    // If the list contains 'none', we are disconnected
    bool hasConnection = !results.contains(ConnectivityResult.none);

    // Update reactive variable
    isConnected.value = hasConnection;

    if (!hasConnection) {
      _showNoConnectionSnackbar();
    } else {
      // If we previously showed the snackbar, close it now
      if (Get.isSnackbarOpen) {
        Get.closeAllSnackbars();
      }
    }
  }

  void _showNoConnectionSnackbar() {
    Get.rawSnackbar(
      messageText: const Text(
        'You are offline. Please check your internet connection.',
        style: TextStyle(color: Colors.white, fontSize: 14),
      ),
      isDismissible: true, // Allow dismiss by swiping
      duration: const Duration(days: 1), // Keeps it open indefinitely until internet returns
      backgroundColor: Colors.red[900]!,
      icon: const Icon(Icons.wifi_off, color: Colors.white, size: 35),
      margin: EdgeInsets.zero,
      snackStyle: SnackStyle.GROUNDED, // Sticks to bottom of screen
      mainButton: TextButton(
        onPressed: () {
          if (Get.isSnackbarOpen) {
             Get.closeCurrentSnackbar();
          }
        },
        child: const Text('Dismiss', style: TextStyle(color: Colors.white)),
      ),
    );
  }

  @override
  void onClose() {
    _connectivitySubscription.cancel();
    super.onClose();
  }
}
