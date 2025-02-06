import 'package:classcare/screens/teacher/homeTeacher.dart';
import 'package:classcare/screens/student/hometStudent.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'login.dart'; // Import your LoginPage
import 'package:cloud_firestore/cloud_firestore.dart';

class SignupPage extends StatefulWidget {
  SignupPage({super.key, required this.post});
  String post;
  @override
  _SignupPageState createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  final _formKey = GlobalKey<FormState>(); // Global key for form validation
  String? _errorMessage;

  Future<void> _signup() async {
    if (_formKey.currentState?.validate() ?? false) {
      if (_passwordController.text != _confirmPasswordController.text) {
        setState(() {
          _errorMessage = "Passwords do not match";
        });
        return;
      }

      try {
        // Register with Firebase Authentication
        UserCredential userCredential =
            await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userCredential.user!.uid)
            .set({
          'email': _emailController.text.trim(),
          'role': widget.post,
          'name': _nameController.text.trim() // Save role as teacher or student
        });
        // Successfully signed up, navigate to LoginPage
        if (widget.post == 'Teacher') {
          Navigator.pushReplacement(context,
              MaterialPageRoute(builder: (context) => TeacherDashboard()));
        } else {
          Navigator.pushReplacement(
              context, MaterialPageRoute(builder: (context) => homeStudent()));
        }
      } on FirebaseAuthException catch (e) {
        setState(() {
          _errorMessage = e.message; // Show error message from Firebase
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue.shade50, // Soft background color
      body: Center(
        child: SingleChildScrollView(
          // Make the UI scrollable
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 50),
            child: Form(
              key: _formKey, // Form key for validation
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _registeredText(),
                  const SizedBox(height: 50),
                  _nameField(context),
                  const SizedBox(height: 20),
                  _emailField(context),
                  const SizedBox(height: 20),
                  _passwordField(context),
                  const SizedBox(height: 20),
                  _confirmPasswordField(context),
                  const SizedBox(height: 30),
                  if (_errorMessage != null) ...[
                    Text(
                      _errorMessage!,
                      style: const TextStyle(color: Colors.red, fontSize: 14),
                    ),
                    const SizedBox(height: 20),
                  ],
                  ElevatedButton(
                    onPressed: _signup,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue, // Button color
                      padding: const EdgeInsets.symmetric(
                          horizontal: 50, vertical: 15),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30)),
                    ),
                    child: const Text('Sign Up',
                        style: TextStyle(color: Colors.white)),
                  ),
                  const SizedBox(height: 20),
                  _signupText(context),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _registeredText() {
    return const Text(
      'Sign Up',
      style: TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 28,
        color: Colors.blue,
      ),
    );
  }

  Widget _emailField(BuildContext context) {
    return TextFormField(
      controller: _emailController,
      decoration: InputDecoration(
        labelText: 'Email',
        labelStyle: const TextStyle(color: Colors.blue),
        hintText: 'Enter your email',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter your email';
        } else if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
          return 'Please enter a valid email address';
        }
        return null;
      },
    );
  }

  Widget _nameField(BuildContext context) {
    return TextFormField(
      controller: _nameController,
      decoration: InputDecoration(
        labelText: 'Name',
        labelStyle: const TextStyle(color: Colors.blue),
        hintText: 'Enter your name',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter your name';
        }
        return null;
      },
    );
  }

  Widget _passwordField(BuildContext context) {
    return TextFormField(
      controller: _passwordController,
      obscureText: true,
      decoration: InputDecoration(
        labelText: 'Password',
        labelStyle: const TextStyle(color: Colors.blue),
        hintText: 'Enter your password',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter a password';
        } else if (value.length < 6) {
          return 'Password must be at least 6 characters';
        }
        return null;
      },
    );
  }

  Widget _confirmPasswordField(BuildContext context) {
    return TextFormField(
      controller: _confirmPasswordController,
      obscureText: true,
      decoration: InputDecoration(
        labelText: 'Confirm Password',
        labelStyle: const TextStyle(color: Colors.blue),
        hintText: 'Confirm your password',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please confirm your password';
        }
        return null;
      },
    );
  }

  Widget _signupText(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 30),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'Already have an account?',
            style: TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 14,
              color: Colors.blueGrey,
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                      builder: (BuildContext context) => LoginPage(
                            post: widget.post,
                          )));
            },
            child: const Text(
              'Log In',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: Colors.blue,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
