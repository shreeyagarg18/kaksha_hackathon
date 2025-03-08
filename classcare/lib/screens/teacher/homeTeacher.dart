import 'dart:math';
import 'package:classcare/screens/teacher/classDetailsPage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class TeacherDashboard extends StatefulWidget {
  const TeacherDashboard({super.key});

  @override
  _TeacherDashboardState createState() => _TeacherDashboardState();
}

class _TeacherDashboardState extends State<TeacherDashboard> {
  final TextEditingController _classNameController = TextEditingController();
  final TextEditingController _slotController = TextEditingController();
  late String _teacherName;

  @override
  void dispose() {
    _classNameController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    fetchTeacherName();
  }

  String generateJoinCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    Random rand = Random();
    return List.generate(6, (index) => chars[rand.nextInt(chars.length)])
        .join();
  }

  Future<void> fetchTeacherName() async {
    try {
      String teacherId = FirebaseAuth.instance.currentUser!.uid;
      DocumentSnapshot teacherDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(teacherId)
          .get();

      setState(() {
        _teacherName = teacherDoc['name'] ?? 'Unknown Teacher';
      });
    } catch (e) {
      print("Error fetching teacher name: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to fetch teacher name.')),
      );
    }
  }

  Future<void> createClass(String className, String slot) async {
    try {
      String classId =
          FirebaseFirestore.instance.collection('classes').doc().id;

      // Generate a random join code
      String joinCode = generateJoinCode();

      // List of fixed colors
      List<Color> availableColors = [
        Colors.blue.shade100,
        Colors.green.shade100,
        Colors.orange.shade100,
        Colors.cyan.shade100,
        Colors.teal.shade100,
        Colors.red.shade100
      ];

      // Randomly select a color
      Color randomColor =
          availableColors[Random().nextInt(availableColors.length)];

      // Convert the color to a hex string to store in Firestore
      String colorHex =
          '#${randomColor.value.toRadixString(16).substring(2).toUpperCase()}';

      await FirebaseFirestore.instance.collection('classes').doc(classId).set({
        'classId': classId,
        'className': className,
        'slot': slot,
        'teacherId': FirebaseAuth.instance.currentUser!.uid,
        'joinCode': joinCode, // Store the join code
        'color': colorHex,
        'teacherName': _teacherName,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Class created successfully!')),
      );
      Navigator.pop(context); // Close the create class dialog
    } catch (e) {
      print("Error creating class: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to create class. Try again.')),
      );
    }
  }

  void openCreateClassDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Create New Class"),
        content: SizedBox(
          height: 150,
          child: Column(
            children: [
              TextField(
                controller: _classNameController,
                decoration: const InputDecoration(
                  labelText: 'Class Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _slotController,
                decoration: const InputDecoration(
                  labelText: 'Slot',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              if (_classNameController.text.trim().isNotEmpty &&
                  _slotController.text.trim().isNotEmpty) {
                createClass(_classNameController.text.trim(),
                    _slotController.text.trim());
                _classNameController.clear();
                _slotController.clear();
              }
            },
            child: const Text("Create"),
          ),
        ],
      ),
    );
  }

  Widget buildClassList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('classes')
          .where('teacherId', isEqualTo: FirebaseAuth.instance.currentUser!.uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text("No Classes Available"));
        }

        return ListView(
          children: snapshot.data!.docs.map((doc) {
            var classData = doc.data() as Map<String, dynamic>;
            // Get the background color from Firestore
            String colorHex = classData['color'] ??
                '#FFFFFF'; // Default to white if no color is found
            Color cardColor = Color(int.parse(
                '0xFF${colorHex.substring(1)}')); // Convert Hex to Color

            return Padding(
              padding: const EdgeInsets.all(20.0),
              child: Card(
                elevation: 5, // Add elevation for a shadow effect
                shape: const RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.all(Radius.circular(20)), // Rounded corners
                ),
                color: cardColor, // Set the background color of the card
                child: Padding(
                  padding:
                      const EdgeInsets.all(16.0), // Padding inside the card
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        classData['className'],
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Slot: ${classData['slot']}",
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[850],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Teacher Name: ${classData['teacherName']}",
                        style: const TextStyle(
                          fontSize: 16,
                          color: Color.fromRGBO(48, 48, 48, 1),
                        ),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ClassDetailPage(
                              classId: classData['classId'],
                              className: classData['className'],
                            ),
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color.fromARGB(
                              255, 247, 245, 245), // Button color
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'View Class',
                          style: TextStyle(color: Colors.black),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 5, 4, 5),
      appBar: AppBar(
  title: const Text("Teacher Dashboard"),
  actions: [
    IconButton(
      icon: const Icon(Icons.logout),
      onPressed: () async {
        showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('Logout'),
      content: Text('Are you sure you want to log out?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel'),
        ),
        TextButton(
          onPressed: () async {
            await FirebaseAuth.instance.signOut();
            Navigator.pop(context); // Close the dialog
            Navigator.pushReplacementNamed(context, '/start'); // Navigate to login screen
          },
          child: Text('Logout'),
        ),
      ],
    ),
  );
      },
      tooltip: 'Logout',
    ),
  ],
),
      body: buildClassList(),
      floatingActionButton: FloatingActionButton(
        onPressed: openCreateClassDialog,
        backgroundColor: Colors.blue, // Customize color as needed
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}