/// ---------- SIGNUP ----------
class SignupRequest {
  final String email;
  final String password;
  final String firstName;
  final String lastName;

  SignupRequest({
    required this.email,
    required this.password,
    required this.firstName,
    required this.lastName,
  });

  Map<String, dynamic> toJson() {
    return {
      "email": email,
      "FirstName": firstName, // backend expects capital F
      "LastName": lastName, // backend expects capital L
      "password": password,
    };
  }
}

class SignupResponse {
  final String status;
  final String message;
  final ClientData? client;

  SignupResponse({required this.status, required this.message, this.client});

  factory SignupResponse.fromJson(Map<String, dynamic> json) {
    return SignupResponse(
      status: json["status"] ?? "error",
      message: json["message"] ?? "",
      client: json["data"] != null && json["data"]["client"] != null
          ? ClientData.fromJson(json["data"]["client"])
          : null,
    );
  }
}

/// ---------- VERIFY OTP ----------
class VerifyRequest {
  final String email;
  final String otp;
  final String role;

  VerifyRequest({required this.email, required this.otp, required this.role});

  Map<String, dynamic> toJson() {
    return {"email": email, "otp": otp, "role": role};
  }
}

class VerifyResponse {
  final String status;
  final String message;
  final ClientData? user;

  VerifyResponse({required this.status, required this.message, this.user});

  factory VerifyResponse.fromJson(Map<String, dynamic> json) {
    return VerifyResponse(
      status: json["status"] ?? "error",
      message: json["message"] ?? "",
      user: json["data"] != null && json["data"]["user"] != null
          ? ClientData.fromJson(json["data"]["user"])
          : null,
    );
  }
}

/// ---------- LOGIN ----------
class LoginRequest {
  final String email;
  final String password;

  LoginRequest({required this.email, required this.password});

  Map<String, dynamic> toJson() {
    return {"email": email, "password": password};
  }
}

class LoginResponse {
  final String status;
  final String message;
  final ClientData? client;
  final String? accessToken;
  final String? refreshToken;

  LoginResponse({
    required this.status,
    required this.message,
    this.client,
    this.accessToken,
    this.refreshToken,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      status: json["status"] ?? "error",
      message: json["message"] ?? "",
      client: json["data"] != null && json["data"]["client"] != null
          ? ClientData.fromJson(json["data"]["client"])
          : null,
      accessToken: json["data"]?["accessToken"],
      refreshToken: json["data"]?["refreshToken"],
    );
  }
}

/// ---------- CLIENT DATA (FIXED) ----------
class ClientData {
  final String id;
  final String email;
  final String role;
  final bool isVerified;
  final String firstName;
  final String lastName;

  ClientData({
    required this.id,
    required this.email,
    required this.role,
    required this.isVerified,
    this.firstName = '',
    this.lastName = '',
  });

  // Used when getting data from API
  factory ClientData.fromJson(Map<String, dynamic> json) {
    return ClientData(
      id: json["_id"] ?? "",
      email: json["email"] ?? "",
      role: json["role"] ?? "",
      isVerified: json["isVerified"] ?? false,
      firstName: json["FirstName"] ?? "",
      lastName: json["LastName"] ?? "",
    );
  }

  // Used when saving to local storage (GetStorage)
  Map<String, dynamic> toJson() {
    return {
      "_id": id,
      "email": email,
      "role": role,
      "isVerified": isVerified,
      "FirstName": firstName, // Save these so fromStorage can find them
      "LastName": lastName,
    };
  }

  // --- RESTORED: Used when loading from local storage ---
  factory ClientData.fromStorage(Map<String, dynamic> json) {
    return ClientData(
      id: json["_id"] ?? "",
      email: json["email"] ?? "",
      role: json["role"] ?? "",
      isVerified: json["isVerified"] ?? false,
      firstName: json["FirstName"] ?? "", // Read saved name
      lastName: json["LastName"] ?? "", // Read saved name
    );
  }
}

/// ---------- LOGOUT ----------
class LogoutRequest {
  final String refreshToken;

  LogoutRequest({required this.refreshToken});

  Map<String, dynamic> toJson() {
    return {"refreshToken": refreshToken};
  }
}

class LogoutResponse {
  final String status;
  final String message;

  LogoutResponse({required this.status, required this.message});

  factory LogoutResponse.fromJson(Map<String, dynamic> json) {
    return LogoutResponse(
      status: json["status"] ?? "error",
      message: json["message"] ?? "",
    );
  }
}

/// ---------- FORGOT PASSWORD ----------
class ForgotPasswordRequest {
  final String email;
  final String role;

  ForgotPasswordRequest({required this.email, required this.role});

  Map<String, dynamic> toJson() => {"email": email, "role": role};
}

class ForgotPasswordResponse {
  final String status;
  final String message;
  final String? resetTokenId;

  ForgotPasswordResponse({
    required this.status,
    required this.message,
    this.resetTokenId,
  });

  factory ForgotPasswordResponse.fromJson(Map<String, dynamic> json) {
    return ForgotPasswordResponse(
      status: json["status"] ?? "error",
      message: json["message"] ?? "",
      resetTokenId: json["data"]?["resetTokenId"],
    );
  }
}

/// ---------- RESET PASSWORD ----------
class ResetPasswordRequest {
  final String resetTokenId;
  final String resetCode;
  final String password;
  final String role;

  ResetPasswordRequest({
    required this.resetTokenId,
    required this.resetCode,
    required this.password,
    required this.role,
  });

  Map<String, dynamic> toJson() => {
    "resetTokenId": resetTokenId,
    "resetCode": resetCode,
    "password": password,
    "role": role,
  };
}

// --- RIDER PROFILE ---

class RiderProfileData {
  final String id;
  final String email;
  final String? picture;
  final bool isVerified;
  final String status;
  final String role;
  final String firstName;
  final String lastName;
  final String? phoneNumber;
  final bool? phoneNumberVerified;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  RiderProfileData({
    required this.id,
    required this.email,
    this.picture,
    required this.isVerified,
    required this.status,
    required this.role,
    required this.firstName,
    required this.lastName,
    this.phoneNumber,
    this.phoneNumberVerified,
    this.createdAt,
    this.updatedAt,
  });

  String get fullName => '$firstName $lastName'.trim();

  factory RiderProfileData.fromJson(Map<String, dynamic> json) {
    return RiderProfileData(
      id: json["_id"] ?? "",
      email: json["email"] ?? "",
      picture: json["picture"],
      isVerified: json["isVerified"] ?? false,
      status: json["status"] ?? "unknown",
      role: json["role"] ?? "client",
      firstName: json["FirstName"] ?? "Guest",
      lastName: json["LastName"] ?? "",
      phoneNumber: json["phoneNumber"],
      phoneNumberVerified: json["phoneNumberVerified"],
      createdAt: json["createdAt"] != null
          ? DateTime.tryParse(json["createdAt"])
          : null,
      updatedAt: json["updatedAt"] != null
          ? DateTime.tryParse(json["updatedAt"])
          : null,
    );
  }

  RiderProfileData copyWith({
    String? id,
    String? email,
    String? picture,
    bool? isVerified,
    String? status,
    String? role,
    String? firstName,
    String? lastName,
    String? phoneNumber,
    bool? phoneNumberVerified,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return RiderProfileData(
      id: id ?? this.id,
      email: email ?? this.email,
      picture: picture ?? this.picture,
      isVerified: isVerified ?? this.isVerified,
      status: status ?? this.status,
      role: role ?? this.role,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      phoneNumberVerified: phoneNumberVerified ?? this.phoneNumberVerified,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class RiderProfileResponse {
  final String status;
  final RiderProfileData? data;

  RiderProfileResponse({required this.status, this.data});

  factory RiderProfileResponse.fromJson(Map<String, dynamic> json) {
    return RiderProfileResponse(
      status: json["status"] ?? "error",
      data: json["data"] != null
          ? RiderProfileData.fromJson(json["data"])
          : null,
    );
  }
}
