import 'package:flutter/material.dart';
import 'package:sarri_ride/utils/constants/colors.dart';
import 'package:sarri_ride/utils/constants/sizes.dart';
import 'package:sarri_ride/utils/helpers/helper_functions.dart';
import 'package:sarri_ride/features/ride/widgets/ride_selection_widget.dart';
import 'package:iconsax/iconsax.dart';

class PaymentDialogs {
  static void showWalletPayment(
    BuildContext context, {
    required RideType? selectedRideType,
    required VoidCallback onConfirm,
  }) {
    final fare = selectedRideType?.price ?? 3200;
    final dark = THelperFunctions.isDarkMode(context);
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(TSizes.defaultSpace),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                dark ? TColors.dark : Colors.white,
                dark ? TColors.darkerGrey : Colors.grey[50]!,
              ],
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header with icon
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [TColors.primary, TColors.primary.withOpacity(0.7)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(40),
                ),
                child: const Icon(
                  Iconsax.wallet_money,
                  color: Colors.white,
                  size: 40,
                ),
              ),
              
              const SizedBox(height: TSizes.spaceBtwItems),
              
              Text(
                'Pay with Wallet',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: dark ? TColors.white : TColors.black,
                ),
              ),
              
              const SizedBox(height: TSizes.spaceBtwSections),
              
              // Payment details card
              Container(
                padding: const EdgeInsets.all(TSizes.defaultSpace),
                decoration: BoxDecoration(
                  color: TColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: TColors.primary.withOpacity(0.2)),
                ),
                child: Column(
                  children: [
                    _buildPaymentRow('Trip Fare', '₦$fare', context, dark),
                    const SizedBox(height: TSizes.spaceBtwItems),
                    _buildPaymentRow('Wallet Balance', '₦5,420', context, dark, isBalance: true),
                    Divider(height: TSizes.spaceBtwItems * 2, color: TColors.primary.withOpacity(0.3)),
                    _buildPaymentRow('Remaining Balance', '₦${5420 - fare}', context, dark, isFinal: true),
                  ],
                ),
              ),
              
              const SizedBox(height: TSizes.spaceBtwSections),
              
              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: BorderSide(color: dark ? TColors.lightGrey : TColors.darkGrey),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Cancel',
                        style: TextStyle(
                          color: dark ? TColors.lightGrey : TColors.darkGrey,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: TSizes.spaceBtwItems),
                  Expanded(
                    flex: 2,
                    child: Container(
                      height: 52,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [TColors.primary, TColors.primary.withOpacity(0.8)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: TColors.primary.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          THelperFunctions.showSnackBar('Payment successful! ₦$fare deducted from wallet');
                          onConfirm();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Iconsax.tick_circle, color: Colors.white),
                            const SizedBox(width: TSizes.spaceBtwItems),
                            Text(
                              'Pay ₦$fare',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  static void showCardPayment(
    BuildContext context, {
    required RideType? selectedRideType,
    required VoidCallback onConfirm,
  }) {
    final fare = selectedRideType?.price ?? 3200;
    final dark = THelperFunctions.isDarkMode(context);
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(TSizes.defaultSpace),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                dark ? TColors.dark : Colors.white,
                dark ? TColors.darkerGrey : Colors.grey[50]!,
              ],
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header with icon
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [TColors.info, TColors.info.withOpacity(0.7)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(40),
                ),
                child: const Icon(
                  Iconsax.card,
                  color: Colors.white,
                  size: 40,
                ),
              ),
              
              const SizedBox(height: TSizes.spaceBtwItems),
              
              Text(
                'Pay with Card',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: dark ? TColors.white : TColors.black,
                ),
              ),
              
              const SizedBox(height: TSizes.spaceBtwSections),
              
              // Payment details card
              Container(
                padding: const EdgeInsets.all(TSizes.defaultSpace),
                decoration: BoxDecoration(
                  color: TColors.info.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: TColors.info.withOpacity(0.2)),
                ),
                child: Column(
                  children: [
                    _buildPaymentRow('Trip Fare', '₦$fare', context, dark),
                    const SizedBox(height: TSizes.spaceBtwItems),
                    _buildPaymentRow('Payment Method', 'Visa ****1234', context, dark),
                  ],
                ),
              ),
              
              const SizedBox(height: TSizes.spaceBtwSections),
              
              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: BorderSide(color: dark ? TColors.lightGrey : TColors.darkGrey),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Cancel',
                        style: TextStyle(
                          color: dark ? TColors.lightGrey : TColors.darkGrey,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: TSizes.spaceBtwItems),
                  Expanded(
                    flex: 2,
                    child: Container(
                      height: 52,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [TColors.info, TColors.info.withOpacity(0.8)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: TColors.info.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _processCardPayment(context, fare, onConfirm, dark);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Iconsax.card, color: Colors.white),
                            const SizedBox(width: TSizes.spaceBtwItems),
                            Text(
                              'Pay ₦$fare',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  static void _processCardPayment(
    BuildContext context,
    int fare,
    VoidCallback onConfirm,
    bool dark,
  ) {
    bool isProcessing = true;
    late BuildContext dialogContext;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext ctx) {
        dialogContext = ctx; // Store the dialog's context
        return StatefulBuilder(
          builder: (context, setState) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            elevation: 0,
            backgroundColor: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.all(TSizes.defaultSpace),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    dark ? TColors.dark : Colors.white,
                    dark ? TColors.darkerGrey : Colors.grey[50]!,
                  ],
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header with icon
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [TColors.info, TColors.info.withOpacity(0.7)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(40),
                    ),
                    child: const Icon(
                      Iconsax.card,
                      color: Colors.white,
                      size: 40,
                    ),
                  ),
                  
                  const SizedBox(height: TSizes.spaceBtwItems),
                  
                  Text(
                    'Processing Payment',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: dark ? TColors.white : TColors.black,
                    ),
                  ),
                  
                  const SizedBox(height: TSizes.spaceBtwSections),
                  
                  // Processing animation
                  Container(
                    padding: const EdgeInsets.all(TSizes.defaultSpace),
                    decoration: BoxDecoration(
                      color: dark ? TColors.darkerGrey : Colors.grey[100],
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        SizedBox(
                          width: 40,
                          height: 40,
                          child: CircularProgressIndicator(
                            strokeWidth: 3,
                            valueColor: AlwaysStoppedAnimation<Color>(TColors.info),
                          ),
                        ),
                        const SizedBox(height: TSizes.spaceBtwItems),
                        Text(
                          'Processing payment of ₦$fare...',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: dark ? TColors.lightGrey : TColors.darkGrey,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: TSizes.spaceBtwSections),
                  
                  // Cancel button
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () {
                        isProcessing = false;
                        if (Navigator.canPop(dialogContext)) {
                          Navigator.of(dialogContext).pop();
                        }
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: BorderSide(color: dark ? TColors.lightGrey : TColors.darkGrey),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Cancel Payment',
                        style: TextStyle(
                          color: dark ? TColors.lightGrey : TColors.darkGrey,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    ).then((_) {
      // Dialog was closed, ensure processing is stopped
      isProcessing = false;
    });
    
    // Simulate payment processing with proper context handling
    Future.delayed(const Duration(seconds: 3)).then((_) {
      if (isProcessing) {
        // Set processing to false first to prevent double execution
        isProcessing = false;
        
        try {
          // Close the processing dialog using the stored dialog context
          if (Navigator.canPop(dialogContext)) {
            Navigator.of(dialogContext).pop();
          }
          
          // Show success message and complete payment
          THelperFunctions.showSnackBar('Payment successful! ₦$fare charged to your card');
          onConfirm();
        } catch (e) {
          // If there's any error closing dialog, still complete the payment
          print('Payment completion error: $e');
          onConfirm();
        }
      }
    }).catchError((error) {
      // Handle any errors in the future
      print('Payment processing error: $error');
      if (isProcessing) {
        isProcessing = false;
        try {
          if (Navigator.canPop(dialogContext)) {
            Navigator.of(dialogContext).pop();
          }
        } catch (e) {
          print('Error closing dialog: $e');
        }
        onConfirm();
      }
    });
  }

  static void showCashPayment(
    BuildContext context, {
    required RideType? selectedRideType,
    required VoidCallback onConfirm,
  }) {
    final fare = selectedRideType?.price ?? 3200;
    final dark = THelperFunctions.isDarkMode(context);
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(TSizes.defaultSpace),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                dark ? TColors.dark : Colors.white,
                dark ? TColors.darkerGrey : Colors.grey[50]!,
              ],
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header with icon
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [TColors.success, TColors.success.withOpacity(0.7)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(40),
                ),
                child: const Icon(
                  Iconsax.money,
                  color: Colors.white,
                  size: 40,
                ),
              ),
              
              const SizedBox(height: TSizes.spaceBtwItems),
              
              Text(
                'Cash Payment',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: dark ? TColors.white : TColors.black,
                ),
              ),
              
              const SizedBox(height: TSizes.spaceBtwSections),
              
              // Payment amount
              Container(
                padding: const EdgeInsets.all(TSizes.defaultSpace),
                decoration: BoxDecoration(
                  color: TColors.success.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: TColors.success.withOpacity(0.2)),
                ),
                child: Column(
                  children: [
                    Text(
                      'Trip Fare',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: dark ? TColors.lightGrey : TColors.darkGrey,
                      ),
                    ),
                    const SizedBox(height: TSizes.xs),
                    Text(
                      '₦$fare',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: TColors.success,
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: TSizes.spaceBtwItems),
              
              // Instruction
              Container(
                padding: const EdgeInsets.all(TSizes.defaultSpace),
                decoration: BoxDecoration(
                  color: dark ? TColors.darkerGrey : Colors.grey[100],
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Icon(
                      Iconsax.info_circle,
                      color: TColors.warning,
                      size: 24,
                    ),
                    const SizedBox(width: TSizes.spaceBtwItems),
                    Expanded(
                      child: Text(
                        'Please have the exact amount ready to pay the driver in cash',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: dark ? TColors.lightGrey : TColors.darkGrey,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: TSizes.spaceBtwSections),
              
              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: BorderSide(color: dark ? TColors.lightGrey : TColors.darkGrey),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Cancel',
                        style: TextStyle(
                          color: dark ? TColors.lightGrey : TColors.darkGrey,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: TSizes.spaceBtwItems),
                  Expanded(
                    flex: 2,
                    child: Container(
                      height: 52,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [TColors.success, TColors.success.withOpacity(0.8)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: TColors.success.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          THelperFunctions.showSnackBar('Cash payment confirmed! Please pay the driver');
                          onConfirm();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Iconsax.tick_circle, color: Colors.white),
                            const SizedBox(width: TSizes.spaceBtwItems),
                            const Text(
                              'Confirm',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  static void showCancelRideDialog(
    BuildContext context, {
    required VoidCallback onConfirm,
  }) {
    final dark = THelperFunctions.isDarkMode(context);
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          elevation: 0,
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(TSizes.defaultSpace),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  dark ? TColors.dark : Colors.white,
                  dark ? TColors.darkerGrey : Colors.grey[50]!,
                ],
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header with icon
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [TColors.warning, TColors.warning.withOpacity(0.7)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(40),
                  ),
                  child: const Icon(
                    Iconsax.warning_2,
                    color: Colors.white,
                    size: 40,
                  ),
                ),
                
                const SizedBox(height: TSizes.spaceBtwItems),
                
                Text(
                  'Cancel Ride',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: dark ? TColors.white : TColors.black,
                  ),
                ),
                
                const SizedBox(height: TSizes.spaceBtwItems),
                
                Text(
                  'Are you sure you want to cancel this ride? Your destination will be reset and you\'ll need to start over.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: dark ? TColors.lightGrey : TColors.darkGrey,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: TSizes.spaceBtwSections),
                
                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          side: BorderSide(color: dark ? TColors.lightGrey : TColors.darkGrey),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'Keep Ride',
                          style: TextStyle(
                            color: dark ? TColors.lightGrey : TColors.darkGrey,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: TSizes.spaceBtwItems),
                    Expanded(
                      child: Container(
                        height: 52,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [TColors.error, TColors.error.withOpacity(0.8)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: TColors.error.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                            onConfirm();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Yes, Cancel',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Helper method to build payment rows
  static Widget _buildPaymentRow(
    String label, 
    String value, 
    BuildContext context, 
    bool dark, {
    bool isBalance = false,
    bool isFinal = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: dark ? TColors.lightGrey : TColors.darkGrey,
            fontWeight: isFinal ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: isFinal 
                ? TColors.success 
                : isBalance 
                    ? TColors.primary
                    : (dark ? TColors.white : TColors.black),
          ),
        ),
      ],
    );
  }
}