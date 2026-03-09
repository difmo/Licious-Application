import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../network/api_client.dart';

class SocketService {
  late IO.Socket socket;

  SocketService() {
    _initSocket();
  }

  void _initSocket() {
    _log('Initializing Socket: ${ApiClient.baseUrl}');
    socket = IO.io(ApiClient.baseUrl, <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': true,
    });

    socket.onConnect((_) {
      _log('CONNECTED', status: 'SUCCESS');
    });

    socket.onDisconnect((_) {
      _log('DISCONNECTED', status: 'WARNING');
    });

    socket.onConnectError(
        (err) => _log('CONNECTION ERROR', data: err, status: 'ERROR'));
    socket.onError((err) => _log('SOCKET ERROR', data: err, status: 'ERROR'));
  }

  void _log(String title, {dynamic data, String? status}) {
    debugPrint('');
    debugPrint(
        '┌─── SOCKET ${status != null ? '[$status] ' : ''}────────────────────────────');
    debugPrint('│ $title');
    if (data != null) debugPrint('│ Data: $data');
    debugPrint('└────────────────────────────────────────────');
  }

  void joinOrderRoom(String orderId) {
    _log('JOIN ROOM', data: 'order_$orderId');
    socket.emit('join', 'order_$orderId');
  }

  void leaveOrderRoom(String orderId) {
    _log('LEAVE ROOM', data: 'order_$orderId');
    socket.emit('leave', 'order_$orderId');
  }

  void onOrderUpdate(Function(dynamic) callback) {
    _log('REGISTER CALLBACK', data: 'orderUpdate');
    socket.on('orderUpdate', (data) {
      _log('EVENT: orderUpdate', data: data);
      callback(data);
    });
  }

  void dispose() {
    socket.dispose();
  }
}

final socketServiceProvider = Provider<SocketService>((ref) {
  return SocketService();
});
