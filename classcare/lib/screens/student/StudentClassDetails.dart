import 'package:classcare/screens/student/attendance_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:classcare/screens/student/assignment_list.dart';
import 'package:classcare/screens/teacher/chat_tab.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'dart:io';

class StudentClassDetails extends StatefulWidget {
  final String classId;
  final String className;

  const StudentClassDetails({
    super.key,
    required this.classId,
    required this.className,
  });

  @override
  _StudentClassDetailsState createState() => _StudentClassDetailsState();
}

class _StudentClassDetailsState extends State<StudentClassDetails>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<DocumentSnapshot> getClassDetails() async {
    return FirebaseFirestore.instance.collection('classes').doc(widget.classId).get();
  }
  
  void _giveAttendance() async{
        String userId = FirebaseAuth.instance.currentUser!.uid;
        String name="";
         DocumentSnapshot doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .get();
        if (doc.exists) {
          name = doc.get('name'); // Extracting the 'name' field  
        } else {
          print("User document does not exist.");
          return null;
    }
        final deviceInfoPlugin = DeviceInfoPlugin();
        String deviceId = '';
        if (Theme.of(context).platform == TargetPlatform.android) {
          var androidInfo = await deviceInfoPlugin.androidInfo;
          deviceId = androidInfo.id; // Unique device ID for Android
        } else if (Theme.of(context).platform == TargetPlatform.iOS) {
          var iosInfo = await deviceInfoPlugin.iosInfo;
          deviceId = iosInfo.identifierForVendor ??
              'Unknown'; // Unique device ID for iOS
        }

        String bluetoothAddress = await _getBluetoothAddress();
        print(bluetoothAddress);
         try {
          await FirebaseFirestore.instance
              .collection('classes')
              .doc(widget.classId)
              .collection('students')
              .doc(userId)
              .set({
            'deviceId': deviceId,
            'bluetoothAddress': bluetoothAddress,
            'name':name,
          });
          print("Data saved successfully.");
        } catch (e) {
          print("Firestore error: $e");
        }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Attendance recorded successfully!')),
    );
    Navigator.push(context, MaterialPageRoute(builder: (context)=>AttendanceScreen()));
  }
  Future<String> _getBluetoothAddress() async {
    try {
      await FlutterBluePlus.turnOn(); 
      
      // Get the Bluetooth address
      String? bluetoothAddress;
      if (Theme.of(context).platform == TargetPlatform.android) {
        List<BluetoothDevice> devices = await FlutterBluePlus.connectedDevices;

        if (devices.isNotEmpty) {
          bluetoothAddress = devices.first.remoteId.toString();
        } else {
          // If no connected devices, try scanning
          await FlutterBluePlus.startScan(timeout: Duration(seconds: 4));

          // Wait for scan results
          await Future.delayed(Duration(seconds: 4));

          // Get scan results and extract devices
          List<ScanResult> scanResults =
              await FlutterBluePlus.scanResults.first;

          if (scanResults.isNotEmpty) {
            bluetoothAddress = scanResults.first.device.remoteId.toString();
          } else {
            bluetoothAddress = 'Android-Bluetooth-Unknown';
          }

          // Stop scanning
          FlutterBluePlus.stopScan();
        }
      } else if (Theme.of(context).platform == TargetPlatform.iOS) {
        // On iOS, getting Bluetooth address directly is challenging
        bluetoothAddress = 'iOS-Bluetooth-Address-Placeholder';
      }

      return bluetoothAddress ?? 'Unknown';
    } catch (e) {
      print("Error getting Bluetooth address: $e");
      return 'Unknown';
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.className),
        // No bottom TabBar here, we'll add it separately
      ),
      body: Column(  
        children: [
          // Give Attendance Button
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
            child: ElevatedButton.icon(
              onPressed: _giveAttendance,
              icon: const Icon(Icons.check_circle),
              label: const Text('Give Attendance'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(48), // sets the button height
              ),
            ),
          ),
          // Custom TabBar
          TabBar(
            controller: _tabController,
            tabs: const [
              Tab(icon: Icon(Icons.assignment), text: "Assignments"),
              Tab(icon: Icon(Icons.chat), text: "Chat"),
            ],
          ),
          // TabBarView
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                AssignmentList(classId: widget.classId),
                ChatTab(classId: widget.classId),
              ],
            ),
          ),
        ],
      ),
    );
  }
}