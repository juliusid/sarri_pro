import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sarri_ride/utils/constants/colors.dart';
import 'package:sarri_ride/utils/constants/sizes.dart';
import 'package:sarri_ride/utils/helpers/helper_functions.dart';
import 'package:iconsax/iconsax.dart';
import 'package:sarri_ride/utils/validators/validation.dart';

class EmergencyContactsScreen extends StatefulWidget {
  const EmergencyContactsScreen({super.key});

  @override
  State<EmergencyContactsScreen> createState() => _EmergencyContactsScreenState();
}

class _EmergencyContactsScreenState extends State<EmergencyContactsScreen> {
  final List<EmergencyContact> _emergencyContacts = [
    EmergencyContact(
      id: '1',
      name: 'John Doe',
      relationship: 'Father',
      phoneNumber: '+234 801 123 4567',
      isPrimary: true,
    ),
    EmergencyContact(
      id: '2',
      name: 'Jane Smith',
      relationship: 'Sister',
      phoneNumber: '+234 802 234 5678',
      isPrimary: false,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final dark = THelperFunctions.isDarkMode(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Emergency Contacts'),
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
          IconButton(
            onPressed: _addEmergencyContact,
            icon: Icon(
              Iconsax.add,
              color: dark ? TColors.light : TColors.dark,
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
            
            // Emergency Info
            _buildEmergencyInfo(context, dark),
            
            const SizedBox(height: TSizes.spaceBtwSections),
            
            // Emergency Contacts List
            _buildEmergencyContactsList(context, dark),
            
            const SizedBox(height: TSizes.spaceBtwSections),
            
            // Add Contact Button
            _buildAddContactButton(context, dark),
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
          colors: [TColors.error, TColors.error.withOpacity(0.8)],
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
              Iconsax.call,
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
                  'Emergency Contacts',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: TColors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: TSizes.xs),
                Text(
                  'People we can contact in case of emergency',
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

  Widget _buildEmergencyInfo(BuildContext context, bool dark) {
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
                'Important Information',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: TSizes.spaceBtwItems),
          
          _buildInfoItem(
            'Emergency services will be contacted automatically if you press the emergency button during a ride.',
            Iconsax.shield_tick,
            TColors.success,
            context,
          ),
          
          _buildInfoItem(
            'Your emergency contacts will be notified with your location and trip details.',
            Iconsax.location,
            TColors.warning,
            context,
          ),
          
          _buildInfoItem(
            'Keep your emergency contacts updated with current phone numbers.',
            Iconsax.call,
            TColors.info,
            context,
          ),
        ],
      ),
    );
  }

  Widget _buildEmergencyContactsList(BuildContext context, bool dark) {
    if (_emergencyContacts.isEmpty) {
      return _buildEmptyState(context, dark);
    }

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
                Iconsax.profile_2user,
                color: TColors.primary,
                size: TSizes.iconMd,
              ),
              const SizedBox(width: TSizes.spaceBtwItems),
              Text(
                'Your Emergency Contacts',
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
            itemCount: _emergencyContacts.length,
            separatorBuilder: (context, index) => Divider(
              height: TSizes.spaceBtwItems * 2,
              color: dark ? TColors.darkGrey : TColors.lightGrey,
            ),
            itemBuilder: (context, index) {
              final contact = _emergencyContacts[index];
              return _buildContactItem(contact, context, dark);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, bool dark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(TSizes.defaultSpace * 2),
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
        children: [
          Container(
            padding: const EdgeInsets.all(TSizes.lg),
            decoration: BoxDecoration(
              color: TColors.error.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Iconsax.call_slash,
              size: TSizes.xl * 2,
              color: TColors.error.withOpacity(0.5),
            ),
          ),
          
          const SizedBox(height: TSizes.spaceBtwItems),
          
          Text(
            'No Emergency Contacts',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          
          const SizedBox(height: TSizes.xs),
          
          Text(
            'Add emergency contacts to ensure someone can be reached if needed during your rides.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: dark ? TColors.lightGrey : TColors.darkGrey,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildContactItem(EmergencyContact contact, BuildContext context, bool dark) {
    return Row(
      children: [
        CircleAvatar(
          radius: TSizes.lg,
          backgroundColor: contact.isPrimary 
              ? TColors.primary.withOpacity(0.1) 
              : TColors.lightGrey.withOpacity(0.3),
          child: Icon(
            Iconsax.user,
            color: contact.isPrimary ? TColors.primary : TColors.darkGrey,
            size: TSizes.iconMd,
          ),
        ),
        
        const SizedBox(width: TSizes.spaceBtwItems),
        
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    contact.name,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (contact.isPrimary) ...[
                    const SizedBox(width: TSizes.sm),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: TSizes.sm,
                        vertical: TSizes.xs / 2,
                      ),
                      decoration: BoxDecoration(
                        color: TColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(TSizes.xs),
                      ),
                      child: Text(
                        'PRIMARY',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: TColors.primary,
                          fontWeight: FontWeight.w600,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              
              const SizedBox(height: TSizes.xs),
              
              Text(
                contact.relationship,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: dark ? TColors.lightGrey : TColors.darkGrey,
                ),
              ),
              
              const SizedBox(height: TSizes.xs),
              
              Text(
                contact.phoneNumber,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: TColors.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        
        PopupMenuButton<String>(
          icon: Icon(
            Iconsax.more,
            color: dark ? TColors.lightGrey : TColors.darkGrey,
            size: TSizes.iconSm,
          ),
          onSelected: (value) => _handleContactAction(value, contact),
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  Icon(Iconsax.edit, size: TSizes.iconSm),
                  const SizedBox(width: TSizes.spaceBtwItems),
                  const Text('Edit'),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'primary',
              child: Row(
                children: [
                  Icon(
                    contact.isPrimary ? Iconsax.star1 : Iconsax.star,
                    size: TSizes.iconSm,
                  ),
                  const SizedBox(width: TSizes.spaceBtwItems),
                  Text(contact.isPrimary ? 'Remove Primary' : 'Set as Primary'),
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
        ),
      ],
    );
  }

  Widget _buildAddContactButton(BuildContext context, bool dark) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _addEmergencyContact,
        icon: const Icon(Iconsax.add),
        label: const Text('Add Emergency Contact'),
        style: ElevatedButton.styleFrom(
          backgroundColor: TColors.error,
          foregroundColor: TColors.white,
          padding: const EdgeInsets.symmetric(vertical: TSizes.md),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(TSizes.buttonRadius),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoItem(String text, IconData icon, Color color, BuildContext context) {
    final dark = THelperFunctions.isDarkMode(context);
    
    return Padding(
      padding: const EdgeInsets.only(bottom: TSizes.spaceBtwItems / 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: color,
            size: TSizes.iconSm,
          ),
          const SizedBox(width: TSizes.spaceBtwItems),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: dark ? TColors.lightGrey : TColors.darkGrey,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _addEmergencyContact() {
    _showContactDialog();
  }

  void _handleContactAction(String action, EmergencyContact contact) {
    switch (action) {
      case 'edit':
        _showContactDialog(contact: contact);
        break;
      case 'primary':
        _togglePrimaryContact(contact);
        break;
      case 'delete':
        _deleteContact(contact);
        break;
    }
  }

  void _showContactDialog({EmergencyContact? contact}) {
    final dark = THelperFunctions.isDarkMode(context);
    final isEditing = contact != null;
    
    final nameController = TextEditingController(text: contact?.name ?? '');
    final relationshipController = TextEditingController(text: contact?.relationship ?? '');
    final phoneController = TextEditingController(text: contact?.phoneNumber ?? '');
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isEditing ? 'Edit Contact' : 'Add Emergency Contact'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameController,
                validator: (value) => value?.isEmpty == true ? 'Name is required' : null,
                decoration: const InputDecoration(
                  labelText: 'Full Name',
                  prefixIcon: Icon(Iconsax.user),
                ),
              ),
              const SizedBox(height: TSizes.spaceBtwInputFields),
              TextFormField(
                controller: relationshipController,
                validator: (value) => value?.isEmpty == true ? 'Relationship is required' : null,
                decoration: const InputDecoration(
                  labelText: 'Relationship',
                  prefixIcon: Icon(Iconsax.heart),
                ),
              ),
              const SizedBox(height: TSizes.spaceBtwInputFields),
              TextFormField(
                controller: phoneController,
                validator: TValidator.validatePhoneNumber,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Phone Number',
                  prefixIcon: Icon(Iconsax.call),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                final newContact = EmergencyContact(
                  id: contact?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
                  name: nameController.text,
                  relationship: relationshipController.text,
                  phoneNumber: phoneController.text,
                  isPrimary: contact?.isPrimary ?? false,
                );
                
                setState(() {
                  if (isEditing) {
                    final index = _emergencyContacts.indexWhere((c) => c.id == contact!.id);
                    _emergencyContacts[index] = newContact;
                  } else {
                    _emergencyContacts.add(newContact);
                  }
                });
                
                Navigator.pop(context);
                THelperFunctions.showSnackBar(
                  isEditing ? 'Contact updated successfully!' : 'Contact added successfully!',
                );
              }
            },
            child: Text(isEditing ? 'Update' : 'Add'),
          ),
        ],
      ),
    );
  }

  void _togglePrimaryContact(EmergencyContact contact) {
    setState(() {
      if (contact.isPrimary) {
        // Remove primary status
        final index = _emergencyContacts.indexWhere((c) => c.id == contact.id);
        _emergencyContacts[index] = EmergencyContact(
          id: contact.id,
          name: contact.name,
          relationship: contact.relationship,
          phoneNumber: contact.phoneNumber,
          isPrimary: false,
        );
      } else {
        // Set as primary and remove primary from others
        for (int i = 0; i < _emergencyContacts.length; i++) {
          _emergencyContacts[i] = EmergencyContact(
            id: _emergencyContacts[i].id,
            name: _emergencyContacts[i].name,
            relationship: _emergencyContacts[i].relationship,
            phoneNumber: _emergencyContacts[i].phoneNumber,
            isPrimary: _emergencyContacts[i].id == contact.id,
          );
        }
      }
    });
    
    THelperFunctions.showSnackBar(
      contact.isPrimary ? 'Primary contact removed' : 'Primary contact updated',
    );
  }

  void _deleteContact(EmergencyContact contact) {
    final dark = THelperFunctions.isDarkMode(context);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Contact'),
        content: Text(
          'Are you sure you want to delete ${contact.name} from your emergency contacts?',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: dark ? TColors.lightGrey : TColors.darkGrey,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _emergencyContacts.removeWhere((c) => c.id == contact.id);
              });
              Navigator.pop(context);
              THelperFunctions.showSnackBar('Contact deleted successfully');
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

class EmergencyContact {
  final String id;
  final String name;
  final String relationship;
  final String phoneNumber;
  final bool isPrimary;

  const EmergencyContact({
    required this.id,
    required this.name,
    required this.relationship,
    required this.phoneNumber,
    required this.isPrimary,
  });
} 