import 'package:get/get.dart';
import 'package:sarri_ride/features/authentication/models/auth_model.dart';

class MapDrawerController extends GetxController {
  static MapDrawerController get instance => Get.find();

  // This will hold the user data when it's available
  final Rx<ClientData?> user = Rx<ClientData?>(null);

  // You can expand this later to hold the full user profile
  final RxString userName = 'Sarri Rider'.obs; // Placeholder name for now
  final RxString userEmail = ''.obs;

  @override
  void onInit() {
    super.onInit();
    loadUserData();
  }

  /// Fetches the logged-in user's data from memory.
  void loadUserData() {
    try {
      // The LoginController stores the ClientData with this tag after a successful login.
      final clientData = Get.find<ClientData>(tag: 'currentUser');
      user.value = clientData;

      // Update the observables with the user's email.
      // NOTE: The login response doesn't include the user's name, so we'll use a placeholder.
      userEmail.value = clientData.email;
    } catch (e) {
      // This will happen if no user is logged in, so we provide default values.
      print("Drawer Controller: Could not find user data. Using defaults.");
      userName.value = "Guest";
      userEmail.value = "Not logged in";
    }
  }
}
