import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sarri_ride/utils/constants/colors.dart';
import 'package:sarri_ride/utils/constants/sizes.dart';
import 'package:sarri_ride/utils/helpers/helper_functions.dart';
import 'package:iconsax/iconsax.dart';
import 'package:sarri_ride/utils/validators/validation.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscureCurrentPassword = true;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dark = THelperFunctions.isDarkMode(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Change Password'),
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
            
            // Password Form
            _buildPasswordForm(context, dark),
            
            const SizedBox(height: TSizes.spaceBtwSections),
            
            // Security Tips
            _buildSecurityTips(context, dark),
            
            const SizedBox(height: TSizes.spaceBtwSections),
            
            // Update Button
            _buildUpdateButton(context, dark),
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
          colors: [TColors.warning, TColors.warning.withOpacity(0.8)],
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
              Iconsax.security_safe,
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
                  'Update Password',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: TColors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: TSizes.xs),
                Text(
                  'Keep your account secure with a strong password',
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

  Widget _buildPasswordForm(BuildContext context, bool dark) {
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
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Password Information',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            
            const SizedBox(height: TSizes.spaceBtwItems),
            
            // Current Password
            TextFormField(
              controller: _currentPasswordController,
              obscureText: _obscureCurrentPassword,
              validator: (value) => value?.isEmpty == true ? 'Current password is required' : null,
              decoration: InputDecoration(
                labelText: 'Current Password',
                prefixIcon: Icon(
                  Iconsax.lock,
                  color: dark ? TColors.lightGrey : TColors.darkGrey,
                ),
                suffixIcon: IconButton(
                  onPressed: () => setState(() => _obscureCurrentPassword = !_obscureCurrentPassword),
                  icon: Icon(
                    _obscureCurrentPassword ? Iconsax.eye_slash : Iconsax.eye,
                    color: dark ? TColors.lightGrey : TColors.darkGrey,
                  ),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(TSizes.inputFieldRadius),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(TSizes.inputFieldRadius),
                  borderSide: BorderSide(color: TColors.primary, width: 2),
                ),
              ),
            ),
            
            const SizedBox(height: TSizes.spaceBtwInputFields),
            
            // New Password
            TextFormField(
              controller: _newPasswordController,
              obscureText: _obscureNewPassword,
              validator: TValidator.validatePassword,
              decoration: InputDecoration(
                labelText: 'New Password',
                prefixIcon: Icon(
                  Iconsax.lock,
                  color: dark ? TColors.lightGrey : TColors.darkGrey,
                ),
                suffixIcon: IconButton(
                  onPressed: () => setState(() => _obscureNewPassword = !_obscureNewPassword),
                  icon: Icon(
                    _obscureNewPassword ? Iconsax.eye_slash : Iconsax.eye,
                    color: dark ? TColors.lightGrey : TColors.darkGrey,
                  ),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(TSizes.inputFieldRadius),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(TSizes.inputFieldRadius),
                  borderSide: BorderSide(color: TColors.primary, width: 2),
                ),
              ),
            ),
            
            const SizedBox(height: TSizes.spaceBtwInputFields),
            
            // Confirm New Password
            TextFormField(
              controller: _confirmPasswordController,
              obscureText: _obscureConfirmPassword,
              validator: (value) {
                if (value?.isEmpty == true) {
                  return 'Please confirm your new password';
                }
                if (value != _newPasswordController.text) {
                  return 'Passwords do not match';
                }
                return null;
              },
              decoration: InputDecoration(
                labelText: 'Confirm New Password',
                prefixIcon: Icon(
                  Iconsax.lock,
                  color: dark ? TColors.lightGrey : TColors.darkGrey,
                ),
                suffixIcon: IconButton(
                  onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                  icon: Icon(
                    _obscureConfirmPassword ? Iconsax.eye_slash : Iconsax.eye,
                    color: dark ? TColors.lightGrey : TColors.darkGrey,
                  ),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(TSizes.inputFieldRadius),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(TSizes.inputFieldRadius),
                  borderSide: BorderSide(color: TColors.primary, width: 2),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSecurityTips(BuildContext context, bool dark) {
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
                Iconsax.shield_tick,
                color: TColors.success,
                size: TSizes.iconMd,
              ),
              const SizedBox(width: TSizes.spaceBtwItems),
              Text(
                'Password Security Tips',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: TSizes.spaceBtwItems),
          
          _buildSecurityTip(
            'Use at least 8 characters',
            Iconsax.tick_circle,
            TColors.success,
            context,
          ),
          
          _buildSecurityTip(
            'Include uppercase and lowercase letters',
            Iconsax.tick_circle,
            TColors.success,
            context,
          ),
          
          _buildSecurityTip(
            'Add numbers and special characters',
            Iconsax.tick_circle,
            TColors.success,
            context,
          ),
          
          _buildSecurityTip(
            'Avoid using personal information',
            Iconsax.tick_circle,
            TColors.success,
            context,
          ),
          
          _buildSecurityTip(
            'Don\'t reuse passwords from other accounts',
            Iconsax.tick_circle,
            TColors.success,
            context,
          ),
        ],
      ),
    );
  }

  Widget _buildSecurityTip(String tip, IconData icon, Color color, BuildContext context) {
    final dark = THelperFunctions.isDarkMode(context);
    
    return Padding(
      padding: const EdgeInsets.only(bottom: TSizes.spaceBtwItems / 2),
      child: Row(
        children: [
          Icon(
            icon,
            color: color,
            size: TSizes.iconSm,
          ),
          const SizedBox(width: TSizes.spaceBtwItems),
          Expanded(
            child: Text(
              tip,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: dark ? TColors.lightGrey : TColors.darkGrey,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUpdateButton(BuildContext context, bool dark) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _updatePassword,
        style: ElevatedButton.styleFrom(
          backgroundColor: TColors.warning,
          foregroundColor: TColors.white,
          padding: const EdgeInsets.symmetric(vertical: TSizes.md),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(TSizes.buttonRadius),
          ),
        ),
        child: _isLoading
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(TColors.white),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Iconsax.shield_tick,
                    size: TSizes.iconSm,
                  ),
                  const SizedBox(width: TSizes.spaceBtwItems),
                  Text(
                    'Update Password',
                    style: TextStyle(
                      fontSize: TSizes.fontSizeMd,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  void _updatePassword() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    // Simulate API call
    await Future.delayed(const Duration(seconds: 2));

    setState(() {
      _isLoading = false;
    });

    // Show success dialog
    _showSuccessDialog();
  }

  void _showSuccessDialog() {
    final dark = THelperFunctions.isDarkMode(context);
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(TSizes.cardRadiusLg),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(TSizes.lg),
              decoration: BoxDecoration(
                color: TColors.success.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Iconsax.tick_circle,
                color: TColors.success,
                size: TSizes.xl + TSizes.lg,
              ),
            ),
            
            const SizedBox(height: TSizes.spaceBtwItems),
            
            Text(
              'Password Updated!',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: TColors.success,
              ),
            ),
            
            const SizedBox(height: TSizes.spaceBtwItems),
            
            Text(
              'Your password has been successfully updated. Please use your new password for future logins.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: dark ? TColors.lightGrey : TColors.darkGrey,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Get.back();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: TColors.success,
                foregroundColor: TColors.white,
              ),
              child: const Text('Done'),
            ),
          ),
        ],
      ),
    );
  }
} 