// ignore_for_file: non_constant_identifier_names

class VerifyDriverEmailRequest {
  final String email;

  VerifyDriverEmailRequest({required this.email});

  Map<String, dynamic> toJson() => {'email': email};
}

class VerifyDriverOtpRequest {
  final String email;
  final String otp;

  VerifyDriverOtpRequest({required this.email, required this.otp});

  Map<String, dynamic> toJson() => {'email': email, 'otp': otp};
}

class VerifyDriverOtpResponse {
  final String status;
  final String message;
  final String? driverId;

  VerifyDriverOtpResponse({
    required this.status,
    required this.message,
    this.driverId,
  });

  factory VerifyDriverOtpResponse.fromJson(Map<String, dynamic> json) {
    return VerifyDriverOtpResponse(
      status: json['status'],
      message: json['message'],
      driverId: json['data']?['driverId'],
    );
  }
}

class DriverRegistrationRequest {
  final String email;
  final String FirstName;
  final String LastName;
  final String password;
  final String phoneNumber;
  final String DateOfBirth;
  final String Gender;
  final String licenseNumber;
  final DrivingLicense drivingLicense;
  final Address currentAddress;
  final Address permanentAddress;
  final String emergencyContactNumber;
  final BankDetails bankDetails;
  final VehicleDetails vehicleDetails;
  final int seat;

  DriverRegistrationRequest({
    required this.email,
    required this.FirstName,
    required this.LastName,
    required this.password,
    required this.phoneNumber,
    required this.DateOfBirth,
    required this.Gender,
    required this.licenseNumber,
    required this.drivingLicense,
    required this.currentAddress,
    required this.permanentAddress,
    required this.emergencyContactNumber,
    required this.bankDetails,
    required this.vehicleDetails,
    required this.seat,
  });

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'FirstName': FirstName,
      'LastName': LastName,
      'password': password,
      'phoneNumber': phoneNumber,
      'DateOfBirth': DateOfBirth,
      'Gender': Gender,
      'licenseNumber': licenseNumber,
      'drivingLicense': drivingLicense.toJson(),
      'currentAddress': currentAddress.toJson(),
      'permanentAddress': permanentAddress.toJson(),
      'emergencyContactNumber': emergencyContactNumber,
      'bankDetails': bankDetails.toJson(),
      'vehicleDetails': vehicleDetails.toJson(),
      'seat': seat,
    };
  }
}

class DrivingLicense {
  final String issueDate;
  final String expiryDate;

  DrivingLicense({required this.issueDate, required this.expiryDate});

  Map<String, dynamic> toJson() => {
    'issueDate': issueDate,
    'expiryDate': expiryDate,
  };
}

class Address {
  final String address;
  final String state;
  final String city;
  final String country;
  final String postalCode;

  Address({
    required this.address,
    required this.state,
    required this.city,
    required this.country,
    required this.postalCode,
  });

  Map<String, dynamic> toJson() => {
    'address': address,
    'state': state,
    'city': city,
    'country': country,
    'postalCode': postalCode,
  };
}

class BankDetails {
  final String bankAccountNumber;
  final String bankName;
  final String bankAccountName;

  BankDetails({
    required this.bankAccountNumber,
    required this.bankName,
    required this.bankAccountName,
  });

  Map<String, dynamic> toJson() => {
    'bankAccountNumber': bankAccountNumber,
    'bankName': bankName,
    'bankAccountName': bankAccountName,
  };
}

class VehicleDetails {
  final String make;
  final String model;
  final int year;
  final String licensePlate;

  VehicleDetails({
    required this.make,
    required this.model,
    required this.year,
    required this.licensePlate,
  });

  Map<String, dynamic> toJson() => {
    'make': make,
    'model': model,
    'year': year,
    'licensePlate': licensePlate,
  };
}

class DriverLoginResponse {
  final String status;
  final String message;
  final DriverLoginData? data;

  DriverLoginResponse({required this.status, required this.message, this.data});

  factory DriverLoginResponse.fromJson(Map<String, dynamic> json) {
    return DriverLoginResponse(
      status: json['status'] ?? 'error',
      message: json['message'] ?? 'Login failed',
      data: json['data'] != null
          ? DriverLoginData.fromJson(json['data'])
          : null,
    );
  }
}

class DriverLoginData {
  final DriverDetails driver;
  final String accessToken;
  final String refreshToken;

  DriverLoginData({
    required this.driver,
    required this.accessToken,
    required this.refreshToken,
  });

  factory DriverLoginData.fromJson(Map<String, dynamic> json) {
    return DriverLoginData(
      driver: DriverDetails.fromJson(json['driver'] ?? {}),
      accessToken: json['accessToken'] ?? '',
      refreshToken: json['refreshToken'] ?? '',
    );
  }
}

class DriverDetails {
  final String id;
  final String name; // Note: API returns 'name', not FirstName/LastName here
  final String email;
  final String role;
  final bool isVerified;

  DriverDetails({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.isVerified,
  });

  factory DriverDetails.fromJson(Map<String, dynamic> json) {
    return DriverDetails(
      id: json['_id'] ?? '',
      name: json['name'] ?? 'Driver', // Use the 'name' field
      email: json['email'] ?? '',
      role: json['role'] ?? 'driver',
      isVerified: json['isVerified'] ?? false,
    );
  }
}
