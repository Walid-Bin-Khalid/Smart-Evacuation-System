//  NavigationNode Model

//  EvacuationPath ke nodeIds ko UI-friendly
//  steps mein convert karta hai
class NavigationNode {
  final String nodeId;
  final String displayName; // "Room 4", "Corridor 3", "Stairs", "EXIT"
  final NavigationNodeType type;
  final double x;
  final double y;
  final String floor;
  final bool isExit;
  final bool isCurrentPosition;
  final bool isReached;

  const NavigationNode({
    required this.nodeId,
    required this.displayName,
    required this.type,
    required this.x,
    required this.y,
    required this.floor,
    this.isExit = false,
    this.isCurrentPosition = false,
    this.isReached = false,
  });

  // ── Build display name from node ID ──
  // e.g. "F1_R4_C" → "Room 4 (First Floor)"
  static String buildDisplayName(String nodeId) {
    if (nodeId.contains('EXIT')) {
      final num = nodeId.replaceAll(RegExp(r'[^0-9]'), '');
      return 'Exit $num';
    }
    if (nodeId.contains('STAIRS')) {
      final floor = _floorFromId(nodeId);
      return 'Stairs ($floor Floor)';
    }
    if (nodeId.contains('_R') && nodeId.endsWith('_C')) {
      final match = RegExp(r'_R(\d+)_C').firstMatch(nodeId);
      return 'Room ${match?.group(1) ?? ''}';
    }
    if (nodeId.contains('_C')) {
      final match = RegExp(r'_C(\d+)').firstMatch(nodeId);
      return 'Corridor ${match?.group(1) ?? ''}';
    }
    if (nodeId.contains('_D')) {
      final match = RegExp(r'_R(\d+)_D').firstMatch(nodeId);
      return 'Door (Room ${match?.group(1) ?? ''})';
    }
    return nodeId;
  }

  static String _floorFromId(String nodeId) {
    if (nodeId.startsWith('F2_')) return 'Second';
    if (nodeId.startsWith('F1_')) return 'First';
    return 'Ground';
  }

  // ── Build type from node ID ──
  static NavigationNodeType typeFromId(String nodeId) {
    if (nodeId.contains('EXIT')) return NavigationNodeType.exit;
    if (nodeId.contains('STAIRS')) return NavigationNodeType.stairs;
    if (nodeId.endsWith('_C')) return NavigationNodeType.room;
    if (nodeId.contains('_C')) return NavigationNodeType.corridor;
    if (nodeId.contains('_D')) return NavigationNodeType.door;
    return NavigationNodeType.generic;
  }

  NavigationNode copyWith({bool? isCurrentPosition, bool? isReached}) {
    return NavigationNode(
      nodeId: nodeId,
      displayName: displayName,
      type: type,
      x: x,
      y: y,
      floor: floor,
      isExit: isExit,
      isCurrentPosition: isCurrentPosition ?? this.isCurrentPosition,
      isReached: isReached ?? this.isReached,
    );
  }
}

enum NavigationNodeType { room, corridor, stairs, door, exit, generic }
