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
