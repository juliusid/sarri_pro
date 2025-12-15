import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sarri_ride/features/payment/controllers/payment_controller.dart';
import 'package:sarri_ride/features/ride/controllers/ride_controller.dart';
import 'package:sarri_ride/features/ride/widgets/payment_dialogs.dart';
import 'package:sarri_ride/utils/constants/colors.dart';
import 'package:sarri_ride/utils/constants/sizes.dart';
import 'package:sarri_ride/utils/helpers/helper_functions.dart';
import 'package:sarri_ride/features/ride/widgets/common_widgets.dart';
import 'package:sarri_ride/features/ride/widgets/ride_selection_widget.dart'; // For RideType
import 'package:iconsax/iconsax.dart';
import 'package:sarri_ride/features/rating/services/rating_service.dart'; // Import RatingService

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
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dark = THelperFunctions.isDarkMode(context);
    final rideController = Get.find<RideController>();

    // Get the current price from RideType or fallback
    final price = widget.selectedRideType?.price ?? 0;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            dark ? TColors.dark : TColors.white,
            dark ? TColors.darkerGrey : Colors.grey[50]!,
          ],
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
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
                  const SizedBox(height: TSizes.spaceBtwItems),

                  // Success Icon
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: TColors.success,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: TColors.success.withOpacity(0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 30,
                    ),
                  ),

                  const SizedBox(height: TSizes.spaceBtwItems),
                  Text(
                    'Trip Completed!',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: TSizes.xs),
                  Text(
                    'Thank you for choosing our service',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: dark ? TColors.lightGrey : Colors.grey[600],
                    ),
                  ),

                  const SizedBox(height: TSizes.spaceBtwSections),

                  // Fare Card
                  Container(
                    padding: const EdgeInsets.all(TSizes.defaultSpace),
                    decoration: BoxDecoration(
                      color: TColors.primary.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(TSizes.cardRadiusLg),
                      border: Border.all(
                        color: TColors.primary.withOpacity(0.1),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Trip Fare',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '₦$price',
                              style: Theme.of(context).textTheme.headlineSmall
                                  ?.copyWith(
                                    color: TColors.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: widget.isPaymentCompleted
                                ? TColors.success
                                : TColors.warning,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            widget.isPaymentCompleted ? 'Paid' : 'Pending',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: TSizes.spaceBtwSections),

                  // PAYMENT SECTION
                  if (!widget.isPaymentCompleted) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _isChangingMethod
                              ? 'Select Payment Method'
                              : 'Payment Method',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        // Show Change button only if not already changing
                        if (!_isChangingMethod)
                          TextButton(
                            onPressed: () =>
                                setState(() => _isChangingMethod = true),
                            child: const Text('Change'),
                          ),
                      ],
                    ),
                    const SizedBox(height: TSizes.spaceBtwItems),

                    // If changing, show all options. If not, show only selected.
                    if (_isChangingMethod)
                      _buildAllPaymentOptions(context, dark)
                    else
                      _buildSelectedPaymentOption(
                        context,
                        dark,
                        rideController,
                      ),
                  ],

                  // --- RATING SECTION ---
                  const SizedBox(height: TSizes.spaceBtwSections),
                  Text(
                    'Rate your experience',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: TSizes.spaceBtwItems),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      return GestureDetector(
                        onTap: () => setState(() => selectedRating = index + 1),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Icon(
                            index < selectedRating
                                ? Icons.star
                                : Icons.star_border,
                            color: TColors.warning,
                            size: 40,
                          ),
                        ),
                      );
                    }),
                  ),

                  // Tags (Only show if a rating is selected)
                  if (selectedRating > 0) ...[
                    const SizedBox(height: TSizes.spaceBtwItems),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      alignment: WrapAlignment.center,
                      children: _availableTags.map((tag) {
                        final isSelected = _selectedTags.contains(tag);
                        return FilterChip(
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
                          backgroundColor: dark
                              ? TColors.darkerGrey
                              : Colors.grey[100],
                          selectedColor: TColors.primary.withOpacity(0.2),
                          labelStyle: TextStyle(
                            color: isSelected
                                ? TColors.primary
                                : (dark ? TColors.white : TColors.black),
                            fontSize: 12,
                          ),
                          // Customizing chip visual
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                            side: BorderSide(
                              color: isSelected
                                  ? TColors.primary
                                  : Colors.transparent,
                            ),
                          ),
                          showCheckmark: false,
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: TSizes.spaceBtwItems),

                    // Review Text Field
                    TextFormField(
                      controller: _reviewController,
                      decoration: InputDecoration(
                        hintText: 'Add a comment (optional)...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: dark ? TColors.darkGrey : TColors.grey,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: dark ? TColors.darkGrey : TColors.grey,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: TColors.primary),
                        ),
                        filled: true,
                        fillColor: dark ? TColors.darkerGrey : Colors.grey[50],
                      ),
                      maxLines: 3,
                      style: TextStyle(
                        fontSize: 14,
                        color: dark ? TColors.white : TColors.black,
                      ),
                    ),
                  ],

                  const SizedBox(height: TSizes.spaceBtwSections),

                  // DONE / SUBMIT BUTTON
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: (widget.isPaymentCompleted && !_isSubmitting)
                          ? _submitRatingAndFinish
                          : null, // Disable "Done" until paid.
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
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
                          : Text(selectedRating > 0 ? 'Submit Rating' : 'Done'),
                    ),
                  ),
                  SizedBox(
                    height:
                        MediaQuery.of(context).padding.bottom +
                        TSizes.defaultSpace,
                  ),
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

      // Initialize service locally or via Get.put
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
          // If rating fails, allow them to proceed anyway so they aren't stuck
          THelperFunctions.showSnackBar(
            'Could not submit rating, but trip is done.',
          );
        }
        widget.onDone(); // Navigate away
      }
    } else {
      // Just finish without rating
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
    if (method.toLowerCase().contains('cash')) {
      icon = Iconsax.money;
      color = TColors.success;
    } else if (method.toLowerCase().contains('wallet')) {
      icon = Iconsax.wallet_money;
      color = TColors.primary;
    } else {
      icon = Iconsax.card;
      color = TColors.info;
    }

    return _buildPaymentCard(
      context: context,
      dark: dark,
      icon: icon,
      color: color,
      title: method, // e.g. "Cash" or "Visa ****"
      subtitle: 'Tap to Pay',
      onTap: () => _initiatePayment(method),
    );
  }

  Widget _buildAllPaymentOptions(BuildContext context, bool dark) {
    return Column(
      children: [
        _buildPaymentCard(
          context: context,
          dark: dark,
          icon: Iconsax.wallet_money,
          color: TColors.primary,
          title: 'Wallet',
          subtitle: 'Pay from balance',
          onTap: () => _updateAndPay('Wallet'),
        ),
        const SizedBox(height: TSizes.spaceBtwItems),
        _buildPaymentCard(
          context: context,
          dark: dark,
          icon: Iconsax.card,
          color: TColors.info,
          title: 'Card',
          subtitle: 'Pay with Card',
          onTap: () => PaymentDialogs.showCardPayment(
            context,
            selectedRideType: widget.selectedRideType,
            tripId: widget.tripId,
          ),
        ),
        const SizedBox(height: TSizes.spaceBtwItems),
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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(TSizes.md),
        decoration: BoxDecoration(
          color: dark ? TColors.darkerGrey : Colors.white,
          borderRadius: BorderRadius.circular(TSizes.cardRadiusMd),
          border: Border.all(color: color.withOpacity(0.3)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(TSizes.sm),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(TSizes.borderRadiusMd),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: TSizes.spaceBtwItems),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
            Icon(
              Iconsax.arrow_right_3,
              size: 16,
              color: dark ? Colors.white70 : Colors.grey,
            ),
          ],
        ),
      ),
    );
  }

  void _updateAndPay(String method) {
    // 1. Update selection in controller
    Get.find<RideController>().selectedPaymentMethod.value = method;

    // 2. Hide the list
    setState(() => _isChangingMethod = false);

    // 3. Initiate payment immediately
    _initiatePayment(method);
  }

  void _initiatePayment(String method) {
    final controller = Get.find<PaymentController>();
    final rideController = Get.find<RideController>();

    // Map display name to API value
    String apiMethod = method.toLowerCase();
    if (apiMethod.contains('wallet'))
      apiMethod = 'transfer'; // Based on wallet notes
    if (apiMethod.contains('cash')) apiMethod = 'cash';
    if (apiMethod.contains('card')) apiMethod = 'card';

    // For card, show dialog to select which card if needed
    if (apiMethod == 'card') {
      PaymentDialogs.showCardPayment(
        context,
        selectedRideType: widget.selectedRideType,
        tripId: widget.tripId,
      );
      return;
    }

    // For Cash/Transfer, call directly
    controller.initiateTripPayment(
      widget.tripId,
      paymentMethod: apiMethod,
      cardId: rideController.selectedCardId.value.isNotEmpty
          ? rideController.selectedCardId.value
          : null,
    );
  }
}
