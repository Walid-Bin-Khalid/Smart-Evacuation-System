import '../Data/building_graph.dart';
import '../Models/slam_pose.dart';

//  CoordinateMapper:
//  ARCore coords (0,0,0) → Building graph coords
class CoordinateMapper {
  final BuildingGraph graph;

  bool _isCalibrated = false;

  double _originArX = 0;
  double _originArZ = 0;
  double _originGraphX = 0;
  double _originGraphY = 0;
  double _scaleX = 100.0;
  double _scaleZ = 100.0;

  double get scaleX => _scaleX;
  double get scaleZ => _scaleZ;

  late final Map<String, GraphNode> _nodeMap;

  CoordinateMapper(this.graph) {
    _nodeMap = {for (final n in graph.nodes) n.id: n};
  }

  bool get isCalibrated => _isCalibrated;

  // ── Single point calibration ──
  bool calibrate({required String knownNodeId, required SlamPose currentPose}) {
    final node = _nodeMap[knownNodeId];
    if (node == null) return false;

    _originArX = currentPose.x;
    _originArZ = currentPose.z;
    _originGraphX = node.x;
    _originGraphY = node.y;
    _isCalibrated = true;
    return true;
  }

  // ── Two point calibration (more accurate) ──
  bool calibrateWithTwoPoints({
    required String node1Id,
    required SlamPose pose1,
    required String node2Id,
    required SlamPose pose2,
  }) {
    final n1 = _nodeMap[node1Id];
    final n2 = _nodeMap[node2Id];
    if (n1 == null || n2 == null) return false;

    final arDeltaX = (pose2.x - pose1.x).abs();
    final arDeltaZ = (pose2.z - pose1.z).abs();
    final graphDeltaX = (n2.x - n1.x).abs();
    final graphDeltaY = (n2.y - n1.y).abs();

    if (arDeltaX > 0.1) {
      _scaleX = graphDeltaX / arDeltaX;
    }
    if (arDeltaZ > 0.1) {
      _scaleZ = graphDeltaY / arDeltaZ;
    }

    _originArX = pose1.x;
    _originArZ = pose1.z;
    _originGraphX = n1.x;
    _originGraphY = n1.y;
    _isCalibrated = true;
    return true;
  }

  // ── ARCore pose → graph coordinates ──
  Map<String, double> poseToGraphCoords(SlamPose pose) {
    if (!_isCalibrated) return {'x': 0, 'y': 0};

    final graphX = _originGraphX + ((pose.x - _originArX) * _scaleX);
    final graphY = _originGraphY + ((pose.z - _originArZ) * _scaleZ);

    return {'x': graphX, 'y': graphY};
  }

  // ── Find nearest graph node to current pose ──
  String? nearestNodeToPose(SlamPose pose, {String? floor}) {
    if (!_isCalibrated) return null;

    final coords = poseToGraphCoords(pose);
    final targetX = coords['x']!;
    final targetY = coords['y']!;

    String? nearestId;
    double nearestDist = double.infinity;

    for (final node in graph.nodes) {
      if (floor != null && node.floor.toLowerCase() != floor.toLowerCase()) {
        continue;
      }

      final dx = node.x - targetX;
      final dy = node.y - targetY;
      final dist = dx * dx + dy * dy;

      if (dist < nearestDist) {
        nearestDist = dist;
        nearestId = node.id;
      }
    }

    return nearestId;
  }

  // ── Crowd poses → graph coords for pathfinding ──
  List<Map<String, double>> posesToGraphCoords(List<SlamPose> poses) {
    return poses
        .where((p) => p.trackingState == SlamTrackingState.tracking)
        .map(poseToGraphCoords)
        .toList();
  }

  // ── Graph coords → ARCore coords (reverse of poseToGraphCoords) ──
  Map<String, double> graphToArCoords({
    required double graphX,
    required double graphY,
  }) {
    if (!_isCalibrated) return {'x': 0, 'z': 0};

    final arX = _originArX + (graphX - _originGraphX) / _scaleX;
    final arZ = _originArZ + (graphY - _originGraphY) / _scaleZ;

    return {'x': arX, 'z': arZ};
  }

  void reset() {
    _isCalibrated = false;
    _originArX = 0;
    _originArZ = 0;
    _originGraphX = 0;
    _originGraphY = 0;
  }
}


























// import '../Data/building_graph.dart';
// import '../Models/slam_pose.dart';

// // ─────────────────────────────────────────────
// //  CoordinateMapper
// //  ARCore coords (0,0,0) → Building graph coords
// // ─────────────────────────────────────────────
// class CoordinateMapper {
//   final BuildingGraph graph;

//   bool _isCalibrated = false;

//   double _originArX = 0;
//   double _originArZ = 0;
//   double _originGraphX = 0;
//   double _originGraphY = 0;
//   double _scaleX = 100.0;
//   double _scaleZ = 100.0;

//   double get scaleX => _scaleX;
//   double get scaleZ => _scaleZ;

//   late final Map<String, GraphNode> _nodeMap;

//   CoordinateMapper(this.graph) {
//     _nodeMap = {for (final n in graph.nodes) n.id: n};
//   }

//   bool get isCalibrated => _isCalibrated;

//   // ── Single point calibration ──
//   bool calibrate({required String knownNodeId, required SlamPose currentPose}) {
//     final node = _nodeMap[knownNodeId];
//     if (node == null) return false;

//     _originArX = currentPose.x;
//     _originArZ = currentPose.z;
//     _originGraphX = node.x;
//     _originGraphY = node.y;
//     _isCalibrated = true;
//     return true;
//   }

//   // ── Two point calibration (more accurate) ──
//   bool calibrateWithTwoPoints({
//     required String node1Id,
//     required SlamPose pose1,
//     required String node2Id,
//     required SlamPose pose2,
//   }) {
//     final n1 = _nodeMap[node1Id];
//     final n2 = _nodeMap[node2Id];
//     if (n1 == null || n2 == null) return false;

//     final arDeltaX = (pose2.x - pose1.x).abs();
//     final arDeltaZ = (pose2.z - pose1.z).abs();
//     final graphDeltaX = (n2.x - n1.x).abs();
//     final graphDeltaY = (n2.y - n1.y).abs();

//     if (arDeltaX > 0.1) {
//       _scaleX = graphDeltaX / arDeltaX;
//     }
//     if (arDeltaZ > 0.1) {
//       _scaleZ = graphDeltaY / arDeltaZ;
//     }

//     _originArX = pose1.x;
//     _originArZ = pose1.z;
//     _originGraphX = n1.x;
//     _originGraphY = n1.y;
//     _isCalibrated = true;
//     return true;
//   }

//   // ── ARCore pose → graph coordinates ──
//   Map<String, double> poseToGraphCoords(SlamPose pose) {
//     if (!_isCalibrated) return {'x': 0, 'y': 0};

//     final graphX = _originGraphX + ((pose.x - _originArX) * _scaleX);
//     final graphY = _originGraphY + ((pose.z - _originArZ) * _scaleZ);

//     return {'x': graphX, 'y': graphY};
//   }

//   // ── Find nearest graph node to current pose ──
//   String? nearestNodeToPose(SlamPose pose, {String? floor}) {
//     if (!_isCalibrated) return null;

//     final coords = poseToGraphCoords(pose);
//     final targetX = coords['x']!;
//     final targetY = coords['y']!;

//     String? nearestId;
//     double nearestDist = double.infinity;

//     for (final node in graph.nodes) {
//       if (floor != null && node.floor.toLowerCase() != floor.toLowerCase()) {
//         continue;
//       }

//       final dx = node.x - targetX;
//       final dy = node.y - targetY;
//       final dist = dx * dx + dy * dy;

//       if (dist < nearestDist) {
//         nearestDist = dist;
//         nearestId = node.id;
//       }
//     }

//     return nearestId;
//   }

//   // ── Crowd poses → graph coords for pathfinding ──
//   List<Map<String, double>> posesToGraphCoords(List<SlamPose> poses) {
//     return poses
//         .where((p) => p.trackingState == SlamTrackingState.tracking)
//         .map(poseToGraphCoords)
//         .toList();
//   }

//   void reset() {
//     _isCalibrated = false;
//     _originArX = 0;
//     _originArZ = 0;
//     _originGraphX = 0;
//     _originGraphY = 0;
//   }
// }
