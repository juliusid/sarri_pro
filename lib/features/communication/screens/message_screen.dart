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
  final String? profileImage;

  const MessageScreen({
    super.key,
    // Maps 'driverName' parameter to 'peerName' property
    required String driverName,
    this.carModel,
    this.plateNumber,
    this.subtitle,
    required this.rating,
    required this.chatId,
    this.profileImage,
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
    if (mounted &&
        data is Map<String, dynamic> &&
        data['chatId'] == widget.chatId) {
      final serverId = data['_id'];

      // 1. De-duplication check (Already have this ID?)
      if (_messages.any((m) => m.id == serverId)) return;

      // 2. Self-Message check (Is this message from ME?)
      String? tempId;
      if (data['meta'] != null && data['meta'] is Map) {
        tempId = data['meta']['tempId'];
      }

      if (tempId != null && _messages.any((m) => m.id == tempId)) {
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
    if (mounted &&
        data is Map<String, dynamic> &&
        data['chatId'] == widget.chatId) {
      String? tempId;
      if (data['meta'] != null && data['meta'] is Map) {
        tempId = data['meta']['tempId'];
      }

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
          backgroundColor: dark ? TColors.dark : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            'Contact ${widget.peerName}',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: dark ? TColors.white : TColors.black,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Choose a method to call',
                style: TextStyle(
                  color: dark ? TColors.lightGrey : TColors.darkGrey,
                ),
              ),
              const SizedBox(height: 24),
              // Normal Call Option
              _buildDialogButton(
                icon: Iconsax.call,
                label: 'Mobile Call',
                color: TColors.success,
                onTap: () {
                  Navigator.pop(context);
                  _makePhoneCall(widget.peerName);
                },
              ),
              const SizedBox(height: 12),
              // In-App Call Option
              _buildDialogButton(
                icon: Iconsax.video,
                label: 'In-App Call',
                color: TColors.primary,
                onTap: () {
                  Navigator.pop(context);
                  _makeInAppCall();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDialogButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: color.withOpacity(0.1),
          foregroundColor: color,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20),
            const SizedBox(width: 10),
            Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  void _makePhoneCall(String name) async {
    const phoneNumber = '+2349012345678'; // Placeholder
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
      String tripId = '';
      if (Get.isRegistered<RideController>()) {
        tripId = Get.find<RideController>().rideId.value;
      }
      if (tripId.isEmpty && Get.isRegistered<TripManagementController>()) {
        tripId =
            Get.find<TripManagementController>().activeTrip.value?.id ?? '';
      }

      if (tripId.isNotEmpty) {
        CallController.instance.startCall(tripId, widget.peerName, 'User');
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

    try {
      await _chatService.sendMessage(widget.chatId, messageText, tempId);
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
    final backgroundColor = dark ? TColors.dark : const Color(0xFFF5F5F5);
    final inputColor = dark ? TColors.darkerGrey : Colors.white;
    final textColor = dark ? TColors.white : TColors.textPrimary;

    // Construct subtitle logic
    String displaySubtitle = widget.subtitle ?? '';
    if (displaySubtitle.isEmpty &&
        widget.carModel != null &&
        widget.plateNumber != null) {
      displaySubtitle = '${widget.carModel} • ${widget.plateNumber}';
    } else if (displaySubtitle.isEmpty) {
      displaySubtitle = 'Active now';
    }

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: dark ? TColors.darkerGrey : Colors.white,
        elevation: 0,
        scrolledUnderElevation: 2,
        shadowColor: Colors.black.withOpacity(0.1),
        leading: IconButton(
          onPressed: () => Get.back(),
          icon: Icon(Icons.arrow_back, color: textColor),
        ),
        titleSpacing: 0,
        title: Row(
          children: [
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.grey.withOpacity(0.2)),
              ),
              child: CircleAvatar(
                radius: 20,
                backgroundColor: TColors.primary.withOpacity(0.1),
                backgroundImage:
                    (widget.profileImage != null &&
                        widget.profileImage!.isNotEmpty)
                    ? NetworkImage(widget.profileImage!)
                    : null,
                child:
                    (widget.profileImage == null ||
                        widget.profileImage!.isEmpty)
                    ? const Icon(Iconsax.user, color: TColors.primary, size: 20)
                    : null,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.peerName,
                    style: TextStyle(
                      color: textColor,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Row(
                    children: [
                      if (widget.rating > 0) ...[
                        const Icon(
                          Icons.star_rounded,
                          color: Colors.amber,
                          size: 14,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          widget.rating.toString(),
                          style: TextStyle(
                            color: dark ? TColors.lightGrey : TColors.darkGrey,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          width: 3,
                          height: 3,
                          decoration: BoxDecoration(
                            color: Colors.grey[400],
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                      ],
                      Expanded(
                        child: Text(
                          displaySubtitle,
                          style: TextStyle(
                            color: dark ? TColors.lightGrey : Colors.grey[600],
                            fontSize: 12,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              color: TColors.success.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              onPressed: () => _showCallOptionsDialog(context),
              icon: const Icon(Iconsax.call, color: TColors.success, size: 22),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : Stack(
                    children: [
                      // Chat List
                      ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 20,
                        ),
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          final message = _messages[index];
                          // Check if previous message was from same sender
                          bool isFirstInSequence = true;
                          if (index > 0) {
                            if (_messages[index - 1].isFromDriver ==
                                message.isFromDriver) {
                              isFirstInSequence = false;
                            }
                          }
                          return Column(
                            children: [
                              // Loading indicator if fetching more
                              if (index == 0 && _isLoadingMore)
                                const Padding(
                                  padding: EdgeInsets.only(bottom: 20),
                                  child: Center(
                                    child: SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    ),
                                  ),
                                ),
                              _buildMessageBubble(
                                message,
                                dark,
                                isFirstInSequence,
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
          ),

          // Bottom Input Area
          Container(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 12,
              bottom: MediaQuery.of(context).padding.bottom + 12,
            ),
            decoration: BoxDecoration(
              color: dark ? TColors.darkerGrey : Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Quick Responses
                if (_shouldShowQuickResponses())
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      children: [
                        _buildQuickResponseChip('I\'m here'),
                        const SizedBox(width: 8),
                        _buildQuickResponseChip('2 minutes away'),
                        const SizedBox(width: 8),
                        _buildQuickResponseChip('Ok, thanks!'),
                        const SizedBox(width: 8),
                        _buildQuickResponseChip('See you soon'),
                      ],
                    ),
                  ),

                // Input Row
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        constraints: const BoxConstraints(
                          minHeight: 48,
                          maxHeight: 100,
                        ),
                        decoration: BoxDecoration(
                          color: dark ? TColors.dark : const Color(0xFFF3F4F6),
                          borderRadius: BorderRadius.circular(24),
                          // Removed unnecessary border to fix visual artifact
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _messageController,
                                decoration: InputDecoration(
                                  hintText: 'Type a message...',
                                  hintStyle: TextStyle(
                                    color: dark
                                        ? TColors.lightGrey
                                        : Colors.grey[500],
                                    fontSize: 15,
                                  ),
                                  border: InputBorder.none,
                                  isDense: true,
                                  contentPadding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                ),
                                style: TextStyle(
                                  color: textColor,
                                  fontSize: 16,
                                ),
                                maxLines: null,
                                keyboardType: TextInputType.multiline,
                                textCapitalization:
                                    TextCapitalization.sentences,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    GestureDetector(
                      onTap: _sendMessage,
                      child: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: TColors.primary,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: TColors.primary.withOpacity(0.4),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Iconsax.send_1,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(
    ChatMessage message,
    bool dark,
    bool isFirstInSequence,
  ) {
    final isMe = !message.isFromDriver;
    final bubbleColor = isMe
        ? TColors.primary
        : (dark ? TColors.darkerGrey : Colors.white);
    final textColor = isMe
        ? Colors.white
        : (dark ? TColors.white : TColors.black);

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(
          top: isFirstInSequence ? 12 : 2,
          left: isMe ? 60 : 0,
          right: isMe ? 0 : 60,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: bubbleColor,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(
              isMe ? 18 : (isFirstInSequence ? 0 : 4),
            ),
            bottomRight: Radius.circular(
              isMe ? (isFirstInSequence ? 0 : 4) : 18,
            ),
          ),
          boxShadow: isMe
              ? []
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 2,
                    offset: const Offset(0, 1),
                  ),
                ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message.text,
              style: TextStyle(color: textColor, fontSize: 15, height: 1.3),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _formatTime(message.timestamp),
                  style: TextStyle(
                    color: isMe
                        ? Colors.white.withOpacity(0.7)
                        : (dark ? Colors.grey[500] : Colors.grey[400]),
                    fontSize: 10,
                  ),
                ),
                if (isMe) ...[
                  const SizedBox(width: 4),
                  Obx(
                    () => Icon(
                      message.isSent.value ? Icons.done_all : Icons.done,
                      size: 14,
                      color: Colors.white.withOpacity(0.8),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickResponseChip(String text) {
    final dark = THelperFunctions.isDarkMode(context);
    final chipColor = dark ? TColors.dark : Colors.white;
    final borderColor = dark ? TColors.darkGrey : Colors.grey[300]!;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _sendQuickMessage(text),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: chipColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: borderColor),
          ),
          child: Text(
            text,
            style: TextStyle(
              color: dark ? TColors.lightGrey : TColors.darkGrey,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  bool _shouldShowQuickResponses() {
    return _messages.isNotEmpty && _messages.last.isFromDriver;
  }

  String _formatTime(DateTime dateTime) {
    return DateFormat('h:mm a').format(dateTime);
  }
}
