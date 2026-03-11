import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import '../state/auth_store.dart';

class SocketClient {
  final Ref _ref;
  io.Socket? _socket;
  final String _baseUrl;

  SocketClient(this._ref, this._baseUrl) {
    _init();
    
    // Listen for auth state changes to reconnect with new token
    _ref.listen(authStoreProvider, (previous, next) {
      if (next.status == AuthStatus.authenticated && 
          previous?.status != AuthStatus.authenticated) {
        debugPrint('SocketClient: Auth state changed to Authenticated. Connecting...');
        connect();
      } else if (next.status == AuthStatus.unauthenticated) {
        debugPrint('SocketClient: Auth state changed to Unauthenticated. Disconnecting...');
        disconnect();
      }
    });
  }

  void _init() {
    final authState = _ref.read(authStoreProvider);
    if (authState.status == AuthStatus.authenticated) {
      connect();
    }
  }

  Future<void> connect() async {
    final token = await _ref.read(secureStorageProvider).getAccessToken();
    
    if (token == null) {
      debugPrint('SocketClient: Cannot connect, no token available.');
      return;
    }

    _socket?.disconnect();
    
    _socket = io.io(_baseUrl, <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
      'extraHeaders': {'Authorization': 'Bearer $token'}
    });

    _socket?.onConnect((_) => debugPrint('SocketClient: Connected'));
    _socket?.onDisconnect((_) => debugPrint('SocketClient: Disconnected'));
    _socket?.onConnectError((err) {
      debugPrint('SocketClient: Connect Error: $err');
      // If error is 401, we might need a manual refresh or wait for Interceptor
    });

    _socket?.connect();
  }

  void disconnect() {
    _socket?.disconnect();
    _socket = null;
  }

  void emit(String event, dynamic data) {
    _socket?.emit(event, data);
  }

  void on(String event, Function(dynamic) handler) {
    _socket?.on(event, handler);
  }
}

final socketClientProvider = Provider<SocketClient>((ref) {
  // Use your production socket URL here
  const socketUrl = 'https://shrimpbite-backend.vercel.app'; 
  return SocketClient(ref, socketUrl);
});
