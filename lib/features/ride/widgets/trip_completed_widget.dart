import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sarri_ride/features/payment/controllers/payment_controller.dart';
import 'package:sarri_ride/features/ride/controllers/ride_controller.dart';
import 'package:sarri_ride/features/payment/screens/payment_methods_screen.dart';
import 'package:sarri_ride/utils/constants/colors.dart';
import 'package:sarri_ride/utils/constants/sizes.dart';
import 'package:sarri_ride/utils/helpers/helper_functions.dart';
import 'package:sarri_ride/features/ride/widgets/common_widgets.dart';
import 'package:sarri_ride/features/ride/widgets/ride_selection_widget.dart';
import 'package:iconsax/iconsax.dart';
import 'package:sarri_ride/features/rating/services/rating_service.dart';

// ---------------------------------------------------------------------------
// Phase enum — controls which section is rendered
// ---------------------------------------------------------------------------
enum _PaymentPhase { pending, confirmed, rating }

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

class _TripCompletedWidgetState extends State<TripCompletedWidget>
    with TickerProviderStateMixin {
  // ---- Controllers ----
  late final RideController _rideController;
  late final PaymentController _paymentController;

  // ---- Phase state ----
  _PaymentPhase _phase = _PaymentPhase.pending;

  // ---- Payment UI state ----
  /// Which method the user has chosen to pay with this session.
  String? _selectedMethod; // 'cash', 'card:<cardId>', null = not chosen
  bool _hasPaidCash = false; // user tapped "I've Paid Cash"

  // ---- Rating state ----
  int _selectedRating = 0;
  final TextEditingController _reviewController = TextEditingController();
  final List<String> _selectedTags = [];
  bool _isSubmittingRating = false;

  static const List<String> _positiveTags = [
    'professional',
    'friendly',
    'clean_vehicle',
    'safe_driving',
    'on_time',
    'good_communication',
  ];
  static const List<String> _negativeTags = [
    'rude',
    'unsafe_driving',
    'dirty_vehicle',
    'late',
    'poor_communication',
  ];

  // ---- Animation ----
  late final AnimationController _checkAnimController;
  late final Animation<double> _checkScaleAnim;

  @override
  void initState() {
    super.initState();
    _rideController = Get.find<RideController>();
    _paymentController = Get.find<PaymentController>();

    // Prefetch saved cards so they're ready if user picks Card.
    _paymentController.fetchSavedCards();

    // Set initial phase based on whether payment was already confirmed
    // (e.g. restored after app restart with payment already done).
    if (widget.isPaymentCompleted) {
      _phase = _PaymentPhase.rating;
    }

    // Check controller's live flag too (e.g. for reconnect scenario).
    if (_rideController.isPaymentCompleted.value) {
      _phase = _PaymentPhase.rating;
    }

    // Confirm animation for the "Payment Confirmed" interstitial.
    _checkAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _checkScaleAnim = CurvedAnimation(
      parent: _checkAnimController,
      curve: Curves.elasticOut,
    );

    // Watch for socket/polling payment confirmation.
    ever(_rideController.isPaymentCompleted, (bool paid) {
      if (paid && _phase == _PaymentPhase.pending && mounted) {
        _advanceToConfirmed();
      }
    });
  }

  @override
  void dispose() {
    _reviewController.dispose();
    _checkAnimController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Phase transitions
  // ---------------------------------------------------------------------------

  void _advanceToConfirmed() {
    setState(() => _phase = _PaymentPhase.confirmed);
    _checkAnimController.forward(from: 0);
    // Auto-advance to rating after a brief success moment.
    Future.delayed(const Duration(milliseconds: 1800), () {
      if (mounted) setState(() => _phase = _PaymentPhase.rating);
    });
  }

  // ---------------------------------------------------------------------------
  // Payment actions
  // ---------------------------------------------------------------------------

  Future<void> _payCash() async {
    final result = await _paymentController.initiateTripPayment(
      widget.tripId,
      paymentMethod: 'cash',
    );

    if (!mounted) return;

    if (result == PaymentResult.awaitingConfirmation) {
      setState(() => _hasPaidCash = true);
      // The widget now shows the "Waiting for driver to confirm" banner.
      // isPaymentCompleted socket/polling will auto-advance the phase.
    } else if (result == PaymentResult.success) {
      _advanceToConfirmed();
    } else if (result == PaymentResult.failed) {
      // Error snackbar already shown by controller.
    }
    // PaymentResult.unknown is not expected for cash.
  }

  Future<void> _payWithCard(String cardId) async {
    final result = await _paymentController.initiateTripPayment(
      widget.tripId,
      paymentMethod: 'card',
      cardId: cardId,
    );

    if (!mounted) return;

    if (result == PaymentResult.success) {
      _advanceToConfirmed();
    } else if (result == PaymentResult.unknown) {
      // Polling/socket will fire. Show a passive waiting state.
      setState(() => _hasPaidCash = true); // Reuse the "waiting" banner.
    }
    // failed: snackbar already shown.
  }

  void _skipPayment() {
    // Let user proceed to rating without paying now.
    // The isPaymentCompleted socket will still fire later if driver confirms.
    setState(() => _phase = _PaymentPhase.rating);
  }

  // ---------------------------------------------------------------------------
  // Rating actions
  // ---------------------------------------------------------------------------

  Future<void> _submitRatingAndFinish() async {
    if (_selectedRating == 0) {
      widget.onDone();
      return;
    }

    setState(() => _isSubmittingRating = true);

    final success = await RatingService.instance.rateDriver(
      tripId: widget.tripId,
      rating: _selectedRating.toDouble(),
      review: _reviewController.text.trim(),
      tags: _selectedTags,
    );

    if (!mounted) return;
    setState(() => _isSubmittingRating = false);

    if (success) {
      THelperFunctions.showSuccessSnackBar(
        'Thank you!',
        'Your rating has been submitted.',
      );
    }
    widget.onDone();
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final dark = THelperFunctions.isDarkMode(context);
    final price = widget.selectedRideType?.price ?? 0;

    return Container(
      decoration: BoxDecoration(
        color: dark ? TColors.dark : TColors.white,
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
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 400),
                switchInCurve: Curves.easeOut,
                switchOutCurve: Curves.easeIn,
                child: _buildPhase(context, dark, price),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhase(BuildContext context, bool dark, int price) {
    switch (_phase) {
      case _PaymentPhase.pending:
        return _buildPaymentPendingPhase(context, dark, price);
      case _PaymentPhase.confirmed:
        return _buildPaymentConfirmedPhase(context, dark, price);
      case _PaymentPhase.rating:
        return _buildRatingPhase(context, dark, price);
    }
  }

  // ---------------------------------------------------------------------------
  // PHASE 1 — Payment Pending
  // ---------------------------------------------------------------------------

  Widget _buildPaymentPendingPhase(
    BuildContext context,
    bool dark,
    int price,
  ) {
    return KeyedSubtree(
      key: const ValueKey('pending'),
      child: Column(
        children: [
          const SizedBox(height: 16),

          // ---- Header ----
          _buildHeaderIcon(
            icon: Iconsax.receipt_1,
            color: TColors.primary,
            dark: dark,
          ),
          const SizedBox(height: 14),
          Text(
            'Trip Complete',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: dark ? TColors.white : TColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Please complete payment to finish',
            style: TextStyle(
              fontSize: 14,
              color: dark ? TColors.lightGrey : TColors.textSecondary,
            ),
          ),

          const SizedBox(height: 28),

          // ---- Fare card ----
          _buildFareCard(context, dark, price),

          const SizedBox(height: 28),

          // ---- Payment section ----
          if (_hasPaidCash)
            _buildAwaitingConfirmationBanner(dark)
          else ...[
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'How would you like to pay?',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: dark ? TColors.white : TColors.textPrimary,
                ),
              ),
            ),
            const SizedBox(height: 14),
            _buildPaymentOptions(context, dark, price),
          ],

          const SizedBox(height: 20),

          // ---- Skip link ----
          Center(
            child: TextButton(
              onPressed: _skipPayment,
              child: Text(
                'Skip for now — remind me later',
                style: TextStyle(
                  fontSize: 13,
                  color: dark ? TColors.lightGrey : TColors.textSecondary,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ),

          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }

  Widget _buildFareCard(BuildContext context, bool dark, int price) {
    final cardColor = dark
        ? TColors.darkerGrey.withOpacity(0.35)
        : const Color(0xFFF9FAFB);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: dark ? Colors.transparent : Colors.grey.shade200,
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
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: dark ? TColors.lightGrey : TColors.textSecondary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '₦$price',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: dark ? TColors.white : TColors.textPrimary,
                ),
              ),
            ],
          ),
          Obx(() {
            final isPaid = _rideController.isPaymentCompleted.value;
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: isPaid
                    ? TColors.success.withOpacity(0.12)
                    : TColors.warning.withOpacity(0.12),
                borderRadius: BorderRadius.circular(30),
              ),
              child: Text(
                isPaid ? 'Paid ✓' : 'Pending',
                style: TextStyle(
                  color: isPaid ? TColors.success : TColors.warning,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildAwaitingConfirmationBanner(bool dark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: TColors.warning.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: TColors.warning.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              valueColor: AlwaysStoppedAnimation<Color>(TColors.warning),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Waiting for confirmation…',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: dark ? TColors.white : TColors.textPrimary,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Your payment request has been sent. The screen will update automatically once confirmed.',
                  style: TextStyle(
                    fontSize: 12,
                    color: dark ? TColors.lightGrey : TColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentOptions(BuildContext context, bool dark, int price) {
    return Obx(() {
      final cards = _paymentController.savedCards;
      final isLoading = _paymentController.isLoading.value;
      final isPaying = _paymentController.isPaying.value;

      return AbsorbPointer(
        absorbing: isPaying,
        child: Opacity(
          opacity: isPaying ? 0.6 : 1.0,
          child: Column(
            children: [
              // ---- Cash option ----
              _buildOptionTile(
                dark: dark,
                icon: Iconsax.money,
                color: TColors.success,
                title: 'Cash',
                subtitle: 'Pay ₦$price directly to driver',
                trailing: isPaying && _selectedMethod == 'cash'
                    ? const _SmallSpinner(color: TColors.success)
                    : null,
                onTap: () {
                  setState(() => _selectedMethod = 'cash');
                  _payCash();
                },
              ),

              const SizedBox(height: 10),

              // ---- Saved cards ----
              if (isLoading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: TColors.primary,
                    ),
                  ),
                )
              else
                ...cards.map((card) {
                  final key = 'card:${card.cardId}';
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _buildOptionTile(
                      dark: dark,
                      icon: Iconsax.card,
                      color: TColors.info,
                      title: '${card.brand} •••• ${card.last4}',
                      subtitle: 'Expires ${card.expiry}',
                      trailing: isPaying && _selectedMethod == key
                          ? const _SmallSpinner(color: TColors.info)
                          : null,
                      onTap: () {
                        setState(() => _selectedMethod = key);
                        _payWithCard(card.cardId);
                      },
                    ),
                  );
                }),

              // ---- Add / manage cards ----
              _buildOptionTile(
                dark: dark,
                icon: Iconsax.add_circle,
                color: TColors.primary,
                title: 'Add or Manage Cards',
                subtitle: 'Securely pay with a new card',
                onTap: () async {
                  await Get.to(() => const PaymentMethodsScreen());
                  // Refresh cards when returning
                  _paymentController.fetchSavedCards();
                },
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildOptionTile({
    required bool dark,
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Widget? trailing,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: dark ? TColors.darkerGrey.withOpacity(0.3) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.18)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
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
            if (trailing != null) ...[
              const SizedBox(width: 10),
              trailing,
            ] else
              Icon(
                Iconsax.arrow_right_3,
                size: 16,
                color: dark ? Colors.white38 : Colors.grey.shade400,
              ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // PHASE 2 — Payment Confirmed (brief interstitial)
  // ---------------------------------------------------------------------------

  Widget _buildPaymentConfirmedPhase(
    BuildContext context,
    bool dark,
    int price,
  ) {
    return KeyedSubtree(
      key: const ValueKey('confirmed'),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 60),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ScaleTransition(
              scale: _checkScaleAnim,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: TColors.success.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Iconsax.tick_circle,
                  color: TColors.success,
                  size: 54,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Payment Confirmed!',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: dark ? TColors.white : TColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '₦$price received — thank you!',
              style: TextStyle(
                fontSize: 15,
                color: dark ? TColors.lightGrey : TColors.textSecondary,
              ),
            ),
            const SizedBox(height: 32),
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: TColors.primary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Loading rating screen…',
              style: TextStyle(
                fontSize: 13,
                color: dark ? TColors.lightGrey : TColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // PHASE 3 — Rating
  // ---------------------------------------------------------------------------

  Widget _buildRatingPhase(BuildContext context, bool dark, int price) {
    final cardColor = dark
        ? TColors.darkerGrey.withOpacity(0.35)
        : const Color(0xFFF9FAFB);

    final contextualTags =
        _selectedRating >= 4
            ? _positiveTags
            : _selectedRating > 0 && _selectedRating <= 2
            ? _negativeTags
            : [..._positiveTags, ..._negativeTags];

    return KeyedSubtree(
      key: const ValueKey('rating'),
      child: Column(
        children: [
          const SizedBox(height: 16),

          _buildHeaderIcon(
            icon: Iconsax.star1,
            color: Colors.amber,
            dark: dark,
          ),
          const SizedBox(height: 14),
          Text(
            'Trip Complete ✓',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: dark ? TColors.white : TColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'How was your experience?',
            style: TextStyle(
              fontSize: 14,
              color: dark ? TColors.lightGrey : TColors.textSecondary,
            ),
          ),

          const SizedBox(height: 28),

          // ---- Paid confirmation pill ----
          if (_rideController.isPaymentCompleted.value)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: TColors.success.withOpacity(0.1),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: TColors.success.withOpacity(0.25)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Iconsax.tick_circle,
                    color: TColors.success,
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '₦$price paid',
                    style: const TextStyle(
                      color: TColors.success,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 28),

          // ---- Stars ----
          Text(
            'Rate your driver',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: dark ? TColors.white : TColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (index) {
              final filled = index < _selectedRating;
              return GestureDetector(
                onTap: () => setState(() {
                  _selectedRating = index + 1;
                  _selectedTags.clear(); // reset tags on re-rate
                }),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: AnimatedScale(
                    scale: filled ? 1.15 : 1.0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      filled ? Iconsax.star1 : Iconsax.star,
                      color: filled
                          ? Colors.amber
                          : (dark ? Colors.grey.shade700 : Colors.grey.shade300),
                      size: 40,
                    ),
                  ),
                ),
              );
            }),
          ),

          // ---- Tags (shown once a rating is selected) ----
          if (_selectedRating > 0) ...[
            const SizedBox(height: 24),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: contextualTags.map((tag) {
                final isSelected = _selectedTags.contains(tag);
                return FilterChip(
                  label: Text(tag.replaceAll('_', ' ').capitalizeFirst!),
                  selected: isSelected,
                  onSelected: (val) {
                    setState(() {
                      if (val) {
                        _selectedTags.add(tag);
                      } else {
                        _selectedTags.remove(tag);
                      }
                    });
                  },
                  backgroundColor: cardColor,
                  selectedColor: TColors.primary.withOpacity(0.12),
                  checkmarkColor: TColors.primary,
                  labelStyle: TextStyle(
                    color: isSelected
                        ? TColors.primary
                        : (dark ? TColors.lightGrey : TColors.textSecondary),
                    fontSize: 13,
                    fontWeight:
                        isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(
                      color: isSelected
                          ? TColors.primary.withOpacity(0.4)
                          : Colors.transparent,
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  showCheckmark: false,
                );
              }).toList(),
            ),

            const SizedBox(height: 20),

            // ---- Comment ----
            TextField(
              controller: _reviewController,
              decoration: InputDecoration(
                hintText: 'Leave a comment (optional)…',
                hintStyle: TextStyle(
                  color: dark ? TColors.lightGrey : TColors.textSecondary,
                  fontSize: 13,
                ),
                filled: true,
                fillColor: cardColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.all(14),
              ),
              maxLines: 3,
              style: TextStyle(
                fontSize: 14,
                color: dark ? TColors.white : TColors.textPrimary,
              ),
            ),
          ],

          const SizedBox(height: 28),

          // ---- Submit / Skip buttons ----
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: _isSubmittingRating ? null : _submitRatingAndFinish,
              style: ElevatedButton.styleFrom(
                backgroundColor: TColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              child: _isSubmittingRating
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.5,
                      ),
                    )
                  : Text(
                      _selectedRating > 0 ? 'Submit Rating & Done' : 'Done',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),

          if (_selectedRating > 0) ...[
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: widget.onDone,
                child: Text(
                  'Skip Rating',
                  style: TextStyle(
                    color: dark ? TColors.lightGrey : TColors.textSecondary,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ],

          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Shared helpers
  // ---------------------------------------------------------------------------

  Widget _buildHeaderIcon({
    required IconData icon,
    required Color color,
    required bool dark,
  }) {
    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: color, size: 36),
    );
  }
}

// ---------------------------------------------------------------------------
// Tiny reusable spinner widget
// ---------------------------------------------------------------------------
class _SmallSpinner extends StatelessWidget {
  final Color color;
  const _SmallSpinner({required this.color});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 18,
      height: 18,
      child: CircularProgressIndicator(
        strokeWidth: 2.5,
        valueColor: AlwaysStoppedAnimation<Color>(color),
      ),
    );
  }
}
