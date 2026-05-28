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
  String _statusMessage = 'Point camera at the floor to initialize SLAM...';
  late String _currentFloor;
  int _currentNodeIndex = 0;

  PathfindingService? _pathfinder;
  CoordinateMapper? _mapper;
  EvacuationPath? _evacuationPath;

  // ── Arrow overlay state ──
  // Direction angle (radians) toward next node
  double _arrowAngle = 0;
  // Distance to next node (meters in ARCore space)
  double _distanceToNext = 0;
  // Next node display name
  String _nextNodeName = '';

  StreamSubscription<SlamPose>? _poseSub;
  StreamSubscription<SlamTrackingState>? _stateSub;

  @override
  void initState() {
    super.initState();
    _currentFloor = widget.initialFloor;
    _loadGraph();
    _listenToSlamState();
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
        _statusMessage = 'SLAM ready. Tap on floor to calibrate position.';
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
            _statusMessage = 'Initializing SLAM... Point at floor.';
            break;
          case SlamTrackingState.tracking:
            if (!_isCalibrated) {
              _statusMessage = 'Floor detected! Tap to set your position.';
            }
            break;
          case SlamTrackingState.limited:
            _statusMessage = 'Tracking limited. Move slowly.';
            break;
          case SlamTrackingState.paused:
            _statusMessage = 'Tracking paused.';
            break;
        }
      });
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

  //  POSE UPDATE
  //  → Update arrow direction overlay
  //  → Check if user reached next node
  void _onPoseUpdate(SlamPose pose) {
    if (!_isCalibrated || _mapper == null || _pathfinder == null) return;
    if (_evacuationPath == null) return;

    _pathfinder!.updateCrowdFromARCore([
      {'x': pose.x, 'y': pose.z},
    ]);

    // Update arrow direction toward next node
    if (_currentNodeIndex < _evacuationPath!.nodeIds.length - 1) {
      final nextNodeId = _evacuationPath!.nodeIds[_currentNodeIndex + 1];
      final nextGraphNode = _pathfinder!.graph.nodes.firstWhere(
        (n) => n.id == nextNodeId,
      );

      // Convert graph coords → ARCore coords
      final nextArCoords = _mapper!.graphToArCoords(
        graphX: nextGraphNode.x,
        graphY: nextGraphNode.y,
      );

      final dx = nextArCoords['x']! - pose.x;
      final dz = nextArCoords['z']! - pose.z;

      // Arrow angle — atan2 gives direction in radians
      final angle = atan2(dx, dz);
      final distance = sqrt(dx * dx + dz * dz);

      // Node display name
      final name = _buildNodeName(nextNodeId);

      setState(() {
        _arrowAngle = angle;
        _distanceToNext = distance;
        _nextNodeName = name;
      });

      // Check if user reached next node (within 1.5 meters)
      if (distance < 1.5) {
        setState(() {
          _currentNodeIndex++;
          if (_currentNodeIndex >= _evacuationPath!.nodeIds.length - 1) {
            _statusMessage = '✅ You reached the EXIT! Stay safe!';
          } else {
            _statusMessage =
                '${_evacuationPath!.nodeIds.length - _currentNodeIndex - 1} steps to exit';
          }
        });
      }
    }
  }

  //  CALIBRATE + FIND PATH
  Future<void> _calibrateAndFindPath() async {
    if (_mapper == null || _pathfinder == null) return;

    if (!_slam.isTracking) {
      setState(() => _statusMessage = 'Wait for floor detection first...');
      return;
    }

    final pose = _slam.currentPose;
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
      setState(() => _statusMessage = 'Calibration failed. Try again.');
      return;
    }

    final path = _pathfinder!.findBestEvacuationPath(startNode.id);

    if (path == null) {
      setState(() {
        _isCalibrated = true;
        _statusMessage = 'No safe route found. Move to a nearby corridor.';
      });
      return;
    }

    setState(() {
      _isCalibrated = true;
      _pathFound = true;
      _evacuationPath = path;
      _currentNodeIndex = 0;
      _statusMessage =
          'Route found! Follow the arrow. ${path.nodeIds.length} steps to exit.';
    });
  }

  // ── Node ID → readable name ──
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
    _slam.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          /// ── AR CAMERA VIEW ──
          if (!_isLoading)
            ARView(
              onARViewCreated: _onARViewCreated,
              planeDetectionConfig: PlaneDetectionConfig.horizontalAndVertical,
            ),

          /// ── LOADING ──
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
                      'Loading building map...',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ),

          /// ── FLUTTER ARROW OVERLAY ──
          /// Camera ke upar render hota hai — no GLB needed!
          if (_isCalibrated && _pathFound) _buildArrowOverlay(),

          /// ── TOP STATUS BAR ──
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
                        : AppColors.neonBlue,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _slam.isTracking ? Icons.sensors : Icons.sensors_off,
                      color: _slam.isTracking
                          ? AppColors.neonGreen
                          : Colors.orange,
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

          /// ── FLOOR + STEPS INFO ──
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

          /// ── BOTTOM CONTROLS ──
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
                          onPressed: _calibrateAndFindPath,
                          icon: const Icon(
                            Icons.my_location,
                            color: Colors.white,
                          ),
                          label: const Text(
                            'TAP TO SET MY LOCATION',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.neonBlue,
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
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const SafeZoneScreen(),
                                  ),
                                );
                              },
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
                            _statusMessage = 'Tap on floor to recalibrate.';
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

          /// ── BACK BUTTON ──
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

  //  FLUTTER ARROW OVERLAY
  //  Screen center pe direction arrow + info
  //  No GLB — pure Flutter Canvas!
  Widget _buildArrowOverlay() {
    final isAtExit =
        _currentNodeIndex >= (_evacuationPath?.nodeIds.length ?? 1) - 1;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Direction Arrow ──
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
                // Exit reached — show checkmark
                ? const Icon(
                    Icons.check_circle,
                    color: AppColors.neonGreen,
                    size: 80,
                  )
                // Rotating arrow toward next node
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

          // ── Next Node Label ──
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.neonBlue),
            ),
            child: Text(
              isAtExit ? '🟢 You are at the EXIT!' : '→ $_nextNodeName',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          const SizedBox(height: 8),

          // ── Distance ──
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















// import 'dart:async';

// import 'package:ar_flutter_plugin_2/ar_flutter_plugin.dart';
// import 'package:ar_flutter_plugin_2/datatypes/config_planedetection.dart';
// import 'package:ar_flutter_plugin_2/managers/ar_anchor_manager.dart';
// import 'package:ar_flutter_plugin_2/managers/ar_location_manager.dart';
// import 'package:ar_flutter_plugin_2/managers/ar_object_manager.dart';
// import 'package:ar_flutter_plugin_2/managers/ar_session_manager.dart';
// import 'package:flutter/material.dart';

// import '../../Core/Constants/app_colors.dart';
// import '../../Models/slam_pose.dart';
// import '../../Services/coordinate_mapper.dart';
// import '../../Services/graph_loader_service.dart';
// import '../../Services/mock_alert_service.dart';
// import '../../Services/pathfinding_service.dart';
// import '../../Services/slam_service.dart';
// import '../Safe Zone/safe_zone_screen.dart';

// class ARNavigationScreen extends StatefulWidget {
//   // ✅ Floor form se pass hota hai — hardcoded nahi
//   final String initialFloor;

//   const ARNavigationScreen({super.key, this.initialFloor = 'Ground'});

//   @override
//   State<ARNavigationScreen> createState() => _ARNavigationScreenState();
// }

// class _ARNavigationScreenState extends State<ARNavigationScreen> {
//   final SlamService _slam = SlamService();

//   bool _isLoading = true;
//   bool _isCalibrated = false;
//   bool _pathFound = false;
//   String _statusMessage = 'Point camera at the floor to initialize SLAM...';
//   late String _currentFloor;
//   int _currentNodeIndex = 0;

//   PathfindingService? _pathfinder;
//   CoordinateMapper? _mapper;
//   EvacuationPath? _evacuationPath;

//   StreamSubscription<SlamPose>? _poseSub;
//   StreamSubscription<SlamTrackingState>? _stateSub;

//   @override
//   void initState() {
//     super.initState();
//     // ✅ Floor form se aata hai — ARCore y-axis se nahi
//     _currentFloor = widget.initialFloor;
//     _loadGraph();
//     _listenToSlamState();
//   }

//   Future<void> _loadGraph() async {
//     try {
//       final graph = await GraphLoaderService.loadGraph();
//       final pathfinder = PathfindingService(graph);
//       final mapper = CoordinateMapper(graph);

//       final alert = MockAlertService().currentAlert;
//       if (alert != null && alert.isActive) {
//         pathfinder.applyHazardAlert(alert.hazardNodeId);
//       }

//       setState(() {
//         _pathfinder = pathfinder;
//         _mapper = mapper;
//         _isLoading = false;
//         _statusMessage = 'SLAM ready. Tap on floor to calibrate position.';
//       });
//     } catch (e) {
//       setState(() {
//         _isLoading = false;
//         _statusMessage = 'Error loading map: ${e.toString()}';
//       });
//     }
//   }

//   void _listenToSlamState() {
//     _stateSub = _slam.trackingStateStream.listen((state) {
//       if (!mounted) return;
//       setState(() {
//         switch (state) {
//           case SlamTrackingState.initializing:
//             _statusMessage = 'Initializing SLAM... Point at floor.';
//             break;
//           case SlamTrackingState.tracking:
//             if (!_isCalibrated) {
//               _statusMessage = 'Floor detected! Tap to set your position.';
//             }
//             break;
//           case SlamTrackingState.limited:
//             _statusMessage = 'Tracking limited. Move slowly.';
//             break;
//           case SlamTrackingState.paused:
//             _statusMessage = 'Tracking paused.';
//             break;
//         }
//       });
//     });
//   }

//   Future<void> _onARViewCreated(
//     ARSessionManager sessionManager,
//     ARObjectManager objectManager,
//     ARAnchorManager anchorManager,
//     ARLocationManager locationManager,
//   ) async {
//     await _slam.initialize(
//       sessionManager: sessionManager,
//       objectManager: objectManager,
//       anchorManager: anchorManager,
//       locationManager: locationManager,
//     );
//     _poseSub = _slam.poseStream.listen(_onPoseUpdate);
//   }

//   void _onPoseUpdate(SlamPose pose) {
//     if (!_isCalibrated || _mapper == null || _pathfinder == null) return;

//     _pathfinder!.updateCrowdFromARCore([
//       {'x': pose.x, 'y': pose.z},
//     ]);

//     if (_evacuationPath != null &&
//         _currentNodeIndex < _evacuationPath!.nodeIds.length - 1) {
//       final nearestNode = _mapper!.nearestNodeToPose(
//         pose,
//         floor: _currentFloor,
//       );
//       final nextNode = _evacuationPath!.nodeIds[_currentNodeIndex + 1];

//       if (nearestNode == nextNode) {
//         setState(() {
//           _currentNodeIndex++;
//           _statusMessage =
//               _currentNodeIndex == _evacuationPath!.nodeIds.length - 1
//               ? '✅ You reached the EXIT! Stay safe!'
//               : 'Follow the arrow → '
//                     '${_evacuationPath!.nodeIds.length - _currentNodeIndex - 1} steps left';
//         });
//       }
//     }
//   }

//   // ─────────────────────────────────────────────
//   //  CALIBRATE
//   //  ✅ Floor widget.initialFloor se aata hai
//   //  ✅ Pehla node us floor ka use hota hai
//   // ─────────────────────────────────────────────
//   Future<void> _calibrateAndFindPath() async {
//     if (_mapper == null || _pathfinder == null) return;

//     if (!_slam.isTracking) {
//       setState(() => _statusMessage = 'Wait for floor detection first...');
//       return;
//     }

//     final pose = _slam.currentPose;

//     // ✅ Floor form se selected — reliable
//     final floor = _currentFloor;

//     // Pehla node us floor ka as starting calibration point
//     final startNode = _pathfinder!.graph.nodes.firstWhere(
//       (n) => n.floor == floor,
//       orElse: () => _pathfinder!.graph.nodes.first,
//     );

//     final calibrated = _mapper!.calibrate(
//       knownNodeId: startNode.id,
//       currentPose: pose,
//     );

//     if (!calibrated) {
//       setState(() => _statusMessage = 'Calibration failed. Try again.');
//       return;
//     }

//     final path = _pathfinder!.findBestEvacuationPath(startNode.id);

//     if (path == null) {
//       setState(() {
//         _isCalibrated = true;
//         _statusMessage = 'No safe route found. Move to a nearby corridor.';
//       });
//       return;
//     }

//     setState(() {
//       _isCalibrated = true;
//       _pathFound = true;
//       _evacuationPath = path;
//       _currentNodeIndex = 0;
//       _statusMessage =
//           'Route found! Follow the arrow. '
//           '${path.nodeIds.length} steps to exit.';
//     });
     
//      final routePoints = path.nodeIds.map((id) {
//       final node = _pathfinder!.graph.nodes.firstWhere((n) => n.id == id);
//       return {'x': node.x, 'z': node.y};
//     }).toList();
    
    
//      await _slam.setRoute(routePoints: routePoints);


//     //    await _placeNextArrow();
//   }

//   Future<void> _placeNextArrow() async {
//     if (_evacuationPath == null || _mapper == null) return;
//     if (_currentNodeIndex >= _evacuationPath!.nodeIds.length - 1) {
//       return;
//     }

//     final nextNodeId = _evacuationPath!.nodeIds[_currentNodeIndex + 1];
//     final nextNode = _pathfinder!.graph.nodes.firstWhere(
//       (n) => n.id == nextNodeId,
//     );

//     await _slam.clearArrows();
//     await _slam.placeDirectionArrow(
//       toGraphX: nextNode.x,
//       toGraphZ: nextNode.y,
//       scaleX: _mapper!.scaleX,
//       scaleZ: _mapper!.scaleZ,
//     );
//   }

//   @override
//   void dispose() {
//     _poseSub?.cancel();
//     _stateSub?.cancel();
//     _slam.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: Stack(
//         children: [
//           /// AR CAMERA VIEW
//           if (!_isLoading)
//             ARView(
//               onARViewCreated: _onARViewCreated,
//               planeDetectionConfig: PlaneDetectionConfig.horizontalAndVertical,
//             ),

//           /// LOADING OVERLAY
//           if (_isLoading)
//             Container(
//               color: AppColors.background,
//               child: const Center(
//                 child: Column(
//                   mainAxisSize: MainAxisSize.min,
//                   children: [
//                     CircularProgressIndicator(color: AppColors.neonBlue),
//                     SizedBox(height: 20),
//                     Text(
//                       'Loading building map...',
//                       style: TextStyle(color: AppColors.textSecondary),
//                     ),
//                   ],
//                 ),
//               ),
//             ),

//           /// TOP STATUS BAR
//           Positioned(
//             top: 0,
//             left: 0,
//             right: 0,
//             child: SafeArea(
//               child: Container(
//                 margin: const EdgeInsets.all(16),
//                 padding: const EdgeInsets.symmetric(
//                   horizontal: 16,
//                   vertical: 12,
//                 ),
//                 decoration: BoxDecoration(
//                   color: Colors.black.withValues(alpha: 0.7),
//                   borderRadius: BorderRadius.circular(16),
//                   border: Border.all(
//                     color: _pathFound
//                         ? AppColors.neonGreen
//                         : AppColors.neonBlue,
//                   ),
//                 ),
//                 child: Row(
//                   children: [
//                     Icon(
//                       _slam.isTracking ? Icons.sensors : Icons.sensors_off,
//                       color: _slam.isTracking
//                           ? AppColors.neonGreen
//                           : Colors.orange,
//                       size: 18,
//                     ),
//                     const SizedBox(width: 10),
//                     Expanded(
//                       child: Text(
//                         _statusMessage,
//                         style: const TextStyle(
//                           color: Colors.white,
//                           fontSize: 13,
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           ),

//           /// FLOOR + NODE INFO
//           if (_isCalibrated)
//             Positioned(
//               top: 110,
//               right: 16,
//               child: Container(
//                 padding: const EdgeInsets.all(12),
//                 decoration: BoxDecoration(
//                   color: Colors.black.withValues(alpha: 0.7),
//                   borderRadius: BorderRadius.circular(12),
//                   border: Border.all(color: AppColors.neonBlue),
//                 ),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.end,
//                   children: [
//                     Text(
//                       '📍 $_currentFloor Floor',
//                       style: const TextStyle(color: Colors.white, fontSize: 13),
//                     ),
//                     if (_evacuationPath != null) ...[
//                       const SizedBox(height: 6),
//                       Text(
//                         'Exit: ${_evacuationPath!.exitNodeId}',
//                         style: const TextStyle(
//                           color: AppColors.neonGreen,
//                           fontSize: 12,
//                         ),
//                       ),
//                       const SizedBox(height: 4),
//                       Text(
//                         'Steps: ${_evacuationPath!.nodeIds.length - _currentNodeIndex - 1} left',
//                         style: const TextStyle(
//                           color: AppColors.textSecondary,
//                           fontSize: 12,
//                         ),
//                       ),
//                     ],
//                   ],
//                 ),
//               ),
//             ),

//           /// BOTTOM CONTROLS
//           Positioned(
//             bottom: 0,
//             left: 0,
//             right: 0,
//             child: SafeArea(
//               child: Container(
//                 margin: const EdgeInsets.all(16),
//                 padding: const EdgeInsets.all(16),
//                 decoration: BoxDecoration(
//                   color: Colors.black.withValues(alpha: 0.8),
//                   borderRadius: BorderRadius.circular(20),
//                   border: Border.all(color: AppColors.neonBlue),
//                 ),
//                 child: Column(
//                   mainAxisSize: MainAxisSize.min,
//                   children: [
//                     /// CALIBRATE BUTTON
//                     if (!_isCalibrated)
//                       SizedBox(
//                         width: double.infinity,
//                         child: ElevatedButton.icon(
//                           onPressed: _calibrateAndFindPath,
//                           icon: const Icon(
//                             Icons.my_location,
//                             color: Colors.white,
//                           ),
//                           label: const Text(
//                             'TAP TO SET MY LOCATION',
//                             style: TextStyle(
//                               color: Colors.white,
//                               fontWeight: FontWeight.bold,
//                             ),
//                           ),
//                           style: ElevatedButton.styleFrom(
//                             backgroundColor: AppColors.neonBlue,
//                             padding: const EdgeInsets.symmetric(vertical: 14),
//                             shape: RoundedRectangleBorder(
//                               borderRadius: BorderRadius.circular(12),
//                             ),
//                           ),
//                         ),
//                       ),

//                     /// ROUTE CONTROLS
//                     if (_isCalibrated && _pathFound)
//                       Row(
//                         children: [
//                           Expanded(
//                             child: ElevatedButton.icon(
//                               onPressed: _placeNextArrow,
//                               icon: const Icon(
//                                 Icons.navigation,
//                                 color: Colors.white,
//                                 size: 18,
//                               ),
//                               label: const Text(
//                                 'NEXT',
//                                 style: TextStyle(color: Colors.white),
//                               ),
//                               style: ElevatedButton.styleFrom(
//                                 backgroundColor: AppColors.cardColor,
//                                 side: const BorderSide(
//                                   color: AppColors.neonBlue,
//                                 ),
//                               ),
//                             ),
//                           ),
//                           const SizedBox(width: 12),
//                           Expanded(
//                             child: ElevatedButton.icon(
//                               onPressed: () {
//                                 Navigator.push(
//                                   context,
//                                   MaterialPageRoute(
//                                     builder: (_) => const SafeZoneScreen(),
//                                   ),
//                                 );
//                               },
//                               icon: const Icon(
//                                 Icons.check_circle,
//                                 color: Colors.black,
//                                 size: 18,
//                               ),
//                               label: const Text(
//                                 'SAFE ZONE',
//                                 style: TextStyle(
//                                   color: Colors.black,
//                                   fontWeight: FontWeight.bold,
//                                 ),
//                               ),
//                               style: ElevatedButton.styleFrom(
//                                 backgroundColor: AppColors.neonGreen,
//                               ),
//                             ),
//                           ),
//                         ],
//                       ),

//                     /// RECALIBRATE
//                     if (_isCalibrated)
//                       TextButton(
//                         onPressed: () {
//                           setState(() {
//                             _isCalibrated = false;
//                             _pathFound = false;
//                             _evacuationPath = null;
//                             _currentNodeIndex = 0;
//                             _statusMessage = 'Tap on floor to recalibrate.';
//                           });
//                           _slam.reset();
//                         },
//                         child: const Text(
//                           'Recalibrate',
//                           style: TextStyle(
//                             color: AppColors.textSecondary,
//                             fontSize: 12,
//                           ),
//                         ),
//                       ),
//                   ],
//                 ),
//               ),
//             ),
//           ),

//           /// BACK BUTTON
//           Positioned(
//             top: 0,
//             left: 0,
//             child: SafeArea(
//               child: IconButton(
//                 icon: const Icon(Icons.arrow_back, color: Colors.white),
//                 onPressed: () => Navigator.pop(context),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
