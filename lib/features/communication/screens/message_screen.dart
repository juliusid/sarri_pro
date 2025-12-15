import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:sarri_ride/features/communication/controllers/chat_controller.dart';
import 'package:sarri_ride/features/communication/controllers/call_controller.dart';
import 'package:sarri_ride/features/driver/controllers/trip_management_controller.dart';
import 'package:sarri_ride/features/ride/controllers/ride_controller.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:sarri_ride/utils/constants/colors.dart';
import 'package:sarri_ride/utils/helpers/helper_functions.dart';
import 'package:iconsax/iconsax.dart';
import 'dart:async';
import 'package:sarri_ride/core/services/websocket_service.dart';
import 'package:sarri_ride/features/communication/services/chat_service.dart';

class ChatMessage {
  final String id;
  final String text;
  final bool isFromDriver; // true = Peer (Left), false = Me (Right)
  final DateTime timestamp;
  RxBool isSent = true.obs;

  ChatMessage({
    required this.id,
    required this.text,
    required this.isFromDriver,
    required this.timestamp,
    bool sent = true,
  }) {
    isSent.value = sent;
  }
}

class MessageScreen extends StatefulWidget {
  // Name to display in the header (Driver or Client name)
  final String peerName;
  // Optional subtitle (e.g., "Toyota • ABC-123" or "Rider")
  final String? subtitle;
  // Kept for backward compatibility if passing separate fields
  final String? carModel;
  final String? plateNumber;

  final double rating;
  final String chatId;

  const MessageScreen({
    super.key,
    // Maps 'driverName' parameter to 'peerName' property
    required String driverName,
    this.carModel,
    this.plateNumber,
    this.subtitle,
    required this.rating,
    required this.chatId,
  }) : peerName = driverName;

  @override
  State<MessageScreen> createState() => _MessageScreenState();
}

class _MessageScreenState extends State<MessageScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  final WebSocketService _webSocketService = WebSocketService.instance;

  // Use Get.put to ensure the service is available if not already injected
  final ChatService _chatService = Get.put(ChatService());

  bool _isLoading = true;
  bool _isLoadingMore = false; // To prevent multiple load more calls
  int _currentPage = 1;
  bool _hasMore = true;

  @override
  void initState() {
    super.initState();

    // Add scroll listener for pagination
    _scrollController.addListener(_onScroll);

    // Initialize chat history from API
    _initializeChat();

    if (widget.chatId.isNotEmpty) {
      // Join the specific chat room
      _webSocketService.joinChatRoom(widget.chatId);

      // Register WebSocket Listeners
      _webSocketService.registerChatListener(_handleIncomingMessage);
      _webSocketService.registerSentListener(_handleSentConfirmation);

      // Mark chat as read locally and potentially on server
      ChatController.instance.markChatAsRead(widget.chatId);
    } else {
      print(
        "MessageScreen Error: Cannot join chat room or listen, chatId is empty.",
      );
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();

    // Unregister WebSocket Listeners
    _webSocketService.unregisterChatListener(_handleIncomingMessage);
    _webSocketService.unregisterSentListener(_handleSentConfirmation);

    if (widget.chatId.isNotEmpty) {
      _webSocketService.leaveChatRoom(widget.chatId);
    }
    super.dispose();
  }

  /// Fetches initial chat history from the backend
  Future<void> _initializeChat() async {
    if (widget.chatId.isEmpty) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      final messages = await _chatService.getMessages(widget.chatId, page: 1);

      if (mounted) {
        setState(() {
          // Sort messages chronologically (oldest first) for the ListView
          messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));

          _messages.assignAll(messages);
          _isLoading = false;

          // If we got fewer than the limit (30), we've reached the end of history
          if (messages.length < 30) _hasMore = false;
        });
        _scrollToBottom();
      }
    } catch (e) {
      print("Error loading chat history: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Scroll listener to trigger pagination
  void _onScroll() {
    if (_scrollController.hasClients &&
        _scrollController.position.pixels ==
            _scrollController.position.minScrollExtent) {
      _loadMoreMessages();
    }
  }

  /// Fetches older messages when scrolling up
  Future<void> _loadMoreMessages() async {
    if (!_hasMore || _isLoadingMore || _isLoading) return;

    setState(() {
      _isLoadingMore = true;
    });

    // Keep track of scroll position to maintain view after loading
    final double oldMaxScroll = _scrollController.position.maxScrollExtent;

    try {
      final nextMessages = await _chatService.getMessages(
        widget.chatId,
        page: _currentPage + 1,
      );

      if (mounted && nextMessages.isNotEmpty) {
        // Sort them chronologically
        nextMessages.sort((a, b) => a.timestamp.compareTo(b.timestamp));

        setState(() {
          _currentPage++;
          // Prepend older messages to the top of the list
          _messages.insertAll(0, nextMessages);
          if (nextMessages.length < 30) _hasMore = false;
          _isLoadingMore = false;
        });

        // Adjust scroll position to keep the user looking at the same message
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_scrollController.hasClients) {
            final newMaxScroll = _scrollController.position.maxScrollExtent;
            // The difference in extent is roughly the height of the new content
            // We want to shift the position by that amount to prevent jumping
            _scrollController.jumpTo(
              _scrollController.position.pixels + (newMaxScroll - oldMaxScroll),
            );
          }
        });
      } else {
        setState(() {
          _hasMore = false;
          _isLoadingMore = false;
        });
      }
    } catch (e) {
      print("Error loading more messages: $e");
      setState(() {
        _isLoadingMore = false;
      });
    }
  }

  // --- Handle incoming message with De-duplication ---
  void _handleIncomingMessage(dynamic data) {
    print("MessageScreen: Received chat:newMessage -> $data");
    if (mounted &&
        data is Map<String, dynamic> &&
        data['chatId'] == widget.chatId) {
      final serverId = data['_id'];

      // 1. De-duplication check (Already have this ID?)
      if (_messages.any((m) => m.id == serverId)) return;

      // 2. Self-Message check (Is this message from ME?)
      // We need to know who 'I' am to filter this out.
      // Since we don't have easy access to my own ID here without complex lookups,
      // we can use the 'tempId' in meta!

      String? tempId;
      if (data['meta'] != null && data['meta'] is Map) {
        tempId = data['meta']['tempId'];
      }

      // If I have a local message with this tempId, it means *I* sent it.
      // The 'chat:sent' event will handle the confirmation/ID swap.
      // We should IGNORE this 'chat:newMessage' event to avoid duplication.
      if (tempId != null && _messages.any((m) => m.id == tempId)) {
        print(
          "Ignoring echoed newMessage because I sent it (found tempId match).",
        );
        return;
      }
      setState(() {
        _messages.add(
          ChatMessage(
            id: serverId ?? 'msg_${DateTime.now().millisecondsSinceEpoch}',
            text: data['message'] ?? '',
            isFromDriver: true, // Incoming in this screen means from the peer
            timestamp:
                DateTime.tryParse(data['createdAt'] ?? '') ?? DateTime.now(),
          ),
        );
      });
      _scrollToBottom();
    }
  }

  // --- Handle sent confirmation (Reconciliation) ---
  void _handleSentConfirmation(dynamic data) {
    print("MessageScreen: Received chat:sent -> $data");
    if (mounted &&
        data is Map<String, dynamic> &&
        data['chatId'] == widget.chatId) {
      // --- FIX: Look for tempId inside 'meta' ---
      String? tempId;
      if (data['meta'] != null && data['meta'] is Map) {
        tempId = data['meta']['tempId'];
      }
      // -----------------------------------------

      final serverId = data['_id'];
      final serverTime = data['createdAt'];

      if (tempId != null && serverId != null) {
        final index = _messages.indexWhere((msg) => msg.id == tempId);

        if (index != -1) {
          setState(() {
            final oldMsg = _messages[index];
            _messages[index] = ChatMessage(
              id: serverId, // Swap temp ID for Server ID
              text: oldMsg.text,
              isFromDriver: false,
              timestamp: DateTime.tryParse(serverTime) ?? DateTime.now(),
              sent: true, // Turn tick blue
            );
            _messages[index].isSent.value = true;
          });
        }
      }
    }
  }

  void _showCallOptionsDialog(BuildContext context) {
    final dark = THelperFunctions.isDarkMode(context);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            'Call ${widget.peerName}',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: dark ? TColors.white : TColors.black,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'How would you like to call?',
                style: TextStyle(
                  color: dark ? TColors.lightGrey : TColors.darkGrey,
                ),
              ),
              const SizedBox(height: 20),
              // Normal Call Option
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    _makePhoneCall(widget.peerName);
                  },
                  icon: const Icon(Icons.phone, color: Colors.white),
                  label: const Text(
                    'Phone Call',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: TColors.success,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // In-App Call Option
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    _makeInAppCall();
                  },
                  icon: const Icon(Icons.videocam, color: Colors.white),
                  label: const Text(
                    'In-App Call',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: TColors.info,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: dark ? TColors.lightGrey : TColors.darkGrey,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _makePhoneCall(String name) async {
    // Use a placeholder or fetch phone from somewhere if available.
    // In real app, pass phone number to MessageScreen.
    const phoneNumber = '+2349012345678';
    final Uri phoneUri = Uri(scheme: 'tel', path: phoneNumber);

    try {
      if (await canLaunchUrl(phoneUri)) {
        await launchUrl(phoneUri);
      } else {
        THelperFunctions.showSnackBar('Could not launch phone app');
      }
    } catch (e) {
      THelperFunctions.showSnackBar('Error making phone call: $e');
    }
  }

  void _makeInAppCall() {
    if (Get.isRegistered<CallController>()) {
      // 1. Find the Active Trip ID dynamically
      String tripId = '';

      // Check if Rider
      if (Get.isRegistered<RideController>()) {
        tripId = Get.find<RideController>().rideId.value;
      }
      // Check if Driver (if Rider ID wasn't found)
      if (tripId.isEmpty && Get.isRegistered<TripManagementController>()) {
        tripId =
            Get.find<TripManagementController>().activeTrip.value?.id ?? '';
      }

      if (tripId.isNotEmpty) {
        // 2. Start call with valid Trip ID
        CallController.instance.startCall(
          tripId, // Valid Trip ID
          widget.peerName, // Name to display
          'User', // Role (optional display)
        );
      } else {
        THelperFunctions.showErrorSnackBar(
          'Error',
          'No active trip found to call.',
        );
      }
    } else {
      THelperFunctions.showErrorSnackBar('Error', 'Call service not available');
    }
  }

  void _sendMessage() async {
    if (_messageController.text.trim().isEmpty || widget.chatId.isEmpty) return;

    final messageText = _messageController.text.trim();
    _messageController.clear();

    // 1. Optimistic UI Update
    final tempId = 'temp_${DateTime.now().millisecondsSinceEpoch}';

    final message = ChatMessage(
      id: tempId,
      text: messageText,
      isFromDriver: false,
      timestamp: DateTime.now(),
      sent: false,
    );

    setState(() {
      _messages.add(message);
    });
    _scrollToBottom();

    // 2. Send via HTTP API with tempId
    print("Attempting to send message via API: $messageText"); // <--- ADD LOG

    try {
      final success = await _chatService.sendMessage(
        widget.chatId,
        messageText,
        tempId,
      );
      if (success) {
        print("API call successful. Waiting for socket confirmation.");
      } else {
        print("API call returned false/failed.");
        // Optional: Mark message as error in UI
        THelperFunctions.showSnackBar("Failed to send message");
      }
    } catch (e) {
      print("Exception sending message: $e");
      THelperFunctions.showSnackBar("Error sending message");
    }
  }

  void _sendQuickMessage(String message) {
    _messageController.text = message;
    _sendMessage();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final dark = THelperFunctions.isDarkMode(context);

    // Construct subtitle logic
    String displaySubtitle = widget.subtitle ?? '';
    if (displaySubtitle.isEmpty &&
        widget.carModel != null &&
        widget.plateNumber != null) {
      displaySubtitle = '${widget.carModel} • ${widget.plateNumber}';
    } else if (displaySubtitle.isEmpty) {
      displaySubtitle = 'Rider';
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: TColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Get.back(),
          icon: const Icon(Icons.arrow_back, color: Colors.white),
        ),
        title: Row(
          children: [
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
                    widget.peerName,
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
                        '${widget.rating} • $displaySubtitle',
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
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : Column(
                      children: [
                        // Show loader at top when pulling/loading more
                        if (_isLoadingMore)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 8.0),
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                        Expanded(
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
                      ],
                    ),
            ),
          ),
          if (_shouldShowQuickResponses())
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
                  // --- Sent Status Indicator ---
                  Row(
                    mainAxisSize: MainAxisSize.min,
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
                        const SizedBox(width: 4),
                        Obx(
                          () => Icon(
                            message.isSent.value ? Icons.done_all : Icons.done,
                            size: 14,
                            color: message.isSent.value
                                ? Colors.lightBlueAccent.withOpacity(0.8)
                                : Colors.white.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickResponseChip(String text) {
    final dark = THelperFunctions.isDarkMode(context);

    return GestureDetector(
      onTap: () => _sendQuickMessage(text),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: dark ? TColors.darkerGrey : Colors.grey[200],
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: dark
                ? TColors.darkGrey.withOpacity(0.5)
                : TColors.grey.withOpacity(0.5),
          ),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: dark ? TColors.lightGrey : TColors.darkGrey,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  bool _shouldShowQuickResponses() {
    return _messages.isNotEmpty && _messages.last.isFromDriver;
  }

  String _formatTime(DateTime dateTime) {
    return DateFormat('HH:mm').format(dateTime);
  }
}
