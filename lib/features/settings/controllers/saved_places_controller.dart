import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/saved_place.dart';
import '../../location/services/places_service.dart';
import '../../../utils/helpers/helper_functions.dart';

class SavedPlacesController extends GetxController {
  static const _storageKey = 'saved_places';
  final RxList<SavedPlace> savedPlaces = <SavedPlace>[].obs;
  final RxList<PlaceSuggestion> placeSuggestions = <PlaceSuggestion>[].obs;
  final RxBool isSearching = false.obs;
  final RxBool isLoadingPlaceDetails = false.obs;
  
  // Text controllers for the add place form
  final TextEditingController labelController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  
  // Selected place details
  final Rx<PlaceDetails?> selectedPlace = Rx<PlaceDetails?>(null);

  @override
  void onInit() {
    super.onInit();
    _initializeAsync();
  }
  
  Future<void> _initializeAsync() async {
    // Wait for next frame to ensure GetStorage is ready
    await Future.delayed(Duration.zero);
    _loadPlaces();
  }

  @override
  void onClose() {
    labelController.dispose();
    addressController.dispose();
    super.onClose();
  }

  void _loadPlaces() {
    try {
      final storage = GetStorage();
      final data = storage.read<List<dynamic>>(_storageKey) ?? [];
      savedPlaces.value = data.map((e) => SavedPlace.fromJson(Map<String, dynamic>.from(e))).toList();
    } catch (e) {
      print('Error loading saved places: $e');
      savedPlaces.value = [];
    }
  }

  void _persist() {
    final jsonList = savedPlaces.map((e) => e.toJson()).toList();
    GetStorage().write(_storageKey, jsonList);
  }

  // Search for places using Google Places autocomplete
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
      THelperFunctions.showSnackBar('Error searching places: $e');
      placeSuggestions.clear();
    } finally {
      isSearching.value = false;
    }
  }

  // Get place details with coordinates
  Future<void> selectPlace(PlaceSuggestion suggestion) async {
    isLoadingPlaceDetails.value = true;
    
    try {
      final details = await PlacesService.getPlaceDetails(suggestion.placeId);
      if (details != null) {
        selectedPlace.value = details;
        addressController.text = details.formattedAddress;
        
        // Auto-fill label if it's empty
        if (labelController.text.isEmpty) {
          labelController.text = details.name.isNotEmpty ? details.name : suggestion.mainText;
        }
      } else {
        THelperFunctions.showSnackBar('Could not get place details');
      }
    } catch (e) {
      THelperFunctions.showSnackBar('Error getting place details: $e');
    } finally {
      isLoadingPlaceDetails.value = false;
    }
  }

  // Add a new saved place
  void addPlace() {
    final label = labelController.text.trim();
    final address = addressController.text.trim();
    final placeDetails = selectedPlace.value;
    
    if (label.isEmpty) {
      THelperFunctions.showSnackBar('Please enter a label for this place');
      return;
    }
    
    if (address.isEmpty || placeDetails == null) {
      THelperFunctions.showSnackBar('Please select a valid address');
      return;
    }
    
    // Check if place with same label already exists
    if (savedPlaces.any((place) => place.label.toLowerCase() == label.toLowerCase())) {
      THelperFunctions.showSnackBar('A place with this label already exists');
      return;
    }
    
    final newPlace = SavedPlace(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      label: label,
      address: address,
      lat: placeDetails.location.latitude,
      lng: placeDetails.location.longitude,
    );
    
    savedPlaces.add(newPlace);
    _persist();
    
    // Clear form
    _clearForm();
    
    THelperFunctions.showSnackBar('Place saved successfully!');
  }

  // Update an existing saved place
  void updatePlace(String id) {
    final label = labelController.text.trim();
    final address = addressController.text.trim();
    final placeDetails = selectedPlace.value;
    
    if (label.isEmpty) {
      THelperFunctions.showSnackBar('Please enter a label for this place');
      return;
    }
    
    if (address.isEmpty || placeDetails == null) {
      THelperFunctions.showSnackBar('Please select a valid address');
      return;
    }
    
    final index = savedPlaces.indexWhere((place) => place.id == id);
    if (index != -1) {
      // Check if another place with same label exists (excluding current place)
      if (savedPlaces.any((place) => 
          place.id != id && place.label.toLowerCase() == label.toLowerCase())) {
        THelperFunctions.showSnackBar('A place with this label already exists');
        return;
      }
      
      final updatedPlace = SavedPlace(
        id: id,
        label: label,
        address: address,
        lat: placeDetails.location.latitude,
        lng: placeDetails.location.longitude,
      );
      
      savedPlaces[index] = updatedPlace;
      _persist();
      
      // Clear form
      _clearForm();
      
      THelperFunctions.showSnackBar('Place updated successfully!');
    }
  }

  // Delete a saved place
  void deletePlace(String id) {
    savedPlaces.removeWhere((p) => p.id == id);
    _persist();
    THelperFunctions.showSnackBar('Place deleted successfully');
  }

  // Load place data for editing
  void loadPlaceForEditing(SavedPlace place) {
    labelController.text = place.label;
    addressController.text = place.address;
    selectedPlace.value = PlaceDetails(
      name: place.label,
      formattedAddress: place.address,
      location: LatLng(place.lat, place.lng),
    );
  }

  // Clear the form
  void _clearForm() {
    labelController.clear();
    addressController.clear();
    selectedPlace.value = null;
    placeSuggestions.clear();
  }

  // Clear search results
  void clearSearch() {
    placeSuggestions.clear();
    isSearching.value = false;
  }

  // Get saved place by coordinates (useful for reverse lookup)
  SavedPlace? getPlaceByCoordinates(double lat, double lng, {double tolerance = 0.001}) {
    return savedPlaces.firstWhereOrNull((place) => 
        (place.lat - lat).abs() < tolerance && 
        (place.lng - lng).abs() < tolerance);
  }

  // Get saved places by label (useful for quick access)
  List<SavedPlace> searchSavedPlaces(String query) {
    if (query.isEmpty) return savedPlaces.toList();
    
    return savedPlaces.where((place) => 
        place.label.toLowerCase().contains(query.toLowerCase()) ||
        place.address.toLowerCase().contains(query.toLowerCase())).toList();
  }
} 