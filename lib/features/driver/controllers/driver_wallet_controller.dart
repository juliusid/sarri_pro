import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:sarri_ride/config/api_config.dart';
import 'package:sarri_ride/core/services/http_service.dart';
import 'package:sarri_ride/core/services/websocket_service.dart';
import 'package:sarri_ride/utils/helpers/helper_functions.dart';

// --- MODELS FOR PARSING API DATA ---

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
  String get formattedTotalEarnings => '₦${totalEarnings.toStringAsFixed(2)}';
  String get formattedPendingEarnings =>
      '₦${pendingEarnings.toStringAsFixed(2)}';
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
      id: json['id'] as String,
      type: json['type'] as String,
      status: json['status'] as String,
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      description: json['description'] as String,
      date: DateTime.tryParse(json['date'] as String? ?? '') ?? DateTime.now(),
    );
  }
}

// --- CONTROLLER ---

class DriverWalletController extends GetxController {
  static DriverWalletController get instance => Get.find();
  final HttpService _httpService = HttpService.instance;
  final WebSocketService _webSocketService = WebSocketService.instance;

  // Wallet Data
  final Rx<WalletBalance?> walletBalance = Rx<WalletBalance?>(null);
  final RxList<WalletTransaction> transactions = <WalletTransaction>[].obs;

  // Statistics (for the charts/cards)
  final RxMap<String, dynamic> walletStats = <String, dynamic>{}.obs;

  // State
  final RxBool isLoadingBalance = true.obs;
  final RxBool isLoadingStats = true.obs;
  final RxBool isLoadingTransactions = true.obs;

  // Pagination
  final RxInt currentPage = 1.obs;
  final RxBool hasNextPage = false.obs;

  @override
  void onInit() {
    super.onInit();
    // Fetch all data when the controller is first initialized
    _webSocketService.registerWalletUpdateListener((data) {
      print("WalletController: Received update, refreshing balance...");
      fetchWalletBalance();
      fetchTransactions();
    });

    _webSocketService.registerPaymentProcessedListener((data) {
      print("WalletController: Payment processed, refreshing balance...");
      fetchWalletBalance();
      fetchTransactions();
    });
    fetchAllWalletData();
  }

  /// Fetches all essential data for the wallet screen in parallel
  Future<void> fetchAllWalletData() async {
    // Reset states
    isLoadingBalance.value = true;
    isLoadingStats.value = true;
    isLoadingTransactions.value = true;
    currentPage.value = 1;
    transactions.clear();

    try {
      // Run all fetches at the same time
      await Future.wait([
        fetchWalletBalance(),
        fetchWalletStatistics('month'), // Default to 'month'
        fetchTransactions(), // Fetch first page
      ]);
    } catch (e) {
      print("Error fetching all wallet data: $e");
    }
  }

  /// 1. Fetches the main wallet balance
  Future<void> fetchWalletBalance() async {
    try {
      final response = await _httpService.get(
        ApiConfig.driverWalletBalanceEndpoint,
      );
      final responseData = _httpService.handleResponse(response);

      if (responseData['success'] == true && responseData['data'] != null) {
        walletBalance.value = WalletBalance.fromJson(responseData['data']);
      } else {
        throw Exception(
          responseData['message'] ?? 'Failed to load wallet balance',
        );
      }
    } catch (e) {
      String msg = e is ApiException ? e.message : e.toString();
      THelperFunctions.showErrorSnackBar(
        'Error',
        'Could not load balance: $msg',
      );
    } finally {
      isLoadingBalance.value = false;
    }
  }

  /// 2. Fetches wallet statistics for a given period
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
      } else {
        throw Exception(responseData['message'] ?? 'Failed to load statistics');
      }
    } catch (e) {
      String msg = e is ApiException ? e.message : e.toString();
      THelperFunctions.showErrorSnackBar('Error', 'Could not load stats: $msg');
    } finally {
      isLoadingStats.value = false;
    }
  }

  /// 3. Fetches paginated transaction history
  Future<void> fetchTransactions({
    String type = 'all',
    bool loadMore = false,
  }) async {
    if (loadMore) {
      if (!hasNextPage.value || isLoadingTransactions.value) return;
      currentPage.value++;
    } else {
      // This is a new fetch or refresh
      currentPage.value = 1;
      transactions.clear();
    }

    isLoadingTransactions.value = true;

    try {
      final Map<String, dynamic> queryParams = {
        'page': currentPage.value.toString(),
        'limit': '20',
        'type': type == 'all' ? '' : type,
      };

      final response = await _httpService.get(
        ApiConfig.driverWalletTransactionsEndpoint,
        queryParameters: queryParams,
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
      } else {
        throw Exception(
          responseData['message'] ?? 'Failed to load transactions',
        );
      }
    } catch (e) {
      String msg = e is ApiException ? e.message : e.toString();
      THelperFunctions.showErrorSnackBar(
        'Error',
        'Could not load transactions: $msg',
      );
    } finally {
      isLoadingTransactions.value = false;
    }
  }
}
