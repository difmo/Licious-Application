import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../network/api_client.dart';

class SocketService {
  late IO.Socket socket;

  SocketService() {
    _initSocket();
  }

  void _initSocket() {
    socket = IO.io(ApiClient.baseUrl, <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': true,
    });

    socket.onConnect((_) {
      print('Socket connected');
    });

    socket.onDisconnect((_) {
      print('Socket disconnected');
    });

    socket.onConnectError((err) => print('Socket connection error: $err'));
    socket.onError((err) => print('Socket error: $err'));
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
