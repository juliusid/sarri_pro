
import 'package:google_maps_flutter/google_maps_flutter.dart';

class BookPackageRequest {
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

  BookPackageRequest({
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

class BookPackageResponse {
  final String status;
  final String message;
  final String? tripId;
  final String? rideId;
  final String? driverId;
  final double? price;
  final double? distanceKm;
  final int? estimatedArrival;

  BookPackageResponse({
    required this.status,
    required this.message,
    this.tripId,
    this.rideId,
    this.driverId,
    this.price,
    this.distanceKm,
    this.estimatedArrival,
  });

  factory BookPackageResponse.fromJson(Map<String, dynamic> json) {
    return BookPackageResponse(
      status: json['status'],
      message: json['message'],
      tripId: json['data']?['tripId'],
      rideId: json['data']?['rideId'],
      driverId: json['data']?['driverId'],
      price: json['data']?['price']?['$numberDecimal'] != null
          ? double.tryParse(json['data']['price']['$numberDecimal'])
          : null,
      distanceKm: json['data']?['distanceKm'],
      estimatedArrival: json['data']?['estimatedArrival'],
    );
  }
}

class PackageDisputeRequest {
  final String tripId;
  final String reason;

  PackageDisputeRequest({required this.tripId, required this.reason});

  Map<String, dynamic> toJson() => {'tripId': tripId, 'reason': reason};
}

class PackageDisputeResponse {
  final String status;
  final String message;

  PackageDisputeResponse({required this.status, required this.message});

  factory PackageDisputeResponse.fromJson(Map<String, dynamic> json) {
    return PackageDisputeResponse(
      status: json['status'],
      message: json['message'],
    );
  }
}

class PackagePaymentInitRequest {
  final String tripId;
  final String paymentMethod; // card, transfer, cash
  final String? cardId;
  final bool useReferralDiscount;

  PackagePaymentInitRequest({
    required this.tripId,
    required this.paymentMethod,
    this.cardId,
    this.useReferralDiscount = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'tripId': tripId,
      'paymentMethod': paymentMethod,
      if (cardId != null) 'cardId': cardId,
      'useReferralDiscount': useReferralDiscount,
    };
  }
}

class PackagePaymentInitResponse {
  final String status;
  final String? paymentMethod;
  final String? reference;
  final String? accessCode;
  final String? authorizationUrl;
  final String? publicKey;

  PackagePaymentInitResponse({
    required this.status,
    this.paymentMethod,
    this.reference,
    this.accessCode,
    this.authorizationUrl,
    this.publicKey,
  });

  factory PackagePaymentInitResponse.fromJson(Map<String, dynamic> json) {
    return PackagePaymentInitResponse(
      status: json['status'],
      paymentMethod: json['paymentMethod'],
      reference: json['reference'],
      accessCode: json['access_code'],
      authorizationUrl: json['authorization_url'],
      publicKey: json['publicKey'],
    );
  }
}

class PackageDebtStatusResponse {
  final String status;
  final bool hasDebt;
  final double debtAmount;
  final double balance;
  final List<dynamic> cashPayments;

  PackageDebtStatusResponse({
    required this.status,
    required this.hasDebt,
    required this.debtAmount,
    required this.balance,
    required this.cashPayments,
  });

  factory PackageDebtStatusResponse.fromJson(Map<String, dynamic> json) {
    return PackageDebtStatusResponse(
      status: json['status'],
      hasDebt: json['hasDebt'] ?? false,
      debtAmount: (json['debtAmount'] as num?)?.toDouble() ?? 0.0,
      balance: (json['balance'] as num?)?.toDouble() ?? 0.0,
      cashPayments: json['cashPayments'] ?? [],
    );
  }
}
