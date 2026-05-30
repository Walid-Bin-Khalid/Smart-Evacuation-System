import 'dart:io';

import 'package:flutter/material.dart';

import '../../Core/Constants/app_colors.dart';
import '../../widgets/primary_button.dart';
import 'alert_sending_screen.dart';

class SOSIncidentFormScreen extends StatefulWidget {
  final File? capturedImage;

  const SOSIncidentFormScreen({super.key, this.capturedImage});

  @override
  State<SOSIncidentFormScreen> createState() => _SOSIncidentFormScreenState();
}

class _SOSIncidentFormScreenState extends State<SOSIncidentFormScreen> {
  String? selectedFloor;
  final List<String> floors = ['Ground', 'First', 'Second'];

  String? selectedAreaType;
  final List<String> areaTypes = ['room', 'corridor', 'stairs', 'door'];

  final TextEditingController roomController = TextEditingController();

  final TextEditingController hazardController = TextEditingController();

  @override
  void dispose() {
    roomController.dispose();
    hazardController.dispose();
    super.dispose();
  }

  void submitAlert() {
    if (selectedFloor == null || selectedAreaType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Floor and Area Type are required')),
      );
      return;
    }

    final roomNo = roomController.text.trim().isEmpty
        ? selectedAreaType!.toUpperCase()
        : roomController.text.trim();

    final prefix = selectedFloor == 'Ground'
        ? 'G'
        : selectedFloor == 'First'
        ? 'F1'
        : 'F2';

    // ignore: unused_local_variable
    String hazardNodeId;

    switch (selectedAreaType) {
      case 'room':
        hazardNodeId = '${prefix}_R${roomNo}_C';
        break;

      case 'corridor':
        hazardNodeId = '${prefix}_C$roomNo';
        break;

      case 'stairs':
        hazardNodeId = '${prefix}_STAIRS';
        break;

      case 'door':
        hazardNodeId = '${prefix}_R${roomNo}_D1';
        break;

      default:
        hazardNodeId = '${prefix}_${roomNo.toUpperCase()}';
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const AlertSendingScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 50),

              if (widget.capturedImage != null) ...[
                Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.file(
                        widget.capturedImage!,
                        width: 70,
                        height: 70,
                        fit: BoxFit.cover,
                      ),
                    ),

                    const SizedBox(width: 12),

                    const Expanded(
                      child: Text(
                        "Attached Picture",
                        style: TextStyle(
                          color: AppColors.neonGreen,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),
              ],

              const Text(
                'REPORT INCIDENT',
                style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 10),

              const Text(
                'Provide emergency details below.',
                style: TextStyle(color: AppColors.textSecondary),
              ),

              const SizedBox(height: 35),

              // Floor Dropdown
              const Text(
                'Floor *',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),

              const SizedBox(height: 10),

              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: AppColors.cardColor,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.neonBlue),
                ),

                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: selectedFloor,
                    dropdownColor: AppColors.cardColor,
                    iconEnabledColor: Colors.white,
                    isExpanded: true,

                    hint: const Text(
                      'Select Floor *',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),

                    style: const TextStyle(color: Colors.white),

                    items: floors
                        .map(
                          (f) => DropdownMenuItem(
                            value: f,
                            child: Text('$f Floor'),
                          ),
                        )
                        .toList(),

                    onChanged: (v) => setState(() => selectedFloor = v),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Area Type
              const Text(
                'Area Type *',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),

              const SizedBox(height: 10),

              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: AppColors.cardColor,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.neonBlue),
                ),

                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: selectedAreaType,
                    dropdownColor: AppColors.cardColor,
                    iconEnabledColor: Colors.white,
                    isExpanded: true,

                    hint: const Text(
                      'Area Type *',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),

                    style: const TextStyle(color: Colors.white),

                    items: areaTypes
                        .map(
                          (t) => DropdownMenuItem(
                            value: t,
                            child: Text(t[0].toUpperCase() + t.substring(1)),
                          ),
                        )
                        .toList(),

                    onChanged: (v) => setState(() => selectedAreaType = v),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Room No
              TextField(
                controller: roomController,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(hintText: 'Room No (e.g. 4, 9)'),
              ),

              const SizedBox(height: 20),

              // Hazard Type
              TextField(
                controller: hazardController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: 'Hazard Type (e.g. fire, smoke)',
                ),
              ),

              const SizedBox(height: 40),

              PrimaryButton(text: 'SEND ALERT', onTap: submitAlert),
            ],
          ),
        ),
      ),
    );
  }
}






// import 'dart:io';

// import 'package:flutter/material.dart';

// import '../../Core/Constants/app_colors.dart';
// import '../../Services/mock_alert_service.dart';
// import '../../widgets/primary_button.dart';
// import 'alert_sending_screen.dart';

// class SOSIncidentFormScreen extends StatefulWidget {
//   final File? capturedImage;

//   const SOSIncidentFormScreen({super.key, this.capturedImage});

//   @override
//   State<SOSIncidentFormScreen> createState() => _SOSIncidentFormScreenState();
// }

// class _SOSIncidentFormScreenState extends State<SOSIncidentFormScreen> {
//   String? selectedFloor;
//   final List<String> floors = ['Ground', 'First', 'Second'];

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

//     MockAlertService().triggerMockAlert(
//       hazardNodeId: hazardNodeId,
//       hazardType: hazardController.text.trim().isEmpty
//           ? 'unknown'
//           : hazardController.text.trim().toLowerCase(),
//       floor: selectedFloor!,
//       reportedBy: 'SELF-SOS',
//     );

//     Navigator.pushReplacement(
//       context,
//       MaterialPageRoute(builder: (_) => const AlertSendingScreen()),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: Padding(
//         padding: const EdgeInsets.all(24),
//         child: SingleChildScrollView(
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               const SizedBox(height: 50),

//               if (widget.capturedImage != null) ...[
//                 Row(
//                   children: [
//                     ClipRRect(
//                       borderRadius: BorderRadius.circular(10),
//                       child: Image.file(
//                         widget.capturedImage!,
//                         width: 70,
//                         height: 70,
//                         fit: BoxFit.cover,
//                       ),
//                     ),

//                     const SizedBox(width: 12),

//                     const Expanded(
//                       child: Text(
//                         "Attached Picture",
//                         style: TextStyle(
//                           color: AppColors.neonGreen,
//                           fontWeight: FontWeight.bold,
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),

//                 const SizedBox(height: 20),
//               ],

//               const Text(
//                 'REPORT INCIDENT',
//                 style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
//               ),

//               const SizedBox(height: 10),

//               const Text(
//                 'Provide emergency details below.',
//                 style: TextStyle(color: AppColors.textSecondary),
//               ),

//               const SizedBox(height: 35),

//               // Floor Dropdown
//               const Text(
//                 'Floor *',
//                 style: TextStyle(
//                   fontWeight: FontWeight.bold,
//                   color: Colors.white,
//                 ),
//               ),

//               const SizedBox(height: 10),

//               Container(
//                 padding: const EdgeInsets.symmetric(horizontal: 16),
//                 decoration: BoxDecoration(
//                   color: AppColors.cardColor,
//                   borderRadius: BorderRadius.circular(14),
//                   border: Border.all(color: AppColors.neonBlue),
//                 ),

//                 child: DropdownButtonHideUnderline(
//                   child: DropdownButton<String>(
//                     value: selectedFloor,
//                     dropdownColor: AppColors.cardColor,
//                     iconEnabledColor: Colors.white,
//                     isExpanded: true,

//                     hint: const Text(
//                       'Select Floor *',
//                       style: TextStyle(color: AppColors.textSecondary),
//                     ),

//                     style: const TextStyle(color: Colors.white),

//                     items: floors
//                         .map(
//                           (f) => DropdownMenuItem(
//                             value: f,
//                             child: Text('$f Floor'),
//                           ),
//                         )
//                         .toList(),

//                     onChanged: (v) => setState(() => selectedFloor = v),
//                   ),
//                 ),
//               ),

//               const SizedBox(height: 20),

//               // Area Type
//               const Text(
//                 'Area Type *',
//                 style: TextStyle(
//                   fontWeight: FontWeight.bold,
//                   color: Colors.white,
//                 ),
//               ),

//               const SizedBox(height: 10),

//               Container(
//                 padding: const EdgeInsets.symmetric(horizontal: 16),
//                 decoration: BoxDecoration(
//                   color: AppColors.cardColor,
//                   borderRadius: BorderRadius.circular(14),
//                   border: Border.all(color: AppColors.neonBlue),
//                 ),

//                 child: DropdownButtonHideUnderline(
//                   child: DropdownButton<String>(
//                     value: selectedAreaType,
//                     dropdownColor: AppColors.cardColor,
//                     iconEnabledColor: Colors.white,
//                     isExpanded: true,

//                     hint: const Text(
//                       'Area Type *',
//                       style: TextStyle(color: AppColors.textSecondary),
//                     ),

//                     style: const TextStyle(color: Colors.white),

//                     items: areaTypes
//                         .map(
//                           (t) => DropdownMenuItem(
//                             value: t,
//                             child: Text(t[0].toUpperCase() + t.substring(1)),
//                           ),
//                         )
//                         .toList(),

//                     onChanged: (v) => setState(() => selectedAreaType = v),
//                   ),
//                 ),
//               ),

//               const SizedBox(height: 20),

//               // Room No
//               TextField(
//                 controller: roomController,
//                 keyboardType: TextInputType.number,
//                 style: const TextStyle(color: Colors.white),
//                 decoration: InputDecoration(hintText: 'Room No (e.g. 4, 9)'),
//               ),

//               const SizedBox(height: 20),

//               // Hazard Type
//               TextField(
//                 controller: hazardController,
//                 style: const TextStyle(color: Colors.white),
//                 decoration: const InputDecoration(
//                   hintText: 'Hazard Type (e.g. fire, smoke)',
//                 ),
//               ),

//               const SizedBox(height: 40),

//               PrimaryButton(text: 'SEND ALERT', onTap: submitAlert),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
