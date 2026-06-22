import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:sarri_ride/features/emergency/controllers/emergency_controller.dart';
import 'package:sarri_ride/features/emergency/screens/emergency_chat_screen.dart';
import 'package:sarri_ride/utils/constants/colors.dart';
import 'package:sarri_ride/utils/constants/sizes.dart';
import 'package:sarri_ride/utils/helpers/helper_functions.dart';

class SwipeToSOSBottomSheet extends StatefulWidget {
  final String? tripId;
  
  const SwipeToSOSBottomSheet({super.key, this.tripId});

  @override
  State<SwipeToSOSBottomSheet> createState() => _SwipeToSOSBottomSheetState();
}

class _SwipeToSOSBottomSheetState extends State<SwipeToSOSBottomSheet> {
  final EmergencyController controller = Get.put(EmergencyController());
  
  bool _isSwiped = false;
  int _countdown = 5;
  Timer? _timer;
  
  double _dragPosition = 0.0;

  void _startCountdown() {
    setState(() {
      _isSwiped = true;
      _countdown = 5;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      setState(() {
        if (_countdown > 0) {
          _countdown--;
        }
      });

      if (_countdown == 0) {
        timer.cancel();
        _triggerEmergency();
      }
    });
  }

  void _cancelEmergency() {
    _timer?.cancel();
    setState(() {
      _isSwiped = false;
      _dragPosition = 0.0;
      _countdown = 5;
    });
    THelperFunctions.showSnackBar('Emergency SOS Cancelled');
  }

  Future<void> _triggerEmergency() async {
    // Automatically trigger an "urgent" emergency
    await controller.reportEmergency(
      category: 'emergency_sos',
      description: 'Emergency triggered via quick SOS swipe during/after ride.',
      tripId: widget.tripId,
    );

    if (controller.hasActiveEmergency) {
      Get.back(); // close sheet
      Get.to(() => const EmergencyChatScreen());
    } else {
      Get.back(); // close sheet
      THelperFunctions.showErrorSnackBar('SOS Failed', 'Failed to trigger emergency. Try again.');
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dark = THelperFunctions.isDarkMode(context);

    return Container(
      padding: const EdgeInsets.all(TSizes.defaultSpace),
      decoration: BoxDecoration(
        color: dark ? TColors.dark : Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(TSizes.cardRadiusLg),
          topRight: Radius.circular(TSizes.cardRadiusLg),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: TSizes.spaceBtwSections),
          
          if (!_isSwiped) ...[
            Text(
              'Emergency SOS',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: TColors.error,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: TSizes.sm),
            Text(
              'Swipe to immediately alert our support team and share your location.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: dark ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
            const SizedBox(height: TSizes.spaceBtwSections),
            
            // Swipe Button
            _buildSwipeSlider(context),
          ] else ...[
            // Countdown View
            Container(
              padding: const EdgeInsets.all(TSizes.lg),
              decoration: BoxDecoration(
                color: TColors.error.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Text(
                '$_countdown',
                style: Theme.of(context).textTheme.displayLarge?.copyWith(
                  color: TColors.error,
                  fontWeight: FontWeight.bold,
                  fontSize: 60,
                ),
              ),
            ),
            const SizedBox(height: TSizes.spaceBtwItems),
            Text(
              'Triggering SOS in $_countdown seconds...',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: TColors.error,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: TSizes.spaceBtwSections),
            
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _cancelEmergency,
                style: ElevatedButton.styleFrom(
                  backgroundColor: dark ? TColors.darkerGrey : Colors.grey[200],
                  foregroundColor: dark ? Colors.white : Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: TSizes.md),
                ),
                child: const Text('CANCEL SOS'),
              ),
            )
          ],
          const SizedBox(height: TSizes.spaceBtwSections),
        ],
      ),
    );
  }

  Widget _buildSwipeSlider(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double sliderWidth = constraints.maxWidth;
        final double buttonWidth = 70.0;
        final double maxDrag = sliderWidth - buttonWidth;

        return Container(
          height: 60,
          decoration: BoxDecoration(
            color: TColors.error.withOpacity(0.2),
            borderRadius: BorderRadius.circular(30),
          ),
          child: Stack(
            children: [
              Center(
                child: Text(
                  'SWIPE TO SOS >>',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: TColors.error,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),
              ),
              Positioned(
                left: _dragPosition,
                child: GestureDetector(
                  onHorizontalDragUpdate: (details) {
                    setState(() {
                      _dragPosition += details.delta.dx;
                      if (_dragPosition < 0) _dragPosition = 0;
                      if (_dragPosition > maxDrag) _dragPosition = maxDrag;
                    });
                  },
                  onHorizontalDragEnd: (details) {
                    if (_dragPosition > maxDrag * 0.8) {
                      setState(() {
                        _dragPosition = maxDrag;
                      });
                      _startCountdown();
                    } else {
                      setState(() {
                        _dragPosition = 0.0;
                      });
                    }
                  },
                  child: Container(
                    width: buttonWidth,
                    height: 60,
                    decoration: BoxDecoration(
                      color: TColors.error,
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: TColors.error.withOpacity(0.5),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Iconsax.arrow_right_1,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
