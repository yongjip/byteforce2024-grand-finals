import 'package:flutter/material.dart';
import 'reservation_screen.dart';
import 'my_reservations_screen.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Import SharedPreferences

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _email = '';  // Holds the email address
  bool _isEmailEntered = false;  // Tracks if the email is submitted

  final TextEditingController _emailController = TextEditingController();
  @override
  void initState() {
    super.initState();
    _loadEmail();
  }

  void _loadEmail() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? storedEmail = prefs.getString('user_email');
    if (storedEmail != null && storedEmail.isNotEmpty) {
      setState(() {
        _email = storedEmail;
        _isEmailEntered = true;
      });
    }
  }

  void _saveEmail(String email) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_email', email);
  }

  void _clearEmail() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_email'); // Remove the email from SharedPreferences
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('LYF Funan Kitchen'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            // If email is entered, show the email and the modify button
            if (_isEmailEntered) ...[
              Text(
                'Email: $_email',
                style: TextStyle(fontSize: 20),
              ),
              SizedBox(height: 10),
              ElevatedButton(
                child: Text('Modify'),
                onPressed: () {
                  // Allow the user to modify their email
                  setState(() {
                    _isEmailEntered = false;  // Show the email input box again
                    _emailController.text = _email;  // Pre-fill the input box with the current email
                  });
                },
              ),
            ] else ...[
              // Email input box
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    labelText: 'Enter your email',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
              ),
              ElevatedButton(
                child: Text('Save Email'),
                onPressed: () {
                  setState(() {
                    _email = _emailController.text;  // Save the entered email
                    _isEmailEntered = true;  // Hide the input box and show the email
                    _saveEmail(_email);  // Save the email to SharedPreferences
                  });
                },
                // button color changes to green when email is entered
                style: ElevatedButton.styleFrom(foregroundColor: Colors.white, backgroundColor: Colors.green),

              ),
            ],

            SizedBox(height: 20),

            // Buttons to navigate to other screens (Reservation or My Reservations)
            ElevatedButton(
              child: Text('Reserve a Kitchen Slot'),
              onPressed: () {
                if (_email.isNotEmpty) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => ReservationScreen(email: _email)),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Please enter your email')),
                  );
                }
              },
            ),
            SizedBox(height: 20),
            ElevatedButton(
                child: Text('My Reservations'),
                onPressed: () {
                  if (_email.isNotEmpty) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => MyReservationsScreen(email: _email)),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Please enter your email')),
                    );
                  }
                }
            ),
          ],
        ),
      ),
    );
  }
}
