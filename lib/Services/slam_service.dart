import 'dart:async';
import 'dart:math';

// import 'package:ar_flutter_plugin_2/ar_flutter_plugin.dart';
// import 'package:ar_flutter_plugin_2/datatypes/config_planedetection.dart';
import 'package:ar_flutter_plugin_2/managers/ar_session_manager.dart';
import 'package:ar_flutter_plugin_2/managers/ar_object_manager.dart';
import 'package:ar_flutter_plugin_2/managers/ar_anchor_manager.dart';
import 'package:ar_flutter_plugin_2/managers/ar_location_manager.dart';
import 'package:ar_flutter_plugin_2/models/ar_hittest_result.dart';
import 'package:ar_flutter_plugin_2/datatypes/node_types.dart';
import 'package:ar_flutter_plugin_2/models/ar_node.dart';
import 'package:ar_flutter_plugin_2/models/ar_anchor.dart';
import 'package:vector_math/vector_math_64.dart';

import '../Models/slam_pose.dart';

// ─────────────────────────────────────────────
//  SlamService
//
//  ar_flutter_plugin_2 actual API:
//  - onARViewCreated → 4 managers milte hain
//  - onPlaneOrPointTap → ARHitTestResult list
//  - worldTransform Matrix4 → x,y,z position
//  - ARNode + ARPlaneAnchor → AR objects place karo
// ─────────────────────────────────────────────
class SlamService {
  static final SlamService _instance = SlamService._internal();
  factory SlamService() => _instance;
  SlamService._internal();

  ARSessionManager? _sessionManager;
  ARObjectManager? _objectManager;
  ARAnchorManager? _anchorManager;

  final StreamController<SlamPose> _poseController =
      StreamController<SlamPose>.broadcast();
  final StreamController<DetectedPlane> _planeController =
      StreamController<DetectedPlane>.broadcast();
  final StreamController<SlamTrackingState> _stateController =
      StreamController<SlamTrackingState>.broadcast();

  SlamPose _currentPose = SlamPose.zero();
  SlamTrackingState _trackingState = SlamTrackingState.initializing;
  bool _isSessionActive = false;
  final List<DetectedPlane> _detectedPlanes = [];
  final List<ARNode> _arrowNodes = [];

  double _lastX = 0;
  double _lastY = 0;
  double _lastZ = 0;

  Timer? _poseTimer;

  Stream<SlamPose> get poseStream => _poseController.stream;
  Stream<DetectedPlane> get planeStream => _planeController.stream;
  Stream<SlamTrackingState> get trackingStateStream => _stateController.stream;

  SlamPose get currentPose => _currentPose;
  SlamTrackingState get trackingState => _trackingState;
  bool get isSessionActive => _isSessionActive;
  bool get isTracking => _trackingState == SlamTrackingState.tracking;
  List<DetectedPlane> get detectedPlanes => List.unmodifiable(_detectedPlanes);

  // ─────────────────────────────────────────────
  //  INITIALIZE
  //  ARView widget ke onARViewCreated mein call karo:
  //
  //  ARView(
  //    onARViewCreated: (session, object, anchor, location) =>
  //      SlamService().initialize(
  //        sessionManager: session,
  //        objectManager: object,
  //        anchorManager: anchor,
  //        locationManager: location,
  //      ),
  //    planeDetectionConfig:
  //      PlaneDetectionConfig.horizontalAndVertical,
  //  )
  // ─────────────────────────────────────────────
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

    // Tap callback — real world hit test results
    _sessionManager!.onPlaneOrPointTap = _onHitTestResult;

    _isSessionActive = true;
    _updateState(SlamTrackingState.initializing);
    _startPoseTimer();
  }

  // ─────────────────────────────────────────────
  //  POSE TIMER
  //  Har 500ms last known position broadcast karo
  //  New position tab milti hai jab user move kare
  //  aur onPlaneOrPointTap fire ho
  // ─────────────────────────────────────────────
  void _startPoseTimer() {
    _poseTimer?.cancel();
    _poseTimer = Timer.periodic(const Duration(milliseconds: 500), (_) {
      if (!_isSessionActive) return;
      if (_trackingState != SlamTrackingState.tracking) return;

      final pose = SlamPose(
        x: _lastX,
        y: _lastY,
        z: _lastZ,
        rotationX: 0,
        rotationY: 0,
        rotationZ: 0,
        timestamp: DateTime.now(),
        trackingState: SlamTrackingState.tracking,
      );
      _currentPose = pose;
      _poseController.add(pose);
    });
  }

  // ─────────────────────────────────────────────
  //  HIT TEST RESULT
  //  onPlaneOrPointTap callback
  //  → real world x,y,z milta hai ARCore se
  // ─────────────────────────────────────────────
  void _onHitTestResult(List<ARHitTestResult> hits) {
    if (hits.isEmpty) return;

    final hit = hits.first;
    final transform = hit.worldTransform;

    _lastX = transform.getColumn(3).x;
    _lastY = transform.getColumn(3).y;
    _lastZ = transform.getColumn(3).z;

    final plane = DetectedPlane(
      id: 'plane_${DateTime.now().millisecondsSinceEpoch}',
      type: PlaneType.horizontal,
      centerX: _lastX,
      centerY: _lastY,
      centerZ: _lastZ,
      width: 1.0,
      height: 1.0,
    );

    _detectedPlanes.add(plane);
    _planeController.add(plane);

    final pose = SlamPose(
      x: _lastX,
      y: _lastY,
      z: _lastZ,
      rotationX: 0,
      rotationY: 0,
      rotationZ: 0,
      timestamp: DateTime.now(),
      trackingState: SlamTrackingState.tracking,
    );

    _currentPose = pose;
    _updateState(SlamTrackingState.tracking);
    _poseController.add(pose);
  }

  // ─────────────────────────────────────────────
  //  FLOOR DETECTION from y coordinate
  //  ARCore y = vertical axis (meters)
  //  Ground < 1.5m, First 1.5-4.5m, Second > 4.5m
  // ─────────────────────────────────────────────
  String detectCurrentFloor() {
    final y = _currentPose.y;
    if (y < 1.5) return 'Ground';
    if (y < 4.5) return 'First';
    return 'Second';
  }

  // ─────────────────────────────────────────────
  //  PLACE DIRECTION ARROW
  //  Next evacuation node ki taraf AR arrow place karo
  // ─────────────────────────────────────────────
  Future<void> placeDirectionArrow({
    required double toGraphX,
    required double toGraphZ,
    required double scaleX,
    required double scaleZ,
  }) async {
    if (_objectManager == null || _anchorManager == null) return;

    // Graph coords → ARCore coords
    final arTargetX = (toGraphX / scaleX);
    final arTargetZ = (toGraphZ / scaleZ);

    // Direction angle
    final angle = atan2(arTargetX - _lastX, arTargetZ - _lastZ);

    try {
      final anchor = ARPlaneAnchor(
        transformation: Matrix4.translation(Vector3(_lastX, _lastY, _lastZ)),
      );

      final added = await _anchorManager!.addAnchor(anchor);
      if (added != true) return;

      final arrowNode = ARNode(
        type: NodeType.webGLB,
        uri:
            'https://raw.githubusercontent.com/KhronosGroup/'
            'glTF-Sample-Models/master/2.0/Arrow/glTF-Binary/Arrow.glb',
        scale: Vector3(0.15, 0.15, 0.15),
        position: Vector3(0, 0, 0),
        rotation: Vector4(0, 1, 0, angle),
        name: 'arrow_${DateTime.now().millisecondsSinceEpoch}',
      );

      final nodeAdded = await _objectManager!.addNode(
        arrowNode,
        planeAnchor: anchor,
      );

      if (nodeAdded == true) {
        _arrowNodes.add(arrowNode);
      }
    } catch (_) {
      // Arrow placement failed — non critical
    }
  }

  // ── Clear all AR arrows ──
  Future<void> clearArrows() async {
    for (final node in _arrowNodes) {
      await _objectManager?.removeNode(node);
    }
    _arrowNodes.clear();
  }

  void _updateState(SlamTrackingState state) {
    if (_trackingState == state) return;
    _trackingState = state;
    _stateController.add(state);
  }

  void pauseSession() {
    _poseTimer?.cancel();
    _updateState(SlamTrackingState.paused);
    _isSessionActive = false;
  }

  void resumeSession() {
    _isSessionActive = true;
    _updateState(SlamTrackingState.initializing);
    _startPoseTimer();
  }

  void dispose() {
    _poseTimer?.cancel();
    _sessionManager?.dispose();
    _poseController.close();
    _planeController.close();
    _stateController.close();
    _isSessionActive = false;
    _detectedPlanes.clear();
    _arrowNodes.clear();
  }

  void reset() {
    _lastX = 0;
    _lastY = 0;
    _lastZ = 0;
    _currentPose = SlamPose.zero();
    _trackingState = SlamTrackingState.initializing;
    _detectedPlanes.clear();
    _arrowNodes.clear();
  }
}
