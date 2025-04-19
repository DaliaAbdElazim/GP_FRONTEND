import 'package:flutter/material.dart';
import 'package:my_app/front_end_helper/curved_clipper.dart';
import 'package:my_app/widgets/navigation_drawer.dart';

class SupportScreen extends StatelessWidget {
  final List<Map<String, dynamic>> faqList = [
    {
      'question': 'How do I reset my password?',
      'answer':
          'To reset your password, go to the login screen and tap on "Forgot Password". Follow the instructions sent to your email.',
    },
    {
      'question': 'How can I update my profile information?',
      'answer':
          'You can update your profile information by navigating to the Profile screen from the menu and tapping on the "Edit Profile" option.',
    },
    {
      'question': 'Is my personal information secure?',
      'answer':
          'Yes, we take data security very seriously. All personal information is encrypted and stored securely following industry standards.',
    },
    {
      'question': 'Can I use this app offline?',
      'answer':
          'Some features of the app are available offline, but most functionality requires an internet connection for the best experience.',
    },
    {
      'question': 'How do I delete my account?',
      'answer':
          'To delete your account, go to Settings > Privacy > Delete Account. Please note that this action is permanent.',
    },
  ];

  @override
Widget build(BuildContext context) {
  // Define the colors to match the first design
  final Color black = const Color.fromARGB(255, 7, 7, 7);
  final Color redBorder = Color(0xFFBE0000);
  
  return Scaffold(
    appBar: AppBar(
      backgroundColor: Color(0xFFBE0000),
      title: Text('Support', style: TextStyle(color: Colors.white)),
      iconTheme: IconThemeData(color: Colors.white),
    ),
    drawer: CustomNavigationDrawer(currentRoute: '/support'),
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
          padding: EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height:15),
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
                        'How can we help you?',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: black,
                        ),
                      ),
                      SizedBox(height: 10),
                      Text(
                        'Check our frequently asked questions below or contact our support team directly.',
                        style: TextStyle(fontSize: 16, color: black),
                      ),
                      SizedBox(height: 20),
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pushNamed(context, '/contact');
                        },
                        icon: Icon(Icons.contact_support),
                        label: Text('Contact Support'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: redBorder,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(
                            vertical: 12,
                            horizontal: 20,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                            side: BorderSide(color: redBorder, width: 1.5),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 20),
              Text(
                'Frequently Asked Questions',
                style: TextStyle(
                  fontSize: 20, 
                  fontWeight: FontWeight.bold,
                  color: black,
                ),
              ),
              SizedBox(height: 10),
              ...faqList.map((faq) => buildFaqItem(faq, black, redBorder)).toList(),
              SizedBox(height: 30),
             
              
            ],
          ),
        ),
      ],
    ),
  );
}

Widget buildFaqItem(Map<String, dynamic> faq, Color black, Color redBorder) {
  return Card(
    margin: EdgeInsets.only(bottom: 8),
    elevation: 2,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(20),
      side: BorderSide(color: redBorder, width: 1.5),
    ),
    child: ExpansionTile(
      title: Text(
        faq['question'],
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: black,
        ),
      ),
      iconColor: redBorder,
      collapsedIconColor: redBorder,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Text(
            faq['answer'], 
            style: TextStyle(height: 1.4, color: black),
          ),
        ),
      ],
    ),
  );
}
}
