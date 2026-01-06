import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:shared_preferences/shared_preferences.dart';

typedef DataUpdateCallback = Function(String eventType, dynamic data);

class WebSocketService {
  static final WebSocketService _instance = WebSocketService._internal();
  
  WebSocketChannel? _channel;
  DataUpdateCallback? _onDataUpdate;
  bool _isConnected = false;

  factory WebSocketService() {
    return _instance;
  }

  WebSocketService._internal();

  bool get isConnected => _isConnected;

  Future<void> connect() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final apiUrl = prefs.getString('api_url') ?? 'http://192.168.1.8:5000/api';
      
      // API URL'sini WebSocket URL'sine çevir
      final wsUrl = apiUrl
          .replaceFirst('http://', 'ws://')
          .replaceFirst('https://', 'wss://')
          .replaceFirst('/api', '');
      
      print('[WebSocket] Connecting to $wsUrl');
      
      _channel = WebSocketChannel.connect(Uri.parse(wsUrl));
      _isConnected = true;
      
      // Server cevabını dinle
      _channel!.stream.listen(
        (message) {
          print('[WebSocket] Received: $message');
          _handleMessage(message);
        },
        onError: (error) {
          print('[WebSocket] Error: $error');
          _isConnected = false;
        },
        onDone: () {
          print('[WebSocket] Disconnected');
          _isConnected = false;
          // Yeniden bağlanmaya çalış
          Future.delayed(Duration(seconds: 3), () => connect());
        },
      );
    } catch (e) {
      print('[WebSocket] Connection failed: $e');
      _isConnected = false;
    }
  }

  void _handleMessage(dynamic message) {
    try {
      // Message JSON olabilir, parse et
      if (_onDataUpdate != null) {
        // Server'dan gelen event'i callback'e ilet
        _onDataUpdate!('data_update', message);
      }
    } catch (e) {
      print('[WebSocket] Error handling message: $e');
    }
  }

  void setOnDataUpdateCallback(DataUpdateCallback callback) {
    _onDataUpdate = callback;
  }

  void disconnect() {
    _channel?.sink.close();
    _isConnected = false;
  }

  void reconnect() {
    disconnect();
    Future.delayed(Duration(seconds: 1), () => connect());
  }
}
