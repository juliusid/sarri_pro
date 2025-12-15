import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import 'package:sarri_ride/features/emergency/controllers/emergency_controller.dart';
import 'package:sarri_ride/utils/constants/colors.dart';
import 'package:sarri_ride/utils/constants/sizes.dart';
import 'package:sarri_ride/utils/helpers/helper_functions.dart';

class EmergencyChatScreen extends StatefulWidget {
  const EmergencyChatScreen({super.key});

  @override
  State<EmergencyChatScreen> createState() => _EmergencyChatScreenState();
}

class _EmergencyChatScreenState extends State<EmergencyChatScreen> {
  final EmergencyController controller = Get.find<EmergencyController>();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  Widget build(BuildContext context) {
    final dark = THelperFunctions.isDarkMode(context);

    return WillPopScope(
      onWillPop: () async {
        // Warn user before leaving emergency screen
        return await _showExitConfirmation(context) ?? false;
      },
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: TColors.error, // Red background for urgency
          foregroundColor: Colors.white,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Emergency Support', style: TextStyle(fontSize: 16)),
              Obx(
                () => Text(
                  'ID: ${controller.currentEmergencyDisplayId}',
                  style: const TextStyle(fontSize: 12, color: Colors.white70),
                ),
              ),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Iconsax.logout),
              tooltip: 'Resolve / Close',
              onPressed: () => _showResolveDialog(context),
            ),
          ],
        ),
        body: Column(
          children: [
            // Status Banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              color: TColors.error.withOpacity(0.1),
              child: const Text(
                'Support agents are being notified. Please stay calm.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: TColors.error,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),

            // Chat Area
            Expanded(
              child: Obx(() {
                final messages = controller.messages;
                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  reverse: false, // Depending on your list order
                  itemBuilder: (context, index) {
                    // Your socket/API likely returns latest last if appending
                    final msg = messages[index];
                    // Determine if message is from me or support
                    // Note: You might need to store currentUserId in controller to compare
                    final isMe =
                        msg['senderModel'] == 'Client' ||
                        msg['senderModel'] == 'Driver';
                    return _buildMessageBubble(msg, isMe, dark);
                  },
                );
              }),
            ),

            // Typing Indicator
            Obx(() {
              if (controller.typingUsers.isNotEmpty) {
                return Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    'Support is typing...',
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                );
              }
              return const SizedBox.shrink();
            }),

            // Input Area
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: dark ? TColors.dark : Colors.white,
                border: Border(top: BorderSide(color: Colors.grey.shade300)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: const InputDecoration(
                        hintText: 'Type a message...',
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Iconsax.send_1, color: TColors.error),
                    onPressed: _sendMessage,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble(Map<String, dynamic> msg, bool isMe, bool dark) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.all(12),
        constraints: BoxConstraints(maxWidth: Get.width * 0.75),
        decoration: BoxDecoration(
          color: isMe
              ? TColors.error
              : (dark ? TColors.darkerGrey : Colors.grey[200]),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isMe)
              Text(
                msg['sender']['FirstName'] ?? 'Support',
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Colors.black54,
                ),
              ),
            Text(
              msg['message'] ?? '',
              style: TextStyle(
                color: isMe
                    ? Colors.white
                    : (dark ? Colors.white : Colors.black),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _formatTime(msg['createdAt']),
              style: TextStyle(
                fontSize: 10,
                color: isMe ? Colors.white70 : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(String? timestamp) {
    if (timestamp == null) return '';
    final date = DateTime.tryParse(timestamp);
    if (date == null) return '';
    return DateFormat('HH:mm').format(date);
  }

  void _sendMessage() {
    if (_messageController.text.trim().isNotEmpty) {
      controller.sendMessage(_messageController.text.trim());
      _messageController.clear();
    }
  }

  Future<bool?> _showExitConfirmation(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Leave Emergency?'),
        content: const Text(
          'Leaving this screen will not cancel the emergency report. You can return later.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Stay'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Leave'),
          ),
        ],
      ),
    );
  }

  void _showResolveDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Resolve Emergency'),
        content: const Text(
          'Are you safe now? This will close the emergency ticket.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              controller.closeEmergencySession();
              Get.back(); // Exit screen
            },
            child: const Text(
              'Yes, I am safe',
              style: TextStyle(color: TColors.success),
            ),
          ),
        ],
      ),
    );
  }
}
