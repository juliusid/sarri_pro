import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sarri_ride/utils/constants/colors.dart';
import 'package:sarri_ride/utils/constants/sizes.dart';
import 'package:sarri_ride/utils/helpers/helper_functions.dart';
import 'package:iconsax/iconsax.dart';

class PaymentMethodsScreen extends StatefulWidget {
  const PaymentMethodsScreen({super.key});

  @override
  State<PaymentMethodsScreen> createState() => _PaymentMethodsScreenState();
}

class _PaymentMethodsScreenState extends State<PaymentMethodsScreen> {
  String selectedPaymentMethod = 'card_1';

  @override
  Widget build(BuildContext context) {
    final dark = THelperFunctions.isDarkMode(context);
    
    return Scaffold(
      backgroundColor: dark ? TColors.dark : TColors.lightGrey,
      appBar: AppBar(
        title: const Text('Payment Methods'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Get.back(),
          icon: Icon(
            Iconsax.arrow_left_2,
            color: dark ? TColors.light : TColors.dark,
            size: TSizes.iconLg,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () => _addPaymentMethod(),
            icon: Icon(
              Iconsax.add,
              color: dark ? TColors.light : TColors.dark,
              size: TSizes.iconLg,
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header Card
            Container(
              width: double.infinity,
              margin: const EdgeInsets.all(TSizes.defaultSpace),
              padding: const EdgeInsets.all(TSizes.defaultSpace),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [TColors.success, TColors.success.withOpacity(0.8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(TSizes.cardRadiusLg),
                boxShadow: [
                  BoxShadow(
                    color: TColors.success.withOpacity(0.3),
                    blurRadius: TSizes.md,
                    offset: const Offset(0, TSizes.sm),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(TSizes.md),
                        decoration: BoxDecoration(
                          color: TColors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(TSizes.cardRadiusMd),
                        ),
                        child: Icon(
                          Iconsax.wallet_3,
                          color: TColors.white,
                          size: TSizes.iconLg,
                        ),
                      ),
                      const SizedBox(width: TSizes.spaceBtwItems),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Payment Methods',
                              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                color: TColors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: TSizes.xs),
                            Text(
                              'Manage your payment options securely',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: TColors.white.withOpacity(0.8),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // Payment Methods Section
            Container(
              margin: const EdgeInsets.symmetric(horizontal: TSizes.defaultSpace),
              padding: const EdgeInsets.all(TSizes.defaultSpace),
              decoration: BoxDecoration(
                color: dark ? TColors.dark : TColors.white,
                borderRadius: BorderRadius.circular(TSizes.cardRadiusLg),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(dark ? 0.3 : 0.1),
                    blurRadius: TSizes.md,
                    offset: const Offset(0, TSizes.sm),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Select Payment Method',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: dark ? TColors.white : TColors.black,
                    ),
                  ),
                  const SizedBox(height: TSizes.spaceBtwItems),
                  
                  // Payment methods list
                  ...List.generate(_paymentMethods.length, (index) {
                    final method = _paymentMethods[index];
                    final isLast = index == _paymentMethods.length - 1;
                    return _buildPaymentMethodCard(method, dark, context, isLast);
                  }),
                ],
              ),
            ),
            
            const SizedBox(height: TSizes.spaceBtwSections),
            
            // Add Payment Method Card
            Container(
              margin: const EdgeInsets.symmetric(horizontal: TSizes.defaultSpace),
              child: InkWell(
                onTap: () => _addPaymentMethod(),
                borderRadius: BorderRadius.circular(TSizes.cardRadiusLg),
                child: Container(
                  padding: const EdgeInsets.all(TSizes.defaultSpace),
                  decoration: BoxDecoration(
                    color: dark ? TColors.dark : TColors.white,
                    borderRadius: BorderRadius.circular(TSizes.cardRadiusLg),
                    border: Border.all(
                      color: TColors.primary,
                      width: 2,
                      style: BorderStyle.solid,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(dark ? 0.3 : 0.1),
                        blurRadius: TSizes.md,
                        offset: const Offset(0, TSizes.sm),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(TSizes.md),
                        decoration: BoxDecoration(
                          color: TColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(TSizes.cardRadiusMd),
                        ),
                        child: Icon(
                          Iconsax.add,
                          color: TColors.primary,
                          size: TSizes.iconLg,
                        ),
                      ),
                      const SizedBox(width: TSizes.spaceBtwItems),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Add New Payment Method',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: TColors.primary,
                              ),
                            ),
                            const SizedBox(height: TSizes.xs),
                            Text(
                              'Link a new card or bank account',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: dark ? TColors.lightGrey : TColors.darkGrey,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Iconsax.arrow_right_3,
                        color: TColors.primary,
                        size: TSizes.iconMd,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: TSizes.spaceBtwSections),
            
            // Security Info
            Container(
              margin: const EdgeInsets.symmetric(horizontal: TSizes.defaultSpace),
              padding: const EdgeInsets.all(TSizes.defaultSpace),
              decoration: BoxDecoration(
                color: TColors.info.withOpacity(0.1),
                borderRadius: BorderRadius.circular(TSizes.cardRadiusLg),
                border: Border.all(
                  color: TColors.info.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(TSizes.sm),
                    decoration: BoxDecoration(
                      color: TColors.info.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(TSizes.cardRadiusMd),
                    ),
                    child: Icon(
                      Iconsax.shield_tick,
                      color: TColors.info,
                      size: TSizes.iconMd,
                    ),
                  ),
                  const SizedBox(width: TSizes.spaceBtwItems),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Secure Payments',
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: TColors.info,
                          ),
                        ),
                        const SizedBox(height: TSizes.xs),
                        Text(
                          'All payment information is encrypted and secured with industry-standard protocols.',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: dark ? TColors.lightGrey : TColors.darkGrey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: TSizes.spaceBtwSections),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentMethodCard(PaymentMethod method, bool dark, BuildContext context, bool isLast) {
    final isSelected = selectedPaymentMethod == method.id;
    
    return Container(
      margin: EdgeInsets.only(bottom: isLast ? 0 : TSizes.spaceBtwItems),
      decoration: BoxDecoration(
        color: dark ? TColors.darkerGrey : TColors.lightGrey,
        borderRadius: BorderRadius.circular(TSizes.cardRadiusMd),
        border: Border.all(
          color: isSelected ? TColors.primary : Colors.transparent,
          width: 2,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(TSizes.defaultSpace),
        leading: Container(
          padding: const EdgeInsets.all(TSizes.sm),
          decoration: BoxDecoration(
            color: method.color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(TSizes.cardRadiusMd),
          ),
          child: Icon(
            method.icon,
            color: method.color,
            size: TSizes.iconLg,
          ),
        ),
        title: Text(
          method.name,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: dark ? TColors.white : TColors.black,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: TSizes.xs),
            Text(
              method.details,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: dark ? TColors.lightGrey : TColors.darkGrey,
              ),
            ),
            if (method.isDefault) ...[
              const SizedBox(height: TSizes.xs),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: TSizes.sm, vertical: TSizes.xs),
                decoration: BoxDecoration(
                  color: TColors.success.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(TSizes.cardRadiusLg),
                ),
                child: Text(
                  'Default',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: TColors.success,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isSelected)
              Container(
                padding: const EdgeInsets.all(TSizes.xs),
                decoration: BoxDecoration(
                  color: TColors.primary,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Iconsax.tick_circle,
                  color: TColors.white,
                  size: TSizes.iconSm,
                ),
              ),
            const SizedBox(width: TSizes.spaceBtwItems),
            PopupMenuButton<String>(
              onSelected: (value) => _handleMenuAction(value, method),
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Iconsax.edit_2, size: TSizes.iconSm),
                      const SizedBox(width: TSizes.spaceBtwItems),
                      const Text('Edit'),
                    ],
                  ),
                ),
                if (!method.isDefault)
                  PopupMenuItem(
                    value: 'default',
                    child: Row(
                      children: [
                        Icon(Iconsax.star, size: TSizes.iconSm),
                        const SizedBox(width: TSizes.spaceBtwItems),
                        const Text('Set as Default'),
                      ],
                    ),
                  ),
                PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Iconsax.trash, size: TSizes.iconSm, color: TColors.error),
                      const SizedBox(width: TSizes.spaceBtwItems),
                      Text('Delete', style: TextStyle(color: TColors.error)),
                    ],
                  ),
                ),
              ],
              child: Icon(
                Iconsax.more,
                color: dark ? TColors.lightGrey : TColors.darkGrey,
                size: TSizes.iconMd,
              ),
            ),
          ],
        ),
        onTap: () {
          setState(() {
            selectedPaymentMethod = method.id;
          });
        },
      ),
    );
  }

  void _addPaymentMethod() {
    THelperFunctions.showSnackBar('Add Payment Method feature coming soon');
  }

  void _handleMenuAction(String action, PaymentMethod method) {
    switch (action) {
      case 'edit':
        THelperFunctions.showSnackBar('Edit ${method.name} feature coming soon');
        break;
      case 'default':
        THelperFunctions.showSnackBar('${method.name} set as default payment method');
        break;
      case 'delete':
        _showDeleteConfirmation(method);
        break;
    }
  }

  void _showDeleteConfirmation(PaymentMethod method) {
    Get.dialog(
      AlertDialog(
        title: const Text('Delete Payment Method'),
        content: Text('Are you sure you want to delete ${method.name}?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Get.back();
              THelperFunctions.showSnackBar('${method.name} deleted successfully');
            },
            child: Text('Delete', style: TextStyle(color: TColors.error)),
          ),
        ],
      ),
    );
  }
}

class PaymentMethod {
  final String id;
  final String name;
  final String details;
  final IconData icon;
  final Color color;
  final bool isDefault;

  PaymentMethod({
    required this.id,
    required this.name,
    required this.details,
    required this.icon,
    required this.color,
    this.isDefault = false,
  });
}

// Mock payment methods
final List<PaymentMethod> _paymentMethods = [
  PaymentMethod(
    id: 'card_1',
    name: 'Visa Card',
    details: '**** **** **** 1234',
    icon: Iconsax.card,
    color: TColors.primary,
    isDefault: true,
  ),
  PaymentMethod(
    id: 'card_2',
    name: 'Mastercard',
    details: '**** **** **** 5678',
    icon: Iconsax.card,
    color: TColors.secondary,
  ),
  PaymentMethod(
    id: 'wallet_1',
    name: 'Digital Wallet',
    details: 'Balance: ₦25,000',
    icon: Iconsax.wallet_money,
    color: TColors.success,
  ),
  PaymentMethod(
    id: 'bank_1',
    name: 'Bank Transfer',
    details: 'GTBank - ****1234',
    icon: Iconsax.bank,
    color: TColors.info,
  ),
]; 