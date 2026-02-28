class UserModel {
  final String id;
  final String fullName;
  final String email;
  final String username;
  final String phoneNumber;

  UserModel({
    required this.id,
    required this.fullName,
    required this.email,
    required this.username,
    required this.phoneNumber,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? '',
      fullName: json['fullName'] ?? '',
      email: json['email'] ?? '',
      username: json['username'] ?? '',
      phoneNumber: json['phoneNumber'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fullName': fullName,
      'email': email,
      'username': username,
      'phoneNumber': phoneNumber,
    };
  }
}

class AuthResponseModel {
  final bool success;
  final String message;
  final String? token;
  final UserModel? data;

  AuthResponseModel({
    required this.success,
    required this.message,
    this.token,
    this.data,
  });

  factory AuthResponseModel.fromJson(Map<String, dynamic> json) {
    return AuthResponseModel(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      token: json['token'],
      data: json['data'] != null ? UserModel.fromJson(json['data']) : null,
    );
  }
}
