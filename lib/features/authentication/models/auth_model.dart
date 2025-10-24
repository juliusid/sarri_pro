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
      "LastName": lastName,   // backend expects capital L
      "password": password,
    };
  }
}

class SignupResponse {
  final String status;
  final String message;
  final ClientData? client;

  SignupResponse({
    required this.status,
    required this.message,
    this.client,
  });

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

  VerifyRequest({
    required this.email,
    required this.otp,
    required this.role,
  });

  Map<String, dynamic> toJson() {
    return {
      "email": email,
      "otp": otp,
      "role": role,
    };
  }
}

class VerifyResponse {
  final String status;
  final String message;
  final ClientData? user;

  VerifyResponse({
    required this.status,
    required this.message,
    this.user,
  });

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

  LoginRequest({
    required this.email,
    required this.password,
  });

  Map<String, dynamic> toJson() {
    return {
      "email": email,
      "password": password,
    };
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

/// ---------- CLIENT DATA ----------
class ClientData {
  final String id;
  final String email;
  final String role;
  final bool isVerified;

  ClientData({
    required this.id,
    required this.email,
    required this.role,
    required this.isVerified,
  });

  factory ClientData.fromJson(Map<String, dynamic> json) {
    return ClientData(
      id: json["_id"] ?? "",
      email: json["email"] ?? "",
      role: json["role"] ?? "",
      isVerified: json["isVerified"] ?? false,
    );
  }
}

/// ---------- LOGOUT ----------
class LogoutRequest {
  final String refreshToken;

  LogoutRequest({
    required this.refreshToken,
  });

  Map<String, dynamic> toJson() {
    return {
      "refreshToken": refreshToken,
    };
  }
}

class LogoutResponse {
  final String status;
  final String message;

  LogoutResponse({
    required this.status,
    required this.message,
  });

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

  ForgotPasswordResponse({required this.status, required this.message, this.resetTokenId});

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