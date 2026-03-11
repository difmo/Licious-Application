class UserModel {
  final String id;
  final String email;
  final String fullName;

  UserModel({required this.id, required this.email, required this.fullName});

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? '',
      email: json['email'] ?? '',
      fullName: json['fullName'] ?? '',
    );
  }
}

enum AuthStatus { initial, authenticated, unauthenticated, loading }

class AuthState {
  final AuthStatus status;
  final UserModel? user;
  final String? error;

  AuthState({
    required this.status,
    this.user,
    this.error,
  });

  factory AuthState.initial() => AuthState(status: AuthStatus.initial);
}
