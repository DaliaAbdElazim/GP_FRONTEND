import 'package:flutter/material.dart';
import 'package:my_app/front_end_helper/curved_clipper.dart';
import 'package:my_app/widgets/navigation_drawer.dart';

class ContactScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Define the light grey color to be used throughout
    final Color black = const Color.fromARGB(255, 7, 7, 7)!;
    final Color redBorder = Color(0xFFBE0000);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFFBE0000),
        title: Text('Contact Us', style: TextStyle(color: Colors.white)),
        iconTheme: IconThemeData(color: Colors.white),
      ),
      drawer: CustomNavigationDrawer(currentRoute: '/contact'),
      body: Stack(
        children: [
          // Top red bar that sits behind everything
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: ClipPath(
              clipper: CurvedBottomClipper(),
              child: Container(
                height: 20,
                color: Color(0xFFBE0000),
                child: Padding(
                  padding: const EdgeInsets.only(left: 20.0, top: 30.0),
                ),
              ),
            ),
          ),

          // Main content
          SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 15),
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(color: redBorder, width: 1.5),
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Get In Touch',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: black,
                            ),
                          ),

                          Text(
                            'We\'d love to hear from you. Please fill out the form below or contact us directly.',
                            style: TextStyle(fontSize: 16, color: black),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 10),
                  TextField(
                    style: TextStyle(color: black),
                    decoration: InputDecoration(
                      labelText: 'Name',
                      labelStyle: TextStyle(color: black),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide(color: redBorder, width: 1.5),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide(color: redBorder, width: 2),
                      ),
                      prefixIcon: Icon(Icons.person, color: black),
                    ),
                  ),
                  SizedBox(height: 16),
                  TextField(
                    style: TextStyle(color: black),
                    decoration: InputDecoration(
                      labelText: 'Email',
                      labelStyle: TextStyle(color: black),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide(color: redBorder, width: 1.5),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide(color: redBorder, width: 2),
                      ),
                      prefixIcon: Icon(Icons.email, color: black),
                    ),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  SizedBox(height: 16),
                  TextField(
                    style: TextStyle(color: black),
                    decoration: InputDecoration(
                      labelText: 'Subject',
                      labelStyle: TextStyle(color: black),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide(color: redBorder, width: 1.5),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide(color: redBorder, width: 2),
                      ),
                      prefixIcon: Icon(Icons.subject, color: black),
                    ),
                  ),
                  SizedBox(height: 16),
                  TextField(
                    style: TextStyle(color: black),
                    decoration: InputDecoration(
                      
                      labelText: 'Message',
                      labelStyle: TextStyle(color: black),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide(color: redBorder, width: 1.5),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide(color: redBorder, width: 2),
                      ),
                      alignLabelWithHint: true,
                      prefixIcon: Padding(
                        padding: EdgeInsets.only(
                          top: 4.0,
                          left: 12.0,
                          right: 8.0,
                        ),
                        child: Align(
                          alignment: Alignment.topCenter,
                          widthFactor: 1.0,
                          heightFactor: 1.0,
                          child: Icon(Icons.message, color: black),
                        ),
                      ),
                    ),
                    maxLines: 5,
                  ),
                  SizedBox(height: 24),
                  Center(
                    child: ElevatedButton(
                      onPressed: () {
                        // Send contact form action
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Message sent!')),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: redBorder,
                        padding: EdgeInsets.symmetric(
                          horizontal: 40,
                          vertical: 15,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: BorderSide(color: redBorder, width: 1.5),
                        ),
                      ),
                      child: Text(
                        'Send Message',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                  SizedBox(height: 30),
                  Text(
                    'Or Reach Us Directly',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: black,
                    ),
                  ),
                  SizedBox(height: 10),
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(color: redBorder, width: 1.5),
                    ),
                    child: ListTile(
                      leading: Icon(Icons.email, color: black),
                      title: Text('Email', style: TextStyle(color: black)),
                      subtitle: Text(
                        'support@example.com',
                        style: TextStyle(color: black),
                      ),
                    ),
                  ),
                  SizedBox(height: 8),
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(color: redBorder, width: 1.5),
                    ),
                    child: ListTile(
                      leading: Icon(Icons.phone, color: black),
                      title: Text('Phone', style: TextStyle(color: black)),
                      subtitle: Text(
                        '+1 (123) 456-7890',
                        style: TextStyle(color: black),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
