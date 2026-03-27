
import 'package:google_maps_flutter/google_maps_flutter.dart';

class PackageBookingRequest {
  final String currentLocationName;
  final String destinationName;
  final LatLng currentLocation;
  final LatLng destination;
  final String category;
  final String state;
  final String packageType;
  final double weightKg;
  final String specialInstructions;
  final String receiverName;
  final String receiverPhoneNumber;

  PackageBookingRequest({
    required this.currentLocationName,
    required this.destinationName,
    required this.currentLocation,
    required this.destination,
    required this.category,
    required this.state,
    required this.packageType,
    required this.weightKg,
    required this.specialInstructions,
    required this.receiverName,
    required this.receiverPhoneNumber,
  });

  Map<String, dynamic> toJson() {
    return {
      'currentLocationName': currentLocationName,
      'destinationName': destinationName,
      'currentLocation': {
        'latitude': currentLocation.latitude,
        'longitude': currentLocation.longitude,
      },
      'destination': {
        'latitude': destination.latitude,
        'longitude': destination.longitude,
      },
      'category': category,
      'state': state,
      'packageType': packageType,
      'weightKg': weightKg,
      'specialInstructions': specialInstructions,
      'ReceiverName': receiverName,
      'ReceiverPhoneNumber': receiverPhoneNumber,
    };
  }
}

class PackageBookingResponse {
  final String tripId;
  final String rideId;
  final String driverId;
  final double price;
  final double distanceKm;
  final int estimatedArrival;

  PackageBookingResponse({
    required this.tripId,
    required this.rideId,
    required this.driverId,
    required this.price,
    required this.distanceKm,
    required this.estimatedArrival,
  });

  factory PackageBookingResponse.fromJson(Map<String, dynamic> json) {
    return PackageBookingResponse(
      tripId: json['data']['tripId'],
      rideId: json['data']['rideId'],
      driverId: json['data']['driverId'],
      price: double.parse(json['data']['price']['$numberDecimal']),
      distanceKm: (json['data']['distanceKm'] as num).toDouble(),
      estimatedArrival: json['data']['estimatedArrival'],
    );
  }
}

class RideRequestEvent {
  final String tripId;
  final String pickupCode;
  final String riderId;
  final String rideId;
  final String riderName;
  final double price;
  final double distanceKm;
  final String currentLocationName;
  final String destinationName;
  final String specialInstructions;
  final String receiverName;
  final String receiverPhoneNumber;
  final LatLng pickupLocation;
  final LatLng dropoffLocation;
  final String category;
  final double weightKg;
  final String packageType;
  final int expiresAt;

  RideRequestEvent({
    required this.tripId,
    required this.pickupCode,
    required this.riderId,
    required this.rideId,
    required this.riderName,
    required this.price,
    required this.distanceKm,
    required this.currentLocationName,
    required this.destinationName,
    required this.specialInstructions,
    required this.receiverName,
    required this.receiverPhoneNumber,
    required this.pickupLocation,
    required this.dropoffLocation,
    required this.category,
    required this.weightKg,
    required this.packageType,
    required this.expiresAt,
  });

  factory RideRequestEvent.fromJson(Map<String, dynamic> json) {
    return RideRequestEvent(
      tripId: json['tripId'],
      pickupCode: json['pickupCode'],
      riderId: json['riderId'],
      rideId: json['rideId'],
      riderName: json['riderName'],
      price: (json['price'] as num).toDouble(),
      distanceKm: (json['distanceKm'] as num).toDouble(),
      currentLocationName: json['currentLocationName'],
      destinationName: json['destinationName'],
      specialInstructions: json['specialInstructions'],
      receiverName: json['ReceiverName'],
      receiverPhoneNumber: json['ReceiverPhoneNumber'],
      pickupLocation: LatLng(
        json['pickupLocation']['latitude'],
        json['pickupLocation']['longitude'],
      ),
      dropoffLocation: LatLng(
        json['dropoffLocation']['latitude'],
        json['dropoffLocation']['longitude'],
      ),
      category: json['category'],
      weightKg: (json['weightKg'] as num).toDouble(),
      packageType: json['packageType'],
      expiresAt: json['expiresAt'],
    );
  }
}

class RideSearchingEvent {
    final String tripId;
    final String? driverId;
    final String? driverName;
    final int? estimatedArrival;
    final String status;

    RideSearchingEvent({
        required this.tripId,
        this.driverId,
        this.driverName,
        this.estimatedArrival,
        required this.status,
    });

    factory RideSearchingEvent.fromJson(Map<String, dynamic> json) {
        return RideSearchingEvent(
            tripId: json['tripId'],
            driverId: json['driverId'],
            driverName: json['driverName'],
            estimatedArrival: json['estimatedArrival'],
            status: json['status'],
        );
    }
}
