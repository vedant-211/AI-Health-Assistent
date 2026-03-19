import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class ConnectivityService {
  static final ConnectivityService _instance = ConnectivityService._internal();
  factory ConnectivityService() => _instance;
  ConnectivityService._internal();

  final _controller = StreamController<bool>.broadcast();
  Stream<bool> get connectionStream => _controller.stream;
  
  bool _isOnline = true;
  bool get isOnline => _isOnline;

  Timer? _timer;

  void startMonitoring() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 10), (_) => checkConnection());
    checkConnection();
  }

  Future<bool> checkConnection() async {
    try {
      final response = await http.get(Uri.parse('https://www.google.com')).timeout(const Duration(seconds: 3));
      final online = response.statusCode == 200;
      if (online != _isOnline) {
        _isOnline = online;
        _controller.add(online);
        debugPrint('🌐 Clinical Connection Status: ${online ? "ONLINE" : "OFFLINE"}');
      }
      return online;
    } catch (_) {
      if (_isOnline) {
        _isOnline = false;
        _controller.add(false);
        debugPrint('🌐 Clinical Connection Status: OFFLINE');
      }
      return false;
    }
  }

  void dispose() {
    _timer?.cancel();
    _controller.close();
  }
}
