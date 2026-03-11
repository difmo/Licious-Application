import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import '../network/api_client.dart';

final socketServiceProvider = Provider<SocketService>((ref) {
  return SocketService();
});

class SocketService {
  IO.Socket? socket;
  // A simple set to quickly keep track of rooms we are joined to
  final Set<String> _joinedRooms = {};

  void connect(
      {Function(Map<String, dynamic>)? onOrderUpdate,
      Function(Map<String, dynamic>)? onRiderAssigned}) async {
    // If a socket exists, disconnect first to avoid duplicates
    disconnect();

    // Extract userId from locally stored token
    String? userId;
    try {
      final token = await ApiClient.getToken();
      if (token != null) {
        final parts = token.split('.');
        if (parts.length == 3) {
          final payload = parts[1];
          final normalized = base64Url.normalize(payload);
          final decoded = utf8.decode(base64Url.decode(normalized));
          final data = jsonDecode(decoded);
          userId = data['id']?.toString() ?? data['_id']?.toString();
        }
      }
    } catch (e) {
      debugPrint('Failed to extract user ID from token for socket: $e');
    }

    try {
      socket = IO.io('https://shrimpbite-backend.vercel.app', <String, dynamic>{
        'transports': ['websocket'],
        'autoConnect': false,
      });

      socket?.connect();

      socket?.onConnect((_) {
        debugPrint('Socket connected: ${socket?.id}');
        if (userId != null) {
          joinRoom('user_$userId');
        }
      });

      socket?.onDisconnect((_) {
        debugPrint('Socket disconnected.');
        _joinedRooms.clear();
      });

      // Global listeners for the background
      socket?.on('orderUpdate', (data) {
        debugPrint('Global Order Update: $data');
        if (onOrderUpdate != null && data is Map<String, dynamic>) {
          onOrderUpdate(data);
        }
      });

      socket?.on('riderAssigned', (data) {
        debugPrint('Rider Assigned: $data');
        if (onRiderAssigned != null && data is Map<String, dynamic>) {
          onRiderAssigned(data);
        }
      });
    } catch (e) {
      debugPrint('Error connecting to socket: $e');
    }
  }

  void joinRoom(String room) {
    if (socket != null && !_joinedRooms.contains(room)) {
      socket?.emit('join', room);
      _joinedRooms.add(room);
      debugPrint('Joined completely to room: $room');
    }
  }

  void joinOrderRoom(String orderId) {
    joinRoom('order_$orderId');
  }

  void leaveRoom(String room) {
    if (socket != null && _joinedRooms.contains(room)) {
      // NOTE: backend may not have a 'leave' listener, but socketio usually handles emit('leave')
      socket?.emit('leave', room);
      _joinedRooms.remove(room);
      debugPrint('Left room: $room');
    }
  }

  void leaveOrderRoom(String orderId) {
    leaveRoom('order_$orderId');
  }

  // Set up local UI listener on pages
  void setOrderUpdateListener(Function(Map<String, dynamic>) callback) {
    socket?.off('orderUpdate'); // Clear old ones if any local overlay needed
    socket?.on('orderUpdate', (data) {
      if (data is Map<String, dynamic>) {
        callback(data);
      }
    });
  }

  void onOrderUpdate(Function(Map<String, dynamic>) callback) {
    setOrderUpdateListener(callback);
  }

  void disconnect() {
    if (socket != null) {
      socket?.disconnect();
      socket = null;
    }
    _joinedRooms.clear();
  }
}
