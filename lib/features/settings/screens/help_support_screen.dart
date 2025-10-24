import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sarri_ride/utils/constants/colors.dart';
import 'package:sarri_ride/utils/constants/sizes.dart';
import 'package:sarri_ride/utils/helpers/helper_functions.dart';
import 'package:iconsax/iconsax.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final dark = THelperFunctions.isDarkMode(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Help & Support'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Get.back(),
          icon: Icon(
            Iconsax.arrow_left_2,
            color: dark ? TColors.light : TColors.dark,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(TSizes.defaultSpace),
        child: Column(
          children: [
            // Header Card
            _buildHeader(context, dark),
            
            const SizedBox(height: TSizes.spaceBtwSections),
            
            // Quick Actions
            _buildQuickActions(context, dark),
            
            const SizedBox(height: TSizes.spaceBtwSections),
            
            // FAQ Section
            _buildFAQSection(context, dark),
            
            const SizedBox(height: TSizes.spaceBtwSections),
            
            // Contact Support
            _buildContactSupport(context, dark),
            
            const SizedBox(height: TSizes.spaceBtwSections),
            
            // App Information
            _buildAppInformation(context, dark),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool dark) {
    return Container(
      padding: const EdgeInsets.all(TSizes.defaultSpace),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [TColors.success, TColors.success.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(TSizes.cardRadiusLg),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(TSizes.md),
            decoration: BoxDecoration(
              color: TColors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(TSizes.cardRadiusMd),
            ),
            child: Icon(
              Iconsax.support,
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
                  'Help & Support',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: TColors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: TSizes.xs),
                Text(
                  'We\'re here to help you with any questions or issues',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: TColors.white.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context, bool dark) {
    return Container(
      padding: const EdgeInsets.all(TSizes.defaultSpace),
      decoration: BoxDecoration(
        color: dark ? TColors.dark : Colors.white,
        borderRadius: BorderRadius.circular(TSizes.cardRadiusLg),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(dark ? 0.3 : 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick Actions',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          
          const SizedBox(height: TSizes.spaceBtwItems),
          
          Row(
            children: [
              Expanded(
                child: _buildQuickActionCard(
                  'Report Issue',
                  'Report a problem with your ride',
                  Iconsax.warning_2,
                  TColors.error,
                  () => _reportIssue(context),
                  context,
                  dark,
                ),
              ),
              const SizedBox(width: TSizes.spaceBtwItems),
              Expanded(
                child: _buildQuickActionCard(
                  'Lost Item',
                  'Report a lost item',
                  Iconsax.search_normal,
                  TColors.warning,
                  () => _reportLostItem(context),
                  context,
                  dark,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: TSizes.spaceBtwItems),
          
          Row(
            children: [
              Expanded(
                child: _buildQuickActionCard(
                  'Rate Driver',
                  'Rate your recent trip',
                  Iconsax.star,
                  TColors.warning,
                  () => _rateDriver(context),
                  context,
                  dark,
                ),
              ),
              const SizedBox(width: TSizes.spaceBtwItems),
              Expanded(
                child: _buildQuickActionCard(
                  'Safety',
                  'Safety tips & emergency',
                  Iconsax.shield_tick,
                  TColors.success,
                  () => _viewSafetyInfo(context),
                  context,
                  dark,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionCard(
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap,
    BuildContext context,
    bool dark,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(TSizes.md),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(TSizes.cardRadiusMd),
          border: Border.all(
            color: color.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(TSizes.sm),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(TSizes.cardRadiusSm),
              ),
              child: Icon(
                icon,
                color: color,
                size: TSizes.iconMd,
              ),
            ),
            const SizedBox(height: TSizes.spaceBtwItems),
            Text(
              title,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: TSizes.xs),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: dark ? TColors.lightGrey : TColors.darkGrey,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFAQSection(BuildContext context, bool dark) {
    final faqs = [
      FAQItem(
        question: 'How do I cancel a ride?',
        answer: 'You can cancel a ride before the driver arrives by tapping the cancel button. Cancellation fees may apply depending on timing.',
      ),
      FAQItem(
        question: 'How are fares calculated?',
        answer: 'Fares are calculated based on distance, time, and current demand. You\'ll see the estimated fare before booking.',
      ),
      FAQItem(
        question: 'What if my driver doesn\'t arrive?',
        answer: 'If your driver doesn\'t arrive within 10 minutes of the estimated time, please contact support for assistance.',
      ),
      FAQItem(
        question: 'How do I update my payment method?',
        answer: 'Go to Settings > Payment Methods to add, remove, or update your payment options.',
      ),
      FAQItem(
        question: 'What should I do in case of an emergency?',
        answer: 'Use the emergency button in the app to alert authorities and your emergency contacts. Your location will be shared automatically.',
      ),
    ];

    return Container(
      padding: const EdgeInsets.all(TSizes.defaultSpace),
      decoration: BoxDecoration(
        color: dark ? TColors.dark : Colors.white,
        borderRadius: BorderRadius.circular(TSizes.cardRadiusLg),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(dark ? 0.3 : 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Iconsax.message_question,
                color: TColors.info,
                size: TSizes.iconMd,
              ),
              const SizedBox(width: TSizes.spaceBtwItems),
              Text(
                'Frequently Asked Questions',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: TSizes.spaceBtwItems),
          
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: faqs.length,
            separatorBuilder: (context, index) => const SizedBox(height: TSizes.spaceBtwItems),
            itemBuilder: (context, index) {
              return _buildFAQItem(faqs[index], context, dark);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFAQItem(FAQItem faq, BuildContext context, bool dark) {
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        title: Text(
          faq.question,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: Icon(
          Iconsax.message_question,
          color: TColors.primary,
          size: TSizes.iconSm,
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(TSizes.xl, 0, TSizes.md, TSizes.md),
            child: Text(
              faq.answer,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: dark ? TColors.lightGrey : TColors.darkGrey,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactSupport(BuildContext context, bool dark) {
    return Container(
      padding: const EdgeInsets.all(TSizes.defaultSpace),
      decoration: BoxDecoration(
        color: dark ? TColors.dark : Colors.white,
        borderRadius: BorderRadius.circular(TSizes.cardRadiusLg),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(dark ? 0.3 : 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Iconsax.call,
                color: TColors.primary,
                size: TSizes.iconMd,
              ),
              const SizedBox(width: TSizes.spaceBtwItems),
              Text(
                'Contact Support',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: TSizes.spaceBtwItems),
          
          _buildContactOption(
            'Live Chat',
            'Chat with our support team',
            Iconsax.message,
            TColors.success,
            () => _startLiveChat(context),
            context,
          ),
          
          _buildContactOption(
            'Email Support',
            'Send us an email',
            Iconsax.sms,
            TColors.info,
            () => _sendEmail(context),
            context,
          ),
          
          _buildContactOption(
            'Phone Support',
            '+234 800 RIDE APP',
            Iconsax.call,
            TColors.warning,
            () => _callSupport(context),
            context,
          ),
          
          _buildContactOption(
            'WhatsApp',
            'Message us on WhatsApp',
            Iconsax.message,
            TColors.success,
            () => _openWhatsApp(context),
            context,
          ),
        ],
      ),
    );
  }

  Widget _buildContactOption(
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap,
    BuildContext context,
  ) {
    final dark = THelperFunctions.isDarkMode(context);
    
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        padding: const EdgeInsets.all(TSizes.sm),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(TSizes.cardRadiusMd),
        ),
        child: Icon(
          icon,
          color: color,
          size: TSizes.iconMd,
        ),
      ),
      title: Text(
        title,
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: dark ? TColors.lightGrey : TColors.darkGrey,
        ),
      ),
      trailing: Icon(
        Iconsax.arrow_right_3,
        color: dark ? TColors.lightGrey : TColors.darkGrey,
        size: TSizes.iconSm,
      ),
      onTap: onTap,
    );
  }

  Widget _buildAppInformation(BuildContext context, bool dark) {
    return Container(
      padding: const EdgeInsets.all(TSizes.defaultSpace),
      decoration: BoxDecoration(
        color: dark ? TColors.dark : Colors.white,
        borderRadius: BorderRadius.circular(TSizes.cardRadiusLg),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(dark ? 0.3 : 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Iconsax.info_circle,
                color: TColors.secondary,
                size: TSizes.iconMd,
              ),
              const SizedBox(width: TSizes.spaceBtwItems),
              Text(
                'App Information',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: TSizes.spaceBtwItems),
          
          _buildInfoRow('App Version', '1.0.0', context),
          _buildInfoRow('Last Updated', 'December 2024', context),
          _buildInfoRow('Platform', 'iOS & Android', context),
          _buildInfoRow('Support Hours', '24/7', context),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, BuildContext context) {
    final dark = THelperFunctions.isDarkMode(context);
    
    return Padding(
      padding: const EdgeInsets.only(bottom: TSizes.spaceBtwItems),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: dark ? TColors.lightGrey : TColors.darkGrey,
            ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // Action methods
  void _reportIssue(BuildContext context) {
    THelperFunctions.showSnackBar('Issue reporting feature coming soon!');
  }

  void _reportLostItem(BuildContext context) {
    THelperFunctions.showSnackBar('Lost item reporting feature coming soon!');
  }

  void _rateDriver(BuildContext context) {
    THelperFunctions.showSnackBar('Driver rating feature coming soon!');
  }

  void _viewSafetyInfo(BuildContext context) {
    THelperFunctions.showSnackBar('Safety information feature coming soon!');
  }

  void _startLiveChat(BuildContext context) {
    THelperFunctions.showSnackBar('Live chat feature coming soon!');
  }

  void _sendEmail(BuildContext context) {
    THelperFunctions.showSnackBar('Email support feature coming soon!');
  }

  void _callSupport(BuildContext context) {
    THelperFunctions.showSnackBar('Phone support feature coming soon!');
  }

  void _openWhatsApp(BuildContext context) {
    THelperFunctions.showSnackBar('WhatsApp support feature coming soon!');
  }
}

class FAQItem {
  final String question;
  final String answer;

  const FAQItem({
    required this.question,
    required this.answer,
  });
} 