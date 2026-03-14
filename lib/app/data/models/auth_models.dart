class UserModel {
  final String id;
  final String fullName;
  final String email;
  final String phoneNumber;
  final String role;
  final bool isShopActive;

  UserModel({
    required this.id,
    required this.fullName,
    required this.email,
    required this.phoneNumber,
    this.role = 'customer',
    this.isShopActive = true,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['_id'] ?? json['id'] ?? '',
      fullName: json['fullName'] ?? json['name'] ?? '',
      email: json['email'] ?? '',
      phoneNumber: json['phoneNumber'] ?? json['phone'] ?? '',
      role: json['role'] ?? 'customer',
      isShopActive: json['isShopActive'] ?? json['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fullName': fullName,
      'email': email,
      'phoneNumber': phoneNumber,
      'role': role,
      'isShopActive': isShopActive,
    };
  }
}

class AuthResponseModel {
  final bool success;
  final String message;
  final String? token;
  final String? refreshToken;
  final UserModel? data;
  final String? otp; // returned by /api/otp/send in dev/dummy mode

  AuthResponseModel({
    required this.success,
    required this.message,
    this.token,
    this.refreshToken,
    this.data,
    this.otp,
  });

  factory AuthResponseModel.fromJson(Map<String, dynamic> json) {
    return AuthResponseModel(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      token: json['token'],
      refreshToken: json['refreshToken'],
      otp: json['otp']?.toString(),
      data: json['data'] is Map<String, dynamic>
          ? UserModel.fromJson(json['data'] as Map<String, dynamic>)
          : null,
    );
  }
}
