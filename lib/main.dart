

import 'package:flutter/material.dart';

import 'package:smart_evacuation_system/Screens/Launch/launch_screen.dart';
import 'package:smart_evacuation_system/Screens/Home/home_screen.dart';
import 'Core/Theme/app_theme.dart';
import 'Services/api_service.dart';
import 'Services/websocket_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // App start pe token SharedPrefs se load karo
  await ApiService().loadToken();

  runApp(const IntelliTrakApp());
}

class IntelliTrakApp extends StatelessWidget {
  const IntelliTrakApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'IntelliTrak',
      theme: AppTheme.darkTheme,
      home: const _AuthGate(),
    );
  }
}

// ── Auth Gate ─────────────────────────────────────────────────
// TOKEN = single source of truth.
// isLoggedIn SharedPref check HATA DIYA — woh stale ho sakta tha.
// Agar token hai aur non-empty hai → logged in.
// ─────────────────────────────────────────────────────────────
class _AuthGate extends StatefulWidget {
  const _AuthGate();

  @override
  State<_AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<_AuthGate> {
  bool _checking = true;
  bool _isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    _check();
  }

  Future<void> _check() async {
    // ── Token = single source of truth ──────────────────
    final token = ApiService().token;
    final isValid = token != null && token.isNotEmpty;

    if (isValid) {
      // WebSocket connect karo — disconnect guard WebSocketService ke andar hai
      WebSocketService().connect();
    }

    setState(() {
      _isLoggedIn = isValid;
      _checking = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_checking) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return _isLoggedIn ? const HomeScreen() : const LaunchScreen();
  }
}
















// //  Changes:
// //    - App start pe ApiService token load karo
// //    - Agar token hai (already logged in) → HomeScreen
// //    - Nahi hai → LaunchScreen (same as before)

// import 'package:flutter/material.dart';
// import 'package:shared_preferences/shared_preferences.dart';

// import 'package:smart_evacuation_system/Screens/Launch/launch_screen.dart';
// import 'package:smart_evacuation_system/Screens/Home/home_screen.dart';
// import 'Core/Theme/app_theme.dart';
// import 'Services/api_service.dart';
// import 'Services/websocket_service.dart';

// void main() async {
//   WidgetsFlutterBinding.ensureInitialized();

//   // App start pe token load karo
//   await ApiService().loadToken();

//   runApp(const IntelliTrakApp());
// }

// class IntelliTrakApp extends StatelessWidget {
//   const IntelliTrakApp({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       debugShowCheckedModeBanner: false,
//       title: 'IntelliTrak',
//       theme: AppTheme.darkTheme,
//       home: const _AuthGate(),
//     );
//   }
// }

// /// ── Auth Gate ──
// /// Agar pehle se logged in hai to seedha HomeScreen,
// /// warna LaunchScreen (apna existing flow same rahega)
// class _AuthGate extends StatefulWidget {
//   const _AuthGate();

//   @override
//   State<_AuthGate> createState() => _AuthGateState();
// }

// class _AuthGateState extends State<_AuthGate> {
//   bool _checking = true;
//   bool _isLoggedIn = false;

//   @override
//   void initState() {
//     super.initState();
//     _check();
//   }

//   Future<void> _check() async {
//     final prefs = await SharedPreferences.getInstance();
//     final loggedIn = prefs.getBool('isLoggedIn') ?? false;

//     if (loggedIn && ApiService().token != null) {
//       // WebSocket bhi connect karo
//       WebSocketService().connect();
//       setState(() {
//         _isLoggedIn = true;
//         _checking = false;
//       });
//     } else {
//       setState(() {
//         _isLoggedIn = false;
//         _checking = false;
//       });
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     if (_checking) {
//       return const Scaffold(
//         body: Center(child: CircularProgressIndicator()),
//       );
//     }
//     return _isLoggedIn ? const HomeScreen() : const LaunchScreen();
//   }
// }
