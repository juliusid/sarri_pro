import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sarri_ride/features/driver/controllers/driver_dashboard_controller.dart';
import 'package:sarri_ride/utils/constants/colors.dart';
import 'package:sarri_ride/utils/constants/sizes.dart';
import 'package:sarri_ride/utils/helpers/helper_functions.dart';
import 'package:iconsax/iconsax.dart';
import 'package:sarri_ride/core/services/http_service.dart';
import 'package:sarri_ride/config/api_config.dart';
import 'package:sarri_ride/utils/validators/validation.dart';
import 'package:sarri_ride/common/widgets/loading_button.dart';

// Model for the bank list
class Bank {
  final String name;
  final String code;
  Bank({required this.name, required this.code});

  factory Bank.fromJson(Map<String, dynamic> json) {
    return Bank(name: json['name'] as String, code: json['code'] as String);
  }
}

class BankDetailsScreen extends StatefulWidget {
  const BankDetailsScreen({super.key});

  @override
  State<BankDetailsScreen> createState() => _BankDetailsScreenState();
}

class _BankDetailsScreenState extends State<BankDetailsScreen> {
  final HttpService _httpService = HttpService.instance;
  final DriverDashboardController _driverController =
      Get.find<DriverDashboardController>();
  final _formKey = GlobalKey<FormState>();

  // Form controllers
  final _accountNumberController = TextEditingController();
  Bank? _selectedBank;

  // State
  List<Bank> _bankList = [];
  bool _isLoadingBanks = true;
  bool _isVerifying = false;
  bool _isResolving = false;
  String? _resolvedAccountName;

  // Controllers to display current details
  final _currentBankNameController = TextEditingController();
  final _currentAccountNameController = TextEditingController();
  final _currentAccountNumberController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchBankList();
    _loadCurrentDetails();
    _accountNumberController.addListener(_onAccountDetailsChanged);
  }

  void _onAccountDetailsChanged() {
    final accountText = _accountNumberController.text.trim();
    if (accountText.length == 10 && _selectedBank != null) {
      _resolveBankAccount();
    } else {
      setState(() {
        _resolvedAccountName = null;
      });
    }
  }

  Future<void> _resolveBankAccount() async {
    final accountText = _accountNumberController.text.trim();
    if (accountText.length != 10 || _selectedBank == null) return;

    setState(() {
      _isResolving = true;
      _resolvedAccountName = null;
    });

    try {
      final response = await _httpService.get(
        '${ApiConfig.driverResolveBankEndpoint}?account_number=$accountText&bank_code=${_selectedBank!.code}',
      );
      final responseData = _httpService.handleResponse(response);

      if (responseData['success'] == true && responseData['data'] != null) {
        setState(() {
          _resolvedAccountName = responseData['data']['account_name'];
        });
      } else {
        setState(() {
          _resolvedAccountName = 'Account not found';
        });
      }
    } catch (e) {
      setState(() {
        _resolvedAccountName = 'Verification failed';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isResolving = false;
        });
      }
    }
  }

  void _loadCurrentDetails() {
    final bankDetails =
        _driverController.currentDriver.value?.driverProfile?.bankDetails;
    if (bankDetails != null) {
      _currentBankNameController.text = bankDetails.bankName ?? 'N/A';
      _currentAccountNameController.text = bankDetails.bankAccountName ?? 'N/A';
      _currentAccountNumberController.text =
          bankDetails.bankAccountNumber ?? 'N/A';
    }
  }

  Future<void> _fetchBankList() async {
    try {
      final response = await _httpService.get(ApiConfig.driverBankListEndpoint);
      final responseData = _httpService.handleResponse(response);

      if (responseData['success'] == true && responseData['data'] is List) {
        List<Bank> banks = (responseData['data'] as List)
            .map((json) => Bank.fromJson(json))
            .toList();
        setState(() {
          _bankList = banks;
          _isLoadingBanks = false;
        });
      } else {
        throw Exception(responseData['message'] ?? 'Failed to load bank list');
      }
    } catch (e) {
      setState(() {
        _isLoadingBanks = false;
      });
      THelperFunctions.showErrorSnackBar(
        'Error',
        'Could not fetch bank list: $e',
      );
    }
  }

  Future<void> _updateBankDetails() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedBank == null) {
      THelperFunctions.showSnackBar('Please select a bank.');
      return;
    }

    setState(() {
      _isVerifying = true;
    });

    try {
      final response = await _httpService.post(
        ApiConfig.driverUpdateBankEndpoint,
        body: {
          "bankAccountNumber": _accountNumberController.text.trim(),
          "bankCode": _selectedBank!.code,
          "bankName": _selectedBank!.name,
        },
      );
      final responseData = _httpService.handleResponse(response);

      if (responseData['success'] == true && responseData['data'] is Map) {
        final data = responseData['data'];

        // Update the text controllers for current details
        _currentBankNameController.text = data['bankName'] ?? 'N/A';
        _currentAccountNameController.text = data['bankAccountName'] ?? 'N/A';
        _currentAccountNumberController.text =
            data['bankAccountNumber'] ?? 'N/A';

        // --- START OF CORRECTION ---
        // Manually update the DriverDashboardController's state
        final driver = _driverController.currentDriver.value;
        if (driver != null && driver.driverProfile != null) {
          // 1. Create new BankDetailsModel with the new data
          final newBankDetails = driver.driverProfile!.bankDetails.copyWith(
            bankName: data['bankName'],
            bankAccountName: data['bankAccountName'],
            bankAccountNumber: data['bankAccountNumber'],
          );

          // 2. Create new DriverProfile with the new BankDetails
          final newDriverProfile = driver.driverProfile!.copyWith(
            bankDetails: newBankDetails,
          );

          // 3. Create new User with the new DriverProfile
          _driverController.currentDriver.value = driver.copyWith(
            driverProfile: newDriverProfile,
          );

          // 4. Notify listeners that the driver object has changed
          _driverController.currentDriver.refresh();
        }
        // --- END OF CORRECTION ---

        // Clear the form fields
        _accountNumberController.clear();
        setState(() {
          _selectedBank = null;
        });

        THelperFunctions.showSuccessSnackBar(
          'Success',
          responseData['message'],
        );
      } else {
        throw Exception(
          responseData['message'] ?? 'Failed to update bank details',
        );
      }
    } catch (e) {
      THelperFunctions.showErrorSnackBar('Verification Failed', e.toString());
    } finally {
      setState(() {
        _isVerifying = false;
      });
    }
  }

  @override
  void dispose() {
    _accountNumberController.removeListener(_onAccountDetailsChanged);
    _accountNumberController.dispose();
    _currentBankNameController.dispose();
    _currentAccountNameController.dispose();
    _currentAccountNumberController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dark = THelperFunctions.isDarkMode(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bank Details'),
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
            // Current Details
            _buildCurrentDetails(context, dark),

            const SizedBox(height: TSizes.spaceBtwSections),

            // Add/Update Form
            _buildUpdateForm(context, dark),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentDetails(BuildContext context, bool dark) {
    return Container(
      padding: const EdgeInsets.all(TSizes.defaultSpace),
      decoration: BoxDecoration(
        color: dark ? TColors.cardBackgroundDark : TColors.cardBackground,
        borderRadius: BorderRadius.circular(TSizes.cardRadiusLg),
        boxShadow: [
          BoxShadow(
            color: TColors.black.withOpacity(dark ? 0.3 : 0.1),
            blurRadius: TSizes.sm,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Current Payout Account',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: TSizes.spaceBtwItems),
          TextFormField(
            controller: _currentBankNameController,
            readOnly: true,
            decoration: const InputDecoration(
              labelText: 'Bank Name',
              prefixIcon: Icon(Iconsax.bank),
            ),
          ),
          const SizedBox(height: TSizes.spaceBtwInputFields),
          TextFormField(
            controller: _currentAccountNameController,
            readOnly: true,
            decoration: const InputDecoration(
              labelText: 'Account Name',
              prefixIcon: Icon(Iconsax.user),
            ),
          ),
          const SizedBox(height: TSizes.spaceBtwInputFields),
          TextFormField(
            controller: _currentAccountNumberController,
            readOnly: true,
            decoration: const InputDecoration(
              labelText: 'Account Number',
              prefixIcon: Icon(Iconsax.hashtag),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUpdateForm(BuildContext context, bool dark) {
    return Container(
      padding: const EdgeInsets.all(TSizes.defaultSpace),
      decoration: BoxDecoration(
        color: dark ? TColors.cardBackgroundDark : TColors.cardBackground,
        borderRadius: BorderRadius.circular(TSizes.cardRadiusLg),
        boxShadow: [
          BoxShadow(
            color: TColors.black.withOpacity(dark ? 0.3 : 0.1),
            blurRadius: TSizes.sm,
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
              'Add / Update Account',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: TSizes.spaceBtwItems),
            // Bank List Dropdown
            _isLoadingBanks
                ? const Center(child: CircularProgressIndicator())
                : DropdownButtonFormField<Bank>(
                    value: _selectedBank,
                    hint: const Text('Select your bank'),
                    isExpanded: true,
                    items: _bankList.map((Bank bank) {
                      return DropdownMenuItem<Bank>(
                        value: bank,
                        child: Text(bank.name, overflow: TextOverflow.ellipsis),
                      );
                    }).toList(),
                    onChanged: (Bank? newValue) {
                      setState(() {
                        _selectedBank = newValue;
                      });
                      _onAccountDetailsChanged();
                    },
                    decoration: const InputDecoration(
                      labelText: 'Bank',
                      prefixIcon: Icon(Iconsax.bank),
                    ),
                    validator: (value) =>
                        value == null ? 'Please select a bank' : null,
                  ),
            const SizedBox(height: TSizes.spaceBtwInputFields),

            // Account Number
            TextFormField(
              controller: _accountNumberController,
              keyboardType: TextInputType.number,
              maxLength: 10,
              decoration: const InputDecoration(
                labelText: 'Account Number',
                prefixIcon: Icon(Iconsax.hashtag),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Account number is required';
                }
                if (value.trim().length != 10) {
                  return 'Account number must be 10 digits';
                }
                return null;
              },
            ),
            
            // Resolved Account Name Display
            if (_isResolving)
              const Padding(
                padding: EdgeInsets.only(top: TSizes.spaceBtwItems),
                child: Row(
                  children: [
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    SizedBox(width: TSizes.spaceBtwItems),
                    Text('Verifying account details...'),
                  ],
                ),
              )
            else if (_resolvedAccountName != null)
              Padding(
                padding: const EdgeInsets.only(top: TSizes.spaceBtwItems),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(TSizes.md),
                  decoration: BoxDecoration(
                    color: _resolvedAccountName == 'Account not found' || _resolvedAccountName == 'Verification failed' 
                        ? TColors.error.withOpacity(0.1) 
                        : TColors.success.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(TSizes.cardRadiusMd),
                    border: Border.all(
                      color: _resolvedAccountName == 'Account not found' || _resolvedAccountName == 'Verification failed' 
                          ? TColors.error 
                          : TColors.success,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _resolvedAccountName == 'Account not found' || _resolvedAccountName == 'Verification failed' 
                            ? Iconsax.warning_2 
                            : Iconsax.tick_circle,
                        color: _resolvedAccountName == 'Account not found' || _resolvedAccountName == 'Verification failed' 
                            ? TColors.error 
                            : TColors.success,
                      ),
                      const SizedBox(width: TSizes.spaceBtwItems),
                      Expanded(
                        child: Text(
                          _resolvedAccountName!,
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: _resolvedAccountName == 'Account not found' || _resolvedAccountName == 'Verification failed' 
                                ? TColors.error 
                                : TColors.success,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
            const SizedBox(height: TSizes.spaceBtwSections),

            // Update Button
            SizedBox(
              width: double.infinity,
              child: LoadingElevatedButton(
                isLoading: _isVerifying,
                text: 'Verify & Save Account',
                loadingText: 'Verifying...',
                onPressed: _updateBankDetails,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
