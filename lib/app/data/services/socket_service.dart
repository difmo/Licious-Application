import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

class SocketService {
  late io.Socket socket;

  SocketService() {
    _initSocket();
  }

  void _initSocket() {
    socket = io
        .io("https://shrimpbite-socket-server.onrender.com", <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': true,
    });
    socket.onConnect((_) {
      debugPrint('Socket connected');
    });

    socket.onDisconnect((_) {
      debugPrint('Socket disconnected');
    });

    socket.onConnectError((err) => debugPrint('Socket connection error: $err'));
    socket.onError((err) => debugPrint('Socket error: $err'));
  }

  void joinOrderRoom(String orderId) {
    socket.emit('join', 'order_$orderId');
  }

  void leaveOrderRoom(String orderId) {
    socket.emit('leave', 'order_$orderId');
  }

  void onOrderUpdate(Function(dynamic) callback) {
    socket.on('orderUpdate', callback);
  }

  void dispose() {
    socket.dispose();
  }
}

final socketServiceProvider = Provider<SocketService>((ref) {
  return SocketService();
});
