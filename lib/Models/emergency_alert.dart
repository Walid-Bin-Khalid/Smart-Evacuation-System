//  EmergencyAlert Model

//  Abhi: MockAlertService se aata hai
//  Baad: Firebase/WebSocket se real-time aayega
//  fromJson() use hoga tab

class EmergencyAlert {
  final String alertId;
  final String hazardNodeId; // blocked graph node
  final String hazardType; // "fire" | "smoke" | "blocked" | "other"
  final String floor; // "Ground" | "First" | "Second"
  final String reportedBy; // employee ID
  final String message; // optional description
  final DateTime timestamp;
  final bool isActive;
  final AlertSeverity severity;

  const EmergencyAlert({
    required this.alertId,
    required this.hazardNodeId,
    required this.hazardType,
    required this.floor,
    required this.reportedBy,
    this.message = '',
    required this.timestamp,
    required this.isActive,
    this.severity = AlertSeverity.high,
  });

  // ── JSON parsing — real backend ke liye ready ──
  factory EmergencyAlert.fromJson(Map<String, dynamic> json) {
    return EmergencyAlert(
      alertId: json['alert_id'] ?? '',
      hazardNodeId: json['hazard_node_id'] ?? '',
      hazardType: json['hazard_type'] ?? 'unknown',
      floor: json['floor'] ?? 'Ground',
      reportedBy: json['reported_by'] ?? '',
      message: json['message'] ?? '',
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'])
          : DateTime.now(),
      isActive: json['is_active'] ?? true,
      severity: AlertSeverity.values.firstWhere(
        (s) => s.name == (json['severity'] ?? 'high'),
        orElse: () => AlertSeverity.high,
      ),
    );
  }

  Map<String, dynamic> toJson() => {
    'alert_id': alertId,
    'hazard_node_id': hazardNodeId,
    'hazard_type': hazardType,
    'floor': floor,
    'reported_by': reportedBy,
    'message': message,
    'timestamp': timestamp.toIso8601String(),
    'is_active': isActive,
    'severity': severity.name,
  };

  // Copy with isActive changed (for clearing alert)
  EmergencyAlert copyWith({bool? isActive}) {
    return EmergencyAlert(
      alertId: alertId,
      hazardNodeId: hazardNodeId,
      hazardType: hazardType,
      floor: floor,
      reportedBy: reportedBy,
      message: message,
      timestamp: timestamp,
      isActive: isActive ?? this.isActive,
      severity: severity,
    );
  }
}

enum AlertSeverity { low, medium, high, critical }
