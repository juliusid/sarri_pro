import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sarri_ride/utils/constants/colors.dart';
import 'package:sarri_ride/utils/constants/sizes.dart';
import 'package:sarri_ride/utils/helpers/helper_functions.dart';
import 'package:iconsax/iconsax.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final dark = THelperFunctions.isDarkMode(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('About'),
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
            
            // App Features
            _buildAppFeatures(context, dark),
            
            const SizedBox(height: TSizes.spaceBtwSections),
            
            // App Information
            _buildAppInformation(context, dark),
            
            const SizedBox(height: TSizes.spaceBtwSections),
            
            // Company Information
            _buildCompanyInformation(context, dark),
            
            const SizedBox(height: TSizes.spaceBtwSections),
            
            // Legal & Policies
            _buildLegalPolicies(context, dark),
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
          colors: [TColors.primary, TColors.primary.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(TSizes.cardRadiusLg),
      ),
      child: Column(
        children: [
          // App Logo
          Container(
            width: TSizes.xl * 2,
            height: TSizes.xl * 2,
            decoration: BoxDecoration(
              color: TColors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(TSizes.cardRadiusLg),
            ),
            child: Icon(
              Iconsax.car,
              color: TColors.white,
              size: TSizes.xl + TSizes.lg,
            ),
          ),
          
          const SizedBox(height: TSizes.spaceBtwItems),
          
          Text(
            'RideApp',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: TColors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          
          const SizedBox(height: TSizes.xs),
          
          Text(
            'Version 1.0.0',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: TColors.white.withOpacity(0.8),
              fontWeight: FontWeight.w500,
            ),
          ),
          
          const SizedBox(height: TSizes.spaceBtwItems),
          
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: TSizes.spaceBtwItems,
              vertical: TSizes.sm,
            ),
            decoration: BoxDecoration(
              color: TColors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(TSizes.cardRadiusLg),
            ),
            child: Text(
              'Your trusted ride companion',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: TColors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppFeatures(BuildContext context, bool dark) {
    final features = [
      FeatureItem(
        icon: Iconsax.car,
        title: 'Easy Booking',
        description: 'Book rides in seconds with our intuitive interface',
        color: TColors.primary,
      ),
      FeatureItem(
        icon: Iconsax.location,
        title: 'Real-time Tracking',
        description: 'Track your ride and driver location in real-time',
        color: TColors.success,
      ),
      FeatureItem(
        icon: Iconsax.shield_tick,
        title: 'Safe & Secure',
        description: 'Your safety is our top priority with 24/7 support',
        color: TColors.info,
      ),
      FeatureItem(
        icon: Iconsax.wallet_3,
        title: 'Multiple Payments',
        description: 'Pay with cash, card, or digital wallet',
        color: TColors.warning,
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
                Iconsax.star,
                color: TColors.primary,
                size: TSizes.iconMd,
              ),
              const SizedBox(width: TSizes.spaceBtwItems),
              Text(
                'What We Offer',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: TSizes.spaceBtwItems),
          
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: TSizes.spaceBtwItems,
              mainAxisSpacing: TSizes.spaceBtwItems,
              childAspectRatio: 1.2,
            ),
            itemCount: features.length,
            itemBuilder: (context, index) {
              return _buildFeatureCard(features[index], context, dark);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureCard(FeatureItem feature, BuildContext context, bool dark) {
    return Container(
      padding: const EdgeInsets.all(TSizes.md),
      decoration: BoxDecoration(
        color: feature.color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(TSizes.cardRadiusMd),
        border: Border.all(
          color: feature.color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(TSizes.sm),
            decoration: BoxDecoration(
              color: feature.color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(TSizes.cardRadiusSm),
            ),
            child: Icon(
              feature.icon,
              color: feature.color,
              size: TSizes.iconMd,
            ),
          ),
          
          const SizedBox(height: TSizes.spaceBtwItems),
          
          Text(
            feature.title,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: TSizes.xs),
          
          Text(
            feature.description,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: dark ? TColors.lightGrey : TColors.darkGrey,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
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
                color: TColors.info,
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
          
          _buildInfoRow('Version', '1.0.0 (Build 100)', context),
          _buildInfoRow('Release Date', 'December 2024', context),
          _buildInfoRow('Size', '45.2 MB', context),
          _buildInfoRow('Minimum OS', 'iOS 12.0, Android 6.0', context),
          _buildInfoRow('Languages', 'English, Yoruba, Hausa, Igbo', context),
          _buildInfoRow('Last Updated', '5 days ago', context),
        ],
      ),
    );
  }

  Widget _buildCompanyInformation(BuildContext context, bool dark) {
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
                Iconsax.building,
                color: TColors.secondary,
                size: TSizes.iconMd,
              ),
              const SizedBox(width: TSizes.spaceBtwItems),
              Text(
                'Company Information',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: TSizes.spaceBtwItems),
          
          _buildInfoRow('Company', 'RideApp Technologies Ltd.', context),
          _buildInfoRow('Founded', '2024', context),
          _buildInfoRow('Headquarters', 'Lagos, Nigeria', context),
          _buildInfoRow('Website', 'www.rideapp.ng', context),
          _buildInfoRow('Email', 'support@rideapp.ng', context),
          _buildInfoRow('Phone', '+234 800 RIDE APP', context),
          
          const SizedBox(height: TSizes.spaceBtwItems),
          
          Container(
            padding: const EdgeInsets.all(TSizes.md),
            decoration: BoxDecoration(
              color: TColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(TSizes.cardRadiusMd),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Our Mission',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: TColors.primary,
                  ),
                ),
                const SizedBox(height: TSizes.xs),
                Text(
                  'To provide safe, reliable, and affordable transportation solutions that connect people and communities across Nigeria.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: dark ? TColors.lightGrey : TColors.darkGrey,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegalPolicies(BuildContext context, bool dark) {
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
                Iconsax.document_text,
                color: TColors.warning,
                size: TSizes.iconMd,
              ),
              const SizedBox(width: TSizes.spaceBtwItems),
              Text(
                'Legal & Policies',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: TSizes.spaceBtwItems),
          
          _buildPolicyItem(
            'Terms of Service',
            'Review our terms and conditions',
            Iconsax.document_text,
            () => Get.toNamed('/terms'),
            context,
          ),
          
          _buildPolicyItem(
            'Privacy Policy',
            'Learn how we protect your data',
            Iconsax.security_safe,
            () => Get.toNamed('/privacy-policy'),
            context,
          ),
          
          _buildPolicyItem(
            'Community Guidelines',
            'Our community standards and rules',
            Iconsax.people,
            () => THelperFunctions.showSnackBar('Community guidelines coming soon!'),
            context,
          ),
          
          _buildPolicyItem(
            'Open Source Licenses',
            'Third-party libraries and licenses',
            Iconsax.code,
            () => THelperFunctions.showSnackBar('Open source licenses coming soon!'),
            context,
          ),
          
          const SizedBox(height: TSizes.spaceBtwItems),
          
          Center(
            child: Text(
              '© 2024 RideApp Technologies Ltd.\nAll rights reserved.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: dark ? TColors.lightGrey : TColors.darkGrey,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, BuildContext context) {
    final dark = THelperFunctions.isDarkMode(context);
    
    return Padding(
      padding: const EdgeInsets.only(bottom: TSizes.spaceBtwItems),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: dark ? TColors.lightGrey : TColors.darkGrey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPolicyItem(
    String title,
    String subtitle,
    IconData icon,
    VoidCallback onTap,
    BuildContext context,
  ) {
    final dark = THelperFunctions.isDarkMode(context);
    
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        padding: const EdgeInsets.all(TSizes.sm),
        decoration: BoxDecoration(
          color: TColors.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(TSizes.cardRadiusMd),
        ),
        child: Icon(
          icon,
          color: TColors.primary,
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
}

class FeatureItem {
  final IconData icon;
  final String title;
  final String description;
  final Color color;

  const FeatureItem({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
  });
} 