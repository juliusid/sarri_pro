import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sarri_ride/utils/constants/colors.dart';
import 'package:sarri_ride/utils/constants/sizes.dart';
import 'package:sarri_ride/utils/helpers/helper_functions.dart';
import 'package:iconsax/iconsax.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  String selectedPeriod = 'This Month';
  bool isBalanceVisible = true;

  @override
  Widget build(BuildContext context) {
    final dark = THelperFunctions.isDarkMode(context);
    
    return Scaffold(
      backgroundColor: dark ? TColors.dark : TColors.lightGrey,
      appBar: AppBar(
        title: const Text('My Wallet'),
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
            onPressed: () => setState(() => isBalanceVisible = !isBalanceVisible),
            icon: Icon(
              isBalanceVisible ? Iconsax.eye_slash : Iconsax.eye,
              color: dark ? TColors.light : TColors.dark,
              size: TSizes.iconLg,
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Wallet Balance Header
            Container(
              width: double.infinity,
              margin: const EdgeInsets.all(TSizes.defaultSpace),
              padding: const EdgeInsets.all(TSizes.defaultSpace),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [TColors.primary, TColors.primary.withOpacity(0.8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(TSizes.cardRadiusLg),
                boxShadow: [
                  BoxShadow(
                    color: TColors.primary.withOpacity(0.3),
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
                              'Wallet Balance',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: TColors.white.withOpacity(0.8),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: TSizes.xs),
                            Text(
                              isBalanceVisible ? '₦25,480.50' : '₦****.**',
                              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                color: TColors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: TSizes.spaceBtwSections),
                  
                  // Quick Actions
                  Row(
                    children: [
                      Expanded(
                        child: _buildQuickAction(
                          icon: Iconsax.add,
                          label: 'Top Up',
                          onTap: () => _topUpWallet(),
                        ),
                      ),
                      const SizedBox(width: TSizes.spaceBtwItems),
                      Expanded(
                        child: _buildQuickAction(
                          icon: Iconsax.arrow_up_3,
                          label: 'Send',
                          onTap: () => _sendMoney(),
                        ),
                      ),
                      const SizedBox(width: TSizes.spaceBtwItems),
                      Expanded(
                        child: _buildQuickAction(
                          icon: Iconsax.arrow_down,
                          label: 'Withdraw',
                          onTap: () => _withdrawMoney(),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // Stats Cards
            Container(
              margin: const EdgeInsets.symmetric(horizontal: TSizes.defaultSpace),
              child: Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      title: 'Total Spent',
                      value: '₦45,200',
                      icon: Iconsax.card_send,
                      color: TColors.error,
                      dark: dark,
                      context: context,
                    ),
                  ),
                  const SizedBox(width: TSizes.spaceBtwItems),
                  Expanded(
                    child: _buildStatCard(
                      title: 'Total Earned',
                      value: '₦2,150',
                      icon: Iconsax.card_receive,
                      color: TColors.success,
                      dark: dark,
                      context: context,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: TSizes.spaceBtwSections),
            
            // Transaction History
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Transaction History',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: dark ? TColors.white : TColors.black,
                        ),
                      ),
                      DropdownButton<String>(
                        value: selectedPeriod,
                        onChanged: (String? newValue) {
                          setState(() {
                            selectedPeriod = newValue!;
                          });
                        },
                        items: <String>['This Week', 'This Month', 'Last Month', 'All Time']
                            .map<DropdownMenuItem<String>>((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                        underline: Container(),
                        icon: Icon(
                          Iconsax.arrow_down_1,
                          color: dark ? TColors.lightGrey : TColors.darkGrey,
                          size: TSizes.iconSm,
                        ),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: dark ? TColors.lightGrey : TColors.darkGrey,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: TSizes.spaceBtwItems),
                  
                  // Transactions list
                  ...List.generate(_transactions.length, (index) {
                    final transaction = _transactions[index];
                    final isLast = index == _transactions.length - 1;
                    return _buildTransactionCard(transaction, dark, context, isLast);
                  }),
                ],
              ),
            ),
            
            const SizedBox(height: TSizes.spaceBtwSections),
            
            // Wallet Settings
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
                    'Wallet Settings',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: dark ? TColors.white : TColors.black,
                    ),
                  ),
                  const SizedBox(height: TSizes.spaceBtwItems),
                  
                  _buildSettingsOption(
                    icon: Iconsax.security_card,
                    title: 'Security Settings',
                    subtitle: 'Manage PIN and security options',
                    onTap: () => _securitySettings(),
                    dark: dark,
                    context: context,
                  ),
                  _buildSettingsOption(
                    icon: Iconsax.bank,
                    title: 'Link Bank Account',
                    subtitle: 'Connect your bank for easy transfers',
                    onTap: () => _linkBankAccount(),
                    dark: dark,
                    context: context,
                  ),
                  _buildSettingsOption(
                    icon: Iconsax.document_download,
                    title: 'Download Statement',
                    subtitle: 'Get your transaction history',
                    onTap: () => _downloadStatement(),
                    dark: dark,
                    context: context,
                    isLast: true,
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

  Widget _buildQuickAction({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(TSizes.cardRadiusMd),
      child: Container(
        padding: const EdgeInsets.all(TSizes.defaultSpace),
        decoration: BoxDecoration(
          color: TColors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(TSizes.cardRadiusMd),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: TColors.white,
              size: TSizes.iconLg,
            ),
            const SizedBox(height: TSizes.xs),
            Text(
              label,
              style: TextStyle(
                color: TColors.white,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required bool dark,
    required BuildContext context,
  }) {
    return Container(
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
        children: [
          Container(
            padding: const EdgeInsets.all(TSizes.sm),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(TSizes.cardRadiusMd),
            ),
            child: Icon(
              icon,
              color: color,
              size: TSizes.iconLg,
            ),
          ),
          const SizedBox(height: TSizes.spaceBtwItems),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: dark ? TColors.white : TColors.black,
            ),
          ),
          const SizedBox(height: TSizes.xs),
          Text(
            title,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: dark ? TColors.lightGrey : TColors.darkGrey,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionCard(WalletTransaction transaction, bool dark, BuildContext context, bool isLast) {
    final isCredit = transaction.type == 'credit';
    final color = isCredit ? TColors.success : TColors.error;
    
    return Container(
      margin: EdgeInsets.only(bottom: isLast ? 0 : TSizes.spaceBtwItems),
      padding: const EdgeInsets.all(TSizes.defaultSpace),
      decoration: BoxDecoration(
        color: dark ? TColors.darkerGrey : TColors.lightGrey,
        borderRadius: BorderRadius.circular(TSizes.cardRadiusMd),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(TSizes.sm),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(TSizes.cardRadiusMd),
            ),
            child: Icon(
              transaction.icon,
              color: color,
              size: TSizes.iconMd,
            ),
          ),
          const SizedBox(width: TSizes.spaceBtwItems),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: dark ? TColors.white : TColors.black,
                  ),
                ),
                const SizedBox(height: TSizes.xs),
                Text(
                  '${transaction.date} • ${transaction.time}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: dark ? TColors.lightGrey : TColors.darkGrey,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${isCredit ? '+' : '-'}₦${transaction.amount}',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(height: TSizes.xs),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: TSizes.sm, vertical: 2),
                decoration: BoxDecoration(
                  color: _getStatusColor(transaction.status).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(TSizes.cardRadiusLg),
                ),
                child: Text(
                  transaction.status,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: _getStatusColor(transaction.status),
                    fontWeight: FontWeight.w600,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required bool dark,
    required BuildContext context,
    bool isLast = false,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: isLast ? 0 : TSizes.spaceBtwItems),
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Container(
          padding: const EdgeInsets.all(TSizes.sm),
          decoration: BoxDecoration(
            color: TColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(TSizes.borderRadiusMd),
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
            color: dark ? TColors.white : TColors.black,
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
          size: TSizes.iconMd,
        ),
        onTap: onTap,
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Completed':
        return TColors.success;
      case 'Pending':
        return TColors.warning;
      case 'Failed':
        return TColors.error;
      default:
        return TColors.info;
    }
  }

  // Action methods
  void _topUpWallet() {
    THelperFunctions.showSnackBar('Top up wallet feature coming soon');
  }

  void _sendMoney() {
    THelperFunctions.showSnackBar('Send money feature coming soon');
  }

  void _withdrawMoney() {
    THelperFunctions.showSnackBar('Withdraw money feature coming soon');
  }

  void _securitySettings() {
    THelperFunctions.showSnackBar('Security settings feature coming soon');
  }

  void _linkBankAccount() {
    THelperFunctions.showSnackBar('Link bank account feature coming soon');
  }

  void _downloadStatement() {
    THelperFunctions.showSnackBar('Download statement feature coming soon');
  }
}

class WalletTransaction {
  final String title;
  final String date;
  final String time;
  final String amount;
  final String type;
  final String status;
  final IconData icon;

  WalletTransaction({
    required this.title,
    required this.date,
    required this.time,
    required this.amount,
    required this.type,
    required this.status,
    required this.icon,
  });
}

// Mock transactions
final List<WalletTransaction> _transactions = [
  WalletTransaction(
    title: 'Top Up from Bank',
    date: 'Today',
    time: '2:30 PM',
    amount: '5,000',
    type: 'credit',
    status: 'Completed',
    icon: Iconsax.card_receive,
  ),
  WalletTransaction(
    title: 'Ride Payment',
    date: 'Today',
    time: '10:15 AM',
    amount: '3,200',
    type: 'debit',
    status: 'Completed',
    icon: Iconsax.car,
  ),
  WalletTransaction(
    title: 'Cashback Reward',
    date: 'Yesterday',
    time: '8:45 PM',
    amount: '150',
    type: 'credit',
    status: 'Completed',
    icon: Iconsax.gift,
  ),
  WalletTransaction(
    title: 'Ride Payment',
    date: 'Yesterday',
    time: '6:20 PM',
    amount: '2,800',
    type: 'debit',
    status: 'Completed',
    icon: Iconsax.car,
  ),
  WalletTransaction(
    title: 'Withdrawal',
    date: 'Dec 15',
    time: '3:10 PM',
    amount: '10,000',
    type: 'debit',
    status: 'Pending',
    icon: Iconsax.card_send,
  ),
  WalletTransaction(
    title: 'Referral Bonus',
    date: 'Dec 14',
    time: '11:30 AM',
    amount: '2,000',
    type: 'credit',
    status: 'Completed',
    icon: Iconsax.people,
  ),
]; 