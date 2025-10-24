import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sarri_ride/utils/constants/colors.dart';
import 'package:sarri_ride/utils/helpers/helper_functions.dart';
import 'package:iconsax/iconsax.dart';
import 'dart:async';

class CallScreen extends StatefulWidget {
  final String driverName;
  final String driverPhone;
  final String carModel;
  final String plateNumber;
  final double rating;

  const CallScreen({
    super.key,
    required this.driverName,
    required this.driverPhone,
    required this.carModel,
    required this.plateNumber,
    required this.rating,
  });

  @override
  State<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen> with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  Timer? _callTimer;
  int _callDuration = 0;
  bool _isMuted = false;
  bool _isSpeakerOn = false;
  CallStatus _callStatus = CallStatus.connecting;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startCall();
  }

  void _initializeAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _pulseController.repeat(reverse: true);
  }

  void _startCall() {
    // Simulate call connection
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _callStatus = CallStatus.connected;
        });
        _startCallTimer();
      }
    });
  }

  void _startCallTimer() {
    _callTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _callDuration++;
        });
      }
    });
  }

  String _formatCallDuration(int seconds) {
    int minutes = seconds ~/ 60;
    int remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  void _endCall() {
    _callTimer?.cancel();
    Get.back();
    THelperFunctions.showSnackBar('Call ended');
  }

  void _toggleMute() {
    setState(() {
      _isMuted = !_isMuted;
    });
    THelperFunctions.showSnackBar(_isMuted ? 'Microphone muted' : 'Microphone unmuted');
  }

  void _toggleSpeaker() {
    setState(() {
      _isSpeakerOn = !_isSpeakerOn;
    });
    THelperFunctions.showSnackBar(_isSpeakerOn ? 'Speaker on' : 'Speaker off');
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _callTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dark = THelperFunctions.isDarkMode(context);
    
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [ TColors.primary.withOpacity(0.8),
              dark ? TColors.darkerGrey : TColors.lightGrey,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Status bar and back button
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Get.back(),
                      icon: const Icon(
                        Icons.arrow_back,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      _getCallStatusText(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Spacer(),
                    const SizedBox(width: 48), // Balance the back button
                  ],
                ),
              ),

              const Spacer(),

              // Driver info section
              Column(
                children: [
                  // Driver avatar with pulse animation
                  AnimatedBuilder(
                    animation: _pulseAnimation,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _callStatus == CallStatus.connecting ? _pulseAnimation.value : 1.0,
                        child: Container(
                          width: 150,
                          height: 150,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withOpacity(0.2),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.3),
                              width: 3,
                            ),
                          ),
                          child: const CircleAvatar(
                            radius: 70,
                            backgroundColor: Colors.white,
                            child: Icon(
                              Iconsax.user,
                              size: 60,
                              color: TColors.primary,
                            ),
                          ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 24),

                  // Driver name
                  Text(
                    widget.driverName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Rating and car info
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 20),
                      const SizedBox(width: 4),
                      Text(
                        '${widget.rating}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const Text(
                        ' • ',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        '${widget.carModel} • ${widget.plateNumber}',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Call duration (when connected)
                  if (_callStatus == CallStatus.connected)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _formatCallDuration(_callDuration),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),

              const Spacer(),

              // Call controls
              Container(
                padding: const EdgeInsets.all(32),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Mute button
                    _buildCallButton(
                      icon: _isMuted ? Iconsax.microphone_slash : Iconsax.microphone,
                      isActive: _isMuted,
                      onPressed: _toggleMute,
                      backgroundColor: Colors.black.withOpacity(0.3),
                    ),

                    // End call button
                    _buildCallButton(
                      icon: Iconsax.call_slash,
                      isActive: true,
                      onPressed: _endCall,
                      backgroundColor: TColors.error,
                      size: 70,
                    ),

                    // Speaker button
                    _buildCallButton(
                      icon: _isSpeakerOn ? Iconsax.volume_high : Iconsax.volume_low_1,
                      isActive: _isSpeakerOn,
                      onPressed: _toggleSpeaker,
                      backgroundColor: Colors.black.withOpacity(0.3),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCallButton({
    required IconData icon,
    required bool isActive,
    required VoidCallback onPressed,
    required Color backgroundColor,
    double size = 60,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: backgroundColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(
          icon,
          color: Colors.white,
          size: size * 0.4,
        ),
      ),
    );
  }

  String _getCallStatusText() {
    switch (_callStatus) {
      case CallStatus.connecting:
        return 'Connecting...';
      case CallStatus.connected:
        return 'Connected';
      case CallStatus.ended:
        return 'Call Ended';
    }
  }
}

enum CallStatus {
  connecting,
  connected,
  ended,
} 