import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:sarri_ride/core/services/http_service.dart';
import 'package:sarri_ride/config/api_config.dart';

class PublicTrackingController extends GetxController {
  final String shareToken;
  PublicTrackingController(this.shareToken);

  final RxBool isLoading = true.obs;
  final RxString errorMsg = ''.obs;

  final Rx<Map<String, dynamic>?> tripData = Rx<Map<String, dynamic>?>(null);
  final Rx<Map<String, dynamic>?> driverData = Rx<Map<String, dynamic>?>(null);
  final Rx<Map<String, dynamic>?> clientData = Rx<Map<String, dynamic>?>(null);

  final Rx<LatLng?> driverLocation = Rx<LatLng?>(null);
  final RxDouble driverHeading = 0.0.obs;

  late IO.Socket _socket;

  @override
  void onInit() {
    super.onInit();
    _fetchInitialData();
  }

  @override
  void onClose() {
    _socket.dispose();
    super.onClose();
  }

  Future<void> _fetchInitialData() async {
    try {
      final response = await HttpService.instance.get('/sharelocation/$shareToken');
      final data = HttpService.instance.handleResponse(response);

      if (data['status'] == 'success' && data['data'] != null) {
        final shareData = data['data'];
        tripData.value = shareData['trip'];
        driverData.value = shareData['driver'];
        clientData.value = shareData['client'];

        if (tripData.value != null && tripData.value!['currentLocation'] != null) {
          final coords = tripData.value!['currentLocation']['coordinates'];
          driverLocation.value = LatLng(coords[1], coords[0]);
        }

        _connectToSocket();
        isLoading.value = false;
      } else {
        errorMsg.value = 'Failed to load trip details.';
        isLoading.value = false;
      }
    } catch (e) {
      print('PublicTrackingController Error: $e');
      errorMsg.value = 'This trip is no longer active or the link is invalid.';
      isLoading.value = false;
    }
  }

  void _connectToSocket() {
    _socket = IO.io(
      ApiConfig.baseUrl, // Assuming baseUrl works without token for public routes
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .build(),
    );

    _socket.connect();

    _socket.onConnect((_) {
      print('Connected to live share server');
      _socket.emitWithAck('join:share', {'shareToken': shareToken}, ack: (response) {
        print('Join share response: $response');
      });
    });

    _socket.on('location:update', (data) {
      if (data != null && data['latitude'] != null && data['longitude'] != null) {
        driverLocation.value = LatLng(data['latitude'], data['longitude']);
        driverHeading.value = (data['heading'] ?? 0.0).toDouble();
      }
    });

    _socket.on('trip:ended', (data) {
      errorMsg.value = data['message'] ?? 'This trip has been completed.';
      _socket.disconnect();
    });

    _socket.onConnectError((err) {
      print('Socket Connect Error: $err');
    });
  }
}
