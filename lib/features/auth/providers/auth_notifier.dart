import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_provider.dart';
import '../models/auth_state.dart';
import '../repository/auth_repository.dart';

final authRepositoryProvider = Provider((ref) {
  return AuthRepository(ref.watch(dioProvider));
});

class AuthNotifier extends Notifier<AuthState> {
  @override
  AuthState build() {
    // We can't use async here directly in build for Notifier (use AsyncNotifier for that)
    // But we can trigger an initial check
    _restoreSession();
    return AuthState.initial();
  }

  Future<void> _restoreSession() async {
    final storage = ref.read(storageServiceProvider);
    final token = await storage.getAccessToken();

    if (token == null) {
      state = AuthState(status: AuthStatus.unauthenticated);
      return;
    }

    try {
      final user = await ref.read(authRepositoryProvider).getProfile();
      state = AuthState(status: AuthStatus.authenticated, user: user);
    } catch (e) {
      state = AuthState(status: AuthStatus.unauthenticated);
    }
  }

  Future<void> login(String email, String password) async {
    state = AuthState(status: AuthStatus.loading);
    try {
      final repository = ref.read(authRepositoryProvider);
      final data = await repository.login(email, password);

      final access = data['access_token'];
      final refresh = data['refresh_token'];
      final user = UserModel.fromJson(data['user']);

      await ref.read(storageServiceProvider).saveTokens(
            access: access,
            refresh: refresh,
          );

      state = AuthState(status: AuthStatus.authenticated, user: user);
    } catch (e) {
      state = AuthState(status: AuthStatus.unauthenticated, error: e.toString());
    }
  }

  Future<void> logout() async {
    try {
      await ref.read(authRepositoryProvider).logout();
    } catch (_) {}
    await ref.read(storageServiceProvider).clearAll();
    state = AuthState(status: AuthStatus.unauthenticated);
  }
}

final authNotifierProvider = NotifierProvider<AuthNotifier, AuthState>(() {
  return AuthNotifier();
});
