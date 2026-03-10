import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import '../../core/utils/app_logger.dart';

class SocketService {
  late io.Socket socket;

  SocketService() {
    _initSocket();
  }

  void _initSocket() {
    AppLogger.info('🔌 Initializing Socket Connection...');
    socket = io.io(
        // "https://shrimpbite-socket-server.onrender.com",
        "http://localhost:5001",
        <String, dynamic>{
          'transports': ['websocket'],
          'autoConnect': true,
        });

    socket.onConnect((_) {
      AppLogger.info('✅ Socket Connected successfully');
    });

    socket.onDisconnect((_) {
      AppLogger.warning('❌ Socket Disconnected');
    });

    socket.onConnectError(
        (err) => AppLogger.error('⚠️ Socket Connection Error', err));
    socket.onError((err) => AppLogger.error('💥 Socket Error', err));
  }

  // ── Order room ────────────────────────────────────
  void joinOrderRoom(String orderId) {
    socket.emit('join', 'order_$orderId');
    AppLogger.info('📦 Joined order room: order_$orderId');
  }

  void leaveOrderRoom(String orderId) {
    socket.emit('leave', 'order_$orderId');
  }

  // ── User personal room (for rider-assigned popup) ─
  void joinUserRoom(String userId) {
    socket.emit('join', 'user_$userId');
    AppLogger.info('👤 Joined user room: user_$userId');
  }

  // ── Rider room ────────────────────────────────────
  void joinRiderRoom(String riderId) {
    socket.emit('join', 'rider_$riderId');
    AppLogger.info('🛵 Joined rider room: rider_$riderId');
  }

  // ── Event listeners ───────────────────────────────
  void onOrderUpdate(Function(dynamic) callback) {
    socket.on('orderUpdate', callback);
  }

  /// Fires when a rider accepts an order — shows popup + sound for user
  void onRiderAssigned(Function(dynamic) callback) {
    socket.on('riderAssigned', callback);
  }

  void offEvent(String event) {
    socket.off(event);
  }

  void dispose() {
    socket.dispose();
  }
}

final socketServiceProvider = Provider<SocketService>((ref) {
  return SocketService();
});
