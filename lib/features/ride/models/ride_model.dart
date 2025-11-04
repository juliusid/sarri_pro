// lib/features/ride/models/ride_model.dart

import 'package:google_maps_flutter/google_maps_flutter.dart';

// --- CALCULATE PRICE ---
// (This section remains unchanged as the API doc provided is for booking)

class CalculatePriceRequest {
  final LatLng currentLocation;
  final LatLng destination;

  CalculatePriceRequest({
    required this.currentLocation,
    required this.destination,
  });

  Map<String, dynamic> toJson() => {
    "currentLocation": {
      "latitude": currentLocation.latitude,
      "longitude": currentLocation.longitude,
    },
    "destination": {
      "latitude": destination.latitude,
      "longitude": destination.longitude,
    },
  };
}

class CalculatePriceResponse {
  final String status;
  final String message;
  final PriceData? data;

  CalculatePriceResponse({
    required this.status,
    required this.message,
    this.data,
  });

  factory CalculatePriceResponse.fromJson(Map<String, dynamic> json) {
    return CalculatePriceResponse(
      status: json['status'] ?? 'error',
      message: json['message'] ?? 'Unknown error',
      data: json['data'] != null ? PriceData.fromJson(json['data']) : null,
    );
  }
}

class PriceData {
  final double distanceKm;
  final RidePrices prices;

  PriceData({required this.distanceKm, required this.prices});

  factory PriceData.fromJson(Map<String, dynamic> json) {
    return PriceData(
      distanceKm: (json['distanceKm'] as num?)?.toDouble() ?? 0.0,
      prices: RidePrices.fromJson(json['prices'] ?? {}),
    );
  }
}

class RidePrices {
  final PriceCategory? luxury;
  final PriceCategory? xl;
  final PriceCategory? comfort;

  RidePrices({this.luxury, this.xl, this.comfort});

  factory RidePrices.fromJson(Map<String, dynamic> json) {
    return RidePrices(
      luxury: json['luxury'] != null
          ? PriceCategory.fromJson(json['luxury'])
          : null,
      xl: json['xl'] != null ? PriceCategory.fromJson(json['xl']) : null,
      comfort: json['comfort'] != null
          ? PriceCategory.fromJson(json['comfort'])
          : null,
    );
  }
}

class PriceCategory {
  final int price;
  final int seats;

  PriceCategory({required this.price, required this.seats});

  factory PriceCategory.fromJson(Map<String, dynamic> json) {
    return PriceCategory(
      price: (json['price'] as num?)?.toInt() ?? 0,
      seats: (json['seats'] as num?)?.toInt() ?? 0,
    );
  }
}

// --- BOOK RIDE (MODIFIED) ---

class BookRideRequest {
  final String currentLocationName;
  final String destinationName;
  final LatLng currentLocation;
  final LatLng destination;
  final String category;
  final String state; // --- ADDED ---

  BookRideRequest({
    required this.currentLocationName,
    required this.destinationName,
    required this.currentLocation,
    required this.destination,
    required this.category,
    required this.state, // --- ADDED ---
  });

  Map<String, dynamic> toJson() => {
    "currentLocationName": currentLocationName,
    "destinationName": destinationName,
    "currentLocation": {
      "latitude": currentLocation.latitude,
      "longitude": currentLocation.longitude,
    },
    "destination": {
      "latitude": destination.latitude,
      "longitude": destination.longitude,
    },
    "category": category.toLowerCase(),
    "state": state, // --- ADDED ---
  };
}

class BookRideResponse {
  final String status;
  final String message;
  final BookRideData? data;

  BookRideResponse({required this.status, required this.message, this.data});

  factory BookRideResponse.fromJson(Map<String, dynamic> json) {
    return BookRideResponse(
      status: json['status'] ?? 'error',
      message: json['message'] ?? 'Booking failed',
      data: json['data'] != null ? BookRideData.fromJson(json['data']) : null,
    );
  }
}

class BookRideData {
  final String rideId;
  final int price; // Kept as int, as "16183" is an integer
  final double distanceKm;

  BookRideData({
    required this.rideId,
    required this.price,
    required this.distanceKm,
  });

  factory BookRideData.fromJson(Map<String, dynamic> json) {
    // --- MODIFIED Price Parsing ---
    int parsedPrice = 0;
    if (json['price'] != null &&
        json['price'] is Map &&
        json['price']['\$numberDecimal'] != null) {
      // Parse the string value from "$numberDecimal"
      parsedPrice =
          int.tryParse(json['price']['\$numberDecimal'].toString()) ?? 0;
    } else if (json['price'] is num) {
      // Fallback if it's ever sent as a simple number
      parsedPrice = (json['price'] as num).toInt();
    }
    // --- END MODIFICATION ---

    return BookRideData(
      rideId: json['rideId'] ?? '',
      price: parsedPrice, // Use the parsed price
      distanceKm: (json['distanceKm'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

// --- OTHER MODELS (Unchanged) ---

class CancelRideRequest {
  final String rideId;

  CancelRideRequest({required this.rideId});

  Map<String, dynamic> toJson() => {"rideId": rideId};
}

class CheckRideStatusRequest {
  final String rideId;

  CheckRideStatusRequest({required this.rideId});

  Map<String, dynamic> toJson() => {"rideId": rideId};
}

class CheckRideStatusResponse {
  final String status;
  final String message;
  final RideStatusData? data;

  CheckRideStatusResponse({
    required this.status,
    required this.message,
    this.data,
  });

  factory CheckRideStatusResponse.fromJson(Map<String, dynamic> json) {
    return CheckRideStatusResponse(
      status: json['status'] ?? 'error',
      message: json['message'] ?? 'Failed to get ride status',
      data: json['data'] != null ? RideStatusData.fromJson(json['data']) : null,
    );
  }
}

class RideStatusData {
  final String rideId;
  final String status;
  final RideDriverDetails? driver;
  final String currentLocationName;
  final String destinationName;
  final int price;
  final double distanceKm;
  final String category;

  RideStatusData({
    required this.rideId,
    required this.status,
    this.driver,
    required this.currentLocationName,
    required this.destinationName,
    required this.price,
    required this.distanceKm,
    required this.category,
  });

  factory RideStatusData.fromJson(Map<String, dynamic> json) {
    // --- PARSE PRICE FROM EITHER BSON OR SIMPLE NUMBER ---
    int parsedPrice = 0;
    if (json['price'] != null &&
        json['price'] is Map &&
        json['price']['\$numberDecimal'] != null) {
      parsedPrice =
          int.tryParse(json['price']['\$numberDecimal'].toString()) ?? 0;
    } else if (json['price'] is num) {
      parsedPrice = (json['price'] as num).toInt();
    }
    // --- END PARSE ---

    return RideStatusData(
      rideId: json['rideId'] ?? '',
      status: json['status'] ?? 'unknown',
      driver: json['driver'] != null
          ? RideDriverDetails.fromJson(json['driver'])
          : null,
      currentLocationName: json['currentLocationName'] ?? 'Unknown',
      destinationName: json['destinationName'] ?? 'Unknown',
      price: parsedPrice, // Use parsed price
      distanceKm: (json['distanceKm'] as num?)?.toDouble() ?? 0.0,
      category: json['category'] ?? '',
    );
  }
}

class RideDriverDetails {
  final String id;
  final String firstName;
  final String lastName;
  final RideVehicleDetails vehicleDetails;

  RideDriverDetails({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.vehicleDetails,
  });

  factory RideDriverDetails.fromJson(Map<String, dynamic> json) {
    return RideDriverDetails(
      id: json['_id'] ?? '',
      firstName: json['FirstName'] ?? 'Driver',
      lastName: json['LastName'] ?? '',
      vehicleDetails: RideVehicleDetails.fromJson(json['vehicleDetails'] ?? {}),
    );
  }
}

class RideVehicleDetails {
  final String make;
  final String model;
  final int year;
  final String licensePlate;

  RideVehicleDetails({
    required this.make,
    required this.model,
    required this.year,
    required this.licensePlate,
  });

  factory RideVehicleDetails.fromJson(Map<String, dynamic> json) {
    return RideVehicleDetails(
      make: json['make'] ?? 'Unknown',
      model: json['model'] ?? 'Car',
      year: (json['year'] as num?)?.toInt() ?? 2020,
      licensePlate: json['licensePlate'] ?? 'N/A',
    );
  }
}
