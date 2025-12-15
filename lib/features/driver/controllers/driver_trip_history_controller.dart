import 'package:get/get.dart';
import 'package:sarri_ride/config/api_config.dart';
import 'package:sarri_ride/core/services/http_service.dart';
import 'package:sarri_ride/utils/helpers/helper_functions.dart';

class DriverTripHistoryController extends GetxController {
  static DriverTripHistoryController get instance => Get.find();
  final HttpService _httpService = HttpService.instance;

  // DATA
  final RxList<dynamic> trips = <dynamic>[].obs;
  final RxMap<String, dynamic> summary = <String, dynamic>{}.obs;
  final RxMap<String, dynamic> ratings = <String, dynamic>{}.obs;
  final RxMap<String, dynamic> timePeriods = <String, dynamic>{}.obs;

  // STATE
  final RxBool isLoading = true.obs;
  final RxBool isLoadingMore = false.obs;

  // FILTERS
  final RxString periodFilter = 'all'.obs;
  final RxString statusFilter = 'all'.obs;
  // Add other filters as needed (paymentMethod, dates, etc.)

  // PAGINATION
  final RxInt currentPage = 1.obs;
  final RxBool hasNextPage = false.obs;

  @override
  void onInit() {
    super.onInit();
    // Fetch initial data when controller is loaded
    setFiltersAndFetch(status: 'all');
  }

  /// Resets filters and page, then fetches new data
  void setFiltersAndFetch({String? period, String? status}) {
    // Update filters if provided
    if (period != null) periodFilter.value = period;
    if (status != null) statusFilter.value = status;

    // Reset pagination
    currentPage.value = 1;

    // Clear old data and fetch
    trips.clear();
    fetchTripHistory(isRefresh: true);
  }

  /// Fetches trip history from the API
  Future<void> fetchTripHistory({bool isRefresh = false}) async {
    // Set loading state
    if (isRefresh) {
      isLoading.value = true;
    } else {
      isLoadingMore.value = true;
    }

    try {
      // 1. Build Query Parameters
      final Map<String, dynamic> queryParams = {
        'page': currentPage.value.toString(),
        'limit': '10', // Or your desired page size
        'period': periodFilter.value,
        'status': statusFilter.value,
        'sortBy': 'bookedAt',
        'sortOrder': 'desc',
      };

      // Add custom dates if period is 'custom'
      // if (periodFilter.value == 'custom') {
      //   queryParams['startDate'] = '...';
      //   queryParams['endDate'] = '...';
      // }

      // 2. Call API
      final response = await _httpService.get(
        ApiConfig.driverTripHistoryEndpoint,
        queryParameters: queryParams,
      );
      final responseData = _httpService.handleResponse(response);

      // 3. Parse Data
      if (responseData['status'] == 'success' && responseData['data'] != null) {
        final data = responseData['data'];

        // Parse trips
        List<dynamic> fetchedTrips = data['trips'] as List? ?? [];
        if (isRefresh) {
          trips.assignAll(fetchedTrips);
        } else {
          trips.addAll(fetchedTrips); // Append for 'load more'
        }

        // Parse summary stats
        summary.value = data['summary'] as Map<String, dynamic>? ?? {};
        ratings.value = data['ratings'] as Map<String, dynamic>? ?? {};
        timePeriods.value = data['timePeriods'] as Map<String, dynamic>? ?? {};

        // Parse pagination
        final pagination = data['pagination'] as Map<String, dynamic>? ?? {};
        hasNextPage.value = pagination['hasNextPage'] as bool? ?? false;
      } else {
        throw Exception(
          responseData['message'] ?? 'Failed to load trip history',
        );
      }
    } catch (e) {
      String errorMsg = e is ApiException ? e.message : e.toString();
      THelperFunctions.showErrorSnackBar('Error', errorMsg);
    } finally {
      // 4. Reset loading state
      isLoading.value = false;
      isLoadingMore.value = false;
    }
  }

  /// Loads the next page of results
  void loadMore() {
    if (hasNextPage.value && !isLoading.value && !isLoadingMore.value) {
      currentPage.value++;
      fetchTripHistory(isRefresh: false);
    }
  }
}
