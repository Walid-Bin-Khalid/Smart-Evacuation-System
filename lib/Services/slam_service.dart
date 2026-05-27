import 'dart:async';
import 'dart:math';

import 'package:ar_flutter_plugin_2/datatypes/node_types.dart';
import 'package:ar_flutter_plugin_2/managers/ar_anchor_manager.dart';
import 'package:ar_flutter_plugin_2/managers/ar_location_manager.dart';
import 'package:ar_flutter_plugin_2/managers/ar_object_manager.dart';
import 'package:ar_flutter_plugin_2/managers/ar_session_manager.dart';

import 'package:ar_flutter_plugin_2/models/ar_anchor.dart';
import 'package:ar_flutter_plugin_2/models/ar_hittest_result.dart';
import 'package:ar_flutter_plugin_2/models/ar_node.dart';
import 'package:vector_math/vector_math_64.dart';

import '../Models/slam_pose.dart';


/// NOTE:
/// ar_flutter_plugin_2 does NOT expose full
/// camera pose APIs like native ARCore.

/// So we use:
/// Predefined graph navigation

/// AR calibrated positioning

/// This is enough for FYP-level
/// indoor AR navigation.

class SlamService {
  static final SlamService _instance = SlamService._internal();

  factory SlamService() => _instance;

  SlamService._internal();

  // MANAGERS
  ARSessionManager? _sessionManager;

  ARObjectManager? _objectManager;

  ARAnchorManager? _anchorManager;

  // STREAMS
  final StreamController<SlamPose> _poseController =
      StreamController<SlamPose>.broadcast();

  final StreamController<SlamTrackingState> _stateController =
      StreamController<SlamTrackingState>.broadcast();

  Stream<SlamPose> get poseStream => _poseController.stream;

  Stream<SlamTrackingState> get trackingStateStream => _stateController.stream;

  // STATE
  SlamTrackingState _trackingState = SlamTrackingState.initializing;

  SlamPose _currentPose = SlamPose.zero();

  bool _isSessionActive = false;

  SlamPose get currentPose => _currentPose;

  bool get isTracking => _trackingState == SlamTrackingState.tracking;

  // CALIBRATION
  double _floorY = 0.0;

  bool _isCalibrated = false;

  // POSE TRACKING
  double _lastX = 0;
  double _lastY = 0;
  double _lastZ = 0;

  final List<_RawPose> _poseHistory = [];

  static const int _smoothingWindow = 5;

  Timer? _poseTimer;

  // ARROW SYSTEM
  final List<ARNode> _activeArrowNodes = [];
  final List<ARAnchor> _activeArrowAnchors = [];
  List<Map<String, double>> _currentRoute = [];

  int _currentRouteIndex = 0;
  static const int _visibleArrowWindow = 3;
  bool _isUpdatingArrows = false;
  DateTime _lastArrowUpdate = DateTime.now();
  static const double _nodeReachThreshold = 1.2;

  // INITIALIZE
  Future<void> initialize({
    required ARSessionManager sessionManager,
    required ARObjectManager objectManager,
    required ARAnchorManager anchorManager,
    required ARLocationManager locationManager,
  }) async {
    _sessionManager = sessionManager;

    _objectManager = objectManager;

    _anchorManager = anchorManager;

    await _sessionManager!.onInitialize(
      showFeaturePoints: true,
      showPlanes: true,
      showWorldOrigin: false,
      handleTaps: true,
    );

    await _objectManager!.onInitialize();

    _sessionManager!.onPlaneOrPointTap = _onPlaneTapCalibration;

    _isSessionActive = true;

    _updateState(SlamTrackingState.initializing);

    _startPoseTimer();
  }

  // CALIBRATION
  void _onPlaneTapCalibration(List<ARHitTestResult> hits) {
    if (hits.isEmpty) return;

    final hit = hits.first;

    final transform = hit.worldTransform;

    final x = transform.getColumn(3).x;
    final y = transform.getColumn(3).y;
    final z = transform.getColumn(3).z;

    if (x.isNaN || y.isNaN || z.isNaN) {
      return;
    }

    _lastX = x;
    _lastY = y;
    _lastZ = z;

    if (!_isCalibrated) {
      _floorY = y;
    }

    _isCalibrated = true;

    _addPoseToHistory(x, y, z);

    _updateState(SlamTrackingState.tracking);
  }

  // POSE TIMER
  void _startPoseTimer() {
    _poseTimer?.cancel();

    _poseTimer = Timer.periodic(const Duration(milliseconds: 150), (_) async {
      if (!_isSessionActive) return;

      if (!_isCalibrated) return;

      final pose = _smoothedPose();

      _currentPose = pose;

      _poseController.add(pose);

      await _updateDynamicArrows();
    });
  }

  // POSE HISTORY
  void _addPoseToHistory(double x, double y, double z) {
    _poseHistory.add(_RawPose(x, y, z));

    if (_poseHistory.length > _smoothingWindow * 2) {
      _poseHistory.removeAt(0);
    }
  }

  // SMOOTHED POSE
  SlamPose _smoothedPose() {
    if (_poseHistory.isEmpty) {
      return SlamPose(
        x: _lastX,
        y: _lastY,
        z: _lastZ,
        rotationX: 0,
        rotationY: 0,
        rotationZ: 0,
        timestamp: DateTime.now(),
        trackingState: SlamTrackingState.tracking,
      );
    }

    final recent = _poseHistory.length > _smoothingWindow
        ? _poseHistory.sublist(_poseHistory.length - _smoothingWindow)
        : _poseHistory;

    final avgX = recent.map((e) => e.x).reduce((a, b) => a + b) / recent.length;

    final avgY = recent.map((e) => e.y).reduce((a, b) => a + b) / recent.length;

    final avgZ = recent.map((e) => e.z).reduce((a, b) => a + b) / recent.length;

    return SlamPose(
      x: avgX,
      y: avgY,
      z: avgZ,
      rotationX: 0,
      rotationY: 0,
      rotationZ: 0,
      timestamp: DateTime.now(),
      trackingState: SlamTrackingState.tracking,
    );
  }

  // SET ROUTE
  Future<void> setRoute({
    required List<Map<String, double>> routePoints,
  }) async {
    _currentRoute = routePoints;

    _currentRouteIndex = 0;

    await _updateVisibleArrows();
  }

  // DYNAMIC ROUTE UPDATING
  Future<void> _updateDynamicArrows() async {
    if (_currentRoute.isEmpty) return;

    if (_isUpdatingArrows) return;

    if (_currentRouteIndex >= _currentRoute.length - 1) {
      return;
    }

    final next = _currentRoute[_currentRouteIndex];

    final targetX = next['x'] ?? 0;
    final targetZ = next['z'] ?? 0;

    final dx = (_lastX - targetX);

    final dz = (_lastZ - targetZ);

    final distance = sqrt(dx * dx + dz * dz);

    if (distance < _nodeReachThreshold) {
      final now = DateTime.now();

      if (now.difference(_lastArrowUpdate).inMilliseconds < 1000) {
        return;
      }

      _lastArrowUpdate = now;

      _currentRouteIndex++;

      if (_currentRouteIndex < _currentRoute.length - 1) {
        _isUpdatingArrows = true;

        await _updateVisibleArrows();

        _isUpdatingArrows = false;
      }
    }
  }

  // VISIBLE ARROWS
  Future<void> _updateVisibleArrows() async {
    if (_isUpdatingArrows) return;

    await clearArrows();

    if (_currentRoute.length < 2) return;

    final start = _currentRouteIndex;

    final end = min(start + _visibleArrowWindow, _currentRoute.length - 1);

    for (int i = start; i < end; i++) {
      final current = _currentRoute[i];

      final next = _currentRoute[i + 1];

      final fromX = current['x'] ?? 0;
      final fromZ = current['z'] ?? 0;

      final toX = next['x'] ?? 0;
      final toZ = next['z'] ?? 0;

      final dx = toX - fromX;
      final dz = toZ - fromZ;

      final angle = atan2(dx, dz);

      final isExit = i == _currentRoute.length - 2;

      await _placeArrowAt(
        x: fromX,
        y: _floorY,
        z: fromZ,
        rotationAngle: angle,
        isExitArrow: isExit,
      );
    }
  }

  // OLD NAVIGATION SUPPORT
  Future<void> placeDirectionArrow({
    required double toGraphX,
    required double toGraphZ,
    required double scaleX,
    required double scaleZ,
  }) async {
    if (!_isCalibrated) return;

    final arTargetX = toGraphX / scaleX;

    final arTargetZ = toGraphZ / scaleZ;

    final dx = arTargetX - _lastX;

    final dz = arTargetZ - _lastZ;

    final angle = atan2(dx, dz);

    await clearArrows();

    final forwardDistance = 0.8;

    final arrowX = _lastX + sin(angle) * forwardDistance;

    final arrowZ = _lastZ + cos(angle) * forwardDistance;

    await _placeArrowAt(
      x: arrowX,
      y: _floorY,
      z: arrowZ,
      rotationAngle: angle,
      isExitArrow: false,
    );
  }

  // PLACE ARROW
  Future<void> _placeArrowAt({
    required double x,
    required double y,
    required double z,
    required double rotationAngle,
    required bool isExitArrow,
  }) async {
    try {
      final anchor = ARPlaneAnchor(
        transformation: Matrix4.translationValues(x, y, z),
      );

      final added = await _anchorManager?.addAnchor(anchor);

      if (added != true) return;

      _activeArrowAnchors.add(anchor);

      final node = ARNode(
        type: NodeType.localGLTF2,

        uri: isExitArrow ? 'models/exit_marker.glb' : 'models/arrow.glb',

        scale: Vector3.all(isExitArrow ? 0.45 : 0.28),

        position: Vector3(0, 0.03, 0),

        rotation: Vector4(0, 1, 0, rotationAngle),

        name: 'arrow_${DateTime.now().millisecondsSinceEpoch}',
      );

      final nodeAdded = await _objectManager?.addNode(
        node,
        planeAnchor: anchor,
      );

      if (nodeAdded == true) {
        _activeArrowNodes.add(node);
      }
    } catch (_) {}
  }

  // CLEAR ARROWS
  Future<void> clearArrows() async {
    for (final node in _activeArrowNodes) {
      try {
        await _objectManager?.removeNode(node);
      } catch (_) {}
    }

    for (final anchor in _activeArrowAnchors) {
      try {
        await _anchorManager?.removeAnchor(anchor);
      } catch (_) {}
    }

    _activeArrowNodes.clear();

    _activeArrowAnchors.clear();
  }

  // FLOOR DETECTION
  String detectCurrentFloor() {
    final y = _currentPose.y;

    if (y < 1.5) {
      return 'Ground';
    }

    if (y < 4.5) {
      return 'First';
    }

    return 'Second';
  }

  // STATE
  void _updateState(SlamTrackingState state) {
    if (_trackingState == state) return;

    _trackingState = state;

    _stateController.add(state);
  }

  // SESSION CONTROLS
  void pauseSession() {
    _poseTimer?.cancel();

    _isSessionActive = false;

    _updateState(SlamTrackingState.paused);
  }

  void resumeSession() {
    _isSessionActive = true;

    _startPoseTimer();

    _updateState(SlamTrackingState.initializing);
  }

  // RESET
  Future<void> reset() async {
    await clearArrows();

    _lastX = 0;
    _lastY = 0;
    _lastZ = 0;

    _floorY = 0;

    _isCalibrated = false;

    _currentRoute.clear();

    _currentRouteIndex = 0;

    _poseHistory.clear();

    _currentPose = SlamPose.zero();

    _updateState(SlamTrackingState.initializing);
  }

  // DISPOSE
  Future<void> dispose() async {
    _poseTimer?.cancel();

    await clearArrows();

    _sessionManager?.dispose();

    await _poseController.close();

    await _stateController.close();

    _currentRoute.clear();

    _poseHistory.clear();

    _isSessionActive = false;
  }
}

// INTERNAL POSE MODEL
class _RawPose {
  final double x;
  final double y;
  final double z;

  _RawPose(this.x, this.y, this.z);
}











































// import 'dart:async';
// import 'dart:math';

// // import 'package:ar_flutter_plugin_2/ar_flutter_plugin.dart';
// // import 'package:ar_flutter_plugin_2/datatypes/config_planedetection.dart';
// import 'package:ar_flutter_plugin_2/managers/ar_session_manager.dart';
// import 'package:ar_flutter_plugin_2/managers/ar_object_manager.dart';
// import 'package:ar_flutter_plugin_2/managers/ar_anchor_manager.dart';
// import 'package:ar_flutter_plugin_2/managers/ar_location_manager.dart';
// import 'package:ar_flutter_plugin_2/models/ar_hittest_result.dart';
// import 'package:ar_flutter_plugin_2/datatypes/node_types.dart';
// import 'package:ar_flutter_plugin_2/models/ar_node.dart';
// import 'package:ar_flutter_plugin_2/models/ar_anchor.dart';
// import 'package:vector_math/vector_math_64.dart';

// import '../Models/slam_pose.dart';

// // ─────────────────────────────────────────────
// //  SlamService
// //
// //  ar_flutter_plugin_2 actual API:
// //  - onARViewCreated → 4 managers milte hain
// //  - onPlaneOrPointTap → ARHitTestResult list
// //  - worldTransform Matrix4 → x,y,z position
// //  - ARNode + ARPlaneAnchor → AR objects place karo
// // ─────────────────────────────────────────────
// class SlamService {
//   static final SlamService _instance = SlamService._internal();
//   factory SlamService() => _instance;
//   SlamService._internal();

//   ARSessionManager? _sessionManager;
//   ARObjectManager? _objectManager;
//   ARAnchorManager? _anchorManager;

//   final StreamController<SlamPose> _poseController =
//       StreamController<SlamPose>.broadcast();
//   final StreamController<DetectedPlane> _planeController =
//       StreamController<DetectedPlane>.broadcast();
//   final StreamController<SlamTrackingState> _stateController =
//       StreamController<SlamTrackingState>.broadcast();

//   SlamPose _currentPose = SlamPose.zero();
//   SlamTrackingState _trackingState = SlamTrackingState.initializing;
//   bool _isSessionActive = false;
//   final List<DetectedPlane> _detectedPlanes = [];
//   final List<ARNode> _arrowNodes = [];

//   double _lastX = 0;
//   double _lastY = 0;
//   double _lastZ = 0;

//   Timer? _poseTimer;

//   Stream<SlamPose> get poseStream => _poseController.stream;
//   Stream<DetectedPlane> get planeStream => _planeController.stream;
//   Stream<SlamTrackingState> get trackingStateStream => _stateController.stream;

//   SlamPose get currentPose => _currentPose;
//   SlamTrackingState get trackingState => _trackingState;
//   bool get isSessionActive => _isSessionActive;
//   bool get isTracking => _trackingState == SlamTrackingState.tracking;
//   List<DetectedPlane> get detectedPlanes => List.unmodifiable(_detectedPlanes);

//   // ─────────────────────────────────────────────
//   //  INITIALIZE
//   //  ARView widget ke onARViewCreated mein call karo:
//   //
//   //  ARView(
//   //    onARViewCreated: (session, object, anchor, location) =>
//   //      SlamService().initialize(
//   //        sessionManager: session,
//   //        objectManager: object,
//   //        anchorManager: anchor,
//   //        locationManager: location,
//   //      ),
//   //    planeDetectionConfig:
//   //      PlaneDetectionConfig.horizontalAndVertical,
//   //  )
//   // ─────────────────────────────────────────────
//   Future<void> initialize({
//     required ARSessionManager sessionManager,
//     required ARObjectManager objectManager,
//     required ARAnchorManager anchorManager,
//     required ARLocationManager locationManager,
//   }) async {
//     _sessionManager = sessionManager;
//     _objectManager = objectManager;
//     _anchorManager = anchorManager;

//     await _sessionManager!.onInitialize(
//       showFeaturePoints: true,
//       showPlanes: true,
//       showWorldOrigin: false,
//       handleTaps: true,
//     );

//     await _objectManager!.onInitialize();

//     // Tap callback — real world hit test results
//     _sessionManager!.onPlaneOrPointTap = _onHitTestResult;

//     _isSessionActive = true;
//     _updateState(SlamTrackingState.initializing);
//     _startPoseTimer();
//   }

//   // ─────────────────────────────────────────────
//   //  POSE TIMER
//   //  Har 500ms last known position broadcast karo
//   //  New position tab milti hai jab user move kare
//   //  aur onPlaneOrPointTap fire ho
//   // ─────────────────────────────────────────────
//   void _startPoseTimer() {
//     _poseTimer?.cancel();
//     _poseTimer = Timer.periodic(const Duration(milliseconds: 500), (_) {
//       if (!_isSessionActive) return;
//       if (_trackingState != SlamTrackingState.tracking) return;

//       final pose = SlamPose(
//         x: _lastX,
//         y: _lastY,
//         z: _lastZ,
//         rotationX: 0,
//         rotationY: 0,
//         rotationZ: 0,
//         timestamp: DateTime.now(),
//         trackingState: SlamTrackingState.tracking,
//       );
//       _currentPose = pose;
//       _poseController.add(pose);
//     });
//   }

//   // ─────────────────────────────────────────────
//   //  HIT TEST RESULT
//   //  onPlaneOrPointTap callback
//   //  → real world x,y,z milta hai ARCore se
//   // ─────────────────────────────────────────────
//   void _onHitTestResult(List<ARHitTestResult> hits) {
//     if (hits.isEmpty) return;

//     final hit = hits.first;
//     final transform = hit.worldTransform;

//     _lastX = transform.getColumn(3).x;
//     _lastY = transform.getColumn(3).y;
//     _lastZ = transform.getColumn(3).z;

//     final plane = DetectedPlane(
//       id: 'plane_${DateTime.now().millisecondsSinceEpoch}',
//       type: PlaneType.horizontal,
//       centerX: _lastX,
//       centerY: _lastY,
//       centerZ: _lastZ,
//       width: 1.0,
//       height: 1.0,
//     );

//     _detectedPlanes.add(plane);
//     _planeController.add(plane);

//     final pose = SlamPose(
//       x: _lastX,
//       y: _lastY,
//       z: _lastZ,
//       rotationX: 0,
//       rotationY: 0,
//       rotationZ: 0,
//       timestamp: DateTime.now(),
//       trackingState: SlamTrackingState.tracking,
//     );

//     _currentPose = pose;
//     _updateState(SlamTrackingState.tracking);
//     _poseController.add(pose);
//   }

//   // ─────────────────────────────────────────────
//   //  FLOOR DETECTION from y coordinate
//   //  ARCore y = vertical axis (meters)
//   //  Ground < 1.5m, First 1.5-4.5m, Second > 4.5m
//   // ─────────────────────────────────────────────
//   String detectCurrentFloor() {
//     final y = _currentPose.y;
//     if (y < 1.5) return 'Ground';
//     if (y < 4.5) return 'First';
//     return 'Second';
//   }

//   // ─────────────────────────────────────────────
//   //  PLACE DIRECTION ARROW
//   //  Next evacuation node ki taraf AR arrow place karo
//   // ─────────────────────────────────────────────
//   Future<void> placeDirectionArrow({
//     required double toGraphX,
//     required double toGraphZ,
//     required double scaleX,
//     required double scaleZ,
//   }) async {
//     if (_objectManager == null || _anchorManager == null) return;

//     // Graph coords → ARCore coords
//     final arTargetX = (toGraphX / scaleX);
//     final arTargetZ = (toGraphZ / scaleZ);

//     // Direction angle
//     final angle = atan2(arTargetX - _lastX, arTargetZ - _lastZ);

//     try {
//       final anchor = ARPlaneAnchor(
//         transformation: Matrix4.translation(Vector3(_lastX, _lastY, _lastZ)),
//       );

//       final added = await _anchorManager!.addAnchor(anchor);
//       if (added != true) return;

//       final arrowNode = ARNode(
//         type: NodeType.webGLB,
//         uri:
//             'https://raw.githubusercontent.com/KhronosGroup/'
//             'glTF-Sample-Models/master/2.0/Arrow/glTF-Binary/Arrow.glb',
//         scale: Vector3(0.15, 0.15, 0.15),
//         position: Vector3(0, 0, 0),
//         rotation: Vector4(0, 1, 0, angle),
//         name: 'arrow_${DateTime.now().millisecondsSinceEpoch}',
//       );

//       final nodeAdded = await _objectManager!.addNode(
//         arrowNode,
//         planeAnchor: anchor,
//       );

//       if (nodeAdded == true) {
//         _arrowNodes.add(arrowNode);
//       }
//     } catch (_) {
//       // Arrow placement failed — non critical
//     }
//   }

//   // ── Clear all AR arrows ──
//   Future<void> clearArrows() async {
//     for (final node in _arrowNodes) {
//       await _objectManager?.removeNode(node);
//     }
//     _arrowNodes.clear();
//   }

//   void _updateState(SlamTrackingState state) {
//     if (_trackingState == state) return;
//     _trackingState = state;
//     _stateController.add(state);
//   }

//   void pauseSession() {
//     _poseTimer?.cancel();
//     _updateState(SlamTrackingState.paused);
//     _isSessionActive = false;
//   }

//   void resumeSession() {
//     _isSessionActive = true;
//     _updateState(SlamTrackingState.initializing);
//     _startPoseTimer();
//   }

//   void dispose() {
//     _poseTimer?.cancel();
//     _sessionManager?.dispose();
//     _poseController.close();
//     _planeController.close();
//     _stateController.close();
//     _isSessionActive = false;
//     _detectedPlanes.clear();
//     _arrowNodes.clear();
//   }

//   void reset() {
//     _lastX = 0;
//     _lastY = 0;
//     _lastZ = 0;
//     _currentPose = SlamPose.zero();
//     _trackingState = SlamTrackingState.initializing;
//     _detectedPlanes.clear();
//     _arrowNodes.clear();
//   }
// }
