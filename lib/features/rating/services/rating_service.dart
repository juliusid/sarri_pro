import 'package:get/get.dart';
import 'package:sarri_ride/config/api_config.dart';
import 'package:sarri_ride/core/services/http_service.dart';

class RatingService extends GetxService {
  static RatingService get instance => Get.find();
  final HttpService _httpService = HttpService.instance;

  // 1. Rate Driver (POST)
  Future<bool> rateDriver({
    required String tripId,
    required double rating,
    String review = '',
    List<String> tags = const [],
  }) async {
    try {
      final body = {
        'tripId': tripId,
        'rating': rating, // Number
        'review': review,
        'tags': tags,
      };

      final response = await _httpService.post(
        ApiConfig.rateDriverEndpoint,
        body: body,
      );
      final responseData = _httpService.handleResponse(response);
      return responseData['status'] == 'success' ||
          responseData['success'] == true;
    } catch (e) {
      print("RatingService Error (Rate): $e");
      return false;
    }
  }

  // 6. Get My Driver Ratings (GET)
  Future<Map<String, dynamic>?> getDriverRatings({
    int page = 1,
    int limit = 10,
  }) async {
    try {
      final response = await _httpService.get(
        ApiConfig.driverRatingsEndpoint,
        queryParameters: {'page': '$page', 'limit': '$limit'},
      );
      final responseData = _httpService.handleResponse(response);

      if (responseData['success'] == true && responseData['data'] != null) {
        return responseData['data'];
      }
      return null;
    } catch (e) {
      print("RatingService Error (Get Driver Ratings): $e");
      return null;
    }
  }
}
