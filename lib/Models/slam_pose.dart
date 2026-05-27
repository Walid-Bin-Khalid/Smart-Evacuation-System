//  SlamPose Real-time pose data from ARCore
class SlamPose {
  final double x;
  final double y;
  final double z;
  final double rotationX;
  final double rotationY;
  final double rotationZ;
  final DateTime timestamp;
  final SlamTrackingState trackingState;

  const SlamPose({
    required this.x,
    required this.y,
    required this.z,
    required this.rotationX,
    required this.rotationY,
    required this.rotationZ,
    required this.timestamp,
    required this.trackingState,
  });

  factory SlamPose.zero() => SlamPose(
    x: 0,
    y: 0,
    z: 0,
    rotationX: 0,
    rotationY: 0,
    rotationZ: 0,
    timestamp: DateTime.now(),
    trackingState: SlamTrackingState.initializing,
  );

  @override
  String toString() =>
      'SlamPose(x: ${x.toStringAsFixed(2)}, '
      'y: ${y.toStringAsFixed(2)}, '
      'z: ${z.toStringAsFixed(2)}, '
      'state: $trackingState)';
}

enum SlamTrackingState { initializing, tracking, limited, paused }

class DetectedPlane {
  final String id;
  final PlaneType type;
  final double centerX;
  final double centerY;
  final double centerZ;
  final double width;
  final double height;

  const DetectedPlane({
    required this.id,
    required this.type,
    required this.centerX,
    required this.centerY,
    required this.centerZ,
    required this.width,
    required this.height,
  });
}

enum PlaneType { horizontal, vertical }
