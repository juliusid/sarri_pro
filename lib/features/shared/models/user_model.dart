import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:sarri_ride/utils/constants/enums.dart';

class User {
  final String id;
  final String email;
  final String firstName;
  final String lastName;
  final String? phoneNumber;
  final UserType userType;
  final DateTime createdAt;
  final DateTime updatedAt;
  final RiderProfile? riderProfile;
  final DriverProfile? driverProfile;

  User({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    this.phoneNumber,
    required this.userType,
    required this.createdAt,
    required this.updatedAt,
    this.riderProfile,
    this.driverProfile,
  });

  String get fullName => '$firstName $lastName';

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'firstName': firstName,
      'lastName': lastName,
      'phoneNumber': phoneNumber,
      'userType': userType.toString(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'riderProfile': riderProfile?.toJson(),
      'driverProfile': driverProfile?.toJson(),
    };
  }

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      email: json['email'],
      firstName: json['firstName'],
      lastName: json['lastName'],
      phoneNumber: json['phoneNumber'],
      userType: UserType.values.firstWhere(
        (e) => e.toString() == json['userType'],
        orElse: () => UserType.rider,
      ),
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      riderProfile: json['riderProfile'] != null 
          ? RiderProfile.fromJson(json['riderProfile']) 
          : null,
      driverProfile: json['driverProfile'] != null 
          ? DriverProfile.fromJson(json['driverProfile']) 
          : null,
    );
  }

  User copyWith({
    String? id,
    String? email,
    String? firstName,
    String? lastName,
    String? phoneNumber,
    UserType? userType,
    DateTime? createdAt,
    DateTime? updatedAt,
    RiderProfile? riderProfile,
    DriverProfile? driverProfile,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      userType: userType ?? this.userType,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      riderProfile: riderProfile ?? this.riderProfile,
      driverProfile: driverProfile ?? this.driverProfile,
    );
  }
}

class RiderProfile {
  final String userId;
  final double rating;
  final int totalTrips;
  final List<String> savedPlaces;
  final String? emergencyContact;
  final Map<String, dynamic>? preferences;

  RiderProfile({
    required this.userId,
    this.rating = 5.0,
    this.totalTrips = 0,
    this.savedPlaces = const [],
    this.emergencyContact,
    this.preferences,
  });

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'rating': rating,
      'totalTrips': totalTrips,
      'savedPlaces': savedPlaces,
      'emergencyContact': emergencyContact,
      'preferences': preferences,
    };
  }

  factory RiderProfile.fromJson(Map<String, dynamic> json) {
    return RiderProfile(
      userId: json['userId'],
      rating: json['rating']?.toDouble() ?? 5.0,
      totalTrips: json['totalTrips'] ?? 0,
      savedPlaces: List<String>.from(json['savedPlaces'] ?? []),
      emergencyContact: json['emergencyContact'],
      preferences: json['preferences'],
    );
  }

  RiderProfile copyWith({
    String? userId,
    double? rating,
    int? totalTrips,
    List<String>? savedPlaces,
    String? emergencyContact,
    Map<String, dynamic>? preferences,
  }) {
    return RiderProfile(
      userId: userId ?? this.userId,
      rating: rating ?? this.rating,
      totalTrips: totalTrips ?? this.totalTrips,
      savedPlaces: savedPlaces ?? this.savedPlaces,
      emergencyContact: emergencyContact ?? this.emergencyContact,
      preferences: preferences ?? this.preferences,
    );
  }
}

class DriverProfile {
  final String userId;
  final String licenseNumber;
  final Vehicle vehicle;
  final List<Document> documents;
  final DriverStatus status;
  final double rating;
  final int totalTrips;
  final double totalEarnings;
  final LatLng? currentLocation;
  final DateTime? lastLocationUpdate;
  final bool isVerified;
  final double acceptanceRate;
  final double cancellationRate;
  final String? emergencyContact;

  DriverProfile({
    required this.userId,
    required this.licenseNumber,
    required this.vehicle,
    this.documents = const [],
    this.status = DriverStatus.offline,
    this.rating = 5.0,
    this.totalTrips = 0,
    this.totalEarnings = 0.0,
    this.currentLocation,
    this.lastLocationUpdate,
    this.isVerified = false,
    this.acceptanceRate = 100.0,
    this.cancellationRate = 0.0,
    this.emergencyContact,
  });

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'licenseNumber': licenseNumber,
      'vehicle': vehicle.toJson(),
      'documents': documents.map((doc) => doc.toJson()).toList(),
      'status': status.toString(),
      'rating': rating,
      'totalTrips': totalTrips,
      'totalEarnings': totalEarnings,
      'currentLocation': currentLocation != null
          ? {
              'latitude': currentLocation!.latitude,
              'longitude': currentLocation!.longitude,
            }
          : null,
      'lastLocationUpdate': lastLocationUpdate?.toIso8601String(),
      'isVerified': isVerified,
      'acceptanceRate': acceptanceRate,
      'cancellationRate': cancellationRate,
      'emergencyContact': emergencyContact,
    };
  }

  factory DriverProfile.fromJson(Map<String, dynamic> json) {
    return DriverProfile(
      userId: json['userId'],
      licenseNumber: json['licenseNumber'],
      vehicle: Vehicle.fromJson(json['vehicle']),
      documents: (json['documents'] as List<dynamic>?)
          ?.map((doc) => Document.fromJson(doc))
          .toList() ?? [],
      status: DriverStatus.values.firstWhere(
        (e) => e.toString() == json['status'],
        orElse: () => DriverStatus.offline,
      ),
      rating: json['rating']?.toDouble() ?? 5.0,
      totalTrips: json['totalTrips'] ?? 0,
      totalEarnings: json['totalEarnings']?.toDouble() ?? 0.0,
      currentLocation: json['currentLocation'] != null
          ? LatLng(
              json['currentLocation']['latitude'],
              json['currentLocation']['longitude'],
            )
          : null,
      lastLocationUpdate: json['lastLocationUpdate'] != null
          ? DateTime.parse(json['lastLocationUpdate'])
          : null,
      isVerified: json['isVerified'] ?? false,
      acceptanceRate: json['acceptanceRate']?.toDouble() ?? 100.0,
      cancellationRate: json['cancellationRate']?.toDouble() ?? 0.0,
      emergencyContact: json['emergencyContact'],
    );
  }

  DriverProfile copyWith({
    String? userId,
    String? licenseNumber,
    Vehicle? vehicle,
    List<Document>? documents,
    DriverStatus? status,
    double? rating,
    int? totalTrips,
    double? totalEarnings,
    LatLng? currentLocation,
    DateTime? lastLocationUpdate,
    bool? isVerified,
    double? acceptanceRate,
    double? cancellationRate,
    String? emergencyContact,
  }) {
    return DriverProfile(
      userId: userId ?? this.userId,
      licenseNumber: licenseNumber ?? this.licenseNumber,
      vehicle: vehicle ?? this.vehicle,
      documents: documents ?? this.documents,
      status: status ?? this.status,
      rating: rating ?? this.rating,
      totalTrips: totalTrips ?? this.totalTrips,
      totalEarnings: totalEarnings ?? this.totalEarnings,
      currentLocation: currentLocation ?? this.currentLocation,
      lastLocationUpdate: lastLocationUpdate ?? this.lastLocationUpdate,
      isVerified: isVerified ?? this.isVerified,
      acceptanceRate: acceptanceRate ?? this.acceptanceRate,
      cancellationRate: cancellationRate ?? this.cancellationRate,
      emergencyContact: emergencyContact ?? this.emergencyContact,
    );
  }
}

class Vehicle {
  final String make;
  final String model;
  final int year;
  final String plateNumber;
  final String color;
  final VehicleType type;
  final int seats;

  Vehicle({
    required this.make,
    required this.model,
    required this.year,
    required this.plateNumber,
    required this.color,
    required this.type,
    this.seats = 4,
  });

  String get displayName => '$year $make $model';

  Map<String, dynamic> toJson() {
    return {
      'make': make,
      'model': model,
      'year': year,
      'plateNumber': plateNumber,
      'color': color,
      'type': type.toString(),
      'seats': seats,
    };
  }

  factory Vehicle.fromJson(Map<String, dynamic> json) {
    return Vehicle(
      make: json['make'],
      model: json['model'],
      year: json['year'],
      plateNumber: json['plateNumber'],
      color: json['color'],
      type: VehicleType.values.firstWhere(
        (e) => e.toString() == json['type'],
        orElse: () => VehicleType.sedan,
      ),
      seats: json['seats'] ?? 4,
    );
  }

  Vehicle copyWith({
    String? make,
    String? model,
    int? year,
    String? plateNumber,
    String? color,
    VehicleType? type,
    int? seats,
  }) {
    return Vehicle(
      make: make ?? this.make,
      model: model ?? this.model,
      year: year ?? this.year,
      plateNumber: plateNumber ?? this.plateNumber,
      color: color ?? this.color,
      type: type ?? this.type,
      seats: seats ?? this.seats,
    );
  }
}

class Document {
  final String id;
  final DocumentType type;
  final String fileName;
  final String filePath;
  final DocumentStatus status;
  final DateTime uploadedAt;
  final DateTime? expiryDate;
  final String? rejectionReason;

  Document({
    required this.id,
    required this.type,
    required this.fileName,
    required this.filePath,
    this.status = DocumentStatus.pending,
    required this.uploadedAt,
    this.expiryDate,
    this.rejectionReason,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.toString(),
      'fileName': fileName,
      'filePath': filePath,
      'status': status.toString(),
      'uploadedAt': uploadedAt.toIso8601String(),
      'expiryDate': expiryDate?.toIso8601String(),
      'rejectionReason': rejectionReason,
    };
  }

  factory Document.fromJson(Map<String, dynamic> json) {
    return Document(
      id: json['id'],
      type: DocumentType.values.firstWhere(
        (e) => e.toString() == json['type'],
      ),
      fileName: json['fileName'],
      filePath: json['filePath'],
      status: DocumentStatus.values.firstWhere(
        (e) => e.toString() == json['status'],
        orElse: () => DocumentStatus.pending,
      ),
      uploadedAt: DateTime.parse(json['uploadedAt']),
      expiryDate: json['expiryDate'] != null
          ? DateTime.parse(json['expiryDate'])
          : null,
      rejectionReason: json['rejectionReason'],
    );
  }

  Document copyWith({
    String? id,
    DocumentType? type,
    String? fileName,
    String? filePath,
    DocumentStatus? status,
    DateTime? uploadedAt,
    DateTime? expiryDate,
    String? rejectionReason,
  }) {
    return Document(
      id: id ?? this.id,
      type: type ?? this.type,
      fileName: fileName ?? this.fileName,
      filePath: filePath ?? this.filePath,
      status: status ?? this.status,
      uploadedAt: uploadedAt ?? this.uploadedAt,
      expiryDate: expiryDate ?? this.expiryDate,
      rejectionReason: rejectionReason ?? this.rejectionReason,
    );
  }
} 