import 'package:flutter/material.dart';
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
    return Scaffold(
      appBar: AppBar(
        title: Text('Support'),
        iconTheme: IconThemeData(color: Colors.white),
      ),
      drawer: CustomNavigationDrawer(currentRoute: '/support'),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              elevation: 4,
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
                      ),
                    ),
                    SizedBox(height: 10),
                    Text(
                      'Check our frequently asked questions below or contact our support team directly.',
                      style: TextStyle(fontSize: 16),
                    ),
                    SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pushNamed(context, '/contact');
                      },
                      icon: Icon(Icons.contact_support),
                      label: Text('Contact Support'),
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal: 20,
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
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            ...faqList.map((faq) => _buildFaqItem(faq)).toList(),
            SizedBox(height: 30),
            Text(
              'Still need help?',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pushNamed(context, '/chatbot');
              },
              icon: Icon(Icons.chat),
              label: Text('Chat with our Bot'),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 12, horizontal: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFaqItem(Map<String, dynamic> faq) {
    return ExpansionTile(
      title: Text(
        faq['question'],
        style: TextStyle(fontWeight: FontWeight.w600),
      ),
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Text(faq['answer'], style: TextStyle(height: 1.4)),
        ),
      ],
    );
  }
}
