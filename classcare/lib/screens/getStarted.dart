

import 'package:classcare/screens/login.dart';
import 'package:flutter/material.dart';

class Start extends StatelessWidget {
  const Start({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue.shade50,
      body: Container(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text("Welcome to ClassCare" ,style: TextStyle(fontSize: 30 , color: Colors.blue ,),),
              SizedBox(height: 30,),
              Container(
                margin: EdgeInsets.symmetric(horizontal: 30),
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (BuildContext context)=>LoginPage(post: "Teacher",)));
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue, // Button color
                    padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  ), 
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      
                      const Text(
                        "Teacher", 
                        style: TextStyle(color: Colors.white),
                      ),
                      const SizedBox(width: 10), // Space between icon and text
                      const Icon(
                        Icons.arrow_forward, // Arrow icon
                        color: Colors.white, // Icon color
                      ),
                    ],
                  ),
                ),
              ),

              SizedBox(height: 30,),
              Container(
                margin: EdgeInsets.symmetric(horizontal: 30),
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (BuildContext context)=>LoginPage(post: "Student",)));
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue, // Button color
                    padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  ), 
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      
                      const Text(
                        "Student", 
                        style: TextStyle(color: Colors.white),
                      ),
                      const SizedBox(width: 10), // Space between icon and text
                      const Icon(
                        Icons.arrow_forward, // Arrow icon
                        color: Colors.white, // Icon color
                      ),
                    ],
                  ),
                ),
              ),
            ],
          )

        ),
      ),
    );
  }
}
