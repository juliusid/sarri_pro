import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sarri_ride/utils/constants/colors.dart';
import 'package:sarri_ride/utils/constants/sizes.dart';
import 'package:sarri_ride/utils/helpers/helper_functions.dart';
import 'package:iconsax/iconsax.dart';
import 'package:sarri_ride/utils/validators/validation.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  void _loadUserData() {
    // In a real app, you'd load from user service
    _firstNameController.text = 'John';
    _lastNameController.text = 'Doe';
    _emailController.text = 'john.doe@email.com';
    _phoneController.text = '+234 801 234 5678';
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dark = THelperFunctions.isDarkMode(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Get.back(),
          icon: Icon(
            Iconsax.arrow_left_2,
            color: dark ? TColors.light : TColors.dark,
          ),
        ),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveProfile,
            child: _isLoading
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(TColors.primary),
                    ),
                  )
                : Text(
                    'Save',
                    style: TextStyle(
                      color: TColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(TSizes.defaultSpace),
        child: Column(
          children: [
            // Header Card
            _buildHeader(context, dark),
            
            const SizedBox(height: TSizes.spaceBtwSections),
            
            // Profile Form
            _buildProfileForm(context, dark),
            
            const SizedBox(height: TSizes.spaceBtwSections),
            
            // Additional Options
            _buildAdditionalOptions(context, dark),
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
          // Profile Picture Section
          Stack(
            children: [
              CircleAvatar(
                radius: TSizes.xl + TSizes.lg,
                backgroundColor: TColors.white.withOpacity(0.2),
                child: Icon(
                  Iconsax.user,
                  size: TSizes.xl + TSizes.lg,
                  color: TColors.white,
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: GestureDetector(
                  onTap: _changeProfilePicture,
                  child: Container(
                    padding: const EdgeInsets.all(TSizes.sm),
                    decoration: BoxDecoration(
                      color: TColors.white,
                      borderRadius: BorderRadius.circular(TSizes.cardRadiusLg),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(
                      Iconsax.camera,
                      size: TSizes.iconSm,
                      color: TColors.primary,
                    ),
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: TSizes.spaceBtwItems),
          
          Text(
            'Update Your Profile',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: TColors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          
          const SizedBox(height: TSizes.xs),
          
          Text(
            'Keep your information up to date',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: TColors.white.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileForm(BuildContext context, bool dark) {
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
              'Personal Information',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            
            const SizedBox(height: TSizes.spaceBtwItems),
            
            // First Name & Last Name Row
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _firstNameController,
                    validator: (value) => value?.isEmpty == true ? 'First name is required' : null,
                    decoration: InputDecoration(
                      labelText: 'First Name',
                      prefixIcon: Icon(
                        Iconsax.user,
                        color: dark ? TColors.lightGrey : TColors.darkGrey,
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
                ),
                const SizedBox(width: TSizes.spaceBtwItems),
                Expanded(
                  child: TextFormField(
                    controller: _lastNameController,
                    validator: (value) => value?.isEmpty == true ? 'Last name is required' : null,
                    decoration: InputDecoration(
                      labelText: 'Last Name',
                      prefixIcon: Icon(
                        Iconsax.user,
                        color: dark ? TColors.lightGrey : TColors.darkGrey,
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
                ),
              ],
            ),
            
            const SizedBox(height: TSizes.spaceBtwInputFields),
            
            // Email
            TextFormField(
              controller: _emailController,
              validator: TValidator.validateEmail,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: 'Email',
                prefixIcon: Icon(
                  Iconsax.sms,
                  color: dark ? TColors.lightGrey : TColors.darkGrey,
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
            
            // Phone Number
            TextFormField(
              controller: _phoneController,
              validator: TValidator.validatePhoneNumber,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: 'Phone Number',
                prefixIcon: Icon(
                  Iconsax.call,
                  color: dark ? TColors.lightGrey : TColors.darkGrey,
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

  Widget _buildAdditionalOptions(BuildContext context, bool dark) {
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
            'Additional Options',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          
          const SizedBox(height: TSizes.spaceBtwItems),
          
          _buildOptionTile(
            'Change Password',
            'Update your account password',
            Iconsax.lock,
            TColors.warning,
            () => Get.toNamed('/change-password'),
            context,
          ),
          
          _buildOptionTile(
            'Privacy Settings',
            'Manage your privacy preferences',
            Iconsax.security_safe,
            TColors.info,
            () => Get.toNamed('/privacy-security'),
            context,
          ),
          
          _buildOptionTile(
            'Delete Account',
            'Permanently delete your account',
            Iconsax.trash,
            TColors.error,
            _showDeleteAccountDialog,
            context,
          ),
        ],
      ),
    );
  }

  Widget _buildOptionTile(
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap,
    BuildContext context,
  ) {
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
          color: THelperFunctions.isDarkMode(context) 
              ? TColors.lightGrey 
              : TColors.darkGrey,
        ),
      ),
      trailing: Icon(
        Iconsax.arrow_right_3,
        color: THelperFunctions.isDarkMode(context) 
            ? TColors.lightGrey 
            : TColors.darkGrey,
        size: TSizes.iconSm,
      ),
      onTap: onTap,
    );
  }

  void _changeProfilePicture() {
    THelperFunctions.showSnackBar('Profile picture change coming soon!');
  }

  void _saveProfile() async {
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

    THelperFunctions.showSnackBar('Profile updated successfully!');
    Get.back();
  }

  void _showDeleteAccountDialog() {
    final dark = THelperFunctions.isDarkMode(context);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              Iconsax.warning_2,
              color: TColors.error,
              size: TSizes.iconMd,
            ),
            const SizedBox(width: TSizes.spaceBtwItems),
            const Text('Delete Account'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to delete your account?',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: TSizes.spaceBtwItems),
            Text(
              'This action cannot be undone. All your data will be permanently deleted.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: dark ? TColors.lightGrey : TColors.darkGrey,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: dark ? TColors.lightGrey : TColors.darkGrey,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              THelperFunctions.showSnackBar('Account deletion feature coming soon!');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: TColors.error,
              foregroundColor: TColors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
} 