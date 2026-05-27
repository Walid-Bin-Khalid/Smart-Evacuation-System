import 'package:flutter/material.dart';

import '../../Core/Constants/app_colors.dart';
import '../../Services/graph_loader_service.dart';
import '../../Services/mock_alert_service.dart';
import '../../Services/pathfinding_service.dart';
import '../../widgets/primary_button.dart';
import 'ar_navigation_screen.dart';
import 'evacuation_navigation_screen.dart';

class SlamInitializationScreen extends StatefulWidget {
  const SlamInitializationScreen({super.key});

  @override
  State<SlamInitializationScreen> createState() =>
      _SlamInitializationScreenState();
}

class _SlamInitializationScreenState extends State<SlamInitializationScreen> {
  final TextEditingController roomController = TextEditingController();
  final TextEditingController hazardController = TextEditingController();

  String? selectedFloor;
  String? selectedAreaType;
  bool isInitializing = false;
  String statusMessage = 'Initializing SLAM & Loading Evacuation Route...';

  final List<String> _floors = ['Ground', 'First', 'Second'];
  final List<String> _areaTypes = ['room', 'corridor', 'stairs', 'door'];

  @override
  void dispose() {
    roomController.dispose();
    hazardController.dispose();
    super.dispose();
  }

  //  Manual route → EvacuationNavigationScreen
  Future<void> startEvacuation() async {
    if (selectedFloor == null || selectedAreaType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Floor and Area Type are required')),
      );
      return;
    }

    setState(() {
      isInitializing = true;
      statusMessage = 'Loading building graph...';
    });

    try {
      final graph = await GraphLoaderService.loadGraph();
      setState(() => statusMessage = 'Initializing pathfinding engine...');

      final pathfinder = PathfindingService(graph);

      final activeAlert = MockAlertService().currentAlert;
      if (activeAlert != null && activeAlert.isActive) {
        pathfinder.applyHazardAlert(activeAlert.hazardNodeId);
      }

      setState(() => statusMessage = 'Calculating safest route...');

      final location = EvacueeLocation(
        floor: selectedFloor!,
        areaType: selectedAreaType!,
        roomNumber: roomController.text.trim().isEmpty
            ? selectedAreaType!.toUpperCase()
            : roomController.text.trim(),
      );

      final evacuationPath = pathfinder.findPathFromFormInput(location);

      if (!mounted) return;

      if (evacuationPath == null) {
        setState(() => isInitializing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'No safe route found. Please move to a nearby corridor.',
            ),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      setState(() => statusMessage = 'Route found! Launching navigation...');
      await Future.delayed(const Duration(milliseconds: 600));

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => EvacuationNavigationScreen(
            floor: selectedFloor!,
            areaType: selectedAreaType!,
            roomNumber: roomController.text.trim(),
            evacuationPath: evacuationPath,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => isInitializing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ─────────────────────────────────────────────
  //  AR Navigation → ARNavigationScreen
  //  ✅ selectedFloor pass karo
  // ─────────────────────────────────────────────
  void startARNavigation() {
    if (selectedFloor == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select your floor first')),
      );
      return;
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => ARNavigationScreen(
          initialFloor: selectedFloor!, // ✅ floor pass ho raha hai
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Initialize Navigation')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Current Location',
                style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              const Text(
                'Provide your current location to start evacuation guidance.',
                style: TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 35),

              /// FLOOR DROPDOWN
              const Text(
                'Floor *',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: AppColors.cardColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.neonBlue),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    dropdownColor: AppColors.cardColor,
                    value: selectedFloor,
                    hint: const Text('Select Floor'),
                    isExpanded: true,
                    items: _floors.map((floor) {
                      return DropdownMenuItem(
                        value: floor,
                        child: Text('$floor Floor'),
                      );
                    }).toList(),
                    onChanged: (value) => setState(() => selectedFloor = value),
                  ),
                ),
              ),

              const SizedBox(height: 25),

              /// AREA TYPE DROPDOWN
              const Text(
                'Area Type *',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: AppColors.cardColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.neonBlue),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    dropdownColor: AppColors.cardColor,
                    value: selectedAreaType,
                    hint: const Text('Select Area Type'),
                    isExpanded: true,
                    items: _areaTypes.map((area) {
                      return DropdownMenuItem(
                        value: area,
                        child: Text(area[0].toUpperCase() + area.substring(1)),
                      );
                    }).toList(),
                    onChanged: (value) =>
                        setState(() => selectedAreaType = value),
                  ),
                ),
              ),

              const SizedBox(height: 25),

              /// ROOM NUMBER
              TextField(
                controller: roomController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: 'Room / Area Number (e.g. 1, 4, 9)',
                  filled: true,
                  fillColor: AppColors.cardColor,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: AppColors.neonBlue),
                  ),
                ),
              ),

              const SizedBox(height: 25),

              /// HAZARD INFO
              TextField(
                controller: hazardController,
                decoration: InputDecoration(
                  hintText: 'Hazard Details (Optional)',
                  filled: true,
                  fillColor: AppColors.cardColor,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: AppColors.neonBlue),
                  ),
                ),
              ),

              const SizedBox(height: 40),

              /// LOADING
              if (isInitializing) ...[
                const Center(
                  child: CircularProgressIndicator(color: AppColors.neonBlue),
                ),
                const SizedBox(height: 20),
                Center(
                  child: Text(
                    statusMessage,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                ),
                const SizedBox(height: 30),
              ],

              /// START EVACUATION
              PrimaryButton(
                text: isInitializing ? 'INITIALIZING...' : 'START EVACUATION',
                onTap: isInitializing ? () {} : startEvacuation,
              ),

              const SizedBox(height: 16),

              /// START AR NAVIGATION
              SizedBox(
                width: double.infinity,
                height: 58,
                child: OutlinedButton.icon(
                  onPressed: isInitializing ? null : startARNavigation,
                  icon: const Icon(Icons.view_in_ar, color: AppColors.neonBlue),
                  label: const Text(
                    'START AR NAVIGATION',
                    style: TextStyle(
                      color: AppColors.neonBlue,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(
                      color: AppColors.neonBlue,
                      width: 1.5,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              const Center(
                child: Text(
                  'AR Navigation uses your camera to guide\nyou in real-time using SLAM technology.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
