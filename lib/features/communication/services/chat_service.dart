import 'package:get/get.dart';
import 'package:sarri_ride/config/api_config.dart';
import 'package:sarri_ride/core/services/http_service.dart';
import 'package:sarri_ride/features/authentication/models/auth_model.dart';
import 'package:sarri_ride/features/communication/screens/message_screen.dart'; // For ChatMessage model

class ChatService extends GetxService {
  static ChatService get instance => Get.find();
  final HttpService _httpService = HttpService.instance;

  Future<List<ChatMessage>> getMessages(
    String chatId, {
    int page = 1,
    int limit = 30,
  }) async {
    try {
      // Get current user ID to determine message direction
      String currentUserId = '';
      if (Get.isRegistered<ClientData>(tag: 'currentUser')) {
        currentUserId = Get.find<ClientData>(tag: 'currentUser').id;
      }

      final response = await _httpService.get(
        ApiConfig.getChatMessagesEndpoint(chatId),
        queryParameters: {'page': page.toString(), 'limit': limit.toString()},
      );

      final responseData = _httpService.handleResponse(response);

      if (responseData['status'] == 'success' && responseData['data'] is List) {
        final List<dynamic> data = responseData['data'];

        return data.map<ChatMessage>((json) {
          final senderId = json['sender'] ?? '';

          // Determine alignment:
          // In MessageScreen, 'isFromDriver' = TRUE means ALIGN LEFT (Peer)
          // 'isFromDriver' = FALSE means ALIGN RIGHT (Me)
          // So if senderId != currentUserId, it's a Peer message (Left).
          final bool isPeerMessage = senderId != currentUserId;

          return ChatMessage(
            id: json['_id'] ?? '',
            text: json['message'] ?? '',
            isFromDriver: isPeerMessage, // Reusing this field to mean "Is Peer"
            timestamp:
                DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
            sent: true, // History messages are always sent
          );
        }).toList();
      }
      return [];
    } catch (e) {
      print("ChatService Error: $e");
      return [];
    }
  }

  Future<bool> sendMessage(String chatId, String text, String tempId) async {
    try {
      final body = {
        'chatId': chatId,
        'text': text,
        'meta': {
          'tempId': tempId, // <-- SENDING TEMP ID HERE
        },
      };

      final response = await _httpService.post(
        ApiConfig.sendChatEndpoint,
        body: body,
      );

      final responseData = _httpService.handleResponse(response);
      return responseData['status'] == 'queued' ||
          responseData['status'] == 'success';
    } catch (e) {
      print("ChatService Error (Send): $e");
      return false;
    }
  }
}
