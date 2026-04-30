import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:sarri_ride/utils/constants/colors.dart';
import 'package:sarri_ride/utils/helpers/helper_functions.dart';

class PaystackWebViewScreen extends StatefulWidget {
  final String authorizationUrl;

  const PaystackWebViewScreen({super.key, required this.authorizationUrl});

  @override
  State<PaystackWebViewScreen> createState() => _PaystackWebViewScreenState();
}

class _PaystackWebViewScreenState extends State<PaystackWebViewScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;
  final String _callbackScheme = "sarriride";

  @override
  void initState() {
    super.initState();

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (NavigationRequest request) {
            final uri = Uri.tryParse(request.url);

            if (uri != null && uri.scheme == _callbackScheme) {
              // Check for success
              if (uri.path.contains('payment/success') ||
                  uri.path.contains('payment-success')) {
                debugPrint("WEBVIEW: Payment success detected.");
                Get.back(result: "success");
              }
              // Check for failure
              else if (uri.path.contains('payment/failed') ||
                  uri.path.contains('payment-failed')) {
                debugPrint("WEBVIEW: Payment failure detected.");
                Get.back(result: "failure");
              } else {
                Get.back(result: "cancelled");
              }
              return NavigationDecision.prevent;
            }
            // Let normal http/https links load
            return NavigationDecision.navigate;
          },
          onPageFinished: (String url) {
            if (mounted) {
              setState(() {
                _isLoading = false;
              });
            }
          },
          onWebResourceError: (WebResourceError error) {
            if (mounted) {
              setState(() {
                _isLoading = false;
              });
            }
            // Only show error for real web page failures
            if (error.errorType != null) {
              THelperFunctions.showErrorSnackBar(
                "Load Error",
                "Failed to load page: ${error.description}",
              );
            }
          },
          onHttpError: (HttpResponseError error) {
            if (mounted) {
              setState(() {
                _isLoading = false;
              });
            }
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.authorizationUrl));
  }

  @override
  Widget build(BuildContext context) {
    final dark = THelperFunctions.isDarkMode(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Verify Your Card"),
        backgroundColor: dark ? TColors.darkerGrey : TColors.lightGrey,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            debugPrint("PAYSTACK WEBVIEW: User closed manually.");
            Get.back(result: "cancelled");
          },
        ),
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(color: TColors.primary),
            ),
        ],
      ),
    );
  }
}
