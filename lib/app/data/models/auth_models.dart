class UserModel {
  final String id;
  final String fullName;
  final String email;
  final String phoneNumber;

  UserModel({
    required this.id,
    required this.fullName,
    required this.email,
    required this.phoneNumber,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['_id'] ?? json['id'] ?? '',
      fullName: json['fullName'] ?? '',
      email: json['email'] ?? '',
      phoneNumber: json['phoneNumber'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fullName': fullName,
      'email': email,
      'phoneNumber': phoneNumber,
    };
  }
}

class AuthResponseModel {
  final bool success;
  final String message;
  final String? token;
  final UserModel? data;
  final String? otp; // returned by /api/otp/send in dev/dummy mode

  AuthResponseModel({
    required this.success,
    required this.message,
    this.token,
    this.data,
    this.otp,
  });

  factory AuthResponseModel.fromJson(Map<String, dynamic> json) {
    return AuthResponseModel(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      token: json['token'],
      otp: json['otp']?.toString(),
      data: json['data'] is Map<String, dynamic>
          ? UserModel.fromJson(json['data'] as Map<String, dynamic>)
          : null,
    );
  }
}
