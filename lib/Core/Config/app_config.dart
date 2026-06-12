//  Har dafa IP change karna ho → sirf _localIp update karo.

class AppConfig {
  //  🔧 YAHAN SIRF YEH EK LINE CHANGE KARO
  //  Apne laptop/PC ka WiFi IP dalo.
  //  Kaise pata karo:
  //    Windows → cmd mein:  ipconfig
  //    Mac/Linux → terminal: ifconfig | grep "inet "
  //
  //  Example: '192.168.1.105'
  static const String _localIp = '192.168.18.74'; // ← SIRF YEH BADLO

  // ── Port (backend ka) ─────────────────────────────────
  static const int _port = 3001;

  // ════════════════════════════════════════════════════════
  //  AUTO-SELECT — in ko mat chhuona
  // ════════════════════════════════════════════════════════

  /// HTTP base URL — ApiService mein use hota hai
  static String get baseUrl => 'http://$_localIp:$_port/v1';

  /// WebSocket URL — WebSocketService mein use hota hai
  static String get wsUrl => 'ws://$_localIp:$_port/ws';

  // ── Info ──────────────────────────────────────────────
  static void printConfig() {
    // ignore: avoid_print
    print('════════════════════════════════════');
    // ignore: avoid_print
    print('  API URL : $baseUrl');
    // ignore: avoid_print
    print('  WS  URL : $wsUrl');
    // ignore: avoid_print
    print('════════════════════════════════════');
  }
}
