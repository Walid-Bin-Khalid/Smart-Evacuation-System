import 'dart:async';

//  Alert Model
//  Yeh wahi data hai jo real backend bhi bhejega
//  Baad mein sirf source change hoga, model same rahega
class EvacuationAlert {
  final String alertId;
  final String hazardNodeId; // graph node jahan hazard hai
  final String hazardType; // "fire" | "smoke" | "blocked" | "other"
  final String floor; // "Ground" | "First" | "Second"
  final String reportedBy; // employee ID jo alert bheja
  final DateTime timestamp;
  final bool isActive; // false = alert clear ho gaya

  const EvacuationAlert({
    required this.alertId,
    required this.hazardNodeId,
    required this.hazardType,
    required this.floor,
    required this.reportedBy,
    required this.timestamp,
    required this.isActive,
  });

  // Jab real backend aaye to fromJson bana lena:
  // factory EvacuationAlert.fromJson(Map<String, dynamic> json) { ... }
}

//  MockAlertService
//
//  Ab:   Fake alerts stream karta hai (test ke liye)
//  Baad: Is file ko delete karo, RealAlertService
//        (Firebase/WebSocket) same stream expose karega
//        — home_screen.dart mein koi change nahi hoga

class MockAlertService {
  // Singleton — poori app mein ek hi instance
  static final MockAlertService _instance = MockAlertService._internal();
  factory MockAlertService() => _instance;
  MockAlertService._internal();

  // Stream controller — alert broadcast karta hai
  final StreamController<EvacuationAlert?> _alertController =
      StreamController<EvacuationAlert?>.broadcast();

  // Current active alert (null = no alert = SAFE)
  EvacuationAlert? _currentAlert;

  //  Public stream  home_screen will listen from here
  Stream<EvacuationAlert?> get alertStream => _alertController.stream;

  //  Current alert getter 
  EvacuationAlert? get currentAlert => _currentAlert;

  // Is app SAFE or in DANGER? 
  bool get isEmergency => _currentAlert != null && _currentAlert!.isActive;

  //  TEST: Fake alert trigger karo
  //  Home screen ke test button se yeh call hoga
  void triggerMockAlert({
    String hazardNodeId = 'G_STAIRS',
    String hazardType = 'fire',
    String floor = 'Ground',
    String reportedBy = 'EMP-001',
  }) 
  
  {
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

  //  Alert clear karo (hazard resolved)
  void clearAlert() {
    _currentAlert = null;
    _alertController.add(null); // null = SAFE
  }

  //  Cleanup
  void dispose() {
    _alertController.close();
  }
}
