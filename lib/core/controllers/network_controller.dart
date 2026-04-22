import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class NetworkController extends GetxController {
  static NetworkController get instance => Get.find();

  final Connectivity _connectivity = Connectivity();
  late StreamSubscription<List<ConnectivityResult>> _connectivitySubscription;
  final RxBool isConnected = true.obs;

  /// Debounce timer to avoid acting on brief connectivity flickers.
  Timer? _debounceTimer;

  @override
  void onInit() {
    super.onInit();
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
      _updateConnectionStatus,
    );
    _checkInitialConnection();
  }

  Future<void> _checkInitialConnection() async {
    final results = await _connectivity.checkConnectivity();
    _updateConnectionStatus(results);
  }

  void _updateConnectionStatus(List<ConnectivityResult> results) {
    bool hasConnection = !results.contains(ConnectivityResult.none);

    _debounceTimer?.cancel();

    if (!hasConnection) {
      // Wait 2s before declaring offline to avoid false positives.
      _debounceTimer = Timer(const Duration(seconds: 2), () {
        isConnected.value = false;
      });
    } else {
      isConnected.value = true;
    }
  }

  @override
  void onClose() {
    _debounceTimer?.cancel();
    _connectivitySubscription.cancel();
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
