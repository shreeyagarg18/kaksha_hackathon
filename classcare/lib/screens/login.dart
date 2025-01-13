import 'package:classcare/screens/homeTeacher.dart';
import 'package:classcare/screens/hometStudent.dart';
import 'package:classcare/screens/signup.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class LoginPage extends StatefulWidget {
  LoginPage({super.key , required this.post});
  String post;
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  // Initializing controllers for email and password fields
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  String? _errorMessage;

  // Dispose of the controllers when the widget is disposed
  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Login function using Firebase Auth
  Future<void> _login() async {
    try {
      UserCredential userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(userCredential.user?.uid).get();
      if (userDoc.exists) {
        String? role = userDoc.data()?['role'];
        if (role == widget.post) {
          if(role=='Teacher'){
             Navigator.pushReplacement(context,MaterialPageRoute(builder: (BuildContext context) =>  TeacherDashboard()));
          }else{
             Navigator.pushReplacement(context,MaterialPageRoute(builder: (BuildContext context) => homeStudent()));

          }
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Login successful')));
        } else {
          setState(() {
            _errorMessage = "Access denied: You are not a $role.";
          });
        }
      } else {
        setState(() {
          _errorMessage = "User data not found. Please contact support.";
        });
      }
      
  } on FirebaseAuthException catch (e) {
    setState(() {
      // Handle specific error codes
      if (e.code == 'user-not-found') {
        _errorMessage = "No account found with this email. Please sign up.";
      } else if (e.code == 'wrong-password') {
        _errorMessage = "Incorrect password. Please try again.";
      } else if (e.code == 'invalid-email') {
        _errorMessage = "The email address is badly formatted. Please check and try again.";
      } else {
        _errorMessage = "An error occurred. Please try again.";
      }
    });
  }
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue.shade50,
      bottomNavigationBar: _signupText(context),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 50),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _registeredText(),
              const SizedBox(height: 50),
              _emailField(),
              const SizedBox(height: 20),
              _passwordField(),
              const SizedBox(height: 30),
              if (_errorMessage != null) ...[
                Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.red, fontSize: 14),
                ),
                const SizedBox(height: 20),
              ],
              ElevatedButton(
                onPressed: _login, // Calling login function when the button is pressed
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                ),
                child: const Text('Login', style: TextStyle(fontSize: 18, color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Registered text widget
  Widget _registeredText() {
    return const Text(
      'Log In',
      style: TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 28,
        color: Colors.blue,
      ),
    );
  }

  // Email field widget
  Widget _emailField() {
    return TextField(
      controller: _emailController, // Set the controller for email input
      decoration: InputDecoration(
        labelText: 'Email',
        labelStyle: const TextStyle(color: Colors.blue),
        hintText: 'Enter Email',
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(30)),
      ),
    );
  }

  // Password field widget
  Widget _passwordField() {
    return TextField(
      controller: _passwordController, // Set the controller for password input
      obscureText: true, // Hide the password input
      decoration: InputDecoration(
        labelText: 'Password',
        labelStyle: const TextStyle(color: Colors.blue),
        hintText: 'Enter Password',
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(50)),
      ),
    );
  }

  // Sign-up text widget
  Widget _signupText(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 30),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'Don\'t have an account?',
            style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14, color: Colors.blueGrey),
          ),
          TextButton(
            onPressed: () {
              Navigator.pushReplacement(
                  context, MaterialPageRoute(builder: (BuildContext context) => SignupPage(post: widget.post,)));
            },
            child: const Text(
              'Sign Up',
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueAccent),
            ),
          ),
        ],
      ),
    );
  }
}
