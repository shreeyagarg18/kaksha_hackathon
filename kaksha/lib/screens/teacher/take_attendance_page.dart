import 'dart:async';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';

// Adding AppColors class to match the StudentClassDetails styling
class AppColors {
  // Base colors
  static const Color background = Color(0xFF121212);
  static const Color surfaceColor = Color(0xFF1E1E1E);
  static const Color cardColor = Color(0xFF252525);

  // Subtle accent colors
  static const Color accentBlue = Color(0xFF81A1C1);
  static const Color accentGreen = Color.fromARGB(255, 125, 225, 130);
  static const Color accentPurple = Color(0xFFB48EAD);
  static const Color accentYellow = Color(0xFFEBCB8B);
  static const Color accentRed = Color(0xFFBF616A);

  // Text colors
  static const Color primaryText = Colors.white;
  static const Color secondaryText = Color(0xFFAAAAAA);
  static const Color tertiaryText = Color(0xFF757575);
}

class TakeAttendancePage extends StatefulWidget {
  const TakeAttendancePage({super.key, required this.ClassId});
  final String ClassId;

  @override
  _TakeAttendancePageState createState() => _TakeAttendancePageState();
}

class _TakeAttendancePageState extends State<TakeAttendancePage> {
  final flutterReactiveBle = FlutterReactiveBle();
  final FlutterLocalNotificationsPlugin localNotifications =
      FlutterLocalNotificationsPlugin();
  Map<String, Map<String, String>> bluetoothMap = {};
  List<Map<String, dynamic>> detectedDevices = [];
  bool isScanning = false;
  StreamSubscription<DiscoveredDevice>? scanSubscription;
  StreamSubscription<BluetoothDiscoveryResult>? classicScanSubscription;
  double distanceThreshold = 5.0; // Default distance threshold in meters

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
      Map<String, Map<String, String>> updatedBluetoothMap = {};
      for (var doc in snapshot.docs) {
        String studentId = doc.id;
        String bluetoothAddress = doc.get('bluetoothAddress');
        String name = doc.get('name'); // Get the name field
        print("hiii");
        updatedBluetoothMap[studentId] = {
          'name': name,
          'bluetoothAddress': bluetoothAddress,
        };
        print(bluetoothAddress);
      }
      print("gg");
      setState(() {
        bluetoothMap =
            updatedBluetoothMap; // Update the map with real-time data
      });
    }, onError: (e) {
      print('Error listening to Bluetooth addresses: $e');
    });
  }

  /// Initialize local notifications
  void _initializeNotifications() {
    const AndroidInitializationSettings androidInit =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    final InitializationSettings initSettings =
        InitializationSettings(android: androidInit);
    localNotifications.initialize(initSettings);
  }

  /// Convert RSSI to approximate distance in meters
  double _rssiToDistance(int rssi) {
    const int A = -59; // RSSI at 1 meter
    const double n = 2.0; // Environmental factor (2.0 for free-space)
    return pow(10, (A - rssi) / (10 * n)).toDouble();
  }

  /// Start scanning for BLE devices with distance filtering
  /// Start scanning for BLE devices with distance filtering
  void _startScanning() {
    // Clear previous scan results and reset scanning state
    _stopScanning(); // Stop any ongoing scans
    setState(() {
      detectedDevices.clear(); // Clear cached devices
      isScanning = true;
    });

    // BLE scanning using flutter_reactive_ble
    scanSubscription = flutterReactiveBle.scanForDevices(
      withServices: [],
      scanMode: ScanMode.balanced,
    ).listen((device) {
      double distance = _rssiToDistance(device.rssi);
      if (distance <= distanceThreshold) {
        if (bluetoothMap.values
            .any((value) => value['bluetoothAddress'] == device.id)) {
          String? studentName;
          String? studentId;
          bluetoothMap.forEach((key, value) {
            if (value['bluetoothAddress'] == device.id) {
              studentName = value['name'];
              studentId = key;
            }
          });
          if (!detectedDevices.any((d) => d['id'] == device.id)) {
            setState(() {
              detectedDevices.add({
                'name': studentName ?? "Unknown BLE Device",
                'id': device.id,
                'rssi': device.rssi,
                'distance': distance,
                'type': 'BLE',
              });
            });
            _sendNotification(studentName ?? "Unknown BLE Device");
            if (studentId != null && studentName != null) {
              saveAttendance(studentId!, studentName!);
            }
          }
        }
      }
    }, onError: (error) {
      setState(() => isScanning = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error scanning: $error")),
      );
    });

    // Classic Bluetooth scanning
    classicScanSubscription =
        FlutterBluetoothSerial.instance.startDiscovery().listen((result) {
      if (bluetoothMap.values
          .any((value) => value['bluetoothAddress'] == result.device.address)) {
        String? studentName;
        String? studentId;
        bluetoothMap.forEach((key, value) {
          if (value['bluetoothAddress'] == result.device.address) {
            studentName = value['name'];
            studentId = key;
          }
        });
        if (!detectedDevices.any((d) => d['id'] == result.device.address)) {
          setState(() {
            detectedDevices.add({
              'name': studentName ?? "Unknown Classic Device",
              'id': result.device.address,
              'rssi': result.rssi ?? -80,
              'distance':
                  result.rssi != null ? _rssiToDistance(result.rssi) : null,
              'type': 'Classic',
            });
          });
          if (studentId != null && studentName != null) {
            saveAttendance(studentId!, studentName!);
          }
          _sendNotification(studentName ?? "Unknown Classic Device");
        }
      }
    });
  }

  /// Stop BLE scanning
  /// Stop BLE and Classic Bluetooth scanning
  void _stopScanning() {
    setState(() => isScanning = false);
    scanSubscription?.cancel();
    classicScanSubscription?.cancel();
    scanSubscription = null;
    classicScanSubscription = null;
  }

  Future<void> saveAttendance(String studentId, String studentName) async {
    try {
      final now = DateTime.now();
      final date = "${now.day}-${now.month}-${now.year}";
      final time = "${now.hour}:${now.minute}:${now.second}";

      await FirebaseFirestore.instance
          .collection('classes')
          .doc(widget.ClassId)
          .collection('attendancehistory')
          .doc(date) // Use studentId as document ID
          .set({
        '$studentName-$studentId': {
          'name': studentName,
          'time': time,
        }
      }, SetOptions(merge: true));

      if (kDebugMode) {
        print("Attendance saved for $studentName at $time on $date");
      }
    } catch (e) {
      print("Error saving attendance: $e");
    }
  }

  /// Send local notification when a device is detected
  void _sendNotification(String deviceName) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'attendance_channel',
      'Attendance Notifications',
      importance: Importance.high,
      priority: Priority.high,
    );
    const NotificationDetails notificationDetails =
        NotificationDetails(android: androidDetails);
    await localNotifications.show(
        0, "Student Detected", "$deviceName is nearby!", notificationDetails);
  }

  @override
  Widget build(BuildContext context) {
    double h = MediaQuery.of(context).size.height;
    double w = MediaQuery.of(context).size.width;

    return Theme(
      data: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: AppColors.background,
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: false,
          titleSpacing: w * 0.01,
        ),
        cardColor: AppColors.cardColor,
      ),
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            "Take Attendance",
            style: TextStyle(
              color: AppColors.primaryText,
              fontWeight: FontWeight.w600,
              fontSize: h * 0.02,
            ),
          ),
          actions: [
            if (detectedDevices.isNotEmpty)
              Padding(
                padding: EdgeInsets.only(right: 16),
                child: IconButton(
                  icon: Icon(Icons.save, color: AppColors.accentBlue),
                  onPressed: () {}, // Placeholder for saving attendance
                  tooltip: "Save Attendance",
                ),
              ),
          ],
        ),
        body: Column(
          children: [
            // Status header
            Container(
              margin: EdgeInsets.fromLTRB(16, 0, 16, 16),
              padding: EdgeInsets.all(h * 0.018),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    isScanning
                        ? AppColors.accentGreen.withOpacity(0.2)
                        : AppColors.accentRed.withOpacity(0.2),
                    isScanning
                        ? AppColors.accentBlue.withOpacity(0.2)
                        : AppColors.accentYellow.withOpacity(0.2),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isScanning
                          ? AppColors.accentGreen.withOpacity(0.2)
                          : AppColors.accentRed.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isScanning
                          ? Icons.bluetooth_searching
                          : Icons.bluetooth_disabled,
                      color: isScanning
                          ? AppColors.accentGreen
                          : AppColors.accentRed,
                      size: 22,
                    ),
                  ),
                  SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isScanning ? "Scanning for devices..." : "Scan stopped",
                        style: TextStyle(
                          color: AppColors.primaryText,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        "Detection range: ${distanceThreshold.toStringAsFixed(1)} meters",
                        style: TextStyle(
                          color: AppColors.secondaryText,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Range slider
            Container(
              margin: EdgeInsets.fromLTRB(16, 0, 16, 16),
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surfaceColor,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Detection Range",
                    style: TextStyle(
                      color: AppColors.primaryText,
                      fontWeight: FontWeight.w500,
                      fontSize: 16,
                    ),
                  ),
                  SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.bluetooth_audio,
                        color: AppColors.accentBlue,
                        size: 16,
                      ),
                      Expanded(
                        child: SliderTheme(
                          data: SliderThemeData(
                            activeTrackColor: AppColors.accentBlue,
                            inactiveTrackColor:
                                AppColors.accentBlue.withOpacity(0.2),
                            thumbColor: AppColors.accentBlue,
                            overlayColor: AppColors.accentBlue.withOpacity(0.1),
                            trackHeight: 4,
                          ),
                          child: Slider(
                            value: distanceThreshold,
                            min: 1.0,
                            max: 10.0,
                            divisions: 19,
                            label: "${distanceThreshold.toStringAsFixed(1)} m",
                            onChanged: (value) {
                              setState(() => distanceThreshold = value);
                            },
                          ),
                        ),
                      ),
                      Icon(
                        Icons.bluetooth,
                        color: AppColors.accentBlue,
                        size: 20,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Detected students section
            Expanded(
              child: Container(
                margin: EdgeInsets.fromLTRB(16, 0, 16, 16),
                decoration: BoxDecoration(
                  color: AppColors.cardColor,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppColors.accentBlue.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Column(
                  children: [
                    Padding(
                      padding: EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Icon(
                            Icons.people_outline,
                            color: AppColors.accentBlue,
                            size: 20,
                          ),
                          SizedBox(width: 8),
                          Text(
                            "Detected Students",
                            style: TextStyle(
                              color: AppColors.primaryText,
                              fontWeight: FontWeight.w500,
                              fontSize: 16,
                            ),
                          ),
                          Spacer(),
                          Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.accentBlue.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              "${detectedDevices.length}",
                              style: TextStyle(
                                color: AppColors.accentBlue,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Divider(
                      height: 1,
                      thickness: 1,
                      color: AppColors.surfaceColor,
                    ),
                    Expanded(
                      child: detectedDevices.isEmpty
                          ? Center(
                              child: Text(
                                "No students detected yet",
                                style: TextStyle(
                                  color: AppColors.secondaryText,
                                  fontSize: 16,
                                ),
                              ),
                            )
                          : ListView.separated(
                              padding: EdgeInsets.all(8),
                              itemCount: detectedDevices.length,
                              separatorBuilder: (context, index) => Divider(
                                height: 1,
                                thickness: 1,
                                color: AppColors.surfaceColor,
                              ),
                              itemBuilder: (context, index) {
                                final device = detectedDevices[index];
                                return ListTile(
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                  leading: Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: AppColors.accentGreen
                                          .withOpacity(0.2),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.check_circle_outline,
                                      color: AppColors.accentGreen,
                                    ),
                                  ),
                                  title: Text(
                                    device['name'] ?? "Unknown Device",
                                    style: TextStyle(
                                      color: AppColors.primaryText,
                                      fontWeight: FontWeight.w500,
                                      fontSize: 16,
                                    ),
                                  ),
                                  subtitle: Text(
                                    "Present",
                                    style: TextStyle(
                                      color: AppColors.accentGreen,
                                      fontSize: 14,
                                    ),
                                  ),
                                  trailing: Icon(
                                    device['type'] == 'BLE'
                                        ? Icons.bluetooth
                                        : Icons.bluetooth_connected,
                                    color: AppColors.accentBlue,
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            ),

            // Control button
            Container(
              margin: EdgeInsets.fromLTRB(16, 0, 16, 16),
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: isScanning ? _stopScanning : _startScanning,
                icon: Icon(
                  isScanning ? Icons.stop_circle : Icons.play_circle,
                  color: AppColors.background,
                ),
                label: Text(
                  isScanning ? 'Stop Scanning' : 'Start Scanning',
                  style: TextStyle(
                    color: AppColors.background,
                    fontWeight: FontWeight.w500,
                    fontSize: 16,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      isScanning ? AppColors.accentRed : AppColors.accentGreen,
                  foregroundColor: AppColors.background,
                  padding: EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
