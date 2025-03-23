// lib/screens/chatbot_screen.dart
import 'package:flutter/material.dart';
import '../widgets/base_screen.dart';

class ChatMessage {
  final String text;
  final bool isUserMessage;

  ChatMessage({required this.text, required this.isUserMessage});
}

class ChatbotScreen extends StatefulWidget {
  @override
  _ChatbotScreenState createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  final TextEditingController _textController = TextEditingController();
  final List<ChatMessage> _messages = [
    ChatMessage(
      text: 'Hello! I\'m your virtual assistant. How can I help you today?',
      isUserMessage: false,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return BaseScreen(
      title: 'Chatbot',
      currentRoute: '/chatbot',
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.all(8.0),
              reverse: false,
              itemCount: _messages.length,
              itemBuilder: (_, int index) {
                return _buildChatMessage(_messages[index]);
              },
            ),
          ),
          Divider(height: 1.0),
          Container(
            decoration: BoxDecoration(color: Theme.of(context).cardColor),
            child: _buildTextComposer(),
          ),
        ],
      ),
    );
  }

  Widget _buildChatMessage(ChatMessage message) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment:
            message.isUserMessage
                ? MainAxisAlignment.end
                : MainAxisAlignment.start,
        children: [
          if (!message.isUserMessage)
            CircleAvatar(
              backgroundColor: Colors.blue,
              child: Icon(Icons.smart_toy, color: Colors.white),
            ),
          SizedBox(width: message.isUserMessage ? 0 : 8.0),
          Flexible(
            child: Container(
              padding: EdgeInsets.all(12.0),
              decoration: BoxDecoration(
                color:
                    message.isUserMessage ? Colors.blue[100] : Colors.grey[200],
                borderRadius: BorderRadius.circular(15.0),
              ),
              child: Text(message.text, style: TextStyle(fontSize: 16.0)),
            ),
          ),
          SizedBox(width: message.isUserMessage ? 8.0 : 0),
          if (message.isUserMessage)
            CircleAvatar(
              backgroundColor: Colors.blue[700],
              child: Icon(Icons.person, color: Colors.white),
            ),
        ],
      ),
    );
  }

  Widget _buildTextComposer() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
      child: Row(
        children: [
          Flexible(
            child: TextField(
              controller: _textController,
              decoration: InputDecoration(
                hintText: 'Send a message',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25.0),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey[200],
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
              ),
              onSubmitted: _handleSubmit,
            ),
          ),
          SizedBox(width: 8.0),
          Container(
            decoration: BoxDecoration(
              color: Colors.blue,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: Icon(Icons.send, color: Colors.white),
              onPressed: () => _handleSubmit(_textController.text),
            ),
          ),
        ],
      ),
    );
  }

  void _handleSubmit(String text) {
    if (text.isEmpty) return;

    _textController.clear();

    setState(() {
      _messages.add(ChatMessage(text: text, isUserMessage: true));
    });

    // Simulate chatbot response
    Future.delayed(Duration(seconds: 1), () {
      setState(() {
        _messages.add(
          ChatMessage(text: _getBotResponse(text), isUserMessage: false),
        );
      });
    });
  }

  String _getBotResponse(String message) {
    message = message.toLowerCase();

    if (message.contains('hello') || message.contains('hi')) {
      return 'Hello there! How can I assist you today?';
    } else if (message.contains('help')) {
      return 'I can help with app navigation, account issues, or feature questions. What do you need assistance with?';
    } else if (message.contains('password')) {
      return 'To reset your password, go to the login screen and tap on "Forgot Password". We\'ll send you instructions via email.';
    } else if (message.contains('account')) {
      return 'For account-related issues, please check the Settings section or contact our support team via the Contact Us page.';
    } else if (message.contains('thank')) {
      return 'You\'re welcome! Is there anything else I can help you with?';
    } else {
      return 'I\'m not sure I understand. Could you rephrase your question or choose a topic like "password reset", "account issues", or "app features"?';
    }
  }
}
