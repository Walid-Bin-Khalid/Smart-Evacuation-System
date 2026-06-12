
import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../Core/Config/app_config.dart';

// ── Alert Model ───────────────────────────────────────────────
class EvacuationAlert {
  final String alertId;
  final String hazardNodeId;
  final String hazardType;
  final String floor;
  final String reportedBy;
  final DateTime timestamp;
  final bool isActive;
  final String message;
  final String severity;
  final String? mongoId;

  const EvacuationAlert({
    required this.alertId,
    required this.hazardNodeId,
    required this.hazardType,
    required this.floor,
    required this.reportedBy,
    required this.timestamp,
    required this.isActive,
    this.message = '',
    this.severity = 'high',
    this.mongoId,
  });

  factory EvacuationAlert.fromJson(Map<String, dynamic> json) {
    return EvacuationAlert(
      alertId: json['alertId'] ?? json['alert_id'] ?? '',
      hazardNodeId: json['hazardNodeId'] ?? json['hazard_node_id'] ?? '',
      hazardType: json['hazardType'] ?? json['hazard_type'] ?? 'unknown',
      floor: json['floor'] ?? 'Ground',
      reportedBy: json['reportedBy'] ?? json['reported_by'] ?? '',
      timestamp: json['timestamp'] != null
          ? DateTime.tryParse(json['timestamp'].toString()) ?? DateTime.now()
          : DateTime.now(),
      isActive: json['isActive'] ?? json['is_active'] ?? true,
      message: json['message'] ?? '',
      severity: json['severity'] ?? 'high',
      mongoId: json['_id']?.toString() ?? json['id']?.toString(),
    );
  }
}

//  WebSocketService
class WebSocketService {
  static final WebSocketService _instance = WebSocketService._internal();
  factory WebSocketService() => _instance;
  WebSocketService._internal();

  // ← AppConfig.wsUrl use hoga — hardcoded nahi
  String get _wsUrl => AppConfig.wsUrl;

  WebSocketChannel? _channel;
  StreamSubscription? _channelSub;
  Timer? _reconnectTimer;
  Timer? _pingTimer;

  bool _isConnected = false;
  bool _shouldConnect = true;

  final StreamController<EvacuationAlert?> _alertController =
      StreamController<EvacuationAlert?>.broadcast();

  EvacuationAlert? _currentAlert;

  Stream<EvacuationAlert?> get alertStream => _alertController.stream;
  EvacuationAlert? get currentAlert => _currentAlert;
  bool get isEmergency => _currentAlert != null && _currentAlert!.isActive;
  bool get isConnected => _isConnected;

  // ── Connect ───────────────────────────────────────────
  Future<void> connect() async {
    _shouldConnect = true;
    await _doConnect();
  }

  Future<void> _doConnect() async {
    if (!_shouldConnect) return;

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token') ?? '';

    final uri = Uri.parse(
      token.isNotEmpty ? '$_wsUrl?token=$token' : _wsUrl,
    );

    debugPrint('[WS] Connecting to $uri');

    try {
      _channel = WebSocketChannel.connect(uri);
      await _channel!.ready;

      _isConnected = true;
      debugPrint('[WS] Connected ✓');

      _channelSub = _channel!.stream.listen(
        _onMessage,
        onError: _onError,
        onDone: _onDone,
      );

      _pingTimer?.cancel();
      _pingTimer = Timer.periodic(const Duration(seconds: 30), (_) {
        _send({'type': 'ping'});
      });
    } catch (e) {
      debugPrint('[WS] Failed: $e');
      _isConnected = false;
      _scheduleReconnect();
    }
  }

  // ── Message Handler ───────────────────────────────────
  void _onMessage(dynamic raw) {
    try {
      final msg = jsonDecode(raw.toString()) as Map<String, dynamic>;
      final type = msg['type'] as String?;
      final payload = msg['payload'] as Map<String, dynamic>?;

      switch (type) {
        case 'sos:created':
          if (payload != null) {
            _currentAlert = EvacuationAlert.fromJson(payload);
            _alertController.add(_currentAlert);
          }
          break;
        case 'sos:resolved':
          _currentAlert = null;
          _alertController.add(null);
          break;
        case 'pong':
          debugPrint('[WS] Pong ✓');
          break;
      }
    } catch (e) {
      debugPrint('[WS] Parse error: $e');
    }
  }

  void _onError(dynamic error) {
    debugPrint('[WS] Error: $error');
    _isConnected = false;
    _scheduleReconnect();
  }

  void _onDone() {
    debugPrint('[WS] Closed');
    _isConnected = false;
    if (_shouldConnect) _scheduleReconnect();
  }

  void _scheduleReconnect() {
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 5), _doConnect);
  }

  // ── Disconnect ────────────────────────────────────────
  void disconnect() {
    _shouldConnect = false;
    _pingTimer?.cancel();
    _reconnectTimer?.cancel();
    _channelSub?.cancel();
    _channel?.sink.close();
    _isConnected = false;
  }

  // ── Alert clear ───────────────────────────────────────
  void clearAlert() {
    _currentAlert = null;
    _alertController.add(null);
  }

  void _send(Map<String, dynamic> msg) {
    if (_isConnected && _channel != null) {
      try {
        _channel!.sink.add(jsonEncode(msg));
      } catch (_) {}
    }
  }

  void dispose() {
    disconnect();
    _alertController.close();
  }
}
