import 'package:flutter/material.dart';

import '../../Core/Constants/app_colors.dart';

class SafeZoneScreen extends StatelessWidget {
  const SafeZoneScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),

          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,

            children: const [
              Icon(
                Icons.verified_rounded,
                size: 130,
                color: AppColors.neonGreen,
              ),

              SizedBox(height: 35),

              Text(
                'SAFE ZONE REACHED',

                textAlign: TextAlign.center,

                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: AppColors.neonGreen,
                ),
              ),

              SizedBox(height: 18),

              Text(
                'Admin has been notified.',

                textAlign: TextAlign.center,

                style: TextStyle(color: AppColors.textSecondary, fontSize: 17),
              ),

              SizedBox(height: 14),

              Text(
                'Evacuation Completed Successfully.',

                textAlign: TextAlign.center,

                style: TextStyle(color: AppColors.textSecondary, fontSize: 15),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


// import 'package:flutter/material.dart';
// import '../../Core/Constants/app_colors.dart';

// class SafeZoneScreen extends StatelessWidget {
//   const SafeZoneScreen({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: Center(
//         child: Padding(
//           padding: const EdgeInsets.all(24),
//           child: Column(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: const [
//               Icon(
//                 Icons.verified_rounded,
//                 size: 120,
//                 color: AppColors.neonGreen,
//               ),
//               SizedBox(height: 30),
//               Text(
//                 'SAFE ZONE REACHED',
//                 textAlign: TextAlign.center,
//                 style: TextStyle(
//                   fontSize: 32,
//                   fontWeight: FontWeight.bold,
//                   color: AppColors.neonGreen,
//                 ),
//               ),
//               SizedBox(height: 20),
//               Text(
//                 'Please wait for further instructions from administration.',
//                 textAlign: TextAlign.center,
//                 style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
