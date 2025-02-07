import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class StudentsList extends StatelessWidget {
  final String classId;

  const StudentsList({super.key, required this.classId});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('classes').doc(classId).get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const Center(child: Text("No class data found."));
        }

        // Check if 'students' field exists
        var classData = snapshot.data!;
        if (!classData.data().toString().contains('students')) {
          return const Center(child: Text("No students enrolled."));
        }

        List<String> studentIds = List<String>.from(classData['students'] ?? []);

        if (studentIds.isEmpty) {
          return const Center(child: Text("No students enrolled."));
        }

        return FutureBuilder<QuerySnapshot>(
          future: FirebaseFirestore.instance
              .collection('users')
              .where(FieldPath.documentId, whereIn: studentIds)
              .get(),
          builder: (context, studentSnapshot) {
            if (studentSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (!studentSnapshot.hasData || studentSnapshot.data!.docs.isEmpty) {
              return const Center(child: Text("No student details found."));
            }

            var students = studentSnapshot.data!.docs;
            return ListView.builder(
              itemCount: students.length,
              itemBuilder: (context, index) {
                var student = students[index];
                return ListTile(
                  leading: const Icon(Icons.person),
                  title: Text(student['name'] ?? 'Unknown'),
                  subtitle: Text(student['email'] ?? 'No Email'),
                );
              },
            );
          },
        );
      },
    );
  }
}
