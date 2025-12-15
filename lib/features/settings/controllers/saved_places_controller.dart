import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:sarri_ride/features/settings/models/saved_place.dart';
import 'package:sarri_ride/features/settings/services/saved_places_service.dart';
import 'package:sarri_ride/features/location/services/places_service.dart';
import 'package:sarri_ride/utils/helpers/helper_functions.dart';

class SavedPlacesController extends GetxController {
  final SavedPlacesService _service = Get.put(SavedPlacesService());

  final RxList<SavedPlace> savedPlaces = <SavedPlace>[].obs;
  final RxList<PlaceSuggestion> placeSuggestions = <PlaceSuggestion>[].obs;
  final RxBool isSearching = false.obs;
  final RxBool isLoading = false.obs;
  final RxBool isLoadingPlaceDetails = false.obs;

  final TextEditingController labelController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final Rx<PlaceDetails?> selectedPlace = Rx<PlaceDetails?>(null);

  // Backend allowed labels
  final List<String> _allowedLabels = [
    'home',
    'work',
    'gym',
    'airport',
    'school',
    'mall',
    'other',
  ];

  @override
  void onInit() {
    super.onInit();
    fetchSavedPlaces();
  }

  @override
  void onClose() {
    labelController.dispose();
    addressController.dispose();
    super.onClose();
  }

  Future<void> fetchSavedPlaces() async {
    isLoading.value = true;
    try {
      final places = await _service.getAllPlaces();
      savedPlaces.assignAll(places);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> searchPlaces(String query) async {
    if (query.length < 3) {
      placeSuggestions.clear();
      return;
    }
    isSearching.value = true;
    try {
      final suggestions = await PlacesService.getPlaceSuggestions(query);
      placeSuggestions.assignAll(suggestions);
    } catch (e) {
      placeSuggestions.clear();
    } finally {
      isSearching.value = false;
    }
  }

  Future<void> selectPlace(PlaceSuggestion suggestion) async {
    isLoadingPlaceDetails.value = true;
    try {
      final details = await PlacesService.getPlaceDetails(suggestion.placeId);
      if (details != null) {
        selectedPlace.value = details;
        addressController.text = details.formattedAddress;
      }
    } finally {
      isLoadingPlaceDetails.value = false;
    }
  }

  Future<void> addPlace() async {
    final labelInput = labelController.text.trim();
    final address = addressController.text.trim();
    final placeDetails = selectedPlace.value;

    if (labelInput.isEmpty) {
      THelperFunctions.showSnackBar('Please enter a label');
      return;
    }

    if (address.isEmpty || placeDetails == null) {
      THelperFunctions.showSnackBar('Please select a valid address');
      return;
    }

    // --- LABEL LOGIC ---
    String apiLabel = labelInput.toLowerCase();
    String? customName;

    if (!_allowedLabels.contains(apiLabel)) {
      // If user typed something custom (e.g. "Mom's House"),
      // send label="other" and customName="Mom's House"
      customName = labelInput;
      apiLabel = 'other';
    }

    isLoading.value = true;

    String city = '';
    String state = '';
    String country = 'Nigeria';

    // Extract address components
    for (var component in placeDetails.addressComponents) {
      final types = List<String>.from(component['types'] ?? []);
      if (types.contains('locality')) city = component['long_name'];
      if (types.contains('administrative_area_level_1'))
        state = component['long_name'];
      if (types.contains('country')) country = component['long_name'];
    }

    final success = await _service.savePlace(
      label: apiLabel,
      address: address,
      lat: placeDetails.location.latitude,
      lng: placeDetails.location.longitude,
      city: city,
      state: state,
      country: country,
      customName: customName,
    );

    isLoading.value = false;

    if (success) {
      // Don't show snackbar here, letting UI handle it if needed,
      // BUT since your UI code calls this and then shows success,
      // ensure we return true/void correctly.
      // The UI code you showed earlier handles the snackbar after await.
      _clearForm();
      await fetchSavedPlaces(); // Refresh list
    } else {
      // If service returns false, we should throw or show error
      THelperFunctions.showErrorSnackBar('Error', 'Failed to save place.');
      throw Exception('Save failed'); // Stop UI from showing success
    }
  }

  Future<void> updatePlace(String id) async {
    final labelInput = labelController.text.trim();
    final placeDetails = selectedPlace.value;

    Map<String, dynamic> updateData = {};

    if (placeDetails != null) {
      updateData['address'] = placeDetails.formattedAddress;
      updateData['coordinates'] = [
        placeDetails.location.longitude,
        placeDetails.location.latitude,
      ];
    }

    String apiLabel = labelInput.toLowerCase();
    if (!_allowedLabels.contains(apiLabel)) {
      updateData['label'] = 'other';
      updateData['customName'] = labelInput;
    } else {
      updateData['label'] = apiLabel;
    }

    isLoading.value = true;
    final success = await _service.updatePlace(id, updateData);
    isLoading.value = false;

    if (success) {
      _clearForm();
      await fetchSavedPlaces();
    } else {
      THelperFunctions.showErrorSnackBar('Error', 'Failed to update place.');
      throw Exception('Update failed');
    }
  }

  Future<void> deletePlace(String id) async {
    final success = await _service.deletePlace(id);
    if (success) {
      savedPlaces.removeWhere((p) => p.id == id);
      THelperFunctions.showSnackBar('Place deleted.');
    } else {
      THelperFunctions.showErrorSnackBar('Error', 'Failed to delete place.');
    }
  }

  void loadPlaceForEditing(SavedPlace place) {
    labelController.text = place.label == 'other'
        ? place.displayName
        : place.label.capitalizeFirst!;
    addressController.text = place.address;

    selectedPlace.value = PlaceDetails(
      name: place.displayName,
      formattedAddress: place.address,
      location: LatLng(place.lat, place.lng),
    );
  }

  void _clearForm() {
    labelController.clear();
    addressController.clear();
    selectedPlace.value = null;
    placeSuggestions.clear();
  }

  void clearSearch() {
    placeSuggestions.clear();
    isSearching.value = false;
  }
}
