import 'package:flutter/material.dart';

import '../../Core/Constants/app_colors.dart';
import '../../Services/pathfinding_service.dart';
import '../Safe Zone/safe_zone_screen.dart';

class EvacuationNavigationScreen extends StatelessWidget {
  final String floor;
  final String areaType;
  final String roomNumber;
  final EvacuationPath evacuationPath;

  const EvacuationNavigationScreen({
    super.key,
    required this.floor,
    required this.areaType,
    required this.roomNumber,
    required this.evacuationPath,
  });

  @override
  Widget build(BuildContext context) {
    // Node IDs → readable route string
    // e.g. "F1_R4_C → F1_C3 → G_STAIRS → G_EXIT_1"
    final routeSteps = evacuationPath.nodeIds
        .map((id) => id.split('_').last)
        .join(' → ');

    return Scaffold(
      appBar: AppBar(title: const Text('Emergency Navigation')),

      body: Padding(
        padding: const EdgeInsets.all(20),

        child: Column(
          children: [
            /// HAZARD WARNING BAR
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.cardColor,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.orange),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, color: Colors.orange),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      evacuationPath.hazardScore > 0
                          ? 'Hazard Score: ${evacuationPath.hazardScore} — Stay alert!'
                          : 'Clear path detected. Follow route carefully.',
                      style: const TextStyle(
                        color: Colors.orange,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            /// CURRENT POSITION CARD
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.cardColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.neonBlue),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Current Position',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 15),
                  Text('Floor: $floor'),
                  const SizedBox(height: 6),
                  Text('Area: $areaType'),
                  const SizedBox(height: 6),
                  Text('Room: ${roomNumber.isEmpty ? "N/A" : roomNumber}'),
                  const SizedBox(height: 6),
                  Text(
                    'Exit via: ${evacuationPath.exitNodeId}',
                    style: const TextStyle(
                      color: AppColors.neonGreen,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Steps: ${evacuationPath.nodeIds.length} nodes',
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            /// PATH VISUALIZATION
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppColors.cardColor,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppColors.neonBlue),
                ),
                child: Stack(
                  children: [
                    // Start point
                    Positioned(
                      top: 60,
                      left: 45,
                      child: buildPoint(Colors.green),
                    ),
                    // Mid point
                    Positioned(
                      top: 190,
                      left: 170,
                      child: buildPoint(AppColors.neonBlue),
                    ),
                    // Exit label
                    Positioned(
                      bottom: 50,
                      right: 45,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.neonGreen,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text(
                          'EXIT',
                          style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    CustomPaint(size: Size.infinite, painter: PathPainter()),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 15),

            /// ROUTE TEXT
            Text(
              routeSteps,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
            ),

            const SizedBox(height: 20),

            /// ACTION BUTTONS
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.cardColor,
                      side: const BorderSide(color: AppColors.neonBlue),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: const Text('REROUTE'),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.neonGreen,
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const SafeZoneScreen(),
                        ),
                      );
                    },
                    child: const Text(
                      'SAFE ZONE',
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget buildPoint(Color color) {
    return Container(
      width: 18,
      height: 18,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [BoxShadow(color: color, blurRadius: 15)],
      ),
    );
  }
}

class PathPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.neonBlue
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke;

    final path = Path();
    path.moveTo(55, 70);
    path.lineTo(190, 210);
    path.lineTo(size.width - 70, size.height - 70);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}



























// import 'package:flutter/material.dart';

// import '../../Core/Constants/app_colors.dart';
// import '../Safe Zone/safe_zone_screen.dart';

// class EvacuationNavigationScreen extends StatelessWidget {
//   final String floor;
//   final String areaType;
//   final String roomNumber;

//   const EvacuationNavigationScreen({
//     super.key,
//     required this.floor,
//     required this.areaType,
//     required this.roomNumber,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text('Emergency Navigation')),

//       body: Padding(
//         padding: const EdgeInsets.all(20),

//         child: Column(
//           children: [
//             /// STATUS BAR
//             Container(
//               width: double.infinity,

//               padding: const EdgeInsets.all(18),

//               decoration: BoxDecoration(
//                 color: AppColors.cardColor,

//                 borderRadius: BorderRadius.circular(18),

//                 border: Border.all(color: Colors.orange),
//               ),

//               child: const Row(
//                 children: [
//                   Icon(Icons.warning_amber_rounded, color: Colors.orange),

//                   SizedBox(width: 12),

//                   Expanded(
//                     child: Text(
//                       'Avoid Staircase 1. '
//                       'Crowd congestion detected.',

//                       style: TextStyle(
//                         color: Colors.orange,
//                         fontWeight: FontWeight.w600,
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ),

//             const SizedBox(height: 25),

//             /// CURRENT POSITION CARD
//             Container(
//               width: double.infinity,

//               padding: const EdgeInsets.all(18),

//               decoration: BoxDecoration(
//                 color: AppColors.cardColor,

//                 borderRadius: BorderRadius.circular(20),

//                 border: Border.all(color: AppColors.neonBlue),
//               ),

//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,

//                 children: [
//                   const Text(
//                     'Current Position',

//                     style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//                   ),

//                   const SizedBox(height: 15),

//                   Text('Floor: $floor'),

//                   const SizedBox(height: 8),

//                   Text('Area: $areaType'),

//                   const SizedBox(height: 8),

//                   Text(
//                     'Room: '
//                     '${roomNumber.isEmpty ? "N/A" : roomNumber}',
//                   ),
//                 ],
//               ),
//             ),

//             const SizedBox(height: 25),

//             /// GRAPH VIEW
//             Expanded(
//               child: Container(
//                 width: double.infinity,

//                 decoration: BoxDecoration(
//                   color: AppColors.cardColor,

//                   borderRadius: BorderRadius.circular(24),

//                   border: Border.all(color: AppColors.neonBlue),
//                 ),

//                 child: Stack(
//                   children: [
//                     Positioned(
//                       top: 60,
//                       left: 45,

//                       child: buildPoint(Colors.green),
//                     ),

//                     Positioned(
//                       top: 190,
//                       left: 170,

//                       child: buildPoint(AppColors.neonBlue),
//                     ),

//                     Positioned(
//                       bottom: 50,
//                       right: 45,

//                       child: Container(
//                         padding: const EdgeInsets.symmetric(
//                           horizontal: 14,
//                           vertical: 8,
//                         ),

//                         decoration: BoxDecoration(
//                           color: AppColors.neonGreen,

//                           borderRadius: BorderRadius.circular(10),
//                         ),

//                         child: const Text(
//                           'EXIT',

//                           style: TextStyle(
//                             color: Colors.black,
//                             fontWeight: FontWeight.bold,
//                           ),
//                         ),
//                       ),
//                     ),

//                     CustomPaint(size: Size.infinite, painter: PathPainter()),
//                   ],
//                 ),
//               ),
//             ),

//             const SizedBox(height: 25),

//             /// ROUTE INFO
//             const Text(
//               'Room → Hallway → '
//               'Stairs 2 → Exit',

//               style: TextStyle(color: AppColors.textSecondary, fontSize: 15),
//             ),

//             const SizedBox(height: 20),

//             /// BUTTONS
//             Row(
//               children: [
//                 Expanded(
//                   child: ElevatedButton(
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: AppColors.cardColor,

//                       side: const BorderSide(color: AppColors.neonBlue),
//                     ),

//                     onPressed: () {},

//                     child: const Text('REROUTE'),
//                   ),
//                 ),

//                 const SizedBox(width: 14),

//                 Expanded(
//                   child: ElevatedButton(
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: AppColors.neonGreen,
//                     ),

//                     onPressed: () {
//                       Navigator.push(
//                         context,

//                         MaterialPageRoute(
//                           builder: (_) => const SafeZoneScreen(),
//                         ),
//                       );
//                     },

//                     child: const Text(
//                       'SAFE ZONE',

//                       style: TextStyle(
//                         color: Colors.black,
//                         fontWeight: FontWeight.bold,
//                       ),
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget buildPoint(Color color) {
//     return Container(
//       width: 18,
//       height: 18,

//       decoration: BoxDecoration(
//         color: color,
//         shape: BoxShape.circle,

//         boxShadow: [BoxShadow(color: color, blurRadius: 15)],
//       ),
//     );
//   }
// }

// class PathPainter extends CustomPainter {
//   @override
//   void paint(Canvas canvas, Size size) {
//     final paint = Paint()
//       ..color = AppColors.neonBlue
//       ..strokeWidth = 4
//       ..style = PaintingStyle.stroke;

//     final path = Path();

//     path.moveTo(55, 70);

//     path.lineTo(190, 210);

//     path.lineTo(size.width - 70, size.height - 70);

//     canvas.drawPath(path, paint);
//   }

//   @override
//   bool shouldRepaint(covariant CustomPainter oldDelegate) {
//     return false;
//   }
// }




















// import 'package:flutter/material.dart';
// import '../../Core/Constants/app_colors.dart';
// import '../Safe Zone/safe_zone_screen.dart';

// class EvacuationNavigationScreen extends StatelessWidget {
//   const EvacuationNavigationScreen({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text('Emergency Navigation')),
//       body: Padding(
//         padding: const EdgeInsets.all(20),
//         child: Column(
//           children: [
//             Expanded(
//               child: Container(
//                 width: double.infinity,
//                 decoration: BoxDecoration(
//                   color: AppColors.cardColor,
//                   borderRadius: BorderRadius.circular(24),
//                   border: Border.all(color: AppColors.neonBlue),
//                 ),
//                 child: Stack(
//                   children: [
//                     Positioned(
//                       top: 50,
//                       left: 40,
//                       child: buildPoint(Colors.green),
//                     ),
//                     Positioned(
//                       top: 180,
//                       left: 150,
//                       child: buildPoint(AppColors.neonBlue),
//                     ),
//                     Positioned(
//                       bottom: 50,
//                       right: 40,
//                       child: Container(
//                         padding: const EdgeInsets.symmetric(
//                           horizontal: 14,
//                           vertical: 8,
//                         ),
//                         decoration: BoxDecoration(
//                           color: AppColors.neonGreen,
//                           borderRadius: BorderRadius.circular(10),
//                         ),
//                         child: const Text(
//                           'EXIT',
//                           style: TextStyle(
//                             color: Colors.black,
//                             fontWeight: FontWeight.bold,
//                           ),
//                         ),
//                       ),
//                     ),
//                     CustomPaint(size: Size.infinite, painter: PathPainter()),
//                   ],
//                 ),
//               ),
//             ),
//             const SizedBox(height: 30),
//             const Text(
//               'Follow highlighted path to nearest exit.',
//               style: TextStyle(color: AppColors.textSecondary),
//             ),
//             const SizedBox(height: 20),
//             SizedBox(
//               width: double.infinity,
//               height: 58,
//               child: ElevatedButton(
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: AppColors.neonGreen,
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(14),
//                   ),
//                 ),
//                 onPressed: () {
//                   Navigator.push(
//                     context,
//                     MaterialPageRoute(builder: (_) => const SafeZoneScreen()),
//                   );
//                 },
//                 child: const Text(
//                   'I REACHED SAFE ZONE',
//                   style: TextStyle(
//                     color: Colors.black,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget buildPoint(Color color) {
//     return Container(
//       width: 18,
//       height: 18,
//       decoration: BoxDecoration(
//         color: color,
//         shape: BoxShape.circle,
//         boxShadow: [BoxShadow(color: color, blurRadius: 15)],
//       ),
//     );
//   }
// }

// class PathPainter extends CustomPainter {
//   @override
//   void paint(Canvas canvas, Size size) {
//     final paint = Paint()
//       ..color = AppColors.neonBlue
//       ..strokeWidth = 4
//       ..style = PaintingStyle.stroke;

//     final path = Path();
//     path.moveTo(55, 60);
//     path.lineTo(170, 190);
//     path.lineTo(size.width - 70, size.height - 70);

//     canvas.drawPath(path, paint);
//   }

//   @override
//   bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
// }
