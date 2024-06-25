import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'add_schedule_screen.dart';
import 'modify_schedule_screen.dart';
import 'remove_schedule_screen.dart';
import '../config.dart'; // Import the config file

class WelcomeScreen extends StatefulWidget {
  @override
  _WelcomeScreenState createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  static const String _serverIp = Config.serverIp; //'http://127.0.0.1:5000';

  final _formKey = GlobalKey<FormState>();
  TextEditingController _aiAssistantController = TextEditingController();

  late stt.SpeechToText _speech;
  bool _isListening = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    _getMicrophonePermission();
  }

  Future<void> _getMicrophonePermission() async {
    var status = await Permission.microphone.request();
    if (status != PermissionStatus.granted) {
      // Handle denied or restricted permissions
      print('Microphone permission not granted');
    }
  }

  Future<void> _listen() async {
    if (!_isListening) {
      bool available = await _speech.initialize(
        onStatus: (status) {
          print('Status: $status');
        },
        onError: (error) {
          print('Error: $error');
        },
      );

      if (available) {
        setState(() => _isListening = true);
        _speech.listen(
          onResult: (result) {
            setState(() {
              _aiAssistantController.text = result.recognizedWords;
            });
          },
        );
      }
    } else {
      setState(() => _isListening = false);
      _speech.stop();
    }
  }

  void _clearText() {
    setState(() {
      _aiAssistantController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Welcome'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: Form(
                  key: _formKey,
                  child: TextFormField(
                    controller: _aiAssistantController,
                    maxLines: 5, // Allowing multiline text
                    decoration: InputDecoration(
                      labelText: 'Talk to AI Assistant',
                      hintText: 'What do you want to do?',
                      suffixIcon: IconButton(
                        icon: Icon(Icons.clear),
                        onPressed: _clearText,
                      ),
                    ),
                    validator: (value) {
                      if (value!.isEmpty) {
                        return 'Please enter a command';
                      }
                      return null;
                    },
                  ),
                ),
              ),
              IconButton(
                icon: Icon(_isListening ? Icons.mic : Icons.mic_none),
                onPressed: _listen,
              ),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: _isLoading
                    ? null
                    : () async {
                        if (_formKey.currentState!.validate()) {
                          setState(() {
                            _isLoading = true;
                          });

                          await sendFormData();

                          setState(() {
                            _isLoading = false;
                          });
                        }
                      },
                child: _isLoading
                    ? CircularProgressIndicator()
                    : Text('Send it to AI Assistant'),
              ),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => AddScheduleScreen()),
                  );
                },
                child: Text('Umów Pacjenta'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> sendFormData() async {
    try {
      final response = await http.post(
        Uri.parse('$_serverIp/submit-ai-form'),
        headers: {'Content-Type': 'application/json'},
        body: _getFormDataAsJson(),
      );

      if (response.statusCode == 200) {
        print('Form data sent successfully!');
        print('response body: ' + response.body);

        final responseData = json.decode(response.body);

        if (responseData['action'] == 'add') {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddScheduleScreen(responseData: responseData),
            ),
          );
        } 
        else if (responseData['action'] == 'modify') {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ChangeScheduleScreen(responseData: responseData),
            ),
          );
        }
        else if (responseData['action'] == 'remove') {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => RemoveScheduleScreen(responseData: responseData),
            ),
          );
        }  
      } else {
        print('Failed to send form data. Status code: ${response.statusCode}');
      }
    } catch (error) {
      print('Error sending form data: $error');
    }
  }

  String _getFormDataAsJson() {
    final formData = {
      'voiceCommand': _aiAssistantController.text,
    };

    return json.encode(formData);
  }
}
