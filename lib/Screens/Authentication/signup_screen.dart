//  Changes:
//    - Local SharedPrefs save HATA DIYA
//    - ApiService().signup() se real backend call
//    - Success pe WebSocket connect + PermissionScreen

import 'package:flutter/material.dart';

import '../Permissions/permission_screen.dart';
import '../../widgets/primary_button.dart';
import '../../Services/api_service.dart';
import '../../Services/websocket_service.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final TextEditingController fullNameController = TextEditingController();
  final TextEditingController employeeIdController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController departmentController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();

  String selectedRole = 'Employee';
  final List<String> roles = ['Employee', 'Admin', 'Supervisor', 'Employer'];

  bool obscurePassword = true;
  bool obscureConfirm = true;
  bool _isLoading = false;

  void createAccount() async {
    final fullName = fullNameController.text.trim();
    final employeeId = employeeIdController.text.trim();
    final email = emailController.text.trim();
    final department = departmentController.text.trim();
    final password = passwordController.text.trim();
    final confirmPassword = confirmPasswordController.text.trim();

    // ── Validation ──
    if (fullName.isEmpty ||
        employeeId.isEmpty ||
        email.isEmpty ||
        password.isEmpty ||
        confirmPassword.isEmpty) {
      _snack('Please fill all fields');
      return;
    }
    if (!email.contains('@') || !email.contains('.')) {
      _snack('Please enter a valid email');
      return;
    }
    if (password.length < 6) {
      _snack('Password must be at least 6 characters');
      return;
    }
    if (password != confirmPassword) {
      _snack('Passwords do not match');
      return;
    }

    setState(() => _isLoading = true);

    // ── Real backend call ──────────────────────────────────
    final result = await ApiService().signup(
      employeeId: employeeId,
      name: fullName,
      email: email,
      password: password,
      confirmPassword: confirmPassword,
      department: department.isEmpty ? 'General' : department,
      role: selectedRole,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result.success) {
      // Signup ke baad auto-login karo
      final loginResult = await ApiService().login(
        email: email,
        password: password,
      );

      if (!mounted) return;

      if (loginResult.success) {
        WebSocketService().connect();
        _snack('Account Created Successfully!');
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const PermissionScreen()),
        );
      } else {
        // Signup hua par login fail — manually login karo
        _snack('Account created! Please login.');
        Navigator.pop(context);
      }
    } else {
      _snack(result.error ?? 'Signup failed');
    }
  }

  void _snack(String msg) =>
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(msg)));

  @override
  void dispose() {
    fullNameController.dispose();
    employeeIdController.dispose();
    emailController.dispose();
    departmentController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
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
                  const SizedBox(height: 20),
                  const Center(
                    child: Column(
                      children: [
                        Text(
                          'Create Account',
                          style: TextStyle(
                              fontSize: 30, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Sign up to continue',
                          style: TextStyle(color: Colors.grey, fontSize: 15),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),

                  _label('Employee ID'),
                  const SizedBox(height: 10),
                  _field(employeeIdController, 'e.g. CSLECT-002',
                      Icons.badge_outlined),
                  const SizedBox(height: 22),

                  _label('Full Name'),
                  const SizedBox(height: 10),
                  _field(fullNameController, 'Enter Full Name',
                      Icons.person_outline),
                  const SizedBox(height: 22),

                  _label('Email'),
                  const SizedBox(height: 10),
                  _field(emailController, 'Enter your email',
                      Icons.email_outlined,
                      type: TextInputType.emailAddress),
                  const SizedBox(height: 22),

                  _label('Department'),
                  const SizedBox(height: 10),
                  _field(departmentController, 'e.g. Engineering',
                      Icons.business_outlined),
                  const SizedBox(height: 22),

                  // ── Role Dropdown ──
                  _label('Role'),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade400),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: selectedRole,
                        isExpanded: true,
                        items: roles
                            .map((r) =>
                                DropdownMenuItem(value: r, child: Text(r)))
                            .toList(),
                        onChanged: (v) => setState(() => selectedRole = v!),
                      ),
                    ),
                  ),
                  const SizedBox(height: 22),

                  _label('Password'),
                  const SizedBox(height: 10),
                  TextField(
                    controller: passwordController,
                    obscureText: obscurePassword,
                    decoration: InputDecoration(
                      hintText: 'Min. 6 characters',
                      filled: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(obscurePassword
                            ? Icons.visibility_off
                            : Icons.visibility),
                        onPressed: () =>
                            setState(() => obscurePassword = !obscurePassword),
                      ),
                    ),
                  ),
                  const SizedBox(height: 22),

                  _label('Confirm Password'),
                  const SizedBox(height: 10),
                  TextField(
                    controller: confirmPasswordController,
                    obscureText: obscureConfirm,
                    decoration: InputDecoration(
                      hintText: 'Re-enter password',
                      filled: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(obscureConfirm
                            ? Icons.visibility_off
                            : Icons.visibility),
                        onPressed: () =>
                            setState(() => obscureConfirm = !obscureConfirm),
                      ),
                    ),
                  ),
                  const SizedBox(height: 35),

                  _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : PrimaryButton(text: 'SIGN UP', onTap: createAccount),

                  const SizedBox(height: 25),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Already have an account?'),
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Login',
                            style:
                                TextStyle(fontWeight: FontWeight.bold)),
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

  Widget _label(String text) => Text(
        text,
        style:
            const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
      );

  Widget _field(
    TextEditingController ctrl,
    String hint,
    IconData icon, {
    TextInputType type = TextInputType.text,
  }) =>
      TextField(
        controller: ctrl,
        keyboardType: type,
        decoration: InputDecoration(
          hintText: hint,
          filled: true,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          prefixIcon: Icon(icon),
        ),
      );
}
















// import 'package:flutter/material.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:permission_handler/permission_handler.dart';

// import '../Permissions/permission_screen.dart';
// import '../../widgets/primary_button.dart';

// class SignupScreen extends StatefulWidget {
//   const SignupScreen({super.key});

//   @override
//   State<SignupScreen> createState() => _SignupScreenState();
// }

// class _SignupScreenState extends State<SignupScreen> {
//   final TextEditingController fullNameController = TextEditingController();
//   final TextEditingController employeeIdController = TextEditingController();
//   final TextEditingController emailController = TextEditingController();
//   final TextEditingController departmentController = TextEditingController();
//   final TextEditingController passwordController = TextEditingController();
//   final TextEditingController confirmPasswordController =
//       TextEditingController();

//   String selectedRole = "Employee";
//   final List<String> roles = ["Employee", "Admin", "Supervisor", "Employer"];

//   bool obscurePassword = true;
//   bool obscureConfirm = true;
//   bool _isLoading = false;

//   void createAccount() async {
//     final fullName = fullNameController.text.trim();
//     final employeeId = employeeIdController.text.trim();
//     final email = emailController.text.trim();
//     final password = passwordController.text.trim();
//     final confirmPassword = confirmPasswordController.text.trim();

//     // ── Validation ──
//     if (fullName.isEmpty ||
//         employeeId.isEmpty ||
//         email.isEmpty ||
//         password.isEmpty ||
//         confirmPassword.isEmpty) {
//       ScaffoldMessenger.of(
//         context,
//       ).showSnackBar(const SnackBar(content: Text("Please fill all fields")));
//       return;
//     }

//     if (!email.contains('@') || !email.contains('.')) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text("Please enter a valid email")),
//       );
//       return;
//     }

//     if (password.length < 6) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text("Password must be at least 6 characters")),
//       );
//       return;
//     }

//     if (password != confirmPassword) {
//       ScaffoldMessenger.of(
//         context,
//       ).showSnackBar(const SnackBar(content: Text("Passwords do not match")));
//       return;
//     }

//     setState(() => _isLoading = true);

//     // ── TO-DO: Firebase Auth + Firestore ──
//     // final cred = await FirebaseAuth.instance
//     //     .createUserWithEmailAndPassword(email: email, password: password);
//     // await FirebaseFirestore.instance
//     //     .collection('users')
//     //     .doc(cred.user!.uid)
//     //     .set({
//     //       'fullName'  : fullName,
//     //       'employeeId': employeeId,
//     //       'email'     : email,
//     //       'role'      : selectedRole,
//     //       'department': departmentController.text.trim(),
//     //       'createdAt' : FieldValue.serverTimestamp(),
//     //     });

//     // Temporary local save — Firebase lagny tak kaam karega
//     final prefs = await SharedPreferences.getInstance();
//     await prefs.setString('fullName', fullName);
//     await prefs.setString('employeeId', employeeId);
//     await prefs.setString('email', email);
//     await prefs.setString(
//       'password',
//       password,
//     ); // Firebase aany k baad hata dena
//     await prefs.setString('role', selectedRole);
//     await prefs.setBool('isLoggedIn', true);

//     if (!mounted) return;
//     setState(() => _isLoading = false);

//     ScaffoldMessenger.of(context).showSnackBar(
//       const SnackBar(content: Text("Account Created Successfully!")),
//     );

//     // Permission check
//     final locationOk = await Permission.location.isGranted;
//     final cameraOk = await Permission.camera.isGranted;
//     final notifOk = await Permission.notification.isGranted;
//     final allGranted = locationOk && cameraOk && notifOk;

//     if (!mounted) return;

//     Navigator.pushReplacement(
//       context,
//       MaterialPageRoute(
//         builder: (_) =>
//             allGranted ? const PermissionScreen() : const PermissionScreen(),
//       ),
//     );
//   }

//   @override
//   void dispose() {
//     fullNameController.dispose();
//     employeeIdController.dispose();
//     emailController.dispose();
//     departmentController.dispose();
//     passwordController.dispose();
//     confirmPasswordController.dispose();
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
//                   const SizedBox(height: 20),

//                   const Center(
//                     child: Column(
//                       children: [
//                         Text(
//                           "Create Account",
//                           style: TextStyle(
//                             fontSize: 30,
//                             fontWeight: FontWeight.bold,
//                           ),
//                         ),
//                         SizedBox(height: 8),
//                         Text(
//                           "Sign up to continue",
//                           style: TextStyle(color: Colors.grey, fontSize: 15),
//                         ),
//                       ],
//                     ),
//                   ),

//                   const SizedBox(height: 40),

//                   // ── Employee ID ──
//                   const Text(
//                     "Employee ID",
//                     style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
//                   ),
//                   const SizedBox(height: 10),
//                   TextField(
//                     controller: employeeIdController,
//                     decoration: InputDecoration(
//                       hintText: "e.g. CSLECT-002",
//                       filled: true,
//                       border: OutlineInputBorder(
//                         borderRadius: BorderRadius.circular(12),
//                         borderSide: BorderSide.none,
//                       ),
//                       prefixIcon: const Icon(Icons.badge_outlined),
//                     ),
//                   ),

//                   const SizedBox(height: 22),

//                   // ── Full Name ──
//                   const Text(
//                     "Full Name",
//                     style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
//                   ),
//                   const SizedBox(height: 10),
//                   TextField(
//                     controller: fullNameController,
//                     decoration: InputDecoration(
//                       hintText: "Enter Full Name",
//                       filled: true,
//                       border: OutlineInputBorder(
//                         borderRadius: BorderRadius.circular(12),
//                         borderSide: BorderSide.none,
//                       ),
//                       prefixIcon: const Icon(Icons.person_outline),
//                     ),
//                   ),

//                   const SizedBox(height: 22),

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

//                   const SizedBox(height: 22),

//                   // ── Role ──
//                   const Text(
//                     "Role",
//                     style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
//                   ),
//                   const SizedBox(height: 10),
//                   Container(
//                     padding: const EdgeInsets.symmetric(horizontal: 14),
//                     decoration: BoxDecoration(
//                       borderRadius: BorderRadius.circular(12),
//                       border: Border.all(color: Colors.grey.shade400),
//                     ),
//                     child: DropdownButtonHideUnderline(
//                       child: DropdownButton<String>(
//                         value: selectedRole,
//                         isExpanded: true,
//                         items: roles
//                             .map(
//                               (r) => DropdownMenuItem(value: r, child: Text(r)),
//                             )
//                             .toList(),
//                         onChanged: (v) => setState(() => selectedRole = v!),
//                       ),
//                     ),
//                   ),

//                   const SizedBox(height: 22),

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
//                       hintText: "Min. 6 characters",
//                       filled: true,
//                       border: OutlineInputBorder(
//                         borderRadius: BorderRadius.circular(12),
//                         borderSide: BorderSide.none,
//                       ),
//                       prefixIcon: const Icon(Icons.lock_outline),
//                       suffixIcon: IconButton(
//                         icon: Icon(
//                           obscurePassword
//                               ? Icons.visibility_off
//                               : Icons.visibility,
//                         ),
//                         onPressed: () =>
//                             setState(() => obscurePassword = !obscurePassword),
//                       ),
//                     ),
//                   ),

//                   const SizedBox(height: 22),

//                   // ── Confirm Password ──
//                   const Text(
//                     "Confirm Password",
//                     style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
//                   ),
//                   const SizedBox(height: 10),
//                   TextField(
//                     controller: confirmPasswordController,
//                     obscureText: obscureConfirm,
//                     decoration: InputDecoration(
//                       hintText: "Re-enter password",
//                       filled: true,
//                       border: OutlineInputBorder(
//                         borderRadius: BorderRadius.circular(12),
//                         borderSide: BorderSide.none,
//                       ),
//                       prefixIcon: const Icon(Icons.lock_outline),
//                       suffixIcon: IconButton(
//                         icon: Icon(
//                           obscureConfirm
//                               ? Icons.visibility_off
//                               : Icons.visibility,
//                         ),
//                         onPressed: () =>
//                             setState(() => obscureConfirm = !obscureConfirm),
//                       ),
//                     ),
//                   ),

//                   const SizedBox(height: 35),

//                   // ── Signup Button ──
//                   _isLoading
//                       ? const Center(child: CircularProgressIndicator())
//                       : PrimaryButton(text: "SIGN UP", onTap: createAccount),

//                   const SizedBox(height: 25),

//                   Row(
//                     mainAxisAlignment: MainAxisAlignment.center,
//                     children: [
//                       const Text("Already have an account?"),
//                       TextButton(
//                         onPressed: () => Navigator.pop(context),
//                         child: const Text(
//                           "Login",
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








