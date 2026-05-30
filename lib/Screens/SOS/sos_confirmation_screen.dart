import 'package:flutter/material.dart';

import 'sos_indanger_screen.dart';

class SOSConfirmationScreen extends StatelessWidget {
  const SOSConfirmationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const SOSInDangerScreen();
  }
}










// import 'dart:io';

// import 'package:flutter/material.dart';
// import 'package:image_picker/image_picker.dart';

// import '../../Core/Constants/app_colors.dart';
// import '../../Services/mock_alert_service.dart';
// import '../../widgets/primary_button.dart';
// import '../Alert/emergency_alert_receiving_screen.dart';
// import '../Navigation/slam_initialization_screen.dart';

// class SOSConfirmationScreen extends StatefulWidget {
//   const SOSConfirmationScreen({super.key});

//   @override
//   State<SOSConfirmationScreen> createState() => _SOSConfirmationScreenState();
// }

// class _SOSConfirmationScreenState extends State<SOSConfirmationScreen> {
//   // ── Step tracker ──
//   // 0 = Are you in danger?
//   // 1 = Image Capture
//   // 2 = Emergency Form
//   int _step = 0;

//   // ── Captured image ──
//   File? capturedImage;

//   // ── Floor dropdown — matches building_graph.json ──
//   String? selectedFloor;
//   final List<String> floors = ['Ground', 'First', 'Second'];

//   // ── Area Type — matches GraphNode.type in JSON ──
//   String? selectedAreaType;
//   final List<String> areaTypes = ['room', 'corridor', 'stairs', 'door'];

//   final TextEditingController roomController = TextEditingController();
//   final TextEditingController hazardController = TextEditingController();

//   @override
//   void dispose() {
//     roomController.dispose();
//     hazardController.dispose();
//     super.dispose();
//   }

//   // ─────────────────────────────────────────────
//   //  CAMERA — live capture
//   // ─────────────────────────────────────────────
//   Future<void> _openCamera() async {
//     final picker = ImagePicker();
//     final XFile? photo = await picker.pickImage(
//       source: ImageSource.camera,
//       imageQuality: 80,
//     );

//     if (photo != null) {
//       setState(() {
//         capturedImage = File(photo.path);
//         _step = 2; // move to Emergency Form
//       });
//     }
//   }

//   // ─────────────────────────────────────────────
//   //  SEND ALERT
//   //  → MockAlertService ko trigger karo
//   //  → AlertSentScreen par navigate karo
//   // ─────────────────────────────────────────────
//   void submitAlert() {
//     if (selectedFloor == null || selectedAreaType == null) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Floor and Area Type are required')),
//       );
//       return;
//     }

//     final roomNo = roomController.text.trim().isEmpty
//         ? selectedAreaType!.toUpperCase()
//         : roomController.text.trim();

//     final prefix = selectedFloor == 'Ground'
//         ? 'G'
//         : selectedFloor == 'First'
//         ? 'F1'
//         : 'F2';

//     String hazardNodeId;
//     switch (selectedAreaType) {
//       case 'room':
//         hazardNodeId = '${prefix}_R${roomNo}_C';
//         break;
//       case 'corridor':
//         hazardNodeId = '${prefix}_C$roomNo';
//         break;
//       case 'stairs':
//         hazardNodeId = '${prefix}_STAIRS';
//         break;
//       case 'door':
//         hazardNodeId = '${prefix}_R${roomNo}_D1';
//         break;
//       default:
//         hazardNodeId = '${prefix}_${roomNo.toUpperCase()}';
//     }

//     // TO-DO: capturedImage bhi backend ko bhejo real API mein
//     MockAlertService().triggerMockAlert(
//       hazardNodeId: hazardNodeId,
//       hazardType: hazardController.text.trim().isEmpty
//           ? 'unknown'
//           : hazardController.text.trim().toLowerCase(),
//       floor: selectedFloor!,
//       reportedBy: 'SELF-SOS',
//       // imageFile: capturedImage, // uncomment when backend ready
//     );

//     Navigator.pushReplacement(
//       context,
//       MaterialPageRoute(builder: (_) => const AlertSentScreen()),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: Padding(
//         padding: const EdgeInsets.all(24),
//         child: Center(
//           child: SingleChildScrollView(
//             child: _step == 0
//                 ? _buildDangerConfirmation()
//                 : _step == 1
//                 ? _buildImageCaptureScreen()
//                 : _buildEmergencyForm(),
//           ),
//         ),
//       ),
//     );
//   }

//   // ─────────────────────────────────────────────
//   //  SCREEN 1 — Danger confirmation
//   // ─────────────────────────────────────────────
//   Widget _buildDangerConfirmation() {
//     return Column(
//       mainAxisAlignment: MainAxisAlignment.center,
//       children: [
//         const Icon(Icons.warning_amber_rounded, size: 120, color: Colors.white),
//         const SizedBox(height: 30),
//         const Text(
//           'Are you in danger?',
//           textAlign: TextAlign.center,
//           style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
//         ),
//         const SizedBox(height: 20),
//         const Text(
//           'This will send emergency alert to admin.',
//           textAlign: TextAlign.center,
//           style: TextStyle(color: AppColors.textSecondary),
//         ),
//         const SizedBox(height: 40),
//         PrimaryButton(
//           text: 'YES, CONTINUE',
//           onTap: () => setState(() => _step = 1), // → Image Capture
//         ),
//       ],
//     );
//   }

//   // ─────────────────────────────────────────────
//   //  SCREEN 2 — Image Capture
//   //  Camera seedha khulti hai jab page load ho
//   // ─────────────────────────────────────────────
//   Widget _buildImageCaptureScreen() {
//     return Column(
//       mainAxisAlignment: MainAxisAlignment.center,
//       children: [
//         const Icon(
//           Icons.camera_alt_rounded,
//           size: 100,
//           color: AppColors.neonBlue,
//         ),
//         const SizedBox(height: 30),
//         const Text(
//           'Take a Photo',
//           textAlign: TextAlign.center,
//           style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
//         ),
//         const SizedBox(height: 16),
//         const Text(
//           'Capture the hazard or emergency\nso admin can verify the situation.',
//           textAlign: TextAlign.center,
//           style: TextStyle(color: AppColors.textSecondary, fontSize: 15),
//         ),
//         const SizedBox(height: 40),

//         // Show captured image preview if user retakes
//         if (capturedImage != null) ...[
//           ClipRRect(
//             borderRadius: BorderRadius.circular(14),
//             child: Image.file(
//               capturedImage!,
//               height: 200,
//               width: double.infinity,
//               fit: BoxFit.cover,
//             ),
//           ),
//           const SizedBox(height: 20),
//           PrimaryButton(
//             text: 'USE THIS PHOTO',
//             onTap: () => setState(() => _step = 2),
//           ),
//           const SizedBox(height: 16),
//           SizedBox(
//             width: double.infinity,
//             height: 58,
//             child: OutlinedButton.icon(
//               onPressed: _openCamera,
//               icon: const Icon(Icons.refresh, color: AppColors.neonBlue),
//               label: const Text(
//                 'RETAKE',
//                 style: TextStyle(
//                   color: AppColors.neonBlue,
//                   fontWeight: FontWeight.bold,
//                   letterSpacing: 1,
//                 ),
//               ),
//               style: OutlinedButton.styleFrom(
//                 side: const BorderSide(color: AppColors.neonBlue, width: 1.5),
//                 shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(14),
//                 ),
//               ),
//             ),
//           ),
//         ] else ...[
//           // Camera abhi tak nahi khuli — Open Camera button
//           PrimaryButton(text: 'OPEN CAMERA', onTap: _openCamera),
//           const SizedBox(height: 16),
//           TextButton(
//             onPressed: () => setState(() => _step = 2),
//             child: const Text(
//               'Skip (not recommended)',
//               style: TextStyle(color: AppColors.textSecondary),
//             ),
//           ),
//         ],

//         const SizedBox(height: 16),
//         TextButton(
//           onPressed: () => setState(() => _step = 0),
//           child: const Text(
//             '← Back',
//             style: TextStyle(color: AppColors.textSecondary),
//           ),
//         ),
//       ],
//     );
//   }

//   // ─────────────────────────────────────────────
//   //  SCREEN 3 — Emergency form
//   // ─────────────────────────────────────────────
//   Widget _buildEmergencyForm() {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         // Show image thumbnail at top if captured
//         if (capturedImage != null) ...[
//           Row(
//             children: [
//               ClipRRect(
//                 borderRadius: BorderRadius.circular(10),
//                 child: Image.file(
//                   capturedImage!,
//                   width: 70,
//                   height: 70,
//                   fit: BoxFit.cover,
//                 ),
//               ),
//               const SizedBox(width: 12),
//               const Expanded(
//                 child: Text(
//                   '✅ Photo attached',
//                   style: TextStyle(
//                     color: AppColors.neonGreen,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//               ),
//             ],
//           ),
//           const SizedBox(height: 20),
//         ],

//         const Text(
//           'REPORT INCIDENT',
//           style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
//         ),
//         const SizedBox(height: 10),
//         const Text(
//           'Provide emergency details below.',
//           style: TextStyle(color: AppColors.textSecondary),
//         ),

//         const SizedBox(height: 35),

//         /// FLOOR DROPDOWN
//         const Text(
//           'Floor *',
//           style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
//         ),
//         const SizedBox(height: 10),
//         Container(
//           padding: const EdgeInsets.symmetric(horizontal: 16),
//           decoration: BoxDecoration(
//             color: AppColors.cardColor,
//             borderRadius: BorderRadius.circular(14),
//             border: Border.all(color: AppColors.neonBlue),
//           ),
//           child: DropdownButtonHideUnderline(
//             child: DropdownButton<String>(
//               value: selectedFloor,
//               dropdownColor: AppColors.cardColor,
//               iconEnabledColor: Colors.white,
//               isExpanded: true,
//               hint: const Text(
//                 'Select Floor *',
//                 style: TextStyle(color: AppColors.textSecondary),
//               ),
//               style: const TextStyle(color: Colors.white),
//               items: floors.map((floor) {
//                 return DropdownMenuItem(
//                   value: floor,
//                   child: Text('$floor Floor'),
//                 );
//               }).toList(),
//               onChanged: (value) => setState(() => selectedFloor = value),
//             ),
//           ),
//         ),

//         const SizedBox(height: 20),

//         /// AREA TYPE DROPDOWN
//         const Text(
//           'Area Type *',
//           style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
//         ),
//         const SizedBox(height: 10),
//         Container(
//           padding: const EdgeInsets.symmetric(horizontal: 16),
//           decoration: BoxDecoration(
//             color: AppColors.cardColor,
//             borderRadius: BorderRadius.circular(14),
//             border: Border.all(color: AppColors.neonBlue),
//           ),
//           child: DropdownButtonHideUnderline(
//             child: DropdownButton<String>(
//               value: selectedAreaType,
//               dropdownColor: AppColors.cardColor,
//               iconEnabledColor: Colors.white,
//               isExpanded: true,
//               hint: const Text(
//                 'Area Type *',
//                 style: TextStyle(color: AppColors.textSecondary),
//               ),
//               style: const TextStyle(color: Colors.white),
//               items: areaTypes.map((type) {
//                 return DropdownMenuItem(
//                   value: type,
//                   child: Text(type[0].toUpperCase() + type.substring(1)),
//                 );
//               }).toList(),
//               onChanged: (value) => setState(() => selectedAreaType = value),
//             ),
//           ),
//         ),

//         const SizedBox(height: 20),

//         /// ROOM NO
//         TextField(
//           controller: roomController,
//           keyboardType: TextInputType.number,
//           style: const TextStyle(color: Colors.white),
//           decoration: InputDecoration(
//             hintText: 'Room No (e.g. 4, 9)',
//             hintStyle: const TextStyle(color: AppColors.textSecondary),
//             filled: true,
//             fillColor: AppColors.cardColor,
//             enabledBorder: OutlineInputBorder(
//               borderRadius: BorderRadius.circular(14),
//               borderSide: const BorderSide(color: AppColors.neonBlue),
//             ),
//             focusedBorder: OutlineInputBorder(
//               borderRadius: BorderRadius.circular(14),
//               borderSide: const BorderSide(
//                 color: AppColors.neonGreen,
//                 width: 2,
//               ),
//             ),
//           ),
//         ),

//         const SizedBox(height: 20),

//         /// HAZARD TYPE
//         TextField(
//           controller: hazardController,
//           style: const TextStyle(color: Colors.white),
//           decoration: InputDecoration(
//             hintText: 'Hazard Type (e.g. fire, smoke)',
//             hintStyle: const TextStyle(color: AppColors.textSecondary),
//             filled: true,
//             fillColor: AppColors.cardColor,
//             enabledBorder: OutlineInputBorder(
//               borderRadius: BorderRadius.circular(14),
//               borderSide: const BorderSide(color: AppColors.neonBlue),
//             ),
//             focusedBorder: OutlineInputBorder(
//               borderRadius: BorderRadius.circular(14),
//               borderSide: const BorderSide(
//                 color: AppColors.neonGreen,
//                 width: 2,
//               ),
//             ),
//           ),
//         ),

//         const SizedBox(height: 40),

//         PrimaryButton(text: 'SEND ALERT', onTap: submitAlert),
//       ],
//     );
//   }
// }

// // ─────────────────────────────────────────────
// //  ALERT SENT SCREEN
// //  2 options:
// //  1. Evacuate Yourself → EmergencyAlertScreen
// //  2. Start Evacuation  → SlamInitializationScreen
// // ─────────────────────────────────────────────
// class AlertSentScreen extends StatelessWidget {
//   const AlertSentScreen({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: Center(
//         child: Padding(
//           padding: const EdgeInsets.all(24),
//           child: Column(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               const Icon(
//                 Icons.check_circle,
//                 color: AppColors.neonGreen,
//                 size: 120,
//               ),

//               const SizedBox(height: 30),

//               const Text(
//                 'Alert Has Been Sent!',
//                 textAlign: TextAlign.center,
//                 style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
//               ),

//               const SizedBox(height: 20),

//               const Text(
//                 'Admin has been notified successfully.\nWhat would you like to do?',
//                 textAlign: TextAlign.center,
//                 style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
//               ),

//               const SizedBox(height: 40),

//               PrimaryButton(
//                 text: 'EVACUATE YOURSELF',
//                 onTap: () {
//                   final alert = MockAlertService().currentAlert;
//                   Navigator.pushReplacement(
//                     context,
//                     MaterialPageRoute(
//                       builder: (_) => EmergencyAlertScreen(
//                         emergencyType:
//                             alert?.hazardType.toUpperCase() ?? 'UNKNOWN',
//                         affectedFloor: alert?.floor ?? 'Ground',
//                         blockedArea: alert?.hazardNodeId ?? '',
//                       ),
//                     ),
//                   );
//                 },
//               ),

//               const SizedBox(height: 16),

//               SizedBox(
//                 width: double.infinity,
//                 height: 58,
//                 child: OutlinedButton.icon(
//                   onPressed: () {
//                     Navigator.pushReplacement(
//                       context,
//                       MaterialPageRoute(
//                         builder: (_) => const SlamInitializationScreen(),
//                       ),
//                     );
//                   },
//                   icon: const Icon(
//                     Icons.directions_run,
//                     color: AppColors.neonBlue,
//                   ),
//                   label: const Text(
//                     'START EVACUATION',
//                     style: TextStyle(
//                       color: AppColors.neonBlue,
//                       fontWeight: FontWeight.bold,
//                       letterSpacing: 1,
//                     ),
//                   ),
//                   style: OutlinedButton.styleFrom(
//                     side: const BorderSide(
//                       color: AppColors.neonBlue,
//                       width: 1.5,
//                     ),
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(14),
//                     ),
//                   ),
//                 ),
//               ),

//               const SizedBox(height: 16),

//               TextButton(
//                 onPressed: () => Navigator.popUntil(context, (r) => r.isFirst),
//                 child: const Text(
//                   'Back to Home',
//                   style: TextStyle(color: AppColors.textSecondary),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
