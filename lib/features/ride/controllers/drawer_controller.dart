import 'package:get/get.dart';
import 'package:sarri_ride/features/authentication/models/auth_model.dart';
import 'package:sarri_ride/features/authentication/services/auth_service.dart';

class MapDrawerController extends GetxController {
  static MapDrawerController get instance => Get.find();

  final Rx<ClientData?> user = Rx<ClientData?>(null);
  final Rx<RiderProfileData?> fullProfile = Rx<RiderProfileData?>(null);

  final RxString userName = 'Guest'.obs;
  final RxString userEmail = ''.obs;

  @override
  void onInit() {
    super.onInit();
    loadUserData();
    fetchFullProfile();
  }

  Future<void> refreshUserData() async {
    loadUserData();
    await fetchFullProfile();
  }

  void loadUserData() {
    try {
      // 1. Get data from Login memory
      final clientData = Get.find<ClientData>(tag: 'currentUser');
      user.value = clientData;
      userEmail.value = clientData.email;

      // --- FIX: Use local name if available, don't force 'Guest' ---
      if (clientData.firstName.isNotEmpty) {
        userName.value = "${clientData.firstName} ${clientData.lastName}";
      } else {
        userName.value = 'Guest';
      }
    } catch (e) {
      print("Drawer Controller: Could not find local user data.");
      userName.value = "Guest";
      userEmail.value = "Not logged in";
    }
  }

  Future<void> fetchFullProfile() async {
    if (user.value != null && user.value!.role == 'client') {
      try {
        final profile = await AuthService.instance.getRiderProfile();
        if (profile != null) {
          fullProfile.value = profile;
          // Update with the freshest name from API
          userName.value = profile.fullName;
          userEmail.value = profile.email;
        }
      } catch (e) {
        print("Drawer Controller: API fetch failed: $e");
      }
    }
  }
}
