class UserModel {
  final String id;
  final String fullName;
  final String email;
  final String phoneNumber;
  final String role;
  final bool isShopActive;
  final String? walletId;

  UserModel({
    required this.id,
    required this.fullName,
    required this.email,
    required this.phoneNumber,
    this.role = 'customer',
    this.isShopActive = true,
    this.walletId,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    final String name = json['fullName'] ?? json['name'] ?? '';
    return UserModel(
      id: json['_id'] ?? json['id'] ?? '',
      fullName: name.isEmpty ? 'Shrimpbite User' : name,
      email: json['email'] ?? '',
      phoneNumber: json['phoneNumber'] ?? json['phone'] ?? '',
      role: json['role'] ?? 'customer',
      isShopActive: json['isShopActive'] ?? json['isActive'] ?? true,
      walletId: (json['walletId'] ?? json['wallet_id'])?.toString(),
    );
  }

  factory UserModel.placeholder(String phone) {
    return UserModel(
      id: 'placeholder',
      fullName: 'Shrimpbite User',
      email: '',
      phoneNumber: phone,
      role: 'user',
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
      'walletId': walletId,
    };
  }

  UserModel copyWith({
    String? id,
    String? fullName,
    String? email,
    String? phoneNumber,
    String? role,
    bool? isShopActive,
  }) {
    return UserModel(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      role: role ?? this.role,
      isShopActive: isShopActive ?? this.isShopActive,
      walletId: walletId ?? this.walletId,
    );
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
      token: json['token'] ?? json['accessToken'] ?? json['idToken'],
      refreshToken: json['refreshToken'],
      otp: json['otp']?.toString(),
      data: (json['data'] ?? json['user'] ?? json['profile']) is Map<String, dynamic>
          ? UserModel.fromJson((json['data'] ?? json['user'] ?? json['profile']) as Map<String, dynamic>)
          : null,
    );
  }
}

/// Response model for POST /api/app-auth/check-user
/// action == "otp" setup for both Rider and Customer
class CheckUserResponseModel {
  final bool success;
  final String message;
  final String? action; // always "otp" now
  final String? role; // "rider" or "customer"
  final bool? isNewUser;

  CheckUserResponseModel({
    required this.success,
    required this.message,
    this.action,
    this.role,
    this.isNewUser,
  });

  factory CheckUserResponseModel.fromJson(Map<String, dynamic> json) {
    return CheckUserResponseModel(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      action: json['action']?.toString(),
      role: json['role']?.toString(),
      isNewUser: json['isNewUser'] as bool?,
    );
  }
}
