import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'welcome_screen.dart';
import 'package:flutter_application_2/widgets/VoiceControl.dart';
import 'package:permission_handler/permission_handler.dart';
import '../config.dart'; // Import the config file



class ChangeScheduleScreen extends StatefulWidget {
  static const String _serverIp = Config.serverIp; //'http://127.0.0.1:5000';
  final Map<String, dynamic>? responseData;

  // Constructor with optional parameter (default to null)
  ChangeScheduleScreen({this.responseData});

  // Constructor with initial data
  ChangeScheduleScreen.withData({required this.responseData});

  //final String voiceCommand;

  //ChangeScheduleScreen({required this.voiceCommand});

  @override
  _ChangeScheduleScreenState createState() => _ChangeScheduleScreenState();
}

class _ChangeScheduleScreenState extends State<ChangeScheduleScreen> {

  // Define doctor, location options
  final List<String> doctorOptions = ['Agnieszka', 'Barbara']; 
  final List<String> locationOptions = ['Górna Wieś', 'Kraków'];

  // Default values for doctor and location
  String _selectedDoctor = 'Agnieszka';
  String _selectedLocation = 'Kraków';

  final _formKey = GlobalKey<FormState>();
  TextEditingController _firstNameController = TextEditingController();
  TextEditingController _lastNameController = TextEditingController();
  TextEditingController _oldDateController = TextEditingController();
  TextEditingController _oldTimeController = TextEditingController();
  TextEditingController _newDateController = TextEditingController();
  TextEditingController _newTimeController = TextEditingController();
  TextEditingController _durationController = TextEditingController();
  TextEditingController _doctorController = TextEditingController();
  TextEditingController _locationController = TextEditingController();
  TextEditingController _commentsController = TextEditingController();
  TextEditingController _phoneNumberController = TextEditingController();
  //TextEditingController _calendarIdController = TextEditingController();
  //TextEditingController _appointmentIdController = TextEditingController();

  // Declare calendarId and appointmentId variables
  late String _calendarId;
  late String _appointmentId;

  bool _isListening = false;
  bool _isLoading = false;

  late VoiceControl _voiceControl; // Declare an instance of the VoiceControl class

  @override
  void initState() {
    super.initState();
    _voiceControl = VoiceControl(); // Initialize the VoiceControl instance
    _getMicrophonePermission();

    // Set the initial values for _doctorController and _locationController
    _doctorController.text = _selectedDoctor;
    _locationController.text = _selectedLocation;

    // Check if response data is available before accessing its properties
    if (widget.responseData != null) {
      // Initialize controllers with data from the response
      _phoneNumberController.text = widget.responseData!['callerPhoneNumber'] ?? '';
      _firstNameController.text = widget.responseData!['firstName'] ?? '';
      _lastNameController.text = widget.responseData!['lastName'] ?? '';
      _oldDateController.text = widget.responseData!['appointmentDate_A'] ?? '';  
      _oldTimeController.text = widget.responseData!['appointmentTime_A'] ?? '';
      _newDateController.text = widget.responseData!['appointmentDate_B'] ?? '';
      _newTimeController.text = widget.responseData!['appointmentTime_B'] ?? '';
      _durationController.text = widget.responseData!['appointmentDuration'].toString() ?? '';
      _doctorController.text = widget.responseData!['doctor'] ?? '';
      _locationController.text = widget.responseData!['location'] ?? '';
      _commentsController.text = widget.responseData!['comments'] ?? '';
       // Initialize doctor and location controllers with default values
      _doctorController.text = widget.responseData!['doctor'] ?? _selectedDoctor;
      _locationController.text = widget.responseData!['location'] ?? _selectedLocation;

      _calendarId = widget.responseData!['calendarId'] ?? '';
      _appointmentId = widget.responseData!['appointmentId'].toString() ?? '';

    }
  }

  Future<void> _getMicrophonePermission() async {
    var status = await Permission.microphone.request();
    if (status != PermissionStatus.granted) {
      // Handle denied or restricted permissions
      print('Microphone permission not granted');
    }
  }

  Future<void> _pickDate() async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(Duration(days: 365)),
    );

    if (pickedDate != null && pickedDate != DateTime.now()) {
      _newDateController.text = pickedDate.toString().split(' ')[0];
    }
  }

  Future<void> _pickTime() async {
    TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (BuildContext context, Widget? child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: false),
          child: child!,
        );
      },
    );

    if (pickedTime != null) {
      _newTimeController.text =
          '${pickedTime.hour}:${pickedTime.minute.toString().padLeft(2, '0')}';
    }
  }

  void _increaseDuration(int step) {
    int currentDuration = int.tryParse(_durationController.text) ?? 0;
    _durationController.text = (currentDuration + step).toString();
  }

  void _decreaseDuration(int step) {
    int currentDuration = int.tryParse(_durationController.text) ?? 0;
    if (currentDuration >= step) {
      _durationController.text = (currentDuration - step).toString();
    }
  }

  // phoneNumberController voice control
  Future<void> _listenPhoneNumber() async {
    await _voiceControl.initialize(); // Initialize voice control

    await _voiceControl.startListening((result) {
      setState(() {
        _phoneNumberController.text = result;
      });
    });

    // Set the timeout duration (e.g., 10 seconds)
    const timeoutDuration = Duration(seconds: 10);

    // Add a delay for the specified duration
    await Future.delayed(timeoutDuration);

    // Stop listening after the delay
    await _voiceControl.stopListening();
  }

  // firstNameController voice control
  Future<void> _listenFirstName() async {
    await _voiceControl.initialize(); // Initialize voice control

    await _voiceControl.startListening((result) {
      setState(() {
        _firstNameController.text = result;
      });
    });

    // Set the timeout duration (e.g., 10 seconds)
    const timeoutDuration = Duration(seconds: 10);

    // Add a delay for the specified duration
    await Future.delayed(timeoutDuration);

    // Stop listening after the delay
    await _voiceControl.stopListening();
  }

  // lastNameController voice control
  Future<void> _listenLastName() async {
    await _voiceControl.initialize();
    
    await _voiceControl.startListening((result) {
      setState(() {
        _lastNameController.text = result;
      });
    });

    const timeoutDuration = Duration(seconds: 10);

    await Future.delayed(timeoutDuration);

    await _voiceControl.stopListening();
  }

  // commentsController voice control
  Future<void> _listenComments() async {
    await _voiceControl.initialize();
    
    await _voiceControl.startListening((result) {
      setState(() {
        _commentsController.text = result;
      });
    });

    const timeoutDuration = Duration(seconds: 10);

    await Future.delayed(timeoutDuration);

    await _voiceControl.stopListening();
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
                Text('Imię: ${data['firstName']}'),
                Text('Nazwisko: ${data['lastName']}'),
                Text('Data: ${data['date']}'),
                Text('Czas: ${data['time']}'),
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
        title: Text('Change Visit'),
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
                /*validator: (value) {
                  if (value!.isEmpty) {
                    return 'Please enter phone number';
                  }
                  return null;
                },*/
              ),
              IconButton(
                icon: Icon(_isListening ? Icons.mic : Icons.mic_none),
                onPressed: _listenPhoneNumber,
              ),
              TextFormField(
                controller: _firstNameController,
                decoration: InputDecoration(labelText: 'Name'),
                validator: (value) {
                  if (value!.isEmpty) {
                    return 'Please enter name';
                  }
                  return null;
                },
              ),
              IconButton(
                icon: Icon(_isListening ? Icons.mic : Icons.mic_none),
                onPressed: _listenFirstName,
              ),
              TextFormField(
                controller: _lastNameController,
                decoration: InputDecoration(labelText: 'Last Name'),
                validator: (value) {
                  if (value!.isEmpty) {
                    return 'Please enter last name';
                  }
                  return null;
                },
              ),
              IconButton(
                icon: Icon(_isListening ? Icons.mic : Icons.mic_none),
                onPressed: _listenLastName,
              ),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _oldDateController,
                      decoration: InputDecoration(labelText: 'Previous date'),
                      enabled: false, // Make the field not editable
                    ),
                  ),
                  SizedBox(width: 8), // Add some spacing between the fields
                  Expanded(
                    child: GestureDetector(
                      onTap: _pickDate,
                      child: AbsorbPointer(
                        child: TextFormField(
                          controller: _newDateController,
                          decoration: InputDecoration(labelText: 'New date'),
                          validator: (value) {
                            if (value!.isEmpty) {
                              return 'Please enter a new date';
                            }
                            return null;
                          },
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _oldTimeController,
                      decoration: InputDecoration(labelText: 'Previous time'),
                      enabled: false, // Make the field not editable
                    ),
                  ),
                  SizedBox(width: 8), // Add some spacing between the fields
                  Expanded(
                    child: GestureDetector(
                      onTap: _pickTime,
                      child: AbsorbPointer(
                        child: TextFormField(
                          controller: _newTimeController,
                          decoration: InputDecoration(labelText: 'New time'),
                          validator: (value) {
                            if (value!.isEmpty) {
                              return 'Please enter a new time';
                            }
                            return null;
                          },
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _durationController,
                      decoration:
                          InputDecoration(labelText: 'Appointment Duration (min)'),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value!.isEmpty) {
                          return 'Please choose appointment duration';
                        }
                        return null;
                      },
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.add),
                    onPressed: () {
                      _increaseDuration(15);
                    },
                  ),
                  IconButton(
                    icon: Icon(Icons.remove),
                    onPressed: () {
                      _decreaseDuration(15);
                    },
                  ),
                ],
              ),
              // Location Dropdown
              DropdownButtonFormField<String>(
                value: locationOptions.contains(_locationController.text) ? _locationController.text : _selectedLocation,
                items: locationOptions.map((location) {
                  return DropdownMenuItem<String>(
                    value: location,
                    child: Text(location),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _locationController.text = value ?? '';
                  });
                },
                decoration: InputDecoration(labelText: 'Location'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please choose a location';
                  }
                  return null;
                },
              ),
              // Doctor Dropdown
              DropdownButtonFormField<String>(
                value: doctorOptions.contains(_doctorController.text) ? _doctorController.text : _selectedDoctor,
                items: doctorOptions.map((doctor) {
                  return DropdownMenuItem<String>(
                    value: doctor,
                    child: Text(doctor),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _doctorController.text = value ?? '';
                  });
                },
                decoration: InputDecoration(labelText: 'Doctor'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please choose a doctor';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _commentsController,
                decoration: InputDecoration(labelText: 'Comments'),
              ),
              IconButton(
                icon: Icon(_isListening ? Icons.mic : Icons.mic_none),
                onPressed: _listenComments,
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
                    : Text('Schedule Visit'),
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
        Uri.parse('${ChangeScheduleScreen._serverIp}/modify-appointment'),
        headers: {'Content-Type': 'application/json'},
        body: _getFormDataAsJson(),
      );

      if (response.statusCode == 200) {
        // Handle successful response from the server
        print('Form data sent successfully!');

        // Decode the response body to extract dynamic data
        final responseData = json.decode(response.body);

        // Show success popup
        _showPopup('Modification Successful', responseData, isSuccess: true);

        // Delay the redirection by 2 seconds
        await Future.delayed(Duration(seconds: 2));

        // Redirect to the welcome screen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => WelcomeScreen()),
        );
      } else {
        // Handle errors if any
        print('Failed to send form data. Status code: ${response.statusCode}');

        // Show error popup
        _showPopup('Error in Modification', {'error': 'Failed to modify appointment'}, isSuccess: false);
      }
    } catch (error) {
      print('Error sending form data: $error');

      // Show error popup
      _showPopup('Error in Modification', {'error': error.toString()}, isSuccess: false);
    }
  }

  String _getFormDataAsJson() {
    final formData = {
      'firstName': _firstNameController.text,
      'lastName': _lastNameController.text,
      'appointmentDate': _newDateController.text,
      'appointmentTime': _newTimeController.text,
      'appointmentDuration': _durationController.text,
      'doctor': _doctorController.text,
      'location': _locationController.text,
      'comments': _commentsController.text,
      'callerPhoneNumber': _phoneNumberController.text.replaceAll(RegExp(r'\s+'), ''),
      'appointmentId': _appointmentId,
      'calendarId': _calendarId,
    };

    return json.encode(formData);
  }


}
