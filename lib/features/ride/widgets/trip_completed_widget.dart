import 'package:flutter/material.dart';
import 'package:sarri_ride/utils/constants/colors.dart';
import 'package:sarri_ride/utils/constants/sizes.dart';
import 'package:sarri_ride/utils/helpers/helper_functions.dart';
import 'package:sarri_ride/features/ride/widgets/common_widgets.dart';
import 'package:sarri_ride/features/ride/widgets/payment_option_widget.dart';
import 'package:sarri_ride/features/ride/widgets/ride_selection_widget.dart';
import 'package:iconsax/iconsax.dart';

class TripCompletedWidget extends StatefulWidget {
  final RideType? selectedRideType;
  final bool isPaymentCompleted;
  final VoidCallback onPayWithWallet;
  final VoidCallback onPayWithCard;
  final VoidCallback onPayWithCash;
  final VoidCallback onDone;

  const TripCompletedWidget({
    super.key,
    required this.selectedRideType,
    required this.isPaymentCompleted,
    required this.onPayWithWallet,
    required this.onPayWithCard,
    required this.onPayWithCash,
    required this.onDone,
  });

  @override
  State<TripCompletedWidget> createState() => _TripCompletedWidgetState();
}

class _TripCompletedWidgetState extends State<TripCompletedWidget>
    with TickerProviderStateMixin {
  late AnimationController _successAnimationController;
  late AnimationController _fadeAnimationController;
  late Animation<double> _successScaleAnimation;
  late Animation<double> _fadeAnimation;
  int selectedRating = 0;

  @override
  void initState() {
    super.initState();
    _successAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _successScaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _successAnimationController,
      curve: Curves.elasticOut,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeAnimationController,
      curve: Curves.easeInOut,
    ));

    // Start animations
    _successAnimationController.forward();
    Future.delayed(const Duration(milliseconds: 200), () {
      _fadeAnimationController.forward();
    });
  }

  @override
  void dispose() {
    _successAnimationController.dispose();
    _fadeAnimationController.dispose();
    super.dispose();
  }

  void _completeTrip() {
    // Enhanced completion logic to ensure everything is cleared
    widget.onDone();
    
    // Add a small delay to ensure proper cleanup
    Future.delayed(const Duration(milliseconds: 100), () {
      // Force rebuild if needed
      if (mounted) {
        THelperFunctions.showSnackBar('Trip completed successfully! Thank you for riding with us.');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final dark = THelperFunctions.isDarkMode(context);
    
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
          // Draggable handle area - this should NOT consume scroll gestures
          GestureDetector(
            onVerticalDragUpdate: (details) {
              // Allow parent to handle drag gestures for panel movement
              // Don't consume the gesture here
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.only(top: TSizes.md, bottom: TSizes.sm),
              child: Center(
                child: Container(
                  width: 50,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ),
          
          // Scrollable content area
          Flexible(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: TSizes.defaultSpace),
              child: Column(
                children: [
                  const SizedBox(height: TSizes.spaceBtwItems),
                  
                  // Animated success section
                  ScaleTransition(
                    scale: _successScaleAnimation,
                    child: Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [TColors.success, TColors.success.withOpacity(0.7)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(60),
                        boxShadow: [
                          BoxShadow(
                            color: TColors.success.withOpacity(0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.check_circle_outline,
                        color: Colors.white,
                        size: 30,
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: TSizes.spaceBtwItems),
                  
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: Column(
                      children: [
                        Text(
                          'Trip Completed!',
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: dark ? TColors.white : TColors.black,
                          ),
                        ),
                        
                        const SizedBox(height: TSizes.xs),
                        
                        Text(
                          'Thank you for choosing our service',
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: dark ? TColors.lightGrey : Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: TSizes.spaceBtwSections),
                  
                  // Modern fare display
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: Container(
                      padding: const EdgeInsets.all(TSizes.defaultSpace),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [TColors.primary.withOpacity(0.1), TColors.primary.withOpacity(0.05)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(TSizes.cardRadiusLg),
                        border: Border.all(color: TColors.primary.withOpacity(0.2)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Trip Fare',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: dark ? TColors.lightGrey : Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: TSizes.xs),
                              Text(
                                '₦${widget.selectedRideType?.price ?? 3200}',
                                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: TColors.primary,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: widget.isPaymentCompleted ? TColors.success : TColors.warning,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              widget.isPaymentCompleted ? 'Paid' : 'Pending',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  if (!widget.isPaymentCompleted) ...[
                    const SizedBox(height: TSizes.spaceBtwSections),
                    
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Choose Payment Method',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: dark ? TColors.white : TColors.black,
                            ),
                          ),
                          
                          const SizedBox(height: TSizes.spaceBtwItems),
                          
                          // Modern payment options
                          Row(
                            children: [
                              Expanded(
                                child: _buildModernPaymentOption(
                                  icon: Iconsax.wallet_money,
                                  title: 'Wallet',
                                  subtitle: '₦5,420 available',
                                  onTap: widget.onPayWithWallet,
                                  dark: dark,
                                ),
                              ),
                              const SizedBox(width: TSizes.spaceBtwItems),
                              Expanded(
                                child: _buildModernPaymentOption(
                                  icon: Iconsax.card,
                                  title: 'Card',
                                  subtitle: 'Visa ****1234',
                                  onTap: widget.onPayWithCard,
                                  dark: dark,
                                ),
                              ),
                            ],
                          ),
                          
                          const SizedBox(height: TSizes.spaceBtwItems),
                          
                          _buildModernPaymentOption(
                            icon: Iconsax.money,
                            title: 'Pay with Cash',
                            subtitle: 'Pay the driver directly',
                            onTap: widget.onPayWithCash,
                            dark: dark,
                            isFullWidth: true,
                          ),
                        ],
                      ),
                    ),
                  ],
                  
                  const SizedBox(height: TSizes.spaceBtwSections),
                  
                  // Rating section
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: Container(
                      padding: const EdgeInsets.all(TSizes.defaultSpace),
                      decoration: BoxDecoration(
                        color: dark ? TColors.dark : Colors.white,
                        borderRadius: BorderRadius.circular(TSizes.cardRadiusLg),
                        border: Border.all(
                          color: Colors.amber.withOpacity(0.2),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(dark ? 0.3 : 0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Text(
                            'Rate your experience',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: dark ? TColors.white : TColors.black,
                            ),
                          ),
                          
                          const SizedBox(height: TSizes.spaceBtwItems),
                          
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(5, (index) {
                              return GestureDetector(
                                onTap: () {
                                  setState(() {
                                    selectedRating = index + 1;
                                  });
                                },
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  margin: const EdgeInsets.symmetric(horizontal: 4),
                                  child: Icon(
                                    index < selectedRating ? Icons.star : Icons.star_border,
                                    color: Colors.amber,
                                    size: 32,
                                  ),
                                ),
                              );
                            }),
                          ),
                          
                          if (selectedRating > 0) ...[
                            const SizedBox(height: TSizes.spaceBtwItems),
                            Text(
                              _getRatingMessage(selectedRating),
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Colors.amber,
                                fontWeight: FontWeight.w500,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: TSizes.spaceBtwSections),
                  
                  // Modern done button
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: Container(
                      width: double.infinity,
                      height: 56,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: widget.isPaymentCompleted 
                              ? [TColors.primary, TColors.primary.withOpacity(0.8)]
                              : [Colors.grey, Colors.grey.withOpacity(0.8)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          if (widget.isPaymentCompleted)
                            BoxShadow(
                              color: TColors.primary.withOpacity(0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 6),
                            ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: widget.isPaymentCompleted ? _completeTrip : () {
                          THelperFunctions.showSnackBar('Please complete payment first');
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              widget.isPaymentCompleted ? Iconsax.tick_circle : Iconsax.warning_2,
                              color: Colors.white,
                            ),
                            const SizedBox(width: TSizes.spaceBtwItems),
                            Text(
                              widget.isPaymentCompleted ? 'Complete Trip' : 'Complete Payment First',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  
                  // Bottom padding for safe area
                  SizedBox(height: MediaQuery.of(context).padding.bottom + TSizes.defaultSpace),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernPaymentOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required bool dark,
    bool isFullWidth = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: dark ? TColors.dark : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: TColors.primary.withOpacity(0.2),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(dark ? 0.3 : 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: isFullWidth
            ? Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: TColors.success.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: TColors.success, size: 24),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                            color: dark ? TColors.white : TColors.black,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: TextStyle(
                            color: dark ? TColors.lightGrey : Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              )
            : Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: TColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: TColors.primary, size: 24),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: dark ? TColors.white : TColors.black,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: dark ? TColors.lightGrey : Colors.grey[600],
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
      ),
    );
  }

  String _getRatingMessage(int rating) {
    switch (rating) {
      case 1:
        return 'We\'re sorry about your experience';
      case 2:
        return 'We\'ll work to improve';
      case 3:
        return 'Thank you for your feedback';
      case 4:
        return 'Great! Thanks for riding with us';
      case 5:
        return 'Excellent! We appreciate you';
      default:
        return '';
    }
  }
} 