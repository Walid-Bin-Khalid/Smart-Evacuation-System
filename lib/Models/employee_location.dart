//  EmployeeLocation Model

//  Form se milta hai (slam_initialization_screen)
//  → pathfinding_service mein node ID resolve karne ke liye

class EmployeeLocation {
  final String employeeId;
  final String floor;
  final String areaType;
  final String roomNumber;
  final String? hazardDetails;
  final DateTime capturedAt;

  const EmployeeLocation({
    required this.employeeId,
    required this.floor,
    required this.areaType,
    required this.roomNumber,
    this.hazardDetails,
    required this.capturedAt,
  });

  // ── Derived: node ID from location ──
  // e.g. First + room + 4 → F1_R4_C
  String get resolvedNodeId {
    final prefix = _floorPrefix(floor);
    final number = roomNumber.trim().replaceAll(RegExp(r'^0+'), '');

    switch (areaType.toLowerCase()) {
      case 'room':
        return '${prefix}_R${number}_C';
      case 'corridor':
        return '${prefix}_C$number';
      case 'stairs':
        return '${prefix}_STAIRS';
      case 'door':
        return '${prefix}_R${number}_D1';
      default:
        return '${prefix}_${number.toUpperCase()}';
    }
  }

  String _floorPrefix(String floor) {
    switch (floor.toLowerCase()) {
      case 'ground':
        return 'G';
      case 'first':
        return 'F1';
      case 'second':
        return 'F2';
      default:
        return floor.toUpperCase();
    }
  }

  factory EmployeeLocation.fromJson(Map<String, dynamic> json) {
    return EmployeeLocation(
      employeeId: json['employee_id'] ?? '',
      floor: json['floor'] ?? 'Ground',
      areaType: json['area_type'] ?? 'room',
      roomNumber: json['room_number'] ?? '',
      hazardDetails: json['hazard_details'],
      capturedAt: json['captured_at'] != null
          ? DateTime.parse(json['captured_at'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
    'employee_id': employeeId,
    'floor': floor,
    'area_type': areaType,
    'room_number': roomNumber,
    'hazard_details': hazardDetails,
    'captured_at': capturedAt.toIso8601String(),
    'resolved_node_id': resolvedNodeId,
  };
}
