import 'dart:async';

import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../Alert/emergency_alert_receiving_screen.dart';
import '../SOS/sos_confirmation_screen.dart';
import '../Profile/profile_screen.dart';
import '../../Services/websocket_service.dart';
import '../Navigation/slam_initialization_screen.dart';
import '../../Core/Constants/app_colors.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String connectionStatus = "Checking...";
  String gpsStatus = "Checking...";
  String lastSync = "--";

  // ── User info ──
  String _displayName = 'Employee';
  String _employeeId = '';
  String _role = 'Employee';

  // ── Alert State ──
  final WebSocketService _alertService = WebSocketService(); // ← CHANGED
  StreamSubscription<EvacuationAlert?>? _alertSubscription;
  EvacuationAlert? _currentAlert;

  bool get _isEmergency => _currentAlert != null && _currentAlert!.isActive;

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
    checkInternet();
    checkGPS();
    updateSyncTime();
    _listenToAlerts();
  }

  Future<void> _loadUserInfo() async {
    // ← NEW
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _displayName = prefs.getString('fullName') ?? 'Employee';
      _employeeId = prefs.getString('employeeId') ?? '';
      _role = prefs.getString('role') ?? 'Employee';
    });
  }

  void _listenToAlerts() {
    _alertSubscription = _alertService.alertStream.listen((alert) {
      setState(() => _currentAlert = alert);
      updateSyncTime();

      if (alert != null && alert.isActive && mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => EmergencyAlertScreen(
              emergencyType: alert.hazardType.toUpperCase(),
              affectedFloor: alert.floor,
              blockedArea: alert.hazardNodeId,
            ),
          ),
        );
      }
    });
  }

  Future<void> checkInternet() async {
    var connectivityResult = await Connectivity().checkConnectivity();
    setState(() {
      if (connectivityResult.contains(ConnectivityResult.mobile) ||
          connectivityResult.contains(ConnectivityResult.wifi)) {
        connectionStatus = "Online";
      } else {
        connectionStatus = "Offline";
      }
    });
  }

  Future<void> checkGPS() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() => gpsStatus = "GPS Off");
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied) {
      setState(() => gpsStatus = "Permission Denied");
      return;
    }
    if (permission == LocationPermission.deniedForever) {
      setState(() => gpsStatus = "Permission Blocked");
      return;
    }

    setState(() => gpsStatus = "GPS Active");
  }

  Future<void> requestLocationPermission() async {
    PermissionStatus status = await Permission.location.request();
    if (status.isGranted) {
      setState(() => gpsStatus = "GPS Active");
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Location Permission Granted')),
      );
    } else {
      setState(() => gpsStatus = "Permission Denied");
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Location Permission Denied')),
      );
    }
  }

  void updateSyncTime() {
    setState(() {
      lastSync = DateFormat('hh:mm a').format(DateTime.now());
    });
  }

  @override
  void dispose() {
    _alertSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        title: Text(
          // ← CHANGED
          'Hello, $_displayName',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          // Mock test button HATA DIYA ✓
          Padding(
            padding: const EdgeInsets.only(right: 15),
            child: GestureDetector(
              onTap: () {
                if (_isEmergency) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => EmergencyAlertScreen(
                        emergencyType: _currentAlert!.hazardType.toUpperCase(),
                        affectedFloor: _currentAlert!.floor,
                        blockedArea: _currentAlert!.hazardNodeId,
                      ),
                    ),
                  );
                }
              },
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: _isEmergency ? Colors.red : AppColors.neonBlue,
                        width: _isEmergency ? 2 : 1,
                      ),
                      boxShadow: _isEmergency
                          ? [
                              BoxShadow(
                                color: Colors.red.withValues(alpha: 0.4),
                                blurRadius: 10,
                                spreadRadius: 1,
                              ),
                            ]
                          : null,
                    ),
                    child: Icon(
                      _isEmergency
                          ? Icons.notifications_active
                          : Icons.notifications_none,
                      size: 22,
                      color: _isEmergency ? Colors.red : AppColors.neonBlue,
                    ),
                  ),

                  if (_isEmergency)
                    Positioned(
                      top: -4,
                      right: -4,
                      child: Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.background,
                            width: 1.5,
                          ),
                        ),
                        child: const Center(
                          child: Text(
                            '1',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),

      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          child: Column(
            children: [
              /// STATUS CARD
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.cardColor,
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(
                    color: _isEmergency ? Colors.red : AppColors.neonBlue,
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: _isEmergency ? Colors.red : AppColors.neonBlue,
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.circle,
                              color: connectionStatus == "Online"
                                  ? AppColors.neonGreen
                                  : Colors.red,
                              size: 12,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              connectionStatus,
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          gpsStatus,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 25),

                    Icon(
                      _isEmergency ? Icons.warning_rounded : Icons.shield,
                      color: _isEmergency ? Colors.red : AppColors.neonGreen,
                      size: 50,
                    ),

                    const SizedBox(height: 15),

                    Text(
                      _isEmergency ? 'DANGER' : 'SAFE',
                      style: TextStyle(
                        color: _isEmergency ? Colors.red : AppColors.neonGreen,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                    ),

                    const SizedBox(height: 10),

                    Text(
                      _isEmergency
                          ? 'Emergency Alert Active!\n${_currentAlert!.hazardType.toUpperCase()} on ${_currentAlert!.floor} Floor'
                          : 'You are Safe',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: _isEmergency
                            ? Colors.red.shade300
                            : AppColors.textSecondary,
                        fontSize: 14,
                      ),
                    ),

                    const SizedBox(height: 20),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.access_time,
                          size: 16,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          'Last Sync: $lastSync',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),

                    if (_isEmergency) ...[
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    const SlamInitializationScreen(),
                              ),
                            );
                          },
                          icon: const Icon(
                            Icons.directions_run,
                            color: Colors.white,
                          ),
                          label: const Text(
                            'Start Evacuation',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                          ),
                        ),
                      ),

                      // Clear alert button (testing) — production mein hata dena
                      TextButton(
                        onPressed: () => _alertService.clearAlert(),
                        child: const Text(
                          '[TEST] Clear Alert',
                          style: TextStyle(color: Colors.grey, fontSize: 11),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 40),

              /// SOS BUTTON
              Expanded(
                child: Center(
                  child: GestureDetector(
                    onTap: () {
                      updateSyncTime();
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const SOSConfirmationScreen(),
                        ),
                      );
                    },
                    child: Container(
                      width: 220,
                      height: 220,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.neonBlue, width: 5),
                        gradient: const RadialGradient(
                          colors: [AppColors.cardColor, Colors.black],
                        ),
                        boxShadow: const [
                          BoxShadow(
                            color: AppColors.neonBlue,
                            blurRadius: 25,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(
                              Icons.warning_rounded,
                              color: AppColors.neonBlue,
                              size: 45,
                            ),
                            SizedBox(height: 10),
                            Text(
                              'SOS',
                              style: TextStyle(
                                fontSize: 42,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 2,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Emergency',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              /// BOTTOM NAVIGATION
              Container(
                padding: const EdgeInsets.symmetric(vertical: 15),
                decoration: BoxDecoration(
                  color: AppColors.cardColor,
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(color: AppColors.neonBlue, width: 1),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    const _BottomItem(
                      icon: Icons.home,
                      label: 'Home',
                      isSelected: true,
                    ),
                    _BottomItem(
                      icon: Icons.location_on,
                      label: 'Location',
                      onTap: requestLocationPermission,
                    ),
                    const _BottomItem(icon: Icons.people, label: 'Contacts'),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ProfileScreen(
                              // ← CHANGED
                              employeeName: _displayName,
                              employeeId: _employeeId,
                              department: _role,
                            ),
                          ),
                        );
                      },
                      child: const _BottomItem(
                        icon: Icons.person,
                        label: 'Profile',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BottomItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback? onTap;

  const _BottomItem({
    required this.icon,
    required this.label,
    this.isSelected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: isSelected ? AppColors.neonBlue : AppColors.textSecondary,
          ),
          const SizedBox(height: 5),
          Text(
            label,
            style: TextStyle(
              color: isSelected ? AppColors.neonBlue : AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
