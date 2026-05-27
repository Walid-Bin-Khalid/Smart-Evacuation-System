import 'package:flutter/material.dart';

class NeonTextField extends StatelessWidget {
  final String hint;
  final bool obscure;
  final TextEditingController controller;

  const NeonTextField({
    super.key,
    required this.hint,
    required this.controller,
    this.obscure = false,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscure,

      decoration: InputDecoration(hintText: hint, border: OutlineInputBorder()),
    );
  }
}






















// class NeonTextField extends StatelessWidget {
//   final String hint;
//   final bool obscure;

//   const NeonTextField({super.key, required this.hint, this.obscure = false, required TextEditingController controller});

//   @override
//   Widget build(BuildContext context) {
//     return TextField(
//       obscureText: obscure,
//       style: const TextStyle(color: Colors.white),
//       decoration: InputDecoration(
//         hintText: hint,
//         hintStyle: const TextStyle(color: AppColors.textSecondary),
//         filled: true,
//         fillColor: AppColors.cardColor,

//         enabledBorder: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(14),
//           borderSide: const BorderSide(color: AppColors.neonBlue),
//         ),

//         focusedBorder: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(14),
//           borderSide: const BorderSide(color: AppColors.neonGreen, width: 2),
//         ),
//       ),
//     );
//   }
// }
