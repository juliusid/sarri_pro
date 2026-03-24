import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sarri_ride/features/payment/controllers/payment_controller.dart';
import 'package:sarri_ride/features/ride/controllers/ride_controller.dart';
import 'package:sarri_ride/features/ride/widgets/payment_dialogs.dart';
import 'package:sarri_ride/utils/constants/colors.dart';
import 'package:sarri_ride/utils/constants/sizes.dart';
import 'package:sarri_ride/utils/helpers/helper_functions.dart';
import 'package:sarri_ride/features/ride/widgets/common_widgets.dart';
import 'package:sarri_ride/features/ride/widgets/ride_selection_widget.dart';
import 'package:iconsax/iconsax.dart';
import 'package:sarri_ride/features/rating/services/rating_service.dart';

class TripCompletedWidget extends StatefulWidget {
  final RideType? selectedRideType;
  final bool isPaymentCompleted;
  final String tripId;
  final VoidCallback onDone;

  const TripCompletedWidget({
    super.key,
    required this.selectedRideType,
    required this.isPaymentCompleted,
    required this.tripId,
    required this.onDone,
  });

  @override
  State<TripCompletedWidget> createState() => _TripCompletedWidgetState();
}

class _TripCompletedWidgetState extends State<TripCompletedWidget> {
  // Track if user wants to change method
  bool _isChangingMethod = false;
  int selectedRating = 0;

  // Rating State
  final TextEditingController _reviewController = TextEditingController();
  final List<String> _selectedTags = [];
  bool _isSubmitting = false;

  // Available tags
  final List<String> _availableTags = [
    'professional',
    'friendly',
    'clean_vehicle',
    'safe_driving',
    'on_time',
    'good_communication',
    'rude',
    'unsafe_driving',
    'dirty_vehicle',
    'late',
    'poor_communication',
  ];

  @override
  void initState() {
    super.initState();
    // Fetch saved cards immediately so they are ready if user wants to switch
    Get.find<PaymentController>().fetchSavedCards();
  }

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dark = THelperFunctions.isDarkMode(context);
    final rideController = Get.find<RideController>();
    final backgroundColor = dark ? TColors.dark : TColors.white;
    final textColor = dark ? TColors.white : TColors.textPrimary;
    final subtitleColor = dark ? TColors.lightGrey : TColors.textSecondary;
    final cardColor = dark
        ? TColors.darkerGrey.withOpacity(0.3)
        : const Color(0xFFF9FAFB);

    // Get the current price from RideType or fallback
    final price = widget.selectedRideType?.price ?? 0;

    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      padding: const EdgeInsets.only(top: 12, bottom: 30),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const DragHandle(),

          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: TSizes.defaultSpace,
              ),
              child: Column(
                children: [
                  const SizedBox(height: 16),

                  // Success Icon
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: TColors.success.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Iconsax.tick_circle,
                      color: TColors.success,
                      size: 40,
                    ),
                  ),

                  const SizedBox(height: 16),
                  Text(
                    'Trip Completed!',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'How was your ride?',
                    style: TextStyle(fontSize: 16, color: subtitleColor),
                  ),

                  const SizedBox(height: 32),

                  // Fare & Status Card
                  Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 20,
                      horizontal: 24,
                    ),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: dark ? Colors.transparent : Colors.grey[200]!,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Total Fare',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: subtitleColor,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '₦$price',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: textColor,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: widget.isPaymentCompleted
                                ? TColors.success.withOpacity(0.15)
                                : TColors.warning.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: Text(
                            widget.isPaymentCompleted ? 'Paid' : 'Pending',
                            style: TextStyle(
                              color: widget.isPaymentCompleted
                                  ? TColors.success
                                  : TColors.warning,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // PAYMENT SECTION
                  if (!widget.isPaymentCompleted) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Payment Method',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                        if (!_isChangingMethod)
                          TextButton(
                            onPressed: () {
                              setState(() => _isChangingMethod = true);
                              Get.find<PaymentController>().fetchSavedCards();
                            },
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              minimumSize: const Size(0, 0),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: const Text(
                              'Change',
                              style: TextStyle(
                                color: TColors.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // If changing, show all options. If not, show only selected.
                    if (_isChangingMethod)
                      _buildAllPaymentOptions(context, dark)
                    else
                      _buildSelectedPaymentOption(
                        context,
                        dark,
                        rideController,
                      ),

                    const SizedBox(height: 32),
                  ],

                  // --- RATING SECTION ---
                  Text(
                    'Rate your Driver',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      return GestureDetector(
                        onTap: () => setState(() => selectedRating = index + 1),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          child: Icon(
                            Iconsax.star1, // Using filled variant
                            color: index < selectedRating
                                ? Colors.amber
                                : (dark ? Colors.grey[700] : Colors.grey[300]),
                            size: 36,
                          ),
                        ),
                      );
                    }),
                  ),

                  // Tags (Only show if a rating is selected)
                  if (selectedRating > 0) ...[
                    const SizedBox(height: 24),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      alignment: WrapAlignment.center,
                      children: _availableTags.map((tag) {
                        final isSelected = _selectedTags.contains(tag);
                        return ChoiceChip(
                          label: Text(
                            tag.replaceAll('_', ' ').capitalizeFirst!,
                          ),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                _selectedTags.add(tag);
                              } else {
                                _selectedTags.remove(tag);
                              }
                            });
                          },
                          backgroundColor: cardColor,
                          selectedColor: TColors.primary.withOpacity(0.1),
                          labelStyle: TextStyle(
                            color: isSelected ? TColors.primary : subtitleColor,
                            fontSize: 13,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                            side: BorderSide(
                              color: isSelected
                                  ? TColors.primary
                                  : Colors.transparent,
                            ),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          showCheckmark: false,
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 24),

                    // Review Text Field
                    TextField(
                      controller: _reviewController,
                      decoration: InputDecoration(
                        hintText: 'Leave a comment...',
                        hintStyle: TextStyle(color: subtitleColor),
                        filled: true,
                        fillColor: cardColor,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.all(16),
                      ),
                      maxLines: 3,
                      style: TextStyle(fontSize: 14, color: textColor),
                    ),
                  ],

                  const SizedBox(height: 32),

                  // DONE / SUBMIT BUTTON
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: (widget.isPaymentCompleted && !_isSubmitting)
                          ? _submitRatingAndFinish
                          : null, // Disable "Done" until paid.
                      style: ElevatedButton.styleFrom(
                        backgroundColor: TColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      child: _isSubmitting
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Text(
                              selectedRating > 0 ? 'Submit Rating' : 'Done',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                  SizedBox(height: MediaQuery.of(context).padding.bottom),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _submitRatingAndFinish() async {
    if (selectedRating > 0) {
      setState(() => _isSubmitting = true);

      final ratingService = Get.put(RatingService());

      final success = await ratingService.rateDriver(
        tripId: widget.tripId,
        rating: selectedRating.toDouble(),
        review: _reviewController.text.trim(),
        tags: _selectedTags,
      );

      if (mounted) {
        setState(() => _isSubmitting = false);
        if (success) {
          THelperFunctions.showSuccessSnackBar(
            'Thank you',
            'Rating submitted successfully',
          );
        } else {
          THelperFunctions.showSnackBar(
            'Could not submit rating, but trip is done.',
          );
        }
        widget.onDone();
      }
    } else {
      widget.onDone();
    }
  }

  Widget _buildSelectedPaymentOption(
    BuildContext context,
    bool dark,
    RideController controller,
  ) {
    final method = controller.selectedPaymentMethod.value;

    IconData icon;
    Color color;
    String displayTitle = method;

    // Determine type
    if (method.toLowerCase().contains('cash')) {
      icon = Iconsax.money;
      color = TColors.success;
      displayTitle = 'Cash';
    } else {
      // Assume card for anything else (Wallet removed)
      icon = Iconsax.card;
      color = TColors.info;
      // If the method string was 'Wallet' or something legacy, fallback to Card generic
      if (method.toLowerCase().contains('wallet')) {
        displayTitle = 'Card'; // Force fallback if state was stuck
      }
    }

    return _buildPaymentCard(
      context: context,
      dark: dark,
      icon: icon,
      color: color,
      title: displayTitle,
      subtitle: 'Tap to Pay',
      onTap: () => _initiatePayment(method),
    );
  }

  Widget _buildAllPaymentOptions(BuildContext context, bool dark) {
    final paymentController = Get.find<PaymentController>();

    return Obx(() {
      return Column(
        children: [
          // Saved Cards List
          if (paymentController.isLoading.value)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Center(child: CircularProgressIndicator()),
            )
          else
            ...paymentController.savedCards.map((card) {
              return Column(
                children: [
                  _buildPaymentCard(
                    context: context,
                    dark: dark,
                    icon: Iconsax.card,
                    color: TColors.info,
                    title: '${card.brand} •••• ${card.last4}',
                    subtitle: 'Expires ${card.expiry}',
                    onTap: () => _updateAndPay(
                      '${card.brand} •••• ${card.last4}',
                      cardId: card.cardId,
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              );
            }),

          // Add New Card
          _buildPaymentCard(
            context: context,
            dark: dark,
            icon: Iconsax.add_circle,
            color: TColors.info,
            title: 'Add New Card',
            subtitle: 'Secure payment',
            onTap: () => PaymentDialogs.showCardPayment(
              context,
              selectedRideType: widget.selectedRideType,
              tripId: widget.tripId,
            ),
          ),
          const SizedBox(height: 12),

          // Cash
          _buildPaymentCard(
            context: context,
            dark: dark,
            icon: Iconsax.money,
            color: TColors.success,
            title: 'Cash',
            subtitle: 'Pay driver directly',
            onTap: () => _updateAndPay('Cash'),
          ),
        ],
      );
    });
  }

  Widget _buildPaymentCard({
    required BuildContext context,
    required bool dark,
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: dark ? TColors.darkerGrey.withOpacity(0.3) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.15)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: dark ? TColors.white : TColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: dark ? TColors.lightGrey : TColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Iconsax.arrow_right_3,
              size: 18,
              color: dark ? Colors.white70 : Colors.grey[400],
            ),
          ],
        ),
      ),
    );
  }

  void _updateAndPay(String method, {String? cardId}) {
    // 1. Update selection in RideController so it persists visually
    final rideController = Get.find<RideController>();
    rideController.selectedPaymentMethod.value = method;
    if (cardId != null) {
      rideController.selectedCardId.value = cardId;
    }

    // 2. Hide the list
    setState(() => _isChangingMethod = false);

    // 3. Initiate payment
    _initiatePayment(method);
  }

  void _initiatePayment(String method) {
    final controller = Get.find<PaymentController>();
    final rideController = Get.find<RideController>();

    String apiMethod = method.toLowerCase();
    String? currentCardId = rideController.selectedCardId.value;

    // 1. Normalize the API method string & Remove Wallet Logic
    if (apiMethod.contains('cash')) {
      apiMethod = 'cash';
      currentCardId = null;
    } else {
      // Default to card for everything else
      apiMethod = 'card';
    }

    // 2. Handle Card Logic
    if (apiMethod == 'card') {
      if (currentCardId == null || currentCardId.isEmpty) {
        PaymentDialogs.showCardPayment(
          context,
          selectedRideType: widget.selectedRideType,
          tripId: widget.tripId,
        );
        return;
      }
    }

    // 3. Execute Payment
    controller.initiateTripPayment(
      widget.tripId,
      paymentMethod: apiMethod,
      cardId: currentCardId,
    );
  }
}
