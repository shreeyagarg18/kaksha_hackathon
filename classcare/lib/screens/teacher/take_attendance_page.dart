import 'dart:async';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';

class TakeAttendancePage extends StatefulWidget {
  TakeAttendancePage({super.key , required this.ClassId});
  String ClassId;

  @override
  _TakeAttendancePageState createState() => _TakeAttendancePageState();
}

class _TakeAttendancePageState extends State<TakeAttendancePage> {
  final flutterReactiveBle = FlutterReactiveBle();
  final FlutterLocalNotificationsPlugin localNotifications = FlutterLocalNotificationsPlugin();
  Map<String, String> bluetoothMap = {};
  List<DiscoveredDevice> detectedDevices = [];
  bool isScanning = false;
  StreamSubscription? scanSubscription;

  double distanceThreshold = 5.0; // 🔥 Default distance threshold in meters

  @override
  void initState() {
    super.initState();
    getBluetoothAddresses();
    _initializeNotifications();
    _checkPermissions();
    _startScanning(); // Start scanning immediately when the page opens
  }

  @override
  void dispose() {
    _stopScanning(); // Stop scanning when the page is disposed
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
  void getBluetoothAddresses() {
  FirebaseFirestore.instance
      .collection('classes')
      .doc(widget.ClassId)
      .collection('students')
      .snapshots() // Listen to real-time updates
      .listen((snapshot) {
    Map<String, String> updatedBluetoothMap = {};
    for (var doc in snapshot.docs) {
      String studentId = doc.id;
      String? bluetoothAddress = doc.get('bluetoothAddress');
      if (bluetoothAddress != null) {
        updatedBluetoothMap[studentId] = bluetoothAddress;
      }
    }
    setState(() {
      bluetoothMap = updatedBluetoothMap; // Update the map with real-time data
    });
  }, onError: (e) {
    print('Error listening to Bluetooth addresses: $e');
  });
}

  /// Initialize local notifications
  void _initializeNotifications() {
    const AndroidInitializationSettings androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    final InitializationSettings initSettings = InitializationSettings(android: androidInit);
    localNotifications.initialize(initSettings);
  }

  /// Convert RSSI to approximate distance in meters
  double _rssiToDistance(int rssi) {
    const int A = -59; // RSSI at 1 meter
    const double n = 2.0; // Environmental factor (2.0 for free-space)
    return pow(10, (A - rssi) / (10 * n)).toDouble();
  }

  /// Start scanning for BLE devices with distance filtering
  void _startScanning() {
    setState(() {
      detectedDevices.clear();
      isScanning = true;
    });

    scanSubscription = flutterReactiveBle.scanForDevices(
      withServices: [],
      scanMode: ScanMode.balanced,
    ).listen((device) {
      double distance = _rssiToDistance(device.rssi);
      if (distance <= distanceThreshold) { // 🔥 Filter based on distance
        if (!detectedDevices.any((d) => d.id == device.id)) {
          if(bluetoothMap.containsValue(device.id)){
            setState(() => detectedDevices.add(device));
            _sendNotification(device.name.isNotEmpty ? device.name : "Unknown Device");
          }
        }
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
    await localNotifications.show(0, "Student Detected", "$deviceName is nearby!", notificationDetails);
  }

  @override
  Widget build(BuildContext context) {  
    return Scaffold(
      appBar: AppBar(
        title: const Text("Take Attendance"),
        actions: [
          if (detectedDevices.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: () {}, // Placeholder for saving attendance
              tooltip: "Save Attendance",
            ),
        ],
      ),
      body: Column(
        children: [
          Container(
            color: isScanning ? Colors.green.shade100 : Colors.orange.shade100,
            padding: const EdgeInsets.all(12.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(isScanning ? Icons.bluetooth_searching : Icons.bluetooth_disabled),
                const SizedBox(width: 10),
                Text(isScanning ? "Scanning for devices..." : "Scan stopped"),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Set Detection Range (meters):", style: TextStyle(fontWeight: FontWeight.bold)),
                Slider(
                  value: distanceThreshold,
                  min: 1.0,
                  max: 20.0,
                  divisions: 19,
                  label: "${distanceThreshold.toStringAsFixed(1)} m",
                  onChanged: (value) {
                    setState(() => distanceThreshold = value);
                  },
                ),
                Text("Current Range: ${distanceThreshold.toStringAsFixed(1)} meters", style: const TextStyle(fontSize: 16)),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: ListView.builder(
              itemCount: detectedDevices.length,
              itemBuilder: (context, index) {
                final device = detectedDevices[index];
                final distance = _rssiToDistance(device.rssi);
                return ListTile(
                  title: Text(device.name.isNotEmpty ? device.name : "Unknown Device"),
                  subtitle: Text("Distance: ${distance.toStringAsFixed(2)} m\nID: ${device.id}"),
                  trailing: const Icon(Icons.check, color: Colors.green),
                );
              },
            ),
          ),
          if (!isScanning)
            ElevatedButton(
              onPressed: _startScanning,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              child: const Text("Start Scanning"),
            ),
          if (isScanning)
            ElevatedButton(
              onPressed: _stopScanning,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text("Stop Scanning"),
            ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }
}
