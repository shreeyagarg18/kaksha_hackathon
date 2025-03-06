import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AttendanceScreen extends StatefulWidget {
  final String classId;
  final String className;

  const AttendanceScreen({
    super.key,
    required this.classId,
    required this.className,
  });

  @override
  _AttendanceScreenState createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  final flutterReactiveBle = FlutterReactiveBle();

  bool isScanning = false;
  bool isBluetoothOn = false;
  bool isCheckingStatus = true;
  StreamSubscription? scanSubscription;
  StreamSubscription? bleStatusSubscription;

  final int rssiThreshold = -65;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
    _monitorBluetoothStatus();
  }

  @override
  void dispose() {
    _stopScanning();
    bleStatusSubscription?.cancel();
    super.dispose();
  }

  // Monitor Bluetooth status
  void _monitorBluetoothStatus() {
    bleStatusSubscription = flutterReactiveBle.statusStream.listen((status) {
      setState(() {
        isBluetoothOn = status == BleStatus.ready;
        isCheckingStatus = false;
      });

      if (kDebugMode) {
        print("Bluetooth status: $status");
      }
    });
  }

  // Request necessary permissions
  Future<void> _checkPermissions() async {
    if (await Permission.bluetoothScan.isDenied ||
        await Permission.bluetoothConnect.isDenied ||
        await Permission.location.isDenied) {
      await [
        Permission.bluetoothScan,
        Permission.bluetoothConnect,
        Permission.location,
      ].request();
    }
  }

  // Start BLE scanning
  void _startScanning() {
    if (!isBluetoothOn) {
      _requestBluetoothPermission();
      return;
    }

    setState(() {
      isScanning = true;
    });

    try {
      scanSubscription = flutterReactiveBle.scanForDevices(
        withServices: [], // Empty list to detect all BLE devices
        scanMode: ScanMode.balanced,
      ).listen((device) {
        // We don't need to store devices here, just confirm that scanning works
        if (kDebugMode) {
          print("Found device: ${device.name} (${device.id})");
        }
      }, onError: (error) {
        if (kDebugMode) {
          print("Error scanning: $error");
        }
        setState(() => isScanning = false);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error scanning: $error")),
        );
      });

      // Mark attendance after a few seconds of scanning to simulate
      Future.delayed(const Duration(seconds: 3), () {
        _stopScanning();
        _recordAttendance();
      });
    } catch (e) {
      setState(() => isScanning = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to start scanning: $e")),
      );
    }
  }

  // Request Bluetooth permission directly
  Future<void> _requestBluetoothPermission() async {
    final status = await Permission.bluetoothScan.request();

    if (status.isGranted) {
      // Bluetooth permission granted, proceed with scanning
      _startScanning();
    } else if (status.isDenied) {
      // Permission denied, show a dialog explaining the need for Bluetooth
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Bluetooth Permission Required'),
          content: const Text(
              'To mark your attendance via Bluetooth, please grant permission. '
              'Choose "While using the app" or "Only this time" to proceed.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                final newStatus = await Permission.bluetoothScan.request();
                if (newStatus.isGranted) {
                  _startScanning();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text(
                            'Bluetooth permission is required to continue.')),
                  );
                }
              },
              child: const Text('Try Again'),
            ),
          ],
        ),
      );
    } else if (status.isPermanentlyDenied) {
      // Permission permanently denied, show settings dialog
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Bluetooth Permission Required'),
          content:
              const Text('Bluetooth permission has been permanently denied. '
                  'Please enable it in the app settings to continue.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                openAppSettings();
              },
              child: const Text('Open Settings'),
            ),
          ],
        ),
      );
    }
  }

  // Stop BLE scanning
  void _stopScanning() {
    scanSubscription?.cancel();
    setState(() => isScanning = false);
  }

  // Record attendance in Firestore
  Future<void> _recordAttendance() async {
    try {
      // Add attendance record to Firestore
      await FirebaseFirestore.instance.collection('attendance').add({
        'classId': widget.classId,
        'studentId': 'current-user-id', // Replace with actual user ID from auth
        'timestamp': FieldValue.serverTimestamp(),
        'method': 'bluetooth',
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Attendance recorded successfully!')),
      );

      // Return to previous screen after a short delay
      Future.delayed(const Duration(seconds: 2), () {
        Navigator.pop(context);
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to record attendance: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Give Attendance: ${widget.className}'),
      ),
      body: isCheckingStatus
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Status bar
                Container(
                  color: isBluetoothOn
                      ? Colors.green.shade100
                      : Colors.orange.shade100,
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    children: [
                      Icon(
                        isBluetoothOn
                            ? Icons.bluetooth
                            : Icons.bluetooth_disabled,
                        color: isBluetoothOn ? Colors.green : Colors.orange,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          isBluetoothOn
                              ? "Bluetooth is ready"
                              : "Bluetooth needs to be enabled",
                          style: TextStyle(
                            color: isBluetoothOn
                                ? Colors.green.shade800
                                : Colors.orange.shade800,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          isScanning
                              ? Icons.bluetooth_searching
                              : (isBluetoothOn
                                  ? Icons.bluetooth_connected
                                  : Icons.bluetooth_disabled),
                          size: 80,
                          color: isScanning
                              ? Colors.blue
                              : (isBluetoothOn ? Colors.green : Colors.grey),
                        ),
                        const SizedBox(height: 20),
                        if (isScanning)
                          Column(
                            children: [
                              const CircularProgressIndicator(),
                              const SizedBox(height: 20),
                              Text(
                                'Scanning and registering attendance...',
                                style: Theme.of(context).textTheme.titleMedium,
                                textAlign: TextAlign.center,
                              ),
                            ],
                          )
                        else
                          Text(
                            isBluetoothOn
                                ? 'Tap the button below to mark your attendance'
                                : 'Please enable Bluetooth to mark your attendance',
                            style: Theme.of(context).textTheme.titleMedium,
                            textAlign: TextAlign.center,
                          ),
                      ],
                    ),
                  ),
                ),

                // Button to start scanning or enable Bluetooth
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: ElevatedButton.icon(
                    onPressed: isScanning ? null : _startScanning,
                    icon: Icon(
                        isBluetoothOn ? Icons.check_circle : Icons.bluetooth),
                    label: Text(
                        isBluetoothOn ? 'Give Attendance' : 'Enable Bluetooth'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          isBluetoothOn ? Colors.blue : Colors.orange,
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(50),
                      padding: const EdgeInsets.symmetric(vertical: 12.0),
                      disabledBackgroundColor: Colors.grey,
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
