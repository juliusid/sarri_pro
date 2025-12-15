import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:sarri_ride/utils/constants/enums.dart';

class User {
  final String id;
  final String email;
  final String firstName;
  final String lastName;
  final String? phoneNumber;
  final UserType userType;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final RiderProfile? riderProfile;
  final DriverProfile? driverProfile;
  final String? picture;

  User({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    this.phoneNumber,
    required this.userType,
    this.createdAt,
    this.updatedAt,
    this.riderProfile,
    this.driverProfile,
    this.picture,
  });

  String get fullName => '$firstName $lastName'.trim();

  // --- Factory to create User from Driver Profile API Data ---
  factory User.fromDriverProfileJson(Map<String, dynamic> json) {
    DriverProfile? profile;
    try {
      profile = DriverProfile.fromJson(json);
    } catch (e) {
      print(
        "Error parsing DriverProfile part in User.fromDriverProfileJson: $e",
      );
      profile = null;
    }

    return User(
      id: json['_id'] ?? '',
      email: json['email'] ?? '',
      firstName: json['FirstName'] ?? '',
      lastName: json['LastName'] ?? '',
      phoneNumber: json['phoneNumber'],
      userType: UserType.driver,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'])
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'])
          : null,
      riderProfile: null,
      driverProfile: profile,
      picture: json['picture'],
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
    String? picture,
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
      picture: picture ?? this.picture,
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
  final DrivingLicenseModel drivingLicense;
  final AddressModel currentAddress;
  final AddressModel permanentAddress;
  final BankDetailsModel bankDetails;
  final Vehicle vehicleDetails;
  final LocationModel location;
  final bool isVerified;
  final bool adminVerified;
  final String availabilityStatus;
  final String status;
  final DateTime? lastLocationUpdate;
  final DateTime? dateOfBirth;
  final String? gender;
  final String? emergencyContactNumber;
  final String? licenseNumber;
  final int? seat;

  // Stats
  final double rating;
  final int totalTrips;
  final double totalEarnings;
  final double acceptanceRate;
  final double cancellationRate;

  DriverProfile({
    required this.userId,
    required this.drivingLicense,
    required this.currentAddress,
    required this.permanentAddress,
    required this.bankDetails,
    required this.vehicleDetails,
    required this.location,
    required this.isVerified,
    required this.adminVerified,
    required this.availabilityStatus,
    required this.status,
    this.lastLocationUpdate,
    this.dateOfBirth,
    this.gender,
    this.emergencyContactNumber,
    this.licenseNumber,
    this.seat,
    this.rating = 4.5,
    this.totalTrips = 0,
    this.totalEarnings = 0.0,
    this.acceptanceRate = 100.0,
    this.cancellationRate = 0.0,
  });

  factory DriverProfile.fromJson(Map<String, dynamic> json) {
    // Helper to safely parse LatLng
    LatLng? parseLatLng(dynamic locData) {
      if (locData != null &&
          locData['coordinates'] is List &&
          locData['coordinates'].length >= 2) {
        final coords = locData['coordinates'];
        final lon = (coords[0] as num?)?.toDouble();
        final lat = (coords[1] as num?)?.toDouble();
        if (lat != null && lon != null) {
          return LatLng(lat, lon);
        }
      }
      return null;
    }

    // --- FIX: Safe Rating Parsing ---
    double parsedRating = 4.5;
    final rawRating = json['rating'];
    if (rawRating is num) {
      parsedRating = rawRating.toDouble();
    } else if (rawRating is Map) {
      final avg = rawRating['average'];
      if (avg is num) parsedRating = avg.toDouble();
    }

    // --- FIX: Safe Stats Parsing ---
    int parsedTrips = (json['totalTrips'] as num?)?.toInt() ?? 0;
    double parsedEarnings = (json['totalEarnings'] as num?)?.toDouble() ?? 0.0;

    return DriverProfile(
      userId: json['_id'] ?? '',
      drivingLicense: DrivingLicenseModel.fromJson(
        json['drivingLicense'] ?? {},
      ),
      currentAddress: AddressModel.fromJson(json['currentAddress'] ?? {}),
      permanentAddress: AddressModel.fromJson(json['permanentAddress'] ?? {}),
      bankDetails: BankDetailsModel.fromJson(json['bankDetails'] ?? {}),
      vehicleDetails: Vehicle.fromJson(json['vehicleDetails'] ?? {}),
      location: LocationModel.fromJson(json['location'] ?? {}),
      isVerified: json['isVerified'] ?? false,
      adminVerified: json['adminVerified'] ?? false,
      availabilityStatus: json['availabilityStatus'] ?? 'unavailable',
      status: json['status'] ?? 'pending',
      lastLocationUpdate: json['lastLocationUpdate'] != null
          ? DateTime.tryParse(json['lastLocationUpdate'])
          : null,
      dateOfBirth: json['DateOfBirth'] != null
          ? DateTime.tryParse(json['DateOfBirth'])
          : null,
      gender: json['Gender'],
      emergencyContactNumber: json['emergencyContactNumber'],
      licenseNumber: json['licenseNumber'],
      seat: (json['seat'] as num?)?.toInt(),

      // Use the safely parsed values
      rating: parsedRating,
      totalTrips: parsedTrips,
      totalEarnings: parsedEarnings,
      acceptanceRate: (json['acceptanceRate'] as num?)?.toDouble() ?? 100.0,
      cancellationRate: (json['cancellationRate'] as num?)?.toDouble() ?? 0.0,
    );
  }

  DriverProfile copyWith({
    LatLng? currentLocation,
    String? availabilityStatus,
    bool? isOnBreak,
    BankDetailsModel? bankDetails,
  }) {
    return DriverProfile(
      userId: userId,
      drivingLicense: drivingLicense,
      currentAddress: currentAddress,
      permanentAddress: permanentAddress,
      bankDetails: bankDetails ?? this.bankDetails,
      vehicleDetails: vehicleDetails,
      location: location.copyWith(coordinates: currentLocation),
      isVerified: isVerified,
      adminVerified: adminVerified,
      availabilityStatus: availabilityStatus ?? this.availabilityStatus,
      status: status,
      lastLocationUpdate: DateTime.now(),
      dateOfBirth: dateOfBirth,
      gender: gender,
      emergencyContactNumber: emergencyContactNumber,
      licenseNumber: licenseNumber,
      seat: seat,
      rating: rating,
      totalTrips: totalTrips,
      totalEarnings: totalEarnings,
      acceptanceRate: acceptanceRate,
      cancellationRate: cancellationRate,
    );
  }
}

class DrivingLicenseModel {
  final DateTime? issueDate;
  final DateTime? expiryDate;
  final String? frontsideImage;
  final String? backsideImage;
  final String? insuranceCertificate;
  final String? vehicleRegistration;

  DrivingLicenseModel({
    this.issueDate,
    this.expiryDate,
    this.frontsideImage,
    this.backsideImage,
    this.insuranceCertificate,
    this.vehicleRegistration,
  });

  factory DrivingLicenseModel.fromJson(Map<String, dynamic> json) {
    return DrivingLicenseModel(
      issueDate: json['issueDate'] != null
          ? DateTime.tryParse(json['issueDate'])
          : null,
      expiryDate: json['expiryDate'] != null
          ? DateTime.tryParse(json['expiryDate'])
          : null,
      frontsideImage: json['frontsideImage'],
      backsideImage: json['backsideImage'],
      insuranceCertificate: json['insuranceCertificate'],
      vehicleRegistration: json['vehicleRegistration'],
    );
  }
}

class AddressModel {
  final String? address;
  final String? state;
  final String? city;
  final String? country;
  final String? postalCode;

  AddressModel({
    this.address,
    this.state,
    this.city,
    this.country,
    this.postalCode,
  });

  factory AddressModel.fromJson(Map<String, dynamic> json) {
    return AddressModel(
      address: json['address'],
      state: json['state'],
      city: json['city'],
      country: json['country'],
      postalCode: json['postalCode'],
    );
  }

  String get fullAddress {
    final parts = [
      address,
      city,
      state,
      country,
    ].where((s) => s != null && s.isNotEmpty).toList();
    return parts.join(', ');
  }
}

class BankDetailsModel {
  final String? bankAccountNumber;
  final String? bankName;
  final String? bankAccountName;

  BankDetailsModel({
    this.bankAccountNumber,
    this.bankName,
    this.bankAccountName,
  });

  factory BankDetailsModel.fromJson(Map<String, dynamic> json) {
    return BankDetailsModel(
      bankAccountNumber: json['bankAccountNumber'],
      bankName: json['bankName'],
      bankAccountName: json['bankAccountName'],
    );
  }

  BankDetailsModel copyWith({
    String? bankAccountNumber,
    String? bankName,
    String? bankAccountName,
  }) {
    return BankDetailsModel(
      bankAccountNumber: bankAccountNumber ?? this.bankAccountNumber,
      bankName: bankName ?? this.bankName,
      bankAccountName: bankAccountName ?? this.bankAccountName,
    );
  }
}

class LocationModel {
  final String? type; // "Point"
  final LatLng? coordinates; // Parsed LatLng
  final String? state;

  LocationModel({this.type, this.coordinates, this.state});

  factory LocationModel.fromJson(Map<String, dynamic> json) {
    LatLng? coords;
    if (json['coordinates'] is List && json['coordinates'].length >= 2) {
      final lon = (json['coordinates'][0] as num?)?.toDouble();
      final lat = (json['coordinates'][1] as num?)?.toDouble();
      if (lat != null && lon != null) {
        coords = LatLng(lat, lon);
      }
    }
    return LocationModel(
      type: json['type'],
      coordinates: coords,
      state: json['state'],
    );
  }

  LocationModel copyWith({LatLng? coordinates}) {
    return LocationModel(
      type: type,
      coordinates: coordinates ?? this.coordinates,
      state: state,
    );
  }
}

class Vehicle {
  final String? make;
  final String? model;
  final int? year;
  final String? plateNumber;
  final String? color;
  final VehicleType type;
  final int seats;

  Vehicle({
    this.make,
    this.model,
    this.year,
    this.plateNumber,
    this.color = 'Unknown',
    this.type = VehicleType.sedan,
    this.seats = 4,
  });

  String get displayName => '${year ?? ''} ${make ?? ''} ${model ?? ''}'.trim();

  factory Vehicle.fromJson(Map<String, dynamic> json) {
    VehicleType determinedType = VehicleType.sedan;
    return Vehicle(
      make: json['make'],
      model: json['model'],
      year: (json['year'] as num?)?.toInt(),
      plateNumber: json['licensePlate'],
      color: json['color'] ?? 'Unknown',
      type: determinedType,
      seats: (json['seats'] as num?)?.toInt() ?? 4,
    );
  }

  Map<String, dynamic> toJson() => {
    'make': make,
    'model': model,
    'year': year,
    'licensePlate': plateNumber,
    'color': color,
    'type': type.toString().split('.').last,
    'seats': seats,
  };
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
      type: DocumentType.values.firstWhere((e) => e.toString() == json['type']),
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
