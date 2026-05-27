import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../Home/home_screen.dart';
import '../../Core/Constants/app_colors.dart';
import '../Authentication/login_screen.dart';

class LaunchScreen extends StatefulWidget {
  const LaunchScreen({super.key});

  @override
  State<LaunchScreen> createState() => _LaunchScreenState();
}

class _LaunchScreenState extends State<LaunchScreen> {
  @override
  void initState() {
    super.initState();

    checkLoginStatus();
  }

  /// CHECK LOGIN STATUS

  Future<void> checkLoginStatus() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    bool isLoggedIn = prefs.getBool('isLoggedIn') ?? false;

    await Future.delayed(const Duration(seconds: 3));

    if (!mounted) return;

    Navigator.pushReplacement(
      context,

      MaterialPageRoute(
        builder: (_) => isLoggedIn ? HomeScreen() : const LoginScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,

            children: [
              /// LOGO
              Container(
                height: 120,
                width: 120,

                decoration: BoxDecoration(
                  color: AppColors.neonBlue,

                  borderRadius: BorderRadius.circular(30),
                ),

                child: const Icon(
                  Icons.directions_run,
                  size: 65,
                  color: Colors.white,
                ),
              ),

              const SizedBox(height: 30),

              /// APP NAME
              RichText(
                text: const TextSpan(
                  children: [
                    TextSpan(
                      text: "Intelli",

                      style: TextStyle(
                        color: AppColors.neonBlue,
                        fontSize: 38,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    TextSpan(
                      text: "Trak",

                      style: TextStyle(
                        color: AppColors.neonBlue,
                        fontSize: 38,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              /// SUBTITLE
              const Text(
                "Emergency Evacuation\nAssistance",

                textAlign: TextAlign.center,

                style: TextStyle(fontSize: 17, color: Colors.grey, height: 1.5),
              ),

              const SizedBox(height: 70),

              /// LOADER
              const SizedBox(
                width: 35,
                height: 35,

                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  color: AppColors.neonBlue,
                ),
              ),

              const SizedBox(height: 25),

              /// LOADING TEXT
              const Text(
                "Loading...",

                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
















// import 'package:flutter/material.dart';
// import 'package:shared_preferences/shared_preferences.dart';

// import '../Home/home_screen.dart';
// import '../../Core/Constants/app_colors.dart';
// import '../Authentication/login_screen.dart';

// class LaunchScreen extends StatefulWidget {
//   const LaunchScreen({super.key});

//   @override
//   State<LaunchScreen> createState() => _LaunchScreenState();
// }

// class _LaunchScreenState extends State<LaunchScreen> {
//   @override
//   void initState() {
//     super.initState();

//     Future.delayed(const Duration(seconds: 3), () {
//       if (!mounted) return;

//       Navigator.pushReplacement(
//         context,
//         MaterialPageRoute(builder: (_) => const LoginScreen()),
//       );
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: SafeArea(
//         child: Center(
//           child: Column(
//             mainAxisAlignment: MainAxisAlignment.center,

//             children: [
//               // Logo Container
//               Container(
//                 height: 120,
//                 width: 120,

//                 decoration: BoxDecoration(
//                   color: AppColors.neonBlue,
//                   borderRadius: BorderRadius.circular(30),
//                 ),

//                 child: const Icon(
//                   Icons.directions_run,
//                   size: 65,
//                   color: Colors.white,
//                 ),
//               ),

//               const SizedBox(height: 30),

//               // App Name
//               RichText(
//                 text: TextSpan(
//                   children: [
//                     const TextSpan(
//                       text: "Intelli",
//                       style: TextStyle(
//                         color: AppColors.neonBlue,
//                         fontSize: 38,
//                         fontWeight: FontWeight.bold,
//                       ),
//                     ),

//                     TextSpan(
//                       text: "Trak",
//                       style: TextStyle(
//                         color: AppColors.neonBlue,
//                         fontSize: 38,
//                         fontWeight: FontWeight.bold,
//                       ),
//                     ),
//                   ],
//                 ),
//               ),

//               const SizedBox(height: 14),

//               // Subtitle
//               const Text(
//                 "Emergency Evacuation\nAssistance",
//                 textAlign: TextAlign.center,

//                 style: TextStyle(fontSize: 17, color: Colors.grey, height: 1.5),
//               ),

//               const SizedBox(height: 70),

//               // Loader
//               SizedBox(
//                 width: 35,
//                 height: 35,

//                 child: CircularProgressIndicator(
//                   strokeWidth: 3,
//                   color: AppColors.neonBlue,
//                 ),
//               ),

//               const SizedBox(height: 25),

//               // Loading Text
//               const Text(
//                 "Loading...",
//                 style: TextStyle(fontSize: 16, color: Colors.grey),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
