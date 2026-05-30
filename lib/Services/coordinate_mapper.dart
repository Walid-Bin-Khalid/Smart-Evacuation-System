import '../Data/building_graph.dart';
import '../Models/slam_pose.dart';

// CoordinateMapper
// ARCore world coords (meters) ↔ Building graph coords (arbitrary units)
//
// FIX 5 — SCALE PROBLEM:
// Old code had _scaleX = _scaleZ = 100.0 hardcoded.
// This meant graph coord 100 mapped to 1 meter in ARCore.
// If your building_graph.json uses different units (e.g. 0–10 range),
// arrows would spawn 100x too far away.
//
// SOLUTION: Auto-detect scale from graph bounding box.
// On calibration, we measure graph extent and assume building is ~30m wide.
// This gives a much better default than hardcoded 100.
//
// For perfect accuracy: call calibrateWithTwoPoints() using two known
// physical landmarks in the building (e.g. two door corners).
class CoordinateMapper {
  final BuildingGraph graph;

  bool _isCalibrated = false;

  double _originArX = 0;
  double _originArZ = 0;
  double _originGraphX = 0;
  double _originGraphY = 0;

  // FIX 5: Scale computed from graph bounding box instead of hardcoded 100
  double _scaleX = 1.0;
  double _scaleZ = 1.0;

  double get scaleX => _scaleX;
  double get scaleZ => _scaleZ;
  bool get isCalibrated => _isCalibrated;

  late final Map<String, GraphNode> _nodeMap;

  CoordinateMapper(this.graph) {
    _nodeMap = {for (final n in graph.nodes) n.id: n};
    // FIX 5: Compute scale from graph extent at construction
    _computeDefaultScale();
  }

  // FIX 5: Auto-compute scale from graph node bounding box
  // Assumes the building is approximately 30m in real world.
  // Adjust _assumedBuildingMeters to match your actual building size.
  void _computeDefaultScale() {
    if (graph.nodes.isEmpty) return;

    const double assumedBuildingMeters = 30.0;

    double minX = double.infinity, maxX = double.negativeInfinity;
    double minY = double.infinity, maxY = double.negativeInfinity;

    for (final node in graph.nodes) {
      if (node.x < minX) minX = node.x;
      if (node.x > maxX) maxX = node.x;
      if (node.y < minY) minY = node.y;
      if (node.y > maxY) maxY = node.y;
    }

    final graphWidth = maxX - minX;
    final graphHeight = maxY - minY;

    // Avoid division by zero
    if (graphWidth > 0) {
      _scaleX = graphWidth / assumedBuildingMeters;
    }
    if (graphHeight > 0) {
      _scaleZ = graphHeight / assumedBuildingMeters;
    }
  }

  // Single point calibration
  // Sets origin (where ARCore 0,0 maps to in graph space)
  // Scale remains from _computeDefaultScale()
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

  // Two-point calibration — use this for best accuracy
  // Walk to two known positions in the building and tap each one
  // node1Id, node2Id: IDs from building_graph.json
  // pose1, pose2: ARCore positions when you tapped those spots
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

    // Only update scale if movement was large enough to be reliable (> 10cm)
    if (arDeltaX > 0.1 && graphDeltaX > 0) {
      _scaleX = graphDeltaX / arDeltaX;
    }
    if (arDeltaZ > 0.1 && graphDeltaY > 0) {
      _scaleZ = graphDeltaY / arDeltaZ;
    }

    _originArX = pose1.x;
    _originArZ = pose1.z;
    _originGraphX = n1.x;
    _originGraphY = n1.y;
    _isCalibrated = true;
    return true;
  }

  // ARCore pose → graph coordinates
  Map<String, double> poseToGraphCoords(SlamPose pose) {
    if (!_isCalibrated) return {'x': 0, 'y': 0};

    final graphX = _originGraphX + ((pose.x - _originArX) * _scaleX);
    final graphY = _originGraphY + ((pose.z - _originArZ) * _scaleZ);

    return {'x': graphX, 'y': graphY};
  }

  // Graph coords → ARCore coords (used by arrow placement)
  Map<String, double> graphToArCoords({
    required double graphX,
    required double graphY,
  }) {
    if (!_isCalibrated) return {'x': 0, 'z': 0};

    final arX = _originArX + (graphX - _originGraphX) / _scaleX;
    final arZ = _originArZ + (graphY - _originGraphY) / _scaleZ;

    return {'x': arX, 'z': arZ};
  }

  // Find nearest graph node to a given pose
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

  List<Map<String, double>> posesToGraphCoords(List<SlamPose> poses) {
    return poses
        .where((p) => p.trackingState == SlamTrackingState.tracking)
        .map(poseToGraphCoords)
        .toList();
  }

  void reset() {
    _isCalibrated = false;
    _originArX = 0;
    _originArZ = 0;
    _originGraphX = 0;
    _originGraphY = 0;
    // Recompute default scale on reset
    _computeDefaultScale();
  }
}


