import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';

import 'signup_screen.dart';
import 'reset_password_screen.dart';
import '../../Screens/Home/home_screen.dart';
import '../Permissions/permission_screen.dart';
import '../../widgets/primary_button.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool obscurePassword = true;
  bool _isLoading = false;

  void login() async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Please fill all fields")));
      return;
    }

    // Basic email format check
    if (!email.contains('@') || !email.contains('.')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter a valid email")),
      );
      return;
    }

    setState(() => _isLoading = true);

    // ── TO-DO: Firebase Auth ──
    // FirebaseAuth.instance.signInWithEmailAndPassword(
    //   email: email, password: password,
    // );
    // Aur Firestore se name/employeeId fetch karo:
    // final doc = await FirebaseFirestore.instance
    //     .collection('users').doc(uid).get();
    // prefs.setString('fullName', doc['fullName']);
    // prefs.setString('employeeId', doc['employeeId']);

    // Temporary local check — Firebase lagny tak kaam karega
    final prefs = await SharedPreferences.getInstance();
    final savedEmail = prefs.getString('email') ?? 'waleedqureshi063@gmail.com';
    final savedPassword = prefs.getString('password') ?? 'FYP2026';

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (email == savedEmail && password == savedPassword) {
      await prefs.setBool('isLoggedIn', true);

      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Login Successful")));

      final locationOk = await Permission.location.isGranted;
      final cameraOk = await Permission.camera.isGranted;
      final notifOk = await Permission.notification.isGranted;
      final allGranted = locationOk && cameraOk && notifOk;

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) =>
              allGranted ? const HomeScreen() : const PermissionScreen(),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Invalid email or password")),
      );
    }
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Center(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 30),

                  const Center(
                    child: Column(
                      children: [
                        Text(
                          "Welcome Back!",
                          style: TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          "Login to your account",
                          style: TextStyle(color: Colors.grey, fontSize: 15),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 45),

                  // ── Email ──
                  const Text(
                    "Email",
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      hintText: "Enter your email",
                      filled: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      prefixIcon: const Icon(Icons.email_outlined),
                    ),
                  ),

                  const SizedBox(height: 25),

                  // ── Password ──
                  const Text(
                    "Password",
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: passwordController,
                    obscureText: obscurePassword,
                    decoration: InputDecoration(
                      hintText: "Enter Password",
                      filled: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          obscurePassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                        ),
                        onPressed: () {
                          setState(() => obscurePassword = !obscurePassword);
                        },
                      ),
                    ),
                  ),

                  const SizedBox(height: 14),

                  // ── Forgot Password ──
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ResetPasswordScreen(),
                          ),
                        );
                      },
                      child: const Text(
                        "Forgot Password?",
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),

                  const SizedBox(height: 25),

                  // ── Login Button ──
                  _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : PrimaryButton(text: "LOGIN", onTap: login),

                  const SizedBox(height: 30),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Don't have an account?"),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const SignupScreen(),
                            ),
                          );
                        },
                        child: const Text(
                          "Sign Up",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}




// import 'package:flutter/material.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:permission_handler/permission_handler.dart';

// import 'signup_screen.dart';
// import 'reset_password_screen.dart';
// import '../../Screens/Home/home_screen.dart';
// import '../Permissions/permission_screen.dart';
// import '../../widgets/primary_button.dart';

// class LoginScreen extends StatefulWidget {
//   const LoginScreen({super.key});

//   @override
//   State<LoginScreen> createState() => _LoginScreenState();
// }

// class _LoginScreenState extends State<LoginScreen> {
//   final TextEditingController emailController = TextEditingController();
//   final TextEditingController passwordController = TextEditingController();

//   bool obscurePassword = true;
//   bool _isLoading = false;

//   void login() async {
//     final email = emailController.text.trim();
//     final password = passwordController.text.trim();

//     if (email.isEmpty || password.isEmpty) {
//       ScaffoldMessenger.of(
//         context,
//       ).showSnackBar(const SnackBar(content: Text("Please fill all fields")));
//       return;
//     }

//     // Basic email format check
//     if (!email.contains('@') || !email.contains('.')) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text("Please enter a valid email")),
//       );
//       return;
//     }

//     setState(() => _isLoading = true);

//     // ── TO-DO: Firebase Auth ──
//     // FirebaseAuth.instance.signInWithEmailAndPassword(
//     //   email: email, password: password,
//     // );
//     // Aur Firestore se name/employeeId fetch karo:
//     // final doc = await FirebaseFirestore.instance
//     //     .collection('users').doc(uid).get();
//     // prefs.setString('fullName', doc['fullName']);
//     // prefs.setString('employeeId', doc['employeeId']);

//     // Temporary local check — Firebase lagny tak kaam karega
//     final prefs = await SharedPreferences.getInstance();
//     final savedEmail = prefs.getString('email') ?? 'waleedqureshi063@gmail.com';
//     final savedPassword = prefs.getString('password') ?? 'FYP2026';
//     final savedName = prefs.getString('fullName') ?? 'Waleed Qureshi';
//     final savedId = prefs.getString('employeeId') ?? 'CSLECT-002';

//     if (!mounted) return;
//     setState(() => _isLoading = false);

//     if (email == savedEmail && password == savedPassword) {
//       await prefs.setBool('isLoggedIn', true);

//       if (!mounted) return;

//       ScaffoldMessenger.of(
//         context,
//       ).showSnackBar(const SnackBar(content: Text("Login Successful")));

//       final locationOk = await Permission.location.isGranted;
//       final cameraOk = await Permission.camera.isGranted;
//       final notifOk = await Permission.notification.isGranted;
//       final allGranted = locationOk && cameraOk && notifOk;

//       if (!mounted) return;

//       Navigator.pushReplacement(
//         context,
//         MaterialPageRoute(
//           builder: (_) =>
//               allGranted ? const HomeScreen() : const PermissionScreen(),
//         ),
//       );
//     } else {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text("Invalid email or password")),
//       );
//     }
//   }

//   @override
//   void dispose() {
//     emailController.dispose();
//     passwordController.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: SafeArea(
//         child: Padding(
//           padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
//           child: Center(
//             child: SingleChildScrollView(
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   const SizedBox(height: 30),

//                   const Center(
//                     child: Column(
//                       children: [
//                         Text(
//                           "Welcome Back!",
//                           style: TextStyle(
//                             fontSize: 30,
//                             fontWeight: FontWeight.bold,
//                           ),
//                         ),
//                         SizedBox(height: 8),
//                         Text(
//                           "Login to your account",
//                           style: TextStyle(color: Colors.grey, fontSize: 15),
//                         ),
//                       ],
//                     ),
//                   ),

//                   const SizedBox(height: 45),

//                   // ── Email ──
//                   const Text(
//                     "Email",
//                     style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
//                   ),
//                   const SizedBox(height: 10),
//                   TextField(
//                     controller: emailController,
//                     keyboardType: TextInputType.emailAddress,
//                     decoration: InputDecoration(
//                       hintText: "Enter your email",
//                       filled: true,
//                       border: OutlineInputBorder(
//                         borderRadius: BorderRadius.circular(12),
//                         borderSide: BorderSide.none,
//                       ),
//                       prefixIcon: const Icon(Icons.email_outlined),
//                     ),
//                   ),

//                   const SizedBox(height: 25),

//                   // ── Password ──
//                   const Text(
//                     "Password",
//                     style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
//                   ),
//                   const SizedBox(height: 10),
//                   TextField(
//                     controller: passwordController,
//                     obscureText: obscurePassword,
//                     decoration: InputDecoration(
//                       hintText: "Enter Password",
//                       filled: true,
//                       border: OutlineInputBorder(
//                         borderRadius: BorderRadius.circular(12),
//                         borderSide: BorderSide.none,
//                       ),
//                       suffixIcon: IconButton(
//                         icon: Icon(
//                           obscurePassword
//                               ? Icons.visibility_off
//                               : Icons.visibility,
//                         ),
//                         onPressed: () {
//                           setState(() => obscurePassword = !obscurePassword);
//                         },
//                       ),
//                     ),
//                   ),

//                   const SizedBox(height: 14),

//                   // ── Forgot Password ──
//                   Align(
//                     alignment: Alignment.centerRight,
//                     child: TextButton(
//                       onPressed: () {
//                         Navigator.push(
//                           context,
//                           MaterialPageRoute(
//                             builder: (_) => const ResetPasswordScreen(),
//                           ),
//                         );
//                       },
//                       child: const Text(
//                         "Forgot Password?",
//                         style: TextStyle(fontWeight: FontWeight.w600),
//                       ),
//                     ),
//                   ),

//                   const SizedBox(height: 25),

//                   // ── Login Button ──
//                   _isLoading
//                       ? const Center(child: CircularProgressIndicator())
//                       : PrimaryButton(text: "LOGIN", onTap: login),

//                   const SizedBox(height: 30),

//                   Row(
//                     mainAxisAlignment: MainAxisAlignment.center,
//                     children: [
//                       const Text("Don't have an account?"),
//                       TextButton(
//                         onPressed: () {
//                           Navigator.push(
//                             context,
//                             MaterialPageRoute(
//                               builder: (_) => const SignupScreen(),
//                             ),
//                           );
//                         },
//                         child: const Text(
//                           "Sign Up",
//                           style: TextStyle(fontWeight: FontWeight.bold),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }
