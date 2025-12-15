import 'package:get/get.dart';
import 'package:sarri_ride/core/services/http_service.dart';
import 'package:sarri_ride/features/authentication/services/auth_service.dart';
import 'package:sarri_ride/features/communication/controllers/call_controller.dart';
import 'package:sarri_ride/features/communication/services/chat_service.dart';

class DependencyInjection {
  static void init() {
    // Services
    Get.put<HttpService>(HttpService(), permanent: true);
    Get.put<AuthService>(AuthService(), permanent: true);
    Get.put<CallController>(CallController(), permanent: true);
    Get.put<ChatService>(ChatService());
  }
}
