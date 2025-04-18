// lib/screens/chatbot_screen.dart
import 'package:flutter/material.dart';
import 'package:my_app/front_end_helper/curved_clipper.dart';
import 'package:my_app/widgets/navigation_drawer.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:uuid/uuid.dart';

// Response data structure
class ApiResponse {
  final String text;
  final String? audioUrl;

  ApiResponse({required this.text, this.audioUrl});
}

class ChatMessage {
  final String text;
  final bool isUserMessage;
  final String? audioUrl; // For storing audio file paths or URLs

  ChatMessage({required this.text, required this.isUserMessage, this.audioUrl});
}

class ChatbotScreen extends StatefulWidget {
  @override
  _ChatbotScreenState createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  final TextEditingController _textController = TextEditingController();
  final FocusNode _textFieldFocusNode = FocusNode();
  final List<ChatMessage> _messages = [
    ChatMessage(
      text:
          '👋 Hi! I\'m Aidy, your first aid assistant. How can I help you today?',
      isUserMessage: false,
    ),
  ];

  bool _isLoading = false;
  bool _isRecording = false;
  late AudioRecorder _audioRecorder;
  final AudioPlayer _audioPlayer = AudioPlayer();
  String? _currentRecordingPath;
  Map<String, bool> _playingAudio = {};
  final uuid = Uuid();

  @override
  void initState() {
    super.initState();
    _audioRecorder = AudioRecorder();

    // Listen for audio completion events
    _audioPlayer.onPlayerComplete.listen((event) {
      _updatePlayingState(null, false);
    });

    // Add post-frame callback to handle keyboard visibility
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Set up a listener for when the screen is tapped
      _textFieldFocusNode.addListener(() {
        if (_textFieldFocusNode.hasFocus) {
          // This ensures the keyboard appears when the field gets focus
        }
      });
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _textFieldFocusNode.dispose();
    _audioRecorder.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Chatbot', style: TextStyle(color: Colors.white)),
        iconTheme: IconThemeData(color: Colors.white),
        backgroundColor: Color(0xFFBE0000),
        elevation: 0,
      ),
      drawer: CustomNavigationDrawer(currentRoute: '/chatbot'),
      body: Stack(
        children: [
          // Curved red bar at the top
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: ClipPath(
              clipper: CurvedBottomClipper(),
              child: Container(height: 20, color: Color(0xFFBE0000)),
            ),
          ),

          // Main content with padding to start below the red bar
          Column(
            children: [
              // Empty space to push content below the red bar
              SizedBox(height: 30), // Adjust this value as needed

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
              if (_isLoading)
                Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        radius: 30, // Optional: controls size
                        backgroundColor: Colors.white, // or any color that fits
                        child: Image.asset(
                          'assets/images/CHATBOT-11.png',
                          width: 50,
                          height: 50,
                          fit: BoxFit.contain,
                        ),
                      ),
                      SizedBox(width: 8.0),
                      Container(
                        padding: EdgeInsets.all(12.0),
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(15.0),
                        ),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Color(0xFFBE0000),
                                ),
                              ),
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Processing...',
                              style: TextStyle(fontSize: 16.0),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              Divider(height: 1.0),
              Container(
                decoration: BoxDecoration(color: Theme.of(context).cardColor),
                child: _buildTextComposer(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChatMessage(ChatMessage message) {
    final String audioId = message.audioUrl ?? '';
    final bool isPlaying = _playingAudio[audioId] ?? false;
    final TextDirection textDir = getTextDirection(message.text);

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
              radius: 30, // Optional: controls size
              backgroundColor: Colors.white, // or any color that fits
              child: Image.asset(
                'assets/images/CHATBOT-11.png',
                width: 50,
                height: 50,
                fit: BoxFit.contain,
              ),
            ),

          Flexible(
            child: Directionality(
              textDirection: textDir,
              child: Container(
                padding: EdgeInsets.all(12.0),
                decoration: BoxDecoration(
                  color:
                      message.isUserMessage
                          ? Colors.blue[100]
                          : Colors.grey[200],
                  borderRadius: BorderRadius.circular(15.0),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(message.text, style: TextStyle(fontSize: 16.0)),
                    if (message.audioUrl != null) ...[
                      SizedBox(height: 8.0),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(
                              isPlaying ? Icons.pause : Icons.play_arrow,
                              color: Color(0xFFBE0000),
                            ),
                            onPressed:
                                () => _handleAudioPlayback(message.audioUrl!),
                          ),
                          Expanded(
                            child: Text(
                              isPlaying ? 'Playing audio...' : 'Voice message',
                              style: TextStyle(
                                fontSize: 12.0,
                                color: Colors.grey[700],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          SizedBox(width: message.isUserMessage ? 8.0 : 0),
          if (message.isUserMessage)
            CircleAvatar(
              radius: 30, // Optional: controls size
              backgroundColor: Colors.white, // or any color that fits
              child: Image.asset(
                'assets/images/user_icon.png',
                width: 50,
                height: 50,
                fit: BoxFit.contain,
              ),
            ),
        ],
      ),
    );
  }

  TextDirection getTextDirection(String text) {
    if (text.isEmpty) return TextDirection.ltr;

    // More robust Arabic detection
    final RegExp arabicPattern = RegExp(
      r'[\u0600-\u06FF\u0750-\u077F\u08A0-\u08FF\uFB50-\uFDFF\uFE70-\uFEFF]',
    );
    final String trimmedText = text.trim();
    if (trimmedText.isNotEmpty && arabicPattern.hasMatch(trimmedText[0])) {
      return TextDirection.rtl;
    }
    return TextDirection.ltr;
  }

  Widget _buildTextComposer() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
      child: Row(
        children: [
          // Voice recording button
          Container(
            decoration: BoxDecoration(
              color: _isRecording ? Colors.red : Colors.grey[300],
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: Icon(
                _isRecording ? Icons.stop : Icons.mic,
                color: _isRecording ? Colors.white : Colors.blue[700],
              ),
              onPressed: _isLoading ? null : _handleVoiceRecording,
            ),
          ),
          SizedBox(width: 8.0),
          // Text input field with multilingual support
          Flexible(
            child: GestureDetector(
              onTap: () {
                // Request focus to explicitly show keyboard when tapped anywhere in the text area
                FocusScope.of(context).requestFocus(_textFieldFocusNode);
              },
              child: TextField(
                controller: _textController,
                focusNode: _textFieldFocusNode,
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
                // Enable proper multilingual support
                keyboardType: TextInputType.multiline,
                textCapitalization: TextCapitalization.sentences,
                // Use Directionality detection based on input
                buildCounter: (
                  context, {
                  required currentLength,
                  required isFocused,
                  maxLength,
                }) {
                  // This is a workaround to trigger rebuilds when text changes
                  final direction = getTextDirection(_textController.text);
                  return Directionality(
                    textDirection: direction,
                    child: Container(), // Empty container, just for rebuilding
                  );
                },
                textDirection: getTextDirection(_textController.text),
                textInputAction: TextInputAction.send,
                showCursor: true,
                onSubmitted: _isLoading ? null : _handleTextSubmit,
                onTap: () {
                  // Ensure keyboard shows when tapped
                  FocusScope.of(context).requestFocus(_textFieldFocusNode);
                },
                onChanged: (text) {
                  // Force rebuild to update text direction
                  setState(() {});
                },
                enabled: !_isLoading && !_isRecording,
              ),
            ),
          ),
          SizedBox(width: 8.0),
          // Send button
          Container(
            decoration: BoxDecoration(
              color:
                  (_isLoading || _textController.text.isEmpty)
                      ? Colors.grey
                      : Color(0xFFBE0000),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: Icon(Icons.send, color: Colors.white),
              onPressed:
                  (_isLoading || _textController.text.isEmpty)
                      ? null
                      : () => _handleTextSubmit(_textController.text),
            ),
          ),
        ],
      ),
    );
  }

  // Handle starting/stopping voice recording
  // Handle starting/stopping voice recording
  void _handleVoiceRecording() async {
    if (_isRecording) {
      // Stop recording
      final path = await _audioRecorder.stop();

      setState(() {
        _isRecording = false;
        _currentRecordingPath = path;
      });

      if (path != null) {
        await _handleVoiceSubmit(path);
      }
    } else {
      // Request permissions
      final status = await Permission.microphone.request();
      if (status != PermissionStatus.granted) {
        // Handle permission denied
        print('Microphone permission denied');
        return;
      }

      // Prepare recording directory
      final directory = await getTemporaryDirectory();
      final filePath = '${directory.path}/${uuid.v4()}.m4a';

      try {
        // Configure recorder with current API
        await _audioRecorder.start(
          const RecordConfig(
            encoder: AudioEncoder.aacLc,
            bitRate: 128000,
            sampleRate: 44100,
          ),
          path: filePath,
        );

        setState(() {
          _isRecording = true;
          _currentRecordingPath = null;
        });
      } catch (e) {
        print('Error starting recording: $e');
        // Handle errors
      }
    }
  }

  // Handle playing/pausing audio messages
  void _handleAudioPlayback(String audioPath) async {
    final isCurrentlyPlaying = _playingAudio[audioPath] ?? false;

    // Stop any currently playing audio
    await _audioPlayer.stop();
    _updatePlayingState(null, false);

    if (!isCurrentlyPlaying) {
      try {
        // Start playing the selected audio
        if (audioPath.startsWith('http')) {
          // Remote audio URL
          await _audioPlayer.play(UrlSource(audioPath));
        } else {
          // Local file path
          await _audioPlayer.play(DeviceFileSource(audioPath));
        }
        _updatePlayingState(audioPath, true);
      } catch (e) {
        print('Error playing audio: $e');
        // Show error if needed
      }
    }
  }

  void _updatePlayingState(String? audioPath, bool isPlaying) {
    setState(() {
      // Update playing status for all audio files
      _playingAudio.updateAll((key, value) => false);

      // Set the specified audio file's playing state
      if (audioPath != null) {
        _playingAudio[audioPath] = isPlaying;
      }
    });
  }

  // Handle text message submission
  void _handleTextSubmit(String text) async {
    if (text.isEmpty) return;

    _textController.clear();

    setState(() {
      _messages.add(ChatMessage(text: text, isUserMessage: true));
      _isLoading = true;
    });

    // Hide keyboard after submitting
    FocusScope.of(context).unfocus();

    try {
      // Make the API call for text
      final response = await fetchChatTextResponse(text);

      setState(() {
        _messages.add(
          ChatMessage(
            text: response.text,
            isUserMessage: false,
            audioUrl: response.audioUrl,
          ),
        );
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _messages.add(
          ChatMessage(
            text:
                "Sorry, I couldn't process your request. Please try again later.",
            isUserMessage: false,
          ),
        );
        _isLoading = false;
      });
    }
  }

  // Handle voice message submission
  Future<void> _handleVoiceSubmit(String audioPath) async {
    setState(() {
      _messages.add(
        ChatMessage(
          text: "Voice message sent",
          isUserMessage: true,
          audioUrl: audioPath,
        ),
      );
      _isLoading = true;
    });

    try {
      // Make the API call with the voice recording
      final response = await fetchChatVoiceResponse(audioPath);

      setState(() {
        _messages.add(
          ChatMessage(
            text: response.text,
            isUserMessage: false,
            audioUrl: response.audioUrl,
          ),
        );
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _messages.add(
          ChatMessage(
            text:
                "Sorry, I couldn't process your voice message. Please try again later.",
            isUserMessage: false,
          ),
        );
        _isLoading = false;
      });
    }
  }

  // API call for text messages
  Future<ApiResponse> fetchChatTextResponse(String message) async {
    final url = Uri.parse(
      'https://7ad9-34-58-161-132.ngrok-free.app/chat-text',
    );

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json; charset=utf-8'},
        body: jsonEncode({'text': message}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        return ApiResponse(
          text:
              data['response'] ??
              "I received your message but I'm not sure how to respond.",
          audioUrl: data['audio_url'],
        );
      } else {
        throw Exception('Failed to get chat response');
      }
    } catch (e) {
      print('Error fetching chat response: $e');
      throw e;
    }
  }

  Future<ApiResponse> fetchChatVoiceResponse(String audioFilePath) async {
    final url = Uri.parse(
      'https://7ad9-34-58-161-132.ngrok-free.app/chat-voice',
    );

    try {
      final request = http.MultipartRequest('POST', url);

      // Add audio file
      final file = await http.MultipartFile.fromPath('audio', audioFilePath);
      request.files.add(file);

      // Send request
      final streamedResponse = await request.send();

      if (streamedResponse.statusCode == 200) {
        // Create a temporary file to store the received audio
        final directory = await getTemporaryDirectory();
        final responseAudioPath = '${directory.path}/${uuid.v4()}.wav';

        // Save the audio response to a file
        final fileStream = streamedResponse.stream;
        final outputFile = File(responseAudioPath);
        await fileStream.pipe(outputFile.openWrite());

        // Return the local file path for the audio
        return ApiResponse(
          text: "Voice response received", // Default text message
          audioUrl: responseAudioPath,
        );
      } else if (streamedResponse.statusCode == 400) {
        // Handle the 400 error case
        final response = await http.Response.fromStream(streamedResponse);
        final errorData = jsonDecode(response.body);
        return ApiResponse(
          text: errorData['error'] ?? "Could not process your voice message",
          audioUrl: null,
        );
      } else {
        // Handle other error cases
        final response = await http.Response.fromStream(streamedResponse);
        final errorData = jsonDecode(response.body);
        throw Exception(
          errorData['detail'] ?? 'Failed to get voice chat response',
        );
      }
    } catch (e) {
      print('Error processing voice chat: $e');
      throw e;
    }
  }
}
