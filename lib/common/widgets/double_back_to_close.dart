import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class DoubleBackToCloseWidget extends StatefulWidget {
  final Widget child;

  /// Called first on every system back press. Return true if it handled the
  /// back navigation internally (e.g. stepped back one screen in a booking
  /// flow) so the double-tap-to-exit logic below is skipped entirely.
  /// Return false (or pass null) to fall through to the exit behavior.
  final bool Function()? onWillPop;

  const DoubleBackToCloseWidget({super.key, required this.child, this.onWillPop});

  @override
  State<DoubleBackToCloseWidget> createState() => _DoubleBackToCloseWidgetState();
}

class _DoubleBackToCloseWidgetState extends State<DoubleBackToCloseWidget> {
  DateTime? _lastPressedAt;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, Object? result) async {
        if (didPop) {
          return;
        }

        if (widget.onWillPop?.call() ?? false) {
          return;
        }

        final now = DateTime.now();
        final backButtonHasNotBeenPressedOrSnackBarHasBeenClosed =
            _lastPressedAt == null ||
            now.difference(_lastPressedAt!) > const Duration(seconds: 2);

        if (backButtonHasNotBeenPressedOrSnackBarHasBeenClosed) {
          _lastPressedAt = now;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Press back again to exit the app'),
              duration: Duration(seconds: 2),
            ),
          );
          return;
        }

        // Exit the app if pressed twice within 2 seconds
        SystemNavigator.pop();
      },
      child: widget.child,
    );
  }
}
