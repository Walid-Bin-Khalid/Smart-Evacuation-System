// ══════════════════════════════════════════════════════════════
//  lib/Services/websocket_service.dart
//
//  MockAlertService ki jagah yeh use hoga.
//  Backend ke /ws endpoint se real-time alerts receive karta hai.
//  Home screen mein sirf ek line change hogi:
//    MockAlertService() → WebSocketService()
// ══════════════════════════════════════════════════════════════

import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ── Alert Model (same as EvacuationAlert in mock_alert_service) ──
// Home screen ka koi code nahi badlega — same fields hain
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
  // MongoDB _id — resolve API call ke liye
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

  // Backend se aane wale JSON ko parse karo
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

// ══════════════════════════════════════════════════════════════
//  WebSocketService
//  home_screen.dart mein MockAlertService() ki jagah use karo
// ══════════════════════════════════════════════════════════════
class WebSocketService {
  // ── Singleton ────────────────────────────────────────────
  static final WebSocketService _instance = WebSocketService._internal();
  factory WebSocketService() => _instance;
  WebSocketService._internal();

  // ── WS URL — ApiService ke baseUrl se match karo ────────
  // Android emulator: ws://10.0.2.2:3001/ws
  // Real device:      ws://192.168.1.100:3001/ws
  static const String _wsBaseUrl = 'ws://10.0.2.2:3001/ws';

  WebSocketChannel? _channel;
  StreamSubscription? _channelSub;
  Timer? _reconnectTimer;
  Timer? _pingTimer;

  bool _isConnected = false;
  bool _shouldConnect = true; // false hone pe reconnect band

  // ── Alert Stream Controller ──────────────────────────────
  final StreamController<EvacuationAlert?> _alertController =
      StreamController<EvacuationAlert?>.broadcast();

  EvacuationAlert? _currentAlert;

  // ── Public API (same as MockAlertService) ────────────────
  Stream<EvacuationAlert?> get alertStream => _alertController.stream;
  EvacuationAlert? get currentAlert => _currentAlert;
  bool get isEmergency => _currentAlert != null && _currentAlert!.isActive;
  bool get isConnected => _isConnected;

  // ══════════════════════════════════════════════════════════
  //  Connect
  // ══════════════════════════════════════════════════════════
  Future<void> connect() async {
    _shouldConnect = true;
    await _doConnect();
  }

  Future<void> _doConnect() async {
    if (!_shouldConnect) return;

    // Token lo — JWT se role/employeeId identify hota hai server pe
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token') ?? '';

    final uri = Uri.parse(
      token.isNotEmpty ? '$_wsBaseUrl?token=$token' : _wsBaseUrl,
    );

    try {
      _channel = WebSocketChannel.connect(uri);
      await _channel!.ready;

      _isConnected = true;
      debugPrint('[WS] Connected to $_wsBaseUrl');

      // Messages sun
      _channelSub = _channel!.stream.listen(
        _onMessage,
        onError: _onError,
        onDone: _onDone,
      );

      // Ping har 30 second
      _pingTimer?.cancel();
      _pingTimer = Timer.periodic(const Duration(seconds: 30), (_) {
        _send({'type': 'ping'});
      });
    } catch (e) {
      debugPrint('[WS] Connection failed: $e');
      _isConnected = false;
      _scheduleReconnect();
    }
  }

  // ══════════════════════════════════════════════════════════
  //  Message Handler
  // ══════════════════════════════════════════════════════════
  void _onMessage(dynamic raw) {
    try {
      final msg = jsonDecode(raw.toString()) as Map<String, dynamic>;
      final type = msg['type'] as String?;
      final payload = msg['payload'] as Map<String, dynamic>?;

      debugPrint('[WS] Received: $type');

      switch (type) {
        // ── Naya SOS alert aya ──
        case 'sos:created':
          if (payload != null) {
            _currentAlert = EvacuationAlert.fromJson(payload);
            _alertController.add(_currentAlert);
          }
          break;

        // ── Alert resolve ho gaya ──
        case 'sos:resolved':
          _currentAlert = null;
          _alertController.add(null);
          break;

        // ── Employee location update (future use) ──
        case 'employee:location':
        case 'employee:status':
          // Admin panel ke liye — abhi ignore
          break;

        // ── Server pong reply ──
        case 'pong':
          debugPrint('[WS] Pong received');
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
    debugPrint('[WS] Connection closed');
    _isConnected = false;
    if (_shouldConnect) _scheduleReconnect();
  }

  // ══════════════════════════════════════════════════════════
  //  Reconnect logic — 5 second baad try karo
  // ══════════════════════════════════════════════════════════
  void _scheduleReconnect() {
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 5), () {
      debugPrint('[WS] Reconnecting...');
      _doConnect();
    });
  }

  // ══════════════════════════════════════════════════════════
  //  Disconnect (logout pe call karo)
  // ══════════════════════════════════════════════════════════
  void disconnect() {
    _shouldConnect = false;
    _pingTimer?.cancel();
    _reconnectTimer?.cancel();
    _channelSub?.cancel();
    _channel?.sink.close();
    _isConnected = false;
    debugPrint('[WS] Disconnected');
  }

  // ══════════════════════════════════════════════════════════
  //  TEST: Mock alert trigger (debug only)
  //  Home screen ka bug_report button same kaam karega
  // ══════════════════════════════════════════════════════════
  void triggerMockAlert({
    String hazardNodeId = 'G_STAIRS',
    String hazardType = 'fire',
    String floor = 'Ground',
    String reportedBy = 'TEST-001',
  }) {
    _currentAlert = EvacuationAlert(
      alertId: 'MOCK-${DateTime.now().millisecondsSinceEpoch}',
      hazardNodeId: hazardNodeId,
      hazardType: hazardType,
      floor: floor,
      reportedBy: reportedBy,
      timestamp: DateTime.now(),
      isActive: true,
    );
    _alertController.add(_currentAlert);
  }

  // ── Alert manually clear karo (test) ──
  void clearAlert() {
    _currentAlert = null;
    _alertController.add(null);
  }

  // ── Send message ──────────────────────────────────────────
  void _send(Map<String, dynamic> msg) {
    if (_isConnected && _channel != null) {
      try {
        _channel!.sink.add(jsonEncode(msg));
      } catch (_) {}
    }
  }

  // ── Cleanup ──────────────────────────────────────────────
  void dispose() {
    disconnect();
    _alertController.close();
  }
}
