import 'dart:io';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../Core/Constants/app_colors.dart';
import '../../widgets/primary_button.dart';
import '../../Services/api_service.dart';
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
  final TextEditingController messageController = TextEditingController();

  bool _isLoading = false;

  @override
  void dispose() {
    roomController.dispose();
    hazardController.dispose();
    messageController.dispose();
    super.dispose();
  }

  void submitAlert() async {
    // ── Validation ───────────────────────────────────────
    if (selectedFloor == null || selectedAreaType == null) {
      _showSnack('Floor and Area Type are required');
      return;
    }
    if (hazardController.text.trim().isEmpty) {
      _showSnack('Hazard Type is required');
      return;
    }

    setState(() => _isLoading = true);

    try {
      // ── SharedPrefs se employee info ─────────────────
      final prefs = await SharedPreferences.getInstance();
      final employeeId = prefs.getString('employeeId') ?? 'UNKNOWN';
      final employeeName = prefs.getString('fullName') ?? 'Unknown';

      // ── roomNumber: null agar empty (logically correct) ──
      final roomInput = roomController.text.trim();
      final roomNumber = roomInput.isEmpty ? null : roomInput;

      // ── Auto message ─────────────────────────────────
      final message = messageController.text.trim().isEmpty
          ? '${hazardController.text.trim()} reported on $selectedFloor floor'
          : messageController.text.trim();

      // ── API call (severity auto-calculate hogi andar) ──
      final result = await ApiService().createSosAlert(
        hazardType: hazardController.text.trim(),
        floor: selectedFloor!,
        areaType: selectedAreaType!,
        roomNumber: roomNumber, // null OK hai
        reportedBy: employeeId,
        reportedByName: employeeName,
        message: message,
        imageFile: widget.capturedImage,
      );

      if (!mounted) return;

      if (result.success) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const AlertSendingScreen()),
        );
      } else {
        _showSnack(result.error ?? 'Alert failed', isError: true);
      }
    } catch (e) {
      if (mounted) {
        _showSnack('Unexpected error: $e', isError: true);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? Colors.red : null,
      ),
    );
  }

  Widget _styledField({required Widget child}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.neonBlue),
      ),
      child: child,
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

              // ── Attached image preview ──
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
                        'Attached Picture',
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

              // ── Floor ──
              _fieldLabel('Floor *'),
              const SizedBox(height: 10),
              _styledField(
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

              // ── Area Type ──
              _fieldLabel('Area Type *'),
              const SizedBox(height: 10),
              _styledField(
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

              // ── Room No (optional) ──
              _fieldLabel('Room No'),
              const SizedBox(height: 10),
              _styledField(
                child: TextField(
                  controller: roomController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    hintText: 'e.g. 4, 9  (optional)',
                    hintStyle: TextStyle(color: AppColors.textSecondary),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // ── Hazard Type ──
              _fieldLabel('Hazard Type *'),
              const SizedBox(height: 10),
              _styledField(
                child: TextField(
                  controller: hazardController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    hintText: 'e.g. fire, smoke',
                    hintStyle: TextStyle(color: AppColors.textSecondary),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // ── Message (optional) ──
              _fieldLabel('Message (Optional)'),
              const SizedBox(height: 10),
              _styledField(
                child: TextField(
                  controller: messageController,
                  maxLines: 2,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    hintText: 'Describe the emergency...',
                    hintStyle: TextStyle(color: AppColors.textSecondary),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
              const SizedBox(height: 40),

              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : PrimaryButton(text: 'SEND ALERT', onTap: submitAlert),
            ],
          ),
        ),
      ),
    );
  }

  Widget _fieldLabel(String text) => Text(
    text,
    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
  );
}