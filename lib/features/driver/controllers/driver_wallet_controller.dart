import 'package:get/get.dart';
import 'package:sarri_ride/config/api_config.dart';
import 'package:sarri_ride/core/services/http_service.dart';
import 'package:sarri_ride/core/services/websocket_service.dart';
import 'package:sarri_ride/utils/helpers/helper_functions.dart';
import 'package:sarri_ride/utils/logging/app_logger.dart';

// --- MODELS ---

class WalletBalance {
  final double balance;
  final double totalEarnings;
  final double pendingEarnings;
  final double withdrawnAmount;
  final int totalTrips;
  final String currency;

  WalletBalance({
    this.balance = 0.0,
    this.totalEarnings = 0.0,
    this.pendingEarnings = 0.0,
    this.withdrawnAmount = 0.0,
    this.totalTrips = 0,
    this.currency = "NGN",
  });

  factory WalletBalance.fromJson(Map<String, dynamic> json) {
    return WalletBalance(
      balance: (json['balance'] as num?)?.toDouble() ?? 0.0,
      totalEarnings: (json['totalEarnings'] as num?)?.toDouble() ?? 0.0,
      pendingEarnings: (json['pendingEarnings'] as num?)?.toDouble() ?? 0.0,
      withdrawnAmount: (json['withdrawnAmount'] as num?)?.toDouble() ?? 0.0,
      totalTrips: (json['totalTrips'] as num?)?.toInt() ?? 0,
      currency: json['currency'] ?? 'NGN',
    );
  }

  String get formattedBalance => '₦${balance.toStringAsFixed(2)}';
}

class WalletTransaction {
  final String id;
  final String type;
  final String status;
  final double amount;
  final String description;
  final DateTime date;

  WalletTransaction({
    required this.id,
    required this.type,
    required this.status,
    required this.amount,
    required this.description,
    required this.date,
  });

  factory WalletTransaction.fromJson(Map<String, dynamic> json) {
    return WalletTransaction(
      id: json['id'] as String? ?? '',
      type: json['type'] as String? ?? 'unknown',
      status: json['status'] as String? ?? 'pending',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      description: json['description'] as String? ?? '',
      date:
          DateTime.tryParse(
            json['date'] as String? ?? json['createdAt'] as String? ?? '',
          ) ??
          DateTime.now(),
    );
  }
}

class WithdrawalRequest {
  final String id;
  final double amount;
  final String status; // pending, approved, rejected
  final String reference;
  final DateTime date;

  WithdrawalRequest({
    required this.id,
    required this.amount,
    required this.status,
    required this.reference,
    required this.date,
  });

  factory WithdrawalRequest.fromJson(Map<String, dynamic> json) {
    return WithdrawalRequest(
      id: json['_id'] ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      status: json['status'] ?? 'pending',
      reference: json['reference'] ?? '',
      date: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
    );
  }
}

// --- CONTROLLER ---

class DriverWalletController extends GetxController {
  static DriverWalletController get instance => Get.find();
  final HttpService _httpService = HttpService.instance;
  final WebSocketService _webSocketService = WebSocketService.instance;

  // Data
  final Rx<WalletBalance?> walletBalance = Rx<WalletBalance?>(null);
  final RxList<WalletTransaction> transactions = <WalletTransaction>[].obs;
  final RxList<WithdrawalRequest> withdrawals = <WithdrawalRequest>[].obs;
  final RxMap<String, dynamic> walletStats = <String, dynamic>{}.obs;

  // Pending Earnings Data
  final RxDouble totalPendingEarnings = 0.0.obs;

  // Load States
  final RxBool isLoadingBalance = true.obs;
  final RxBool isLoadingStats = true.obs;
  final RxBool isLoadingTransactions = true.obs;
  final RxBool isLoadingWithdrawals = false.obs;
  final RxBool isWithdrawing = false.obs;

  // Pagination
  final RxInt currentPage = 1.obs;
  final RxBool hasNextPage = false.obs;

  @override
  void onInit() {
    super.onInit();
    _webSocketService.registerWalletUpdateListener((data) => refreshAll());
    _webSocketService.registerPaymentProcessedListener((data) => refreshAll());
    fetchAllWalletData();
  }

  void refreshAll() {
    fetchAllWalletData();
  }

  Future<void> fetchAllWalletData() async {
    isLoadingBalance.value = true;
    isLoadingStats.value = true;
    isLoadingTransactions.value = true;

    try {
      await Future.wait([
        fetchWalletBalance(),
        fetchPendingEarnings(),
        fetchWalletStatistics('month'),
        fetchTransactions(),
        fetchWithdrawals(),
      ]);
    } catch (e, stack) {
      AppLogger.error("Error fetching wallet data", error: e, stackTrace: stack);
    } finally {
      isLoadingBalance.value = false;
      isLoadingStats.value = false;
      isLoadingTransactions.value = false;
    }
  }

  Future<void> fetchWalletBalance() async {
    try {
      final response = await _httpService.get(
        ApiConfig.driverWalletBalanceEndpoint,
      );
      final responseData = _httpService.handleResponse(response);
      if (responseData['success'] == true && responseData['data'] != null) {
        walletBalance.value = WalletBalance.fromJson(responseData['data']);
      }
    } catch (e, stack) {
      AppLogger.error("Balance fetch error", error: e, stackTrace: stack);
    }
  }

  Future<void> fetchPendingEarnings() async {
    try {
      final response = await _httpService.get(
        ApiConfig.driverWalletPendingEarningsEndpoint,
      );
      final responseData = _httpService.handleResponse(response);
      if (responseData['success'] == true && responseData['data'] != null) {
        totalPendingEarnings.value =
            (responseData['data']['totalPendingEarnings'] as num?)
                ?.toDouble() ??
            0.0;
      }
    } catch (e, stack) {
      AppLogger.error("Pending earnings error", error: e, stackTrace: stack);
    }
  }

  Future<void> fetchWalletStatistics(String period) async {
    isLoadingStats.value = true;
    try {
      final response = await _httpService.get(
        ApiConfig.driverWalletStatisticsEndpoint,
        queryParameters: {'period': period},
      );
      final responseData = _httpService.handleResponse(response);
      if (responseData['success'] == true && responseData['data'] != null) {
        walletStats.value = responseData['data'];
      }
    } catch (e, stack) {
      AppLogger.error("Wallet stats fetch error", error: e, stackTrace: stack);
    } finally {
      isLoadingStats.value = false;
    }
  }

  Future<void> fetchTransactions({
    String type = 'all',
    bool loadMore = false,
  }) async {
    if (loadMore) {
      if (!hasNextPage.value || isLoadingTransactions.value) return;
      currentPage.value++;
    } else {
      currentPage.value = 1;
      transactions.clear();
    }
    isLoadingTransactions.value = true;

    try {
      final response = await _httpService.get(
        ApiConfig.driverWalletTransactionsEndpoint,
        queryParameters: {
          'page': currentPage.value.toString(),
          'limit': '20',
          'type': type == 'all' ? '' : type,
        },
      );
      final responseData = _httpService.handleResponse(response);

      if (responseData['status'] == 'success' && responseData['data'] != null) {
        final List<dynamic> txList = responseData['data']['transactions'] ?? [];
        final pagination = responseData['data']['pagination'] ?? {};
        final newTransactions = txList
            .map((tx) => WalletTransaction.fromJson(tx))
            .toList();

        if (loadMore) {
          transactions.addAll(newTransactions);
        } else {
          transactions.assignAll(newTransactions);
        }
        hasNextPage.value = pagination['hasNextPage'] ?? false;
      }
    } catch (e) {
      // THelperFunctions.showErrorSnackBar('Error', 'Could not load transactions');
    } finally {
      isLoadingTransactions.value = false;
    }
  }

  Future<void> fetchWithdrawals() async {
    isLoadingWithdrawals.value = true;
    try {
      final response = await _httpService.get(
        ApiConfig.driverWalletWithdrawalsEndpoint,
      );
      final responseData = _httpService.handleResponse(response);
      if (responseData['success'] == true && responseData['data'] != null) {
        final List<dynamic> wList = responseData['data']['withdrawals'] ?? [];
        withdrawals.assignAll(
          wList.map((w) => WithdrawalRequest.fromJson(w)).toList(),
        );
      }
    } catch (e) {
      print("Withdrawals fetch error: $e");
    } finally {
      isLoadingWithdrawals.value = false;
    }
  }

  Future<bool> initiateWithdrawal(double amount) async {
    isWithdrawing.value = true;
    try {
      final response = await _httpService.post(
        ApiConfig.driverWalletWithdrawEndpoint,
        body: {'amount': amount},
      );

      final responseData = _httpService.handleResponse(response);

      if (responseData['status'] == 'success' ||
          responseData['success'] == true) {
        await fetchAllWalletData(); // Refresh everything
        return true;
      } else {
        THelperFunctions.showErrorSnackBar(
          'Withdrawal Failed',
          responseData['message'] ?? 'Unknown error',
        );
        return false;
      }
    } catch (e) {
      String msg = e is ApiException ? e.message : e.toString();
      THelperFunctions.showErrorSnackBar('Withdrawal Error', msg);
      return false;
    } finally {
      isWithdrawing.value = false;
    }
  }
}
