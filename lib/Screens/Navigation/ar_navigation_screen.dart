import 'dart:async';
import 'dart:math';

import 'package:ar_flutter_plugin_2/ar_flutter_plugin.dart';
import 'package:ar_flutter_plugin_2/datatypes/config_planedetection.dart';
import 'package:ar_flutter_plugin_2/managers/ar_anchor_manager.dart';
import 'package:ar_flutter_plugin_2/managers/ar_location_manager.dart';
import 'package:ar_flutter_plugin_2/managers/ar_object_manager.dart';
import 'package:ar_flutter_plugin_2/managers/ar_session_manager.dart';
import 'package:flutter/material.dart';

import '../../Core/Constants/app_colors.dart';
import '../../Models/slam_pose.dart';
import '../../Services/coordinate_mapper.dart';
import '../../Services/graph_loader_service.dart';
import '../../Services/mock_alert_service.dart';
import '../../Services/pathfinding_service.dart';
import '../../Services/slam_service.dart';
import '../Safe Zone/safe_zone_screen.dart';

class ARNavigationScreen extends StatefulWidget {
  final String initialFloor;
  const ARNavigationScreen({super.key, this.initialFloor = 'Ground'});

  @override
  State<ARNavigationScreen> createState() => _ARNavigationScreenState();
}

class _ARNavigationScreenState extends State<ARNavigationScreen> {
  final SlamService _slam = SlamService();

  bool _isLoading = true;
  bool _isCalibrated = false;
  bool _pathFound = false;
  bool _safeZoneTriggered = false;
  String _statusMessage = 'Point camera at the floor to initialize SLAM...';
  late String _currentFloor;
  int _currentNodeIndex = 0;

  PathfindingService? _pathfinder;
  CoordinateMapper? _mapper;
  EvacuationPath? _evacuationPath;

  double _arrowAngle = 0;
  double _distanceToNext = 0;
  String _nextNodeName = '';

  StreamSubscription<SlamPose>? _poseSub;
  StreamSubscription<SlamTrackingState>? _stateSub;
  StreamSubscription<EvacuationAlert?>? _alertSub;

  @override
  void initState() {
    super.initState();
    _currentFloor = widget.initialFloor;
    _loadGraph();
    _listenToSlamState();
    _listenToLiveAlerts();
  }

  Future<void> _loadGraph() async {
    try {
      final graph = await GraphLoaderService.loadGraph();
      final pathfinder = PathfindingService(graph);
      final mapper = CoordinateMapper(graph);

      final alert = MockAlertService().currentAlert;
      if (alert != null && alert.isActive) {
        pathfinder.applyHazardAlert(alert.hazardNodeId);
      }

      setState(() {
        _pathfinder = pathfinder;
        _mapper = mapper;
        _isLoading = false;
        _statusMessage =
            'Scan floor — white dots dikhne chahiye. Phir tap karo.';
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _statusMessage = 'Error loading map: ${e.toString()}';
      });
    }
  }

  void _listenToSlamState() {
    _stateSub = _slam.trackingStateStream.listen((state) {
      if (!mounted) return;
      setState(() {
        switch (state) {
          case SlamTrackingState.initializing:
            _statusMessage = 'Camera floor ki taraf point karo...';
            break;
          case SlamTrackingState.tracking:
            if (!_isCalibrated) {
              // FIX: Tracking ready — button press karo ab
              _statusMessage = '✅ Floor detected! Neeche button dabao.';
            }
            break;
          case SlamTrackingState.limited:
            _statusMessage = 'Tracking limited — slowly move karo.';
            break;
          case SlamTrackingState.paused:
            _statusMessage = 'Tracking paused.';
            break;
        }
      });
    });
  }

  void _listenToLiveAlerts() {
    _alertSub = MockAlertService().alertStream.listen((alert) {
      if (!mounted) return;
      if (alert == null || !alert.isActive) return;
      if (_pathfinder == null || !_isCalibrated) return;

      _pathfinder!.applyHazardAlert(alert.hazardNodeId);

      if (_evacuationPath != null &&
          _currentNodeIndex < _evacuationPath!.nodeIds.length) {
        final currentNodeId = _evacuationPath!.nodeIds[_currentNodeIndex];
        final newPath = _pathfinder!.findBestEvacuationPath(currentNodeId);

        if (newPath != null && mounted) {
          setState(() {
            _evacuationPath = newPath;
            _currentNodeIndex = 0;
            _statusMessage =
                '⚠️ Hazard! Route updated. ${newPath.nodeIds.length} steps to exit.';
          });
          _reconnect3DArrows(newPath);
        }
      }
    });
  }

  Future<void> _onARViewCreated(
    ARSessionManager sessionManager,
    ARObjectManager objectManager,
    ARAnchorManager anchorManager,
    ARLocationManager locationManager,
  ) async {
    await _slam.initialize(
      sessionManager: sessionManager,
      objectManager: objectManager,
      anchorManager: anchorManager,
      locationManager: locationManager,
    );
    _poseSub = _slam.poseStream.listen(_onPoseUpdate);
  }

  void _onPoseUpdate(SlamPose pose) {
    if (!_isCalibrated || _mapper == null || _pathfinder == null) return;
    if (_evacuationPath == null) return;
    if (_safeZoneTriggered) return;

    _pathfinder!.updateCrowdFromARCore([
      {'x': pose.x, 'y': pose.z},
    ]);

    final totalNodes = _evacuationPath!.nodeIds.length;

    if (_currentNodeIndex >= totalNodes - 1) {
      _triggerSafeZone();
      return;
    }

    final nextNodeId = _evacuationPath!.nodeIds[_currentNodeIndex + 1];
    final nextGraphNode = _pathfinder!.graph.nodes.firstWhere(
      (n) => n.id == nextNodeId,
    );

    final nextArCoords = _mapper!.graphToArCoords(
      graphX: nextGraphNode.x,
      graphY: nextGraphNode.y,
    );

    final dx = nextArCoords['x']! - pose.x;
    final dz = nextArCoords['z']! - pose.z;
    final angle = atan2(dx, dz);
    final distance = sqrt(dx * dx + dz * dz);
    final name = _buildNodeName(nextNodeId);

    setState(() {
      _arrowAngle = angle;
      _distanceToNext = distance;
      _nextNodeName = name;
    });

    if (distance < 1.5) {
      setState(() {
        _currentNodeIndex++;
        final remaining = totalNodes - _currentNodeIndex - 1;
        if (_currentNodeIndex >= totalNodes - 1) {
          _statusMessage = '✅ EXIT pe pohunch gaye!';
          _triggerSafeZone();
        } else {
          _statusMessage = '$remaining steps to exit';
        }
      });
    }
  }

  void _triggerSafeZone() {
    if (_safeZoneTriggered) return;
    _safeZoneTriggered = true;
    if (!mounted) return;

    Future.delayed(const Duration(milliseconds: 800), () {
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const SafeZoneScreen()),
      );
    });
  }

  // ─────────────────────────────────────────────
  // FIX: _calibrateAndFindPath
  //
  // PURANA problem:
  //   if (!_slam.isTracking) → "Wait for floor detection"
  //   isTracking sirf tap ke baad true hota tha
  //   Button press karo → message aata tha → frustrating
  //
  // NAYA behavior:
  //   isTracking  OR  isPlanesVisible → allow karo
  //   isPlanesVisible = 3 sec baad auto-true (timer se)
  //   Agar na bhi hua → zero pose se start karo (FYP mein acceptable)
  // ─────────────────────────────────────────────
  Future<void> _calibrateAndFindPath() async {
    if (_mapper == null || _pathfinder == null) return;

    // FIX: Allow calibration if tracking OR planes visible (3sec timer)
    // Pure zero pose se bhi kaam chalega demo ke liye
    if (!_slam.isTracking && !_slam.isPlanesVisible) {
      setState(
        () => _statusMessage = 'Thoda wait karo... floor scan ho rahi hai.',
      );
      return;
    }

    final pose = _slam.currentPose; // may be zero — that's OK
    final floor = _currentFloor;

    final startNode = _pathfinder!.graph.nodes.firstWhere(
      (n) => n.floor == floor,
      orElse: () => _pathfinder!.graph.nodes.first,
    );

    final calibrated = _mapper!.calibrate(
      knownNodeId: startNode.id,
      currentPose: pose,
    );

    if (!calibrated) {
      setState(() => _statusMessage = 'Calibration failed. Dobara try karo.');
      return;
    }

    final path = _pathfinder!.findBestEvacuationPath(startNode.id);

    if (path == null) {
      setState(() {
        _isCalibrated = true;
        _statusMessage = 'Koi safe route nahi mila. Corridor mein jao.';
      });
      return;
    }

    setState(() {
      _isCalibrated = true;
      _pathFound = true;
      _evacuationPath = path;
      _currentNodeIndex = 0;
      _safeZoneTriggered = false;
      _statusMessage =
          'Route mil gaya! Arrow follow karo. ${path.nodeIds.length} steps.';
    });

    _reconnect3DArrows(path);
  }

  Future<void> _reconnect3DArrows(EvacuationPath path) async {
    if (_mapper == null) return;

    final routePoints = path.nodeIds.map((id) {
      final node = _pathfinder!.graph.nodes.firstWhere((n) => n.id == id);
      final arCoords = _mapper!.graphToArCoords(graphX: node.x, graphY: node.y);
      return {'x': arCoords['x']!, 'z': arCoords['z']!};
    }).toList();

    await _slam.setRoute(routePoints: routePoints);
  }

  String _buildNodeName(String nodeId) {
    if (nodeId.contains('EXIT')) return '🟢 EXIT';
    if (nodeId.contains('STAIRS')) return '🪜 Stairs';
    if (nodeId.endsWith('_C')) {
      final match = RegExp(r'_R(\d+)_C').firstMatch(nodeId);
      return 'Room ${match?.group(1) ?? ''}';
    }
    if (nodeId.contains('_C')) {
      final match = RegExp(r'_C(\d+)').firstMatch(nodeId);
      return 'Corridor ${match?.group(1) ?? ''}';
    }
    return nodeId;
  }

  @override
  void dispose() {
    _poseSub?.cancel();
    _stateSub?.cancel();
    _alertSub?.cancel();
    _slam.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // FIX: Button active hoga agar tracking ya planes visible ho
    final bool canCalibrate = _slam.isTracking || _slam.isPlanesVisible;

    return Scaffold(
      body: Stack(
        children: [
          // AR CAMERA VIEW
          if (!_isLoading)
            ARView(
              onARViewCreated: _onARViewCreated,
              planeDetectionConfig: PlaneDetectionConfig.horizontalAndVertical,
            ),

          // LOADING
          if (_isLoading)
            Container(
              color: Colors.black,
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: AppColors.neonBlue),
                    SizedBox(height: 20),
                    Text(
                      'Building map load ho raha hai...',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ),

          // 2D COMPASS ARROW OVERLAY
          if (_isCalibrated && _pathFound) _buildArrowOverlay(),

          // TOP STATUS BAR
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Container(
                margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.75),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _pathFound
                        ? AppColors.neonGreen
                        : (canCalibrate
                              ? AppColors.neonGreen
                              : AppColors.neonBlue),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      // FIX: Icon green jab bhi calibrate possible ho
                      canCalibrate ? Icons.sensors : Icons.sensors_off,
                      color: canCalibrate ? AppColors.neonGreen : Colors.orange,
                      size: 18,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _statusMessage,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // FLOOR + STEPS INFO
          if (_isCalibrated)
            Positioned(
              top: 110,
              right: 16,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.75),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.neonBlue),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '📍 $_currentFloor Floor',
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                    ),
                    if (_evacuationPath != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        'Exit: ${_evacuationPath!.exitNodeId}',
                        style: const TextStyle(
                          color: AppColors.neonGreen,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Steps: ${_evacuationPath!.nodeIds.length - _currentNodeIndex - 1} left',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

          // BOTTOM CONTROLS
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.neonBlue),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (!_isCalibrated)
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          // FIX: canCalibrate true ho to button active
                          onPressed: canCalibrate
                              ? _calibrateAndFindPath
                              : null,
                          icon: const Icon(
                            Icons.my_location,
                            color: Colors.white,
                          ),
                          label: Text(
                            canCalibrate
                                ? 'TAP TO SET MY LOCATION'
                                : 'FLOOR SCAN HO RAHI HAI...',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            // FIX: Button grey jab disabled, blue jab ready
                            backgroundColor: canCalibrate
                                ? AppColors.neonBlue
                                : Colors.grey.shade800,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),

                    if (_isCalibrated && _pathFound)
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _triggerSafeZone,
                              icon: const Icon(
                                Icons.check_circle,
                                color: Colors.black,
                                size: 18,
                              ),
                              label: const Text(
                                'SAFE ZONE',
                                style: TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.neonGreen,
                              ),
                            ),
                          ),
                        ],
                      ),

                    if (_isCalibrated)
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _isCalibrated = false;
                            _pathFound = false;
                            _evacuationPath = null;
                            _currentNodeIndex = 0;
                            _safeZoneTriggered = false;
                            _statusMessage =
                                'Floor pe tap karo — recalibrate karo.';
                          });
                          _slam.reset();
                        },
                        child: const Text(
                          'Recalibrate',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),

          // BACK BUTTON
          Positioned(
            top: 0,
            left: 0,
            child: SafeArea(
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildArrowOverlay() {
    final isAtExit =
        _currentNodeIndex >= (_evacuationPath?.nodeIds.length ?? 1) - 1;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 160,
            height: 160,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.black.withValues(alpha: 0.55),
              border: Border.all(
                color: isAtExit ? AppColors.neonGreen : AppColors.neonBlue,
                width: 2.5,
              ),
            ),
            child: isAtExit
                ? const Icon(
                    Icons.check_circle,
                    color: AppColors.neonGreen,
                    size: 80,
                  )
                : Transform.rotate(
                    angle: _arrowAngle,
                    child: const Icon(
                      Icons.navigation,
                      color: AppColors.neonBlue,
                      size: 80,
                    ),
                  ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.neonBlue),
            ),
            child: Text(
              isAtExit ? '🟢 EXIT pe pohunch gaye!' : '→ $_nextNodeName',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 8),
          if (!isAtExit)
            Text(
              '${_distanceToNext.toStringAsFixed(1)} m',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
            ),
        ],
      ),
    );
  }
}

