import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TakeAttendancePage extends StatefulWidget {
  final String classId;
  final String className;

  const TakeAttendancePage({
    super.key,
    required this.classId,
    required this.className,
  });

  @override
  _TakeAttendancePageState createState() => _TakeAttendancePageState();
}

class _TakeAttendancePageState extends State<TakeAttendancePage> {
  final flutterReactiveBle = FlutterReactiveBle();
  final FlutterLocalNotificationsPlugin localNotifications = FlutterLocalNotificationsPlugin();
  
  List<DiscoveredDevice> detectedDevices = [];
  bool isScanning = false;
  StreamSubscription? scanSubscription;
   final int rssiThreshold = -65;
  @override
  void initState() {
    super.initState();
    _initializeNotifications();
    _checkPermissions();
    // Start scanning immediately when page opens
    _startScanning();
  }

  @override
  void dispose() {
    _stopScanning(); // Make sure to stop scanning when page is disposed
    super.dispose();
  }

  /// Request necessary Android permissions at runtime
  Future<void> _checkPermissions() async {
    if (await Permission.bluetoothScan.isDenied ||
        await Permission.bluetoothConnect.isDenied ||
        await Permission.location.isDenied ||
        await Permission.notification.isDenied) {
      await [
        Permission.bluetoothScan,
        Permission.bluetoothConnect,
        Permission.location,
        Permission.notification
      ].request();
    }
  }

  /// Initialize local notifications
  void _initializeNotifications() {
    const AndroidInitializationSettings androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    final InitializationSettings initSettings = InitializationSettings(android: androidInit);
    localNotifications.initialize(initSettings);
  }

  /// Start scanning for BLE devices
  void _startScanning() {
    setState(() {
      detectedDevices.clear();
      isScanning = true;
    });

    scanSubscription = flutterReactiveBle.scanForDevices(
      withServices: [], // Empty list to detect all BLE devices
      scanMode: ScanMode.balanced,
    ).listen((device) {
       if (device.rssi >= rssiThreshold) { 
      if (!detectedDevices.any((d) => d.id == device.id)) {
        setState(() => detectedDevices.add(device));
        _sendNotification(device.name.isNotEmpty ? device.name : "Unknown Device");
      }
       }
    }, onError: (error) {
      if (kDebugMode) {
        print("Error scanning: $error");
      }
      setState(() => isScanning = false);
      
      // Show error in snackbar
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error scanning: $error")),
      );
    });
  }

  /// Stop BLE scanning
  void _stopScanning() {
    setState(() => isScanning = false);
    scanSubscription?.cancel();
  }

  /// Send local notification when a device is detected
  void _sendNotification(String deviceName) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'attendance_channel', 'Attendance Notifications',
      importance: Importance.high,
      priority: Priority.high,
    );
    const NotificationDetails notificationDetails = NotificationDetails(android: androidDetails);
    await localNotifications.show(0, "Student Detected", "$deviceName is present!", notificationDetails);
  }

  /// Save attendance data to Firestore
  Future<void> _saveAttendance() async {
    try {
      // Create a new document in the attendanceRecords subcollection
      DocumentReference attendanceRef = await FirebaseFirestore.instance
          .collection('classes')
          .doc(widget.classId)
          .collection('attendanceRecords')
          .add({
            'date': Timestamp.now(),
            'totalPresent': detectedDevices.length,
          });
      
      // Add individual student/device records
      for (var device in detectedDevices) {
        await attendanceRef.collection('devices').add({
          'deviceId': device.id,
          'deviceName': device.name.isNotEmpty ? device.name : "Unknown Device",
          'timestamp': Timestamp.now(),
        });
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Attendance saved successfully!")),
      );
      
      // Return to previous screen after saving
      Navigator.of(context).pop();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error saving attendance: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Take Attendance: ${widget.className}"),
        actions: [
          if (detectedDevices.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _saveAttendance,
              tooltip: "Save Attendance",
            ),
        ],
      ),
      body: Column(
        children: [
          // Status bar
          Container(
            color: isScanning ? Colors.green.shade100 : Colors.orange.shade100,
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                Icon(
                  isScanning ? Icons.bluetooth_searching : Icons.bluetooth_disabled,
                  color: isScanning ? Colors.green : Colors.orange,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    isScanning
                        ? "Scanning for student devices..."
                        : "Scanning paused",
                    style: TextStyle(
                      color: isScanning ? Colors.green.shade800 : Colors.orange.shade800,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Text(
                  "Found: ${detectedDevices.length}",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          
          // Scan control buttons
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: isScanning ? _stopScanning : _startScanning,
                    icon: Icon(isScanning ? Icons.stop : Icons.play_arrow),
                    label: Text(isScanning ? "Stop Scanning" : "Start Scanning"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isScanning ? Colors.red : Colors.green,
                      padding: const EdgeInsets.symmetric(vertical: 12.0),
                    ),
                  ),
                ),
                if (detectedDevices.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: _saveAttendance,
                    icon: const Icon(Icons.save),
                    label: const Text("Save Attendance"),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12.0),
                    ),
                  ),
                ],
              ],
            ),
          ),
          
          // Detected devices list
          Expanded(
            child: detectedDevices.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.bluetooth, size: 64, color: Colors.grey.shade400),
                        const SizedBox(height: 16),
                        Text(
                          "No devices detected yet",
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Make sure students have Bluetooth enabled",
                          style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: detectedDevices.length,
                    itemBuilder: (context, index) {
                      final device = detectedDevices[index];
                      return ListTile(
                        leading: const CircleAvatar(
                          backgroundColor: Colors.green,
                          child: Icon(Icons.person, color: Colors.white),
                        ),
                        title: Text(device.name.isNotEmpty ? device.name : "Unknown Device"),
                        subtitle: Text("ID: ${device.id}"),
                        trailing: const Icon(Icons.check_circle, color: Colors.green),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}