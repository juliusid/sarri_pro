import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import 'package:sarri_ride/features/driver/controllers/driver_wallet_controller.dart';
import 'package:sarri_ride/utils/constants/colors.dart';
import 'package:sarri_ride/utils/constants/sizes.dart';
import 'package:sarri_ride/utils/helpers/helper_functions.dart';
import 'package:sarri_ride/common/widgets/loading_button.dart';

class WalletScreen extends StatelessWidget {
  const WalletScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(DriverWalletController());
    final dark = THelperFunctions.isDarkMode(context);
    final backgroundColor = dark ? TColors.dark : const Color(0xFFF8F9FA);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text(
          'My Wallet',
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: backgroundColor,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Get.back(),
          icon: Icon(
            Iconsax.arrow_left_2,
            color: dark ? TColors.white : TColors.black,
          ),
        ),
        actions: [
          IconButton(
            onPressed: controller.fetchAllWalletData,
            icon: Icon(
              Iconsax.refresh,
              color: dark ? TColors.white : TColors.black,
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: controller.fetchAllWalletData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(TSizes.defaultSpace),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Balance Card
              _buildBalanceCard(context, controller, dark),
              const SizedBox(height: TSizes.spaceBtwItems),

              // 2. Pending Earnings (if any)
              Obx(() {
                if (controller.totalPendingEarnings.value > 0) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: TSizes.spaceBtwItems),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: TColors.warning.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: TColors.warning.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Iconsax.clock,
                          color: TColors.warning,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Pending Clearance',
                              style: TextStyle(
                                color: dark
                                    ? TColors.lightGrey
                                    : TColors.darkGrey,
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              '₦${controller.totalPendingEarnings.value.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: TColors.warning,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                }
                return const SizedBox.shrink();
              }),

              // 3. Tab Section (Transactions / Withdrawals)
              DefaultTabController(
                length: 2,
                child: Column(
                  children: [
                    Container(
                      height: 45,
                      decoration: BoxDecoration(
                        color: dark ? TColors.darkerGrey : Colors.white,
                        borderRadius: BorderRadius.circular(25),
                        border: Border.all(
                          color: dark
                              ? Colors.transparent
                              : Colors.grey.withOpacity(0.2),
                        ),
                      ),
                      child: TabBar(
                        indicatorSize: TabBarIndicatorSize.tab,
                        indicator: BoxDecoration(
                          color: TColors.primary,
                          borderRadius: BorderRadius.circular(25),
                        ),
                        labelColor: Colors.white,
                        unselectedLabelColor: dark
                            ? TColors.lightGrey
                            : TColors.darkGrey,
                        labelStyle: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                        tabs: const [
                          Tab(text: "Transactions"),
                          Tab(text: "Withdrawals"),
                        ],
                      ),
                    ),
                    const SizedBox(height: TSizes.spaceBtwSections),

                    // Tab Views content handled manually to fit in ScrollView
                    // We use an AnimatedSwitcher or GetX condition here for simplicity or just list both with conditional visibility
                    // A better approach in SingleChildScrollView is to not use TabBarView (which needs height).
                    // We'll simulate tabs or stick to one list.
                    // For robustness, let's just show titles and lists below.
                  ],
                ),
              ),

              // 4. Transactions List
              Text(
                "Recent Activity",
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: TSizes.sm),
              _buildTransactionsList(context, controller, dark),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBalanceCard(
    BuildContext context,
    DriverWalletController controller,
    bool dark,
  ) {
    return Obx(() {
      final balance = controller.walletBalance.value?.balance ?? 0.0;
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [TColors.primary, TColors.primary.withOpacity(0.8)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: TColors.primary.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          children: [
            Text(
              'Available Balance',
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            controller.isLoadingBalance.value
                ? const SizedBox(
                    height: 40,
                    width: 40,
                    child: CircularProgressIndicator(color: Colors.white),
                  )
                : Text(
                    '₦${balance.toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: balance > 500
                    ? () => _showWithdrawModal(context, controller, balance)
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: TColors.primary,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Withdraw Funds',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            ),
            if (balance <= 500)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  "Minimum withdrawal: ₦500",
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 12,
                  ),
                ),
              ),
          ],
        ),
      );
    });
  }

  Widget _buildTransactionsList(
    BuildContext context,
    DriverWalletController controller,
    bool dark,
  ) {
    return Obx(() {
      if (controller.isLoadingTransactions.value) {
        return const Center(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: CircularProgressIndicator(),
          ),
        );
      }

      if (controller.transactions.isEmpty) {
        return _buildEmptyState(dark, "No transactions yet");
      }

      return ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: controller.transactions.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final tx = controller.transactions[index];
          final isCredit = [
            'trip_earning',
            'debt_settlement',
            'bonus',
          ].contains(tx.type);
          final isDebit = [
            'withdrawal',
            'cash_payment',
            'penalty',
          ].contains(tx.type);

          Color iconColor = isCredit
              ? TColors.success
              : (isDebit ? TColors.error : TColors.info);
          IconData icon = isCredit
              ? Iconsax.arrow_down_2
              : (isDebit ? Iconsax.arrow_up_2 : Iconsax.refresh);

          if (tx.type == 'trip_earning') icon = Iconsax.car;
          if (tx.type == 'withdrawal') icon = Iconsax.bank;

          return Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: dark ? TColors.darkerGrey.withOpacity(0.3) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: dark ? Colors.transparent : Colors.grey.withOpacity(0.1),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: iconColor, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tx.description,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: dark ? TColors.white : TColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        DateFormat('MMM dd, hh:mm a').format(tx.date),
                        style: TextStyle(
                          color: dark
                              ? TColors.lightGrey
                              : TColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '${isCredit ? '+' : (isDebit ? '-' : '')}₦${tx.amount.toStringAsFixed(0)}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: iconColor,
                  ),
                ),
              ],
            ),
          );
        },
      );
    });
  }

  Widget _buildEmptyState(bool dark, String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          children: [
            Icon(
              Iconsax.wallet_1,
              size: 48,
              color: dark ? TColors.darkGrey : Colors.grey[300],
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: TextStyle(
                color: dark ? TColors.lightGrey : TColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showWithdrawModal(
    BuildContext context,
    DriverWalletController controller,
    double maxBalance,
  ) {
    final amountController = TextEditingController();
    final dark = THelperFunctions.isDarkMode(context);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: dark ? TColors.dark : TColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          left: 24,
          right: 24,
          top: 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Withdraw Funds',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Available: ₦${maxBalance.toStringAsFixed(2)}',
              style: TextStyle(
                color: TColors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),

            // Amount Input
            TextField(
              controller: amountController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              style: TextStyle(color: dark ? TColors.white : TColors.black),
              decoration: InputDecoration(
                labelText: 'Amount',
                prefixText: '₦ ',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                suffixIcon: TextButton(
                  onPressed: () =>
                      amountController.text = maxBalance.toStringAsFixed(2),
                  child: const Text('MAX'),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Confirm Button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: Obx(
                () => LoadingElevatedButton(
                  isLoading: controller.isWithdrawing.value,
                  text: 'Confirm Withdrawal',
                  onPressed: () async {
                    final amount =
                        double.tryParse(amountController.text) ?? 0.0;

                    if (amount < 500) {
                      THelperFunctions.showSnackBar(
                        'Minimum withdrawal is ₦500',
                      );
                      return;
                    }
                    if (amount > maxBalance) {
                      THelperFunctions.showSnackBar('Insufficient funds');
                      return;
                    }

                    final success = await controller.initiateWithdrawal(amount);
                    if (success) {
                      Navigator.pop(context);
                      THelperFunctions.showSuccessSnackBar(
                        'Success',
                        'Withdrawal initiated successfully',
                      );
                    }
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
