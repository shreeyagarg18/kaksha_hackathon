import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:lottie/lottie.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({Key? key}) : super(key: key);

  @override
  _AttendanceScreen createState() => _AttendanceScreen();
}

class _AttendanceScreen extends State<AttendanceScreen> {
  final flutterReactiveBle = FlutterReactiveBle();
  bool isBluetoothOn = false;
  bool isCheckingStatus = true;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
    _monitorBluetoothStatus();
  }

  // Monitor Bluetooth status
  void _monitorBluetoothStatus() {
    flutterReactiveBle.statusStream.listen((status) {
      setState(() {
        isBluetoothOn = status == BleStatus.ready;
        isCheckingStatus = false;
      });
    });
  }

  // Request necessary permissions
  Future<void> _checkPermissions() async {
    await [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.location,
    ].request();
  }

  // Show dialog to guide user for Bluetooth settings
  void _showBluetoothDialog({required String title, required String message}) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.black87,
        title: Text(title, style: const TextStyle(color: Colors.white)),
        content: Text(message, style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await openAppSettings();
            },
            child: const Text("Open Settings", style: TextStyle(color: Colors.blue)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  // Check Bluetooth status and prompt user to turn it on if off
  void _checkBluetoothStatus() {
    if (!isBluetoothOn) {
      _showBluetoothDialog(
        title: "Bluetooth is OFF",
        message: "Please turn on Bluetooth manually in system settings.",
      );
    }
  }

  // Toggle Bluetooth status
  Future<void> _toggleBluetooth() async {
    if (isBluetoothOn) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Bluetooth is already ON")),
      );
    } else {
      _showBluetoothDialog(
        title: "Turn On Bluetooth",
        message: "Bluetooth is off. Please turn it on manually in system settings.",
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Dark theme background
      appBar: AppBar(
        backgroundColor: Colors.black87,
        title: const Text('Give Attendance', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: isCheckingStatus
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Lottie.asset(
                    'assets/attendance.json', // Replace with your Lottie animation file
                    width: 400, // Increased size
                    height: 400, // Increased size
                    fit: BoxFit.cover,
                  ),
                  const SizedBox(height: 80),
                  ElevatedButton.icon(
                    onPressed: _toggleBluetooth,
                    icon: Icon(isBluetoothOn ? Icons.check : Icons.settings, color: Colors.white),
                    label: Text(
                      isBluetoothOn ? 'Bluetooth is ON' : 'Turn ON Bluetooth',
                      style: const TextStyle(color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isBluetoothOn ? Color.fromARGB(255, 91, 196, 96) : Color(0xFFBF616A),
                      minimumSize: const Size(220, 50),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}