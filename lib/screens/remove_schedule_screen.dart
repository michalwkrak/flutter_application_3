import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
//import 'package:permission_handler/permission_handler.dart';
import 'welcome_screen.dart';
//import 'package:flutter_application_2/widgets/VoiceControl.dart';
import '../config.dart'; // Import the config file

class RemoveScheduleScreen extends StatefulWidget {
  static const String _serverIp = Config.serverIp; //'http://127.0.0.1:5000';
  final Map<String, dynamic>? responseData;

  // Constructor with optional parameter (default to null)
  RemoveScheduleScreen({this.responseData});

  // Constructor with initial data
  RemoveScheduleScreen.withData({required this.responseData});

  @override
  _RemoveScheduleScreenState createState() => _RemoveScheduleScreenState();
}


class _RemoveScheduleScreenState extends State<RemoveScheduleScreen> {
  
  // Define doctor, location options
  //final List<String> doctorOptions = ['Agnieszka', 'Barbara']; 
  //final List<String> locationOptions = ['Górna Wieś', 'Kraków'];

  // Default values for doctor and location
  //String _selectedDoctor = 'Agnieszka';
  //String _selectedLocation = 'Kraków';

  final _formKey = GlobalKey<FormState>();
  TextEditingController _phoneNumberController = TextEditingController(text: 'Nie podano');
  TextEditingController _firstNameController = TextEditingController(text: 'Nie podano');
  TextEditingController _lastNameController = TextEditingController(text: 'Nie podano');
  TextEditingController _dateController = TextEditingController();
  TextEditingController _timeController = TextEditingController();
  TextEditingController _durationController = TextEditingController();
  TextEditingController _doctorController = TextEditingController();
  TextEditingController _locationController = TextEditingController();
  TextEditingController _commentsController = TextEditingController();

  
  //bool _isListening = false;
  bool _isLoading = false;
  late String _appointmentId;
  bool _appointmentIdIsNull = false;

  //late VoiceControl _voiceControl; // Declare an instance of the VoiceControl class


  @override
  void initState() {
    super.initState();
    //_voiceControl = VoiceControl(); // Initialize the VoiceControl instance
    //_speech = stt.SpeechToText();
    //_getMicrophonePermission();

    // Set the initial values for _doctorController and _locationController
    //_doctorController.text = _selectedDoctor;
    //_locationController.text = _selectedLocation;

    // Check if response data is available before accessing its properties
    if (widget.responseData != null) {
      // Initialize controllers with data from the response
      _firstNameController.text = widget.responseData!['firstName'] ?? '';
      _lastNameController.text = widget.responseData!['lastName'] ?? '';
      _dateController.text = widget.responseData!['appointmentDate'] ?? '';
      _timeController.text = widget.responseData!['appointmentTime'] ?? '';
      _durationController.text = widget.responseData!['appointmentDuration'].toString() ?? '';
      _commentsController.text = widget.responseData!['comments'] ?? '';
      _phoneNumberController.text = widget.responseData!['callerPhoneNumber'] ?? '';

       // Initialize doctor and location controllers with default values
      _doctorController.text = widget.responseData!['doctor'] ?? '';
      _locationController.text = widget.responseData!['location'] ?? '';

      _appointmentId = widget.responseData!['appointmentId'].toString() ?? '';
      _appointmentIdIsNull = widget.responseData!['appointmentId'] == null;
    }
  }


  void _showPopup(String title, Map<String, dynamic> data, {bool isSuccess = true}) {
    Color backgroundColor = isSuccess ? Colors.green : Colors.red;
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          contentPadding: EdgeInsets.zero, // Adjust size based on content
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Status: ${data['status']}'),
              Text('Message: ${data['message']}'),
              //Text('Imię: ${data['firstName']}'),
              //Text('Nazwisko: ${data['lastName']}'),
              //Text('Data: ${data['date']}'),
              //Text('Czas: ${data['time']}'),
            ],
          ),
          backgroundColor: backgroundColor,
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Remove Visit'),
        backgroundColor: _appointmentIdIsNull ? Colors.orange : Colors.green,
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              TextFormField(
                controller: _phoneNumberController,
                decoration: InputDecoration(labelText: 'Phone Number'),
              ),
              TextFormField(
                controller: _firstNameController,
                decoration: InputDecoration(labelText: 'Name'),               
              ),
              TextFormField(
                controller: _lastNameController,
                decoration: InputDecoration(labelText: 'Last Name'),
              ),
              TextFormField(
                controller: _dateController,
                decoration: InputDecoration(labelText: 'Date'),
              ),
              TextFormField(
                controller: _timeController,
                decoration: InputDecoration(labelText: 'Time'),
              ),
              TextFormField(
                controller: _durationController,
                decoration: InputDecoration(labelText: 'Appointment Duration (min)'),
              ),
              TextFormField(
                controller: _locationController,
                decoration: InputDecoration(labelText: 'Location'),
              ),
              TextFormField(
                controller: _doctorController,
                decoration: InputDecoration(labelText: 'Doctor'),
              ),
              TextFormField(
                controller: _commentsController,
                decoration: InputDecoration(labelText: 'Comments'),
              ),

              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _isLoading ? null : () async {
                  if (_formKey.currentState!.validate()) {
                    setState(() {
                      _isLoading = true;
                    });

                    // Send form data to the server
                    await sendFormData();

                    setState(() {
                      _isLoading = false;
                    });
                  }
                },
                child: _isLoading
                    ? CircularProgressIndicator()
                    : Text('Remove Visit'),
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
        Uri.parse('${RemoveScheduleScreen._serverIp}/delete-appointment'),
        headers: {'Content-Type': 'application/json'},
        //body: _getFormDataAsJson(),
        body: json.encode({'appointmentId': _appointmentId}),
      );

      if (response.statusCode == 200) {
        // Handle successful response from the server
        print('Appointment removed successfully!');

        // Decode the response body to extract dynamic data
        final responseData = json.decode(response.body);
      
        // Show success popup
        _showPopup('Appointment Removed', responseData, isSuccess: true);

        // Delay the redirection by 2 seconds
        await Future.delayed(Duration(seconds: 4));
      
        // Redirect to the welcome screen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => WelcomeScreen()),
        );
      } else {
        // Handle errors if any
        print('Failed to send form data. Status code: ${response.statusCode}');

        // Show error popup
        _showPopup('Appointment is not removed', {'error': 'Failed to remove data'}, isSuccess: false);
      }
    } catch (error) {
      print('Error sending form data: $error');

      // Show error popup
      _showPopup('Appointment is not removed', {'error': error.toString()}, isSuccess: false);
    }
  }

  String _getFormDataAsJson() {
    final formData = {
      'firstName': _firstNameController.text,
      'lastName': _lastNameController.text,
      'appointmentDate': _dateController.text,
      'appointmentTime': _timeController.text,
      'appointmentDuration': _durationController.text,
      'doctor': _doctorController.text,
      'location': _locationController.text,
      'comments': _commentsController.text,
      'callerPhoneNumber': _phoneNumberController.text.replaceAll(RegExp(r'\s+'), ''),
    };

    return json.encode(formData);
  }

}

