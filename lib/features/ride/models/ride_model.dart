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
  final Map<String, PriceCategory> prices;

  PriceData({required this.distanceKm, required this.prices});

  factory PriceData.fromJson(Map<String, dynamic> json) {
    Map<String, PriceCategory> parsedPrices = {};
    if (json['prices'] != null) {
      (json['prices'] as Map<String, dynamic>).forEach((key, value) {
        if (value != null) {
          parsedPrices[key] = PriceCategory.fromJson(value);
        }
      });
    }

    return PriceData(
      distanceKm: (json['distanceKm'] as num?)?.toDouble() ?? 0.0,
      prices: parsedPrices,
    );
  }
}

class PriceCategory {
  final int price;
  final int? originalPrice;
  final int seats;
  final bool isActive;

  PriceCategory({
    required this.price,
    this.originalPrice,
    required this.seats,
    this.isActive = true,
  });

  factory PriceCategory.fromJson(Map<String, dynamic> json) {
    return PriceCategory(
      price: (json['price'] as num?)?.toInt() ?? 0,
      originalPrice: (json['originalPrice'] as num?)?.toInt(),
      seats: (json['seats'] as num?)?.toInt() ?? 0,
      isActive: json['isActive'] ?? true,
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
      rideId: json['tripId'] ?? '',
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
  final String? phoneNumber;
  final double rating;
  final String? profileImage;
  final RideVehicleDetails vehicleDetails;

  RideDriverDetails({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.phoneNumber,
    required this.rating,
    this.profileImage,
    required this.vehicleDetails,
  });

  factory RideDriverDetails.fromJson(Map<String, dynamic> json) {
    String parsedFirstName = json['FirstName'] ?? json['firstName'] ?? json['name'] ?? 'Driver';
    String parsedLastName = json['LastName'] ?? json['lastName'] ?? '';
    
    // Sometimes the backend sends full name in `name`
    if (json['name'] != null && json['FirstName'] == null && json['firstName'] == null) {
       final parts = json['name'].toString().split(' ');
       parsedFirstName = parts.first;
       if (parts.length > 1) {
         parsedLastName = parts.sublist(1).join(' ');
       }
    }

    return RideDriverDetails(
      id: json['_id'] ?? json['id'] ?? '',
      firstName: parsedFirstName,
      lastName: parsedLastName,
      phoneNumber: json['PhoneNumber'] ?? json['phone'] ?? json['phoneNumber'],
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      profileImage: json['picture'] ?? json['profileImage'],
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

/// A generic response wrapper for the reconnect API.
class ReconnectResponse {
  final String status;
  final String message;
  final Map<String, dynamic>? data; // Raw data
  final String? userRole; // 'driver' or 'client'

  ReconnectResponse({
    required this.status,
    required this.message,
    this.data,
    this.userRole,
  });

  factory ReconnectResponse.fromJson(Map<String, dynamic> json, String role) {
    return ReconnectResponse(
      status: json['status'] ?? 'error',
      message: json['message'] ?? 'Failed to reconnect',
      data: json['data'] as Map<String, dynamic>?,
      userRole: role,
    );
  }
}

/// Typed data for a DRIVER reconnecting.
class DriverReconnectData {
  final String tripId;
  final String status;
  final String chatId;
  final String category;
  final String pickup;
  final String destination;
  final double distance;
  final double price;
  final int seats;
  final String riderId;
  final String riderName;
  final String riderPhone;
  final double riderRating;
  final String? riderPicture;
  final String? paymentStatus; // e.g. "pending" | "completed"
  final String? paymentMethod; // e.g. "cash" | "card" | "transfer"
  final double? cashAmount; // Store expected cash amount

  DriverReconnectData({
    required this.tripId,
    required this.status,
    required this.chatId,
    required this.category,
    required this.pickup,
    required this.destination,
    required this.distance,
    required this.price,
    required this.seats,
    required this.riderId,
    required this.riderName,
    required this.riderPhone,
    required this.riderRating,
    this.riderPicture,
    this.paymentStatus,
    this.paymentMethod,
    this.cashAmount,
  });

  factory DriverReconnectData.fromJson(Map<String, dynamic> json) {
    double parsedPrice = 0.0;
    if (json['price'] != null && json['price']['\$numberDecimal'] != null) {
      parsedPrice =
          double.tryParse(json['price']['\$numberDecimal'].toString()) ?? 0.0;
    } else if (json['price'] is num) {
      parsedPrice = (json['price'] as num).toDouble();
    }

    return DriverReconnectData(
      tripId: json['tripId'] ?? '',
      status: json['status'] ?? 'unknown',
      chatId: json['chatId'] ?? '',
      category: json['category'] ?? 'unknown',
      pickup: json['pickup'] ?? 'Unknown',
      destination: json['destination'] ?? 'Unknown',
      distance: (json['distance'] as num?)?.toDouble() ?? 0.0,
      price: parsedPrice,
      seats: (json['seats'] as num?)?.toInt() ?? 4,
      riderId: json['rider']?['_id'] ?? json['rider']?['id'] ?? '',
      riderName: json['rider']?['name'] ?? json['rider']?['firstName'] ?? json['rider']?['FirstName'] ?? 'Rider',
      riderPhone: json['rider']?['phoneNumber'] ?? json['rider']?['phone'] ?? '',
      riderRating: (json['rider']?['rating'] as num?)?.toDouble() ?? 0.0,
      riderPicture: json['rider']?['picture'] ?? json['rider']?['profileImage'],
      paymentStatus: json['paymentStatus'] as String?,
      paymentMethod: json['paymentMethod'] as String?,
      cashAmount: (json['cashAmount'] as num?)?.toDouble() ??
          (json['amount'] as num?)?.toDouble(),
    );
  }
}

/// Typed data for a RIDER reconnecting.
class RiderReconnectData {
  final String tripId;
  final String status;
  final String? chatId; // ChatId is not in the 'pending' response
  final String category;
  final String pickup;
  final String destination;
  final double distance;
  final double price;
  final int seats;
  final RideDriverDetails? driver; // Driver is not in 'pending' response
  // Optional fields returned by the reconnect API (used to restore payment UI correctly).
  final String? paymentStatus; // e.g. "pending" | "completed"
  final String? paymentMethod; // e.g. "cash" | "card" | "transfer"
  final double? cashAmount; // When payment is pending via cash (if provided)

  RiderReconnectData({
    required this.tripId,
    required this.status,
    this.chatId,
    required this.category,
    required this.pickup,
    required this.destination,
    required this.distance,
    required this.price,
    required this.seats,
    this.driver,
    this.paymentStatus,
    this.paymentMethod,
    this.cashAmount,
  });

  factory RiderReconnectData.fromJson(Map<String, dynamic> json) {
    double parsedPrice = 0.0;
    if (json['price'] != null && json['price']['\$numberDecimal'] != null) {
      parsedPrice =
          double.tryParse(json['price']['\$numberDecimal'].toString()) ?? 0.0;
    } else if (json['price'] is num) {
      parsedPrice = (json['price'] as num).toDouble();
    }

    return RiderReconnectData(
      tripId: json['tripId'] ?? '',
      status: json['status'] ?? 'unknown',
      chatId: json['chatId'], // Will be null if pending
      category: json['category'] ?? 'unknown',
      pickup: json['pickup'] ?? 'Unknown',
      destination: json['destination'] ?? 'Unknown',
      distance: (json['distance'] as num?)?.toDouble() ?? 0.0,
      price: parsedPrice,
      seats: (json['seats'] as num?)?.toInt() ?? 4,
      driver: json['driver'] != null
          ? RideDriverDetails.fromJson(json['driver'])
          : null,
      paymentStatus: json['paymentStatus'] as String?,
      paymentMethod: json['paymentMethod'] as String?,
      cashAmount: (json['cashAmount'] as num?)?.toDouble() ??
          (json['amount'] as num?)?.toDouble(),
    );
  }
}
