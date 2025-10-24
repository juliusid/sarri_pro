import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:sarri_ride/features/communication/controllers/chat_controller.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:sarri_ride/utils/constants/colors.dart';
import 'package:sarri_ride/utils/helpers/helper_functions.dart';
import 'package:sarri_ride/features/communication/screens/call_screen.dart';
import 'package:iconsax/iconsax.dart';
import 'dart:async';
import 'package:sarri_ride/core/services/websocket_service.dart'; // <-- Import WebSocketService

class ChatMessage {
  final String id; // Use message ID from backend if available
  final String text;
  final bool isFromDriver;
  final DateTime timestamp;
  RxBool isSent =
      true.obs; // Track if sent (initially true for received, update for sent)

  ChatMessage({
    required this.id,
    required this.text,
    required this.isFromDriver,
    required this.timestamp,
    bool sent = true, // Default to true for received messages
  }) {
    isSent.value = sent;
  }
}
// --- End Class ---

class MessageScreen extends StatefulWidget {
  final String driverName;
  final String carModel;
  final String plateNumber;
  final double rating;
  final String chatId;

  const MessageScreen({
    super.key,
    required this.driverName,
    required this.carModel,
    required this.plateNumber,
    required this.rating,
    required this.chatId,
  });

  @override
  State<MessageScreen> createState() => _MessageScreenState();
}

class _MessageScreenState extends State<MessageScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  final WebSocketService _webSocketService =
      WebSocketService.instance; // Get instance

  @override
  void initState() {
    super.initState();
    _initializeChat();

    if (widget.chatId.isNotEmpty) {
      _webSocketService.joinChatRoom(widget.chatId);
      // --- Register WebSocket Listeners ---
      _webSocketService.registerChatListener(_handleIncomingMessage);
      _webSocketService.registerSentListener(_handleSentConfirmation);
      // --- Mark chat as read ---
      ChatController.instance.markChatAsRead(widget.chatId);
      // --- End Mark ---
      // --- End Register ---
    } else {
      print(
        "MessageScreen Error: Cannot join chat room or listen, chatId is empty.",
      );
      // Optionally show error and pop screen
      // WidgetsBinding.instance.addPostFrameCallback((_) {
      //    THelperFunctions.showSnackBar("Cannot initialize chat.");
      //    Get.back();
      // });
    }
  }

  // --- NEW: Handle incoming message ---
  void _handleIncomingMessage(dynamic data) {
    print("MessageScreen: Received chat:newMessage -> $data");
    if (mounted &&
        data is Map<String, dynamic> &&
        data['chatId'] == widget.chatId) {
      // Ensure message belongs to this chat
      setState(() {
        _messages.add(
          ChatMessage(
            // Use backend ID if available, otherwise generate one
            id: data['_id'] ?? 'msg_${DateTime.now().millisecondsSinceEpoch}',
            text: data['message'] ?? '',
            isFromDriver:
                true, // Assuming messages via 'chat:newMessage' are from the other party (driver)
            timestamp:
                DateTime.tryParse(data['createdAt'] ?? '') ?? DateTime.now(),
          ),
        );
      });
      _scrollToBottom();
    }
  }

  // --- NEW: Handle sent confirmation ---
  void _handleSentConfirmation(dynamic data) {
    print("MessageScreen: Received chat:sent -> $data");
    if (mounted &&
        data is Map<String, dynamic> &&
        data['chatId'] == widget.chatId) {
      // Find the corresponding message sent by the user and mark it as 'sent'
      // This assumes the 'chat:sent' payload includes enough info to identify the message
      // (e.g., a temporary ID sent from client, echoed back by server, or the final _id)
      final messageId = data['_id']; // Assuming backend confirms with final ID
      if (messageId != null) {
        final index = _messages.indexWhere(
          (msg) => !msg.isFromDriver && msg.id == messageId,
        ); // Match based on ID
        if (index != -1) {
          setState(() {
            _messages[index].isSent.value = true;
          });
        } else {
          // If ID doesn't match, maybe use timestamp/text matching as fallback? Less reliable.
          print(
            "chat:sent confirmation received, but could not find matching sent message with ID: $messageId",
          );
        }
      }
    }
  }

  void _initializeChat() {
    /* ... (as before) ... */
    // Add initial welcome message from driver
    // These are local placeholders, real history should be fetched via API if needed
    _messages.addAll([
      ChatMessage(
        id: 'init_1',
        text: "Hello! I'm ${widget.driverName}, your driver for today.",
        isFromDriver: true,
        timestamp: DateTime.now().subtract(const Duration(minutes: 2)),
      ),
      ChatMessage(
        id: 'init_2',
        text: "I'm on my way to pick you up. ETA is about 5 minutes.",
        isFromDriver: true,
        timestamp: DateTime.now().subtract(const Duration(minutes: 1)),
      ),
    ]);
  }

  void _showCallOptionsDialog(BuildContext context) {
    /* ... (as before) ... */
  }
  void _makePhoneCall(String driverName) async {
    /* ... (as before) ... */
  }
  void _makeInAppCall() {
    /* ... (as before) ... */
  }

  // --- MODIFIED: Send message via WebSocket ---
  void _sendMessage() {
    if (_messageController.text.trim().isEmpty || widget.chatId.isEmpty) return;

    final messageText = _messageController.text.trim();
    // Create a temporary ID for tracking confirmation
    final tempId = 'temp_${DateTime.now().millisecondsSinceEpoch}';

    final message = ChatMessage(
      id: tempId, // Use temp ID initially
      text: messageText,
      isFromDriver: false, // Message from current user (rider)
      timestamp: DateTime.now(),
      sent: false, // Mark as not sent initially
    );

    setState(() {
      _messages.add(message);
    });

    // Emit message via WebSocket
    _webSocketService.emit('chat:sendMessage', {
      // Assuming this is the event name to send a message
      'chatId': widget.chatId,
      'message': messageText,
      'tempId': tempId, // Send temp ID for potential echo back in chat:sent
    });
    print("MessageScreen: Emitted chat:sendMessage with tempId: $tempId");

    _messageController.clear();
    _scrollToBottom();

    // REMOVED: _simulateDriverResponse(); // No longer needed
  }
  // --- END MODIFICATION ---

  // --- REMOVED: _simulateDriverResponse() ---

  void _scrollToBottom() {
    /* ... (as before) ... */
  }
  void _sendQuickMessage(String message) {
    /* ... (as before) ... */
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();

    // --- Unregister WebSocket Listeners ---
    _webSocketService.unregisterChatListener(_handleIncomingMessage);
    _webSocketService.unregisterSentListener(_handleSentConfirmation);
    // --- End Unregister ---

    if (widget.chatId.isNotEmpty) {
      _webSocketService.leaveChatRoom(widget.chatId);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    /* ... (build method remains the same) ... */
    final dark = THelperFunctions.isDarkMode(context);

    return Scaffold(
      appBar: AppBar(
        /* ... AppBar structure ... */
        backgroundColor: TColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Get.back(),
          icon: Icon(Icons.arrow_back, color: Colors.white),
        ),
        title: Row(
          children: [
            /* ... Avatar, Name, Rating ... */
            const CircleAvatar(
              radius: 20,
              backgroundColor: Colors.white,
              child: Icon(Iconsax.user, color: TColors.primary, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.driverName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Row(
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 14),
                      const SizedBox(width: 2),
                      Text(
                        '${widget.rating} • ${widget.carModel}',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () => _showCallOptionsDialog(context),
            icon: const Icon(Iconsax.call, color: Colors.white),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            // Chat messages
            child: Container(
              color: dark ? TColors.dark : Colors.grey[100],
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(16),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final message = _messages[index];
                  return _buildMessageBubble(message, dark);
                },
              ),
            ),
          ),
          if (_shouldShowQuickResponses()) // Quick response buttons
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: dark ? TColors.dark : Colors.white,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildQuickResponseChip('I\'m here'),
                    const SizedBox(width: 8),
                    _buildQuickResponseChip('2 minutes away'),
                    const SizedBox(width: 8),
                    _buildQuickResponseChip('Thank you'),
                    const SizedBox(width: 8),
                    _buildQuickResponseChip('See you soon'),
                  ],
                ),
              ),
            ),
          Container(
            // Message input
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: dark ? TColors.dark : Colors.white,
              border: Border(
                top: BorderSide(
                  color: dark ? TColors.darkerGrey : TColors.lightGrey,
                ),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    constraints: const BoxConstraints(minHeight: 48),
                    decoration: BoxDecoration(
                      color: dark ? TColors.darkerGrey : Colors.grey[200],
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Center(
                      child: TextField(
                        controller: _messageController,
                        decoration: InputDecoration(
                          hintText: 'Type a message...',
                          hintStyle: TextStyle(
                            color: dark ? TColors.lightGrey : Colors.grey[600],
                          ),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                          isCollapsed: true,
                        ),
                        style: TextStyle(
                          color: dark ? TColors.white : TColors.black,
                        ),
                        maxLines: null,
                        minLines: 1,
                        textCapitalization: TextCapitalization.sentences,
                        keyboardType: TextInputType.multiline,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _sendMessage,
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: const BoxDecoration(
                      color: TColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Iconsax.send_1,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- MODIFIED: Added Obx wrapper for sent status ---
  Widget _buildMessageBubble(ChatMessage message, bool dark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: message.isFromDriver
            ? MainAxisAlignment.start
            : MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (message.isFromDriver) ...[
            /* ... Driver Avatar ... */
            const CircleAvatar(
              radius: 16,
              backgroundColor: TColors.primary,
              child: Icon(Iconsax.support, color: Colors.white, size: 16),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.7,
              ),
              decoration: BoxDecoration(
                color: message.isFromDriver
                    ? (dark ? TColors.darkerGrey : Colors.white)
                    : TColors.primary,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: message.isFromDriver
                      ? const Radius.circular(4)
                      : const Radius.circular(18),
                  bottomRight: message.isFromDriver
                      ? const Radius.circular(18)
                      : const Radius.circular(4),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(dark ? 0.2 : 0.08),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: message.isFromDriver
                    ? CrossAxisAlignment.start
                    : CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    message.text,
                    style: TextStyle(
                      color: message.isFromDriver
                          ? (dark ? TColors.white : TColors.black)
                          : Colors.white,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  // --- Add Sent Status Indicator ---
                  Row(
                    mainAxisSize: MainAxisSize.min, // Important for alignment
                    children: [
                      Text(
                        _formatTime(message.timestamp),
                        style: TextStyle(
                          color: message.isFromDriver
                              ? (dark
                                    ? TColors.lightGrey.withOpacity(0.7)
                                    : Colors.grey[600])
                              : Colors.white.withOpacity(0.7),
                          fontSize: 11,
                        ),
                      ),
                      if (!message.isFromDriver) ...[
                        // Only show checkmark for user's messages
                        const SizedBox(width: 4),
                        Obx(
                          () => Icon(
                            // Wrap Icon in Obx
                            message.isSent.value
                                ? Icons.done_all
                                : Icons.done, // Change icon based on isSent
                            size: 14,
                            color: message.isSent.value
                                ? Colors.lightBlueAccent.withOpacity(0.8)
                                : Colors.white.withOpacity(0.7), // Change color
                          ),
                        ),
                      ],
                    ],
                  ),
                  // --- End Sent Status ---
                ],
              ),
            ),
          ),
          if (!message.isFromDriver) ...[
            /* ... Placeholder/User Avatar ... */
            const SizedBox(width: 8),
            const Opacity(opacity: 0.0, child: CircleAvatar(radius: 16)),
          ],
        ],
      ),
    );
  }

  Widget _buildQuickResponseChip(String text) {
    final dark = THelperFunctions.isDarkMode(context);

    return GestureDetector(
      onTap: () => _sendQuickMessage(text),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 8,
        ), // Increased vertical padding
        decoration: BoxDecoration(
          color: dark
              ? TColors.darkerGrey
              : Colors.grey[200], // Adjusted colors
          borderRadius: BorderRadius.circular(20), // More rounded
          border: Border.all(
            color: dark
                ? TColors.darkGrey.withOpacity(0.5)
                : TColors.grey.withOpacity(0.5), // Subtle border
          ),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: dark
                ? TColors.lightGrey
                : TColors.darkGrey, // Adjusted text color
            fontSize: 13, // Slightly smaller font
          ),
        ),
      ),
    );
  }

  bool _shouldShowQuickResponses() {
    // Show quick responses if there are messages and the last message is from driver
    return _messages.isNotEmpty && _messages.last.isFromDriver;
  }

  String _formatTime(DateTime dateTime) {
    // Use intl package for better time formatting if needed later
    return DateFormat('HH:mm').format(dateTime); // Simple HH:mm format
  }
} // End of _MessageScreenState
