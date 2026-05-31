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
import 'package:sensors_plus/sensors_plus.dart';
import 'package:vector_math/vector_math_64.dart';

import '../Models/slam_pose.dart';

class SlamService {
  static final SlamService _instance = SlamService._internal();
  factory SlamService() => _instance;
  SlamService._internal();

  ARSessionManager? _sessionManager;
  ARObjectManager? _objectManager;
  ARAnchorManager? _anchorManager;

  // ── STREAMS ──
  final StreamController<SlamPose> _poseController =
      StreamController<SlamPose>.broadcast();
  final StreamController<SlamTrackingState> _stateController =
      StreamController<SlamTrackingState>.broadcast();
  final StreamController<int> _nodeReachedController =
      StreamController<int>.broadcast();

  Stream<SlamPose> get poseStream => _poseController.stream;
  Stream<SlamTrackingState> get trackingStateStream => _stateController.stream;
  Stream<int> get nodeReachedStream => _nodeReachedController.stream;

  // ── STATE ──
  SlamTrackingState _trackingState = SlamTrackingState.initializing;
  SlamPose _currentPose = SlamPose.zero();
  bool _isSessionActive = false;

  SlamPose get currentPose => _currentPose;
  bool get isTracking => _trackingState == SlamTrackingState.tracking;

  bool _planesVisible = false;
  bool get isPlanesVisible => _planesVisible;
  Timer? _autoTrackingTimer;

  // ── CALIBRATION ──
  double _floorY = 0.0;
  bool _isCalibrated = false;

  // ─────────────────────────────────────────────
  // POSE TRACKING — sensor based
  // _lastX, _lastZ ab accelerometer se update honge
  // ─────────────────────────────────────────────
  double _lastX = 0;
  double _lastY = 0;
  double _lastZ = 0;

  // Accelerometer integration ke liye
  double _velX = 0;
  double _velZ = 0;
  double _accX = 0;
  double _accZ = 0;
  DateTime _lastAccTime = DateTime.now();
  DateTime _lastGyroTime = DateTime.now(); // FIX: separate timer for gyro

  // Gyroscope heading ke liye
  double _headingRad = 0; // radians — phone ka yaw

  StreamSubscription? _accelSub;
  StreamSubscription? _gyroSub;

  final List<_RawPose> _poseHistory = [];
  static const int _smoothingWindow = 5;
  Timer? _poseTimer;

  // ── ARROW SYSTEM ──
  final List<ARNode> _activeArrowNodes = [];
  final List<ARAnchor> _activeArrowAnchors = [];
  List<Map<String, double>> _currentRoute = [];

  int _currentRouteIndex = 0;
  static const int _visibleArrowWindow = 3;
  bool _isPlacingArrows = false;
  bool _isUpdatingRoute = false;
  DateTime _lastArrowUpdate = DateTime.now();
  static const double _nodeReachThreshold = 1.2;

  // ─────────────────────────────────────────────
  // INITIALIZE
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

    _sessionManager!.onPlaneOrPointTap = _onPlaneTapCalibration;

    _isSessionActive = true;
    _updateState(SlamTrackingState.initializing);

    // Sensors start karo
    _startSensors();
    _startPoseTimer();

    // 3 sec baad auto tracking
    _autoTrackingTimer = Timer(const Duration(seconds: 3), () {
      if (!_isSessionActive) return;
      if (_trackingState == SlamTrackingState.initializing) {
        _planesVisible = true;
        _updateState(SlamTrackingState.tracking);
      }
    });
  }

  // ─────────────────────────────────────────────
  // SENSORS — Accelerometer + Gyroscope
  // Yahi hai asli fix — movement yahan se aayegi
  // ─────────────────────────────────────────────
  void _startSensors() {
    // Gyroscope — heading track karo
    _gyroSub =
        gyroscopeEventStream(
          samplingPeriod: const Duration(milliseconds: 50),
        ).listen((event) {
          if (!_isCalibrated) return;
          final now = DateTime.now();
          final dt =
              now.difference(_lastGyroTime).inMilliseconds /
              1000.0; // FIX: own timer
          _lastGyroTime = now; // FIX: update gyro timer, not accel timer
          // Y axis = yaw (left/right rotation)
          _headingRad += event.y * dt;
        });

    // Accelerometer — position update karo
    _accelSub =
        accelerometerEventStream(
          samplingPeriod: const Duration(milliseconds: 50),
        ).listen((event) {
          if (!_isCalibrated) return;

          final now = DateTime.now();
          final dt = now.difference(_lastAccTime).inMilliseconds / 1000.0;
          _lastAccTime = now;

          if (dt <= 0 || dt > 0.5) return; // bad delta — skip

          // World frame mein convert karo heading use karke
          // Phone ke local X,Z → World X,Z
          final cosH = cos(_headingRad);
          final sinH = sin(_headingRad);

          // Gravity remove karo (simple high-pass)
          // event.x = lateral, event.z = forward/back
          final rawAx = event.x;
          final rawAz =
              -event.z; // negative kyunki forward = negative Z in sensor

          // Threshold — choti movements ignore karo (noise)
          final ax = rawAx.abs() > 0.15 ? rawAx * 0.08 : 0.0;
          final az = rawAz.abs() > 0.15 ? rawAz * 0.08 : 0.0;

          // World coordinates mein rotate karo
          _accX = ax * cosH - az * sinH;
          _accZ = ax * sinH + az * cosH;

          // Velocity integrate karo
          _velX = (_velX + _accX * dt) * 0.85; // damping — drift rok
          _velZ = (_velZ + _accZ * dt) * 0.85;

          // Position update karo
          _lastX += _velX * dt;
          _lastZ += _velZ * dt;

          // Pose history mein add karo
          _addPoseToHistory(_lastX, _lastY, _lastZ);
        });
  }

  // ─────────────────────────────────────────────
  // CALIBRATION — floor pe tap
  // ─────────────────────────────────────────────
  void _onPlaneTapCalibration(List<ARHitTestResult> hits) {
    _autoTrackingTimer?.cancel();

    if (hits.isEmpty) {
      _planesVisible = true;
      if (!_isCalibrated) {
        _floorY = 0.0;
        _isCalibrated = true;
        _lastAccTime = DateTime.now();
        _addPoseToHistory(0, 0, 0);
      }
      _updateState(SlamTrackingState.tracking);
      return;
    }

    final hit = hits.first;
    final transform = hit.worldTransform;
    final x = transform.getColumn(3).x;
    final y = transform.getColumn(3).y;
    final z = transform.getColumn(3).z;

    final safeX = x.isNaN ? 0.0 : x;
    final safeY = y.isNaN ? 0.0 : y;
    final safeZ = z.isNaN ? 0.0 : z;

    _lastX = safeX;
    _lastY = safeY;
    _lastZ = safeZ;

    if (!_isCalibrated) {
      _floorY = safeY;
    }

    _isCalibrated = true;
    _planesVisible = true;
    _lastAccTime = DateTime.now();
    _lastGyroTime = DateTime.now(); // FIX: reset gyro timer too
    _velX = 0;
    _velZ = 0;
    _addPoseToHistory(safeX, safeY, safeZ);
    _updateState(SlamTrackingState.tracking);
  }

  // ─────────────────────────────────────────────
  // POSE TIMER — 150ms tick
  // ─────────────────────────────────────────────
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

  void _addPoseToHistory(double x, double y, double z) {
    _poseHistory.add(_RawPose(x, y, z));
    if (_poseHistory.length > _smoothingWindow * 2) {
      _poseHistory.removeAt(0);
    }
  }

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
      rotationY: _headingRad, // heading bhi pass karo
      rotationZ: 0,
      timestamp: DateTime.now(),
      trackingState: SlamTrackingState.tracking,
    );
  }

  // ─────────────────────────────────────────────
  // SET ROUTE
  // ─────────────────────────────────────────────
  Future<void> setRoute({
    required List<Map<String, double>> routePoints,
  }) async {
    _currentRoute = routePoints;
    _currentRouteIndex = 0;
    await _updateVisibleArrows();
  }

  // ─────────────────────────────────────────────
  // DYNAMIC ARROWS — node reach check
  // ─────────────────────────────────────────────
  Future<void> _updateDynamicArrows() async {
    if (_currentRoute.isEmpty) return;
    if (_isUpdatingRoute) return;
    if (_currentRouteIndex >= _currentRoute.length - 1) return;

    final next = _currentRoute[_currentRouteIndex];
    final targetX = next['x'] ?? 0;
    final targetZ = next['z'] ?? 0;

    final dx = _lastX - targetX;
    final dz = _lastZ - targetZ;
    final distance = sqrt(dx * dx + dz * dz);

    if (distance < _nodeReachThreshold) {
      final now = DateTime.now();
      if (now.difference(_lastArrowUpdate).inMilliseconds < 800) return;

      _lastArrowUpdate = now;
      _currentRouteIndex++;

      _nodeReachedController.add(_currentRouteIndex);

      if (_currentRouteIndex < _currentRoute.length - 1) {
        _isUpdatingRoute = true;
        await _updateVisibleArrows();
        _isUpdatingRoute = false;
      }
    }
  }

  // ─────────────────────────────────────────────
  // VISIBLE ARROWS — next 3 nodes
  // ─────────────────────────────────────────────
  Future<void> _updateVisibleArrows() async {
    if (_isPlacingArrows) return;
    _isPlacingArrows = true;

    try {
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
          y: _floorY + 0.03,
          z: fromZ,
          rotationAngle: angle,
          isExitArrow: isExit,
        );
      }
    } finally {
      _isPlacingArrows = false;
    }
  }

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
        type: NodeType.webGLB,
        uri:
            'https://github.com/chrisraff/3d-maze/raw/refs/heads/master/models/arrow.glb',
        scale: Vector3.all(isExitArrow ? 0.45 : 0.28),
        position: Vector3(0, 0, 0),
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

  Future<void> clearArrows() async {
    final nodesToRemove = List<ARNode>.from(_activeArrowNodes);
    final anchorsToRemove = List<ARAnchor>.from(_activeArrowAnchors);
    _activeArrowNodes.clear();
    _activeArrowAnchors.clear();

    for (final node in nodesToRemove) {
      try {
        await _objectManager?.removeNode(node);
      } catch (_) {}
    }
    for (final anchor in anchorsToRemove) {
      try {
        await _anchorManager?.removeAnchor(anchor);
      } catch (_) {}
    }
  }

  String detectCurrentFloor() {
    final y = _currentPose.y;
    if (y < 1.5) return 'Ground';
    if (y < 4.5) return 'First';
    return 'Second';
  }

  void _updateState(SlamTrackingState state) {
    if (_trackingState == state) return;
    _trackingState = state;
    _stateController.add(state);
  }

  void pauseSession() {
    _poseTimer?.cancel();
    _autoTrackingTimer?.cancel();
    _accelSub?.cancel();
    _gyroSub?.cancel();
    _isSessionActive = false;
    _updateState(SlamTrackingState.paused);
  }

  void resumeSession() {
    _isSessionActive = true;
    _startSensors();
    _startPoseTimer();
    _updateState(SlamTrackingState.initializing);
  }

  Future<void> reset() async {
    _autoTrackingTimer?.cancel();
    await clearArrows();

    _lastX = 0;
    _lastY = 0;
    _lastZ = 0;
    _velX = 0;
    _velZ = 0;
    _accX = 0;
    _accZ = 0;
    _headingRad = 0;
    _floorY = 0;
    _isCalibrated = false;
    _planesVisible = false;
    _currentRoute.clear();
    _currentRouteIndex = 0;
    _poseHistory.clear();
    _currentPose = SlamPose.zero();
    _isPlacingArrows = false;
    _isUpdatingRoute = false;

    _updateState(SlamTrackingState.initializing);
  }

  Future<void> dispose() async {
    _poseTimer?.cancel();
    _autoTrackingTimer?.cancel();
    _accelSub?.cancel();
    _gyroSub?.cancel();
    await clearArrows();
    _sessionManager?.dispose();

    if (!_poseController.isClosed) await _poseController.close();
    if (!_stateController.isClosed) await _stateController.close();
    if (!_nodeReachedController.isClosed) await _nodeReachedController.close();

    _currentRoute.clear();
    _poseHistory.clear();
    _isSessionActive = false;
  }
}

class _RawPose {
  final double x;
  final double y;
  final double z;
  _RawPose(this.x, this.y, this.z);
}

