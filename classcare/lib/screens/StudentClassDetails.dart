import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class Studentclassdetails extends StatelessWidget {
  final String classId;
  final String className;

  Studentclassdetails({required this.classId, required this.className});

  // Fetch the class details from Firestore
  Future<DocumentSnapshot> getClassDetails() async {
    return FirebaseFirestore.instance.collection('classes').doc(classId).get();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(className),
        actions: [
          IconButton(
            icon: Icon(Icons.exit_to_app),
            onPressed: () {
              // Handle student sign-out if needed
            },
          ),
        ],
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: getClassDetails(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData) {
            return const Center(child: Text("Class not found"));
          }

          var classData = snapshot.data!.data() as Map<String, dynamic>;

          return Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Class Name: ${classData['className']}',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 10),
                Text(
                  'Slot: ${classData['slot']}',
                  style: TextStyle(fontSize: 18),
                ),
                SizedBox(height: 20),
                Text(
                  'Teacher: ${classData['teacherName'] ?? 'Not Available'}',
                  style: TextStyle(fontSize: 18),
                ),
                SizedBox(height: 20),
                Text(
                  'Assignments:',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 10),
                // Display list of assignments (if available)
                classData['assignments'] != null
                    ? Expanded(
                        child: ListView.builder(
                          itemCount: classData['assignments'].length,
                          itemBuilder: (context, index) {
                            var assignment = classData['assignments'][index];
                            return Card(
                              elevation: 4,
                              margin: EdgeInsets.symmetric(vertical: 10),
                              child: ListTile(
                                title: Text(assignment['title']),
                                subtitle: Text('Due Date: ${assignment['dueDate']}'),
                                onTap: () {
                                  // Handle assignment details, submission, etc.
                                },
                              ),
                            );
                          },
                        ),
                      )
                    : Center(child: Text("No assignments available")),
              ],
            ),
          );
        },
      ),
    );
  }
}
