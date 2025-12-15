// import 'package:flutter/material.dart';
// import 'package:flutter_inappwebview/flutter_inappwebview.dart';
// import 'package:get/get.dart';
// import 'package:sarri_ride/utils/constants/colors.dart';
// import 'package:sarri_ride/utils/helpers/helper_functions.dart';

// class PaystackWebViewScreen extends StatefulWidget {
//   final String authorizationUrl;

//   const PaystackWebViewScreen({super.key, required this.authorizationUrl});

//   @override
//   State<PaystackWebViewScreen> createState() => _PaystackWebViewScreenState();
// }

// class _PaystackWebViewScreenState extends State<PaystackWebViewScreen> {
//   InAppWebViewController? _webViewController;
//   bool _isLoading = true;
//   final String _callbackScheme = "sarriride";
//   final String _callbackHost = "payment-callback";

//   @override
//   Widget build(BuildContext context) {
//     final dark = THelperFunctions.isDarkMode(context);

//     return Scaffold(
//       appBar: AppBar(
//         title: const Text("Verify Your Card"),
//         backgroundColor: dark ? TColors.darkerGrey : TColors.lightGrey,
//         leading: IconButton(
//           icon: const Icon(Icons.close),
//           onPressed: () {
//             print(
//               "PAYSTACK WEBVIEW: Close button pressed. Returning 'cancelled'.",
//             );
//             Get.back(result: "cancelled"); // Return 'cancelled'
//           },
//         ),
//       ),
//       body: Stack(
//         children: [
//           InAppWebView(
//             initialUrlRequest: URLRequest(
//               url: Uri.parse(widget.authorizationUrl),
//             ),
//             onWebViewCreated: (controller) {
//               _webViewController = controller;
//             },
//             onLoadStop: (controller, url) {
//               setState(() {
//                 _isLoading = false;
//               });

//               // --- THIS IS THE PRINT STATEMENT YOU REQUESTED ---
//               print("WEBVIEW CURRENT URL: ${url.toString()}");
//               // --- END PRINT STATEMENT ---

//               // Check if this is one of our app's deep links
//               if (url?.scheme == _callbackScheme &&
//                   url?.host == _callbackHost) {
//                 print("WEBVIEW: Intercepted app deep link: $url");

//                 // Check the URL path to see if it was a success or failure
//                 if (url?.path == "/payment/success") {
//                   // It was successful.
//                   print("WEBVIEW: Payment success. Returning 'success'.");
//                   Get.back(result: "success");
//                 } else if (url?.path == "/payment/failed") {
//                   // It failed.
//                   String reason =
//                       url?.queryParameters['reason'] ?? "unknown_failure";
//                   print(
//                     "WEBVIEW: Payment failed. Reason: $reason. Returning 'failure'.",
//                   );
//                   Get.back(result: "failure");
//                 } else {
//                   // It was a deep link but not one we recognize
//                   print("WEBVIEW: Unknown deep link path: ${url?.path}");
//                   Get.back(result: "cancelled"); // Default to cancelled
//                 }
//               }
//             },
//             onLoadError: (controller, url, code, message) {
//               setState(() {
//                 _isLoading = false;
//               });
//               THelperFunctions.showErrorSnackBar(
//                 "Load Error",
//                 "Failed to load page: $message",
//               );
//             },
//             onLoadHttpError: (controller, url, statusCode, description) {
//               setState(() {
//                 _isLoading = false;
//               });
//               THelperFunctions.showErrorSnackBar(
//                 "HTTP Error",
//                 "Error $statusCode: $description",
//               );
//             },
//           ),
//           if (_isLoading)
//             const Center(
//               child: CircularProgressIndicator(color: TColors.primary),
//             ),
//         ],
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:sarri_ride/utils/constants/colors.dart';
import 'package:sarri_ride/utils/helpers/helper_functions.dart';

class PaystackWebViewScreen extends StatefulWidget {
  final String authorizationUrl;

  const PaystackWebViewScreen({super.key, required this.authorizationUrl});

  @override
  State<PaystackWebViewScreen> createState() => _PaystackWebViewScreenState();
}

class _PaystackWebViewScreenState extends State<PaystackWebViewScreen> {
  InAppWebViewController? _webViewController;
  bool _isLoading = true;
  final String _callbackScheme = "sarriride";
  // Note: Some webviews might strip the host or treat it differently,
  // so we will primarily check the scheme.

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
            print("PAYSTACK WEBVIEW: User closed manually.");
            Get.back(result: "cancelled");
          },
        ),
      ),
      body: Stack(
        children: [
          InAppWebView(
            initialUrlRequest: URLRequest(url: WebUri(widget.authorizationUrl)),
            initialSettings: InAppWebViewSettings(
              useShouldOverrideUrlLoading:
                  true, // IMPORTANT: Enables intercepting
              mediaPlaybackRequiresUserGesture: false,
              javaScriptEnabled: true,
            ),
            onWebViewCreated: (controller) {
              _webViewController = controller;
            },

            // --- THE FIX: Intercept the URL before it loads ---
            shouldOverrideUrlLoading: (controller, navigationAction) async {
              final uri = navigationAction.request.url;

              if (uri != null && uri.scheme == _callbackScheme) {
                print("WEBVIEW: Intercepted custom scheme: $uri");

                // Check success
                // The URL is like: sarriride://payment-callback/payment/success?type=card_added
                if (uri.path.contains('/payment/success')) {
                  print("WEBVIEW: Payment success detected.");
                  Get.back(result: "success");
                }
                // Check failure
                else if (uri.path.contains('/payment/failed')) {
                  String reason =
                      uri.queryParameters['reason'] ?? "Verification failed";
                  print("WEBVIEW: Payment failed. Reason: $reason");
                  // You might want to pass the specific reason back
                  Get.back(result: "failure");
                }
                // Fallback for any other sarriride:// link
                else {
                  print("WEBVIEW: Unknown custom link, closing.");
                  Get.back(result: "cancelled");
                }

                // Stop the WebView from trying to load "sarriride://" (which would crash/error)
                return NavigationActionPolicy.CANCEL;
              }

              // Let normal http/https links load
              return NavigationActionPolicy.ALLOW;
            },

            onLoadStop: (controller, url) {
              // We keep this just to hide the loader for normal pages
              if (mounted) {
                setState(() {
                  _isLoading = false;
                });
              }
            },

            onReceivedError: (controller, request, error) {
              // Ignore errors if they are related to our custom scheme
              if (request.url.scheme == _callbackScheme) return;

              if (mounted) {
                setState(() {
                  _isLoading = false;
                });
              }
              // Only show error if it's a real web page error
              if (request.url.scheme.startsWith('http')) {
                THelperFunctions.showErrorSnackBar(
                  "Load Error",
                  "Failed to load page: ${error.description}",
                );
              }
            },

            onReceivedHttpError: (controller, request, errorResponse) {
              if (mounted) {
                setState(() {
                  _isLoading = false;
                });
              }
            },
          ),

          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(color: TColors.primary),
            ),
        ],
      ),
    );
  }
}
