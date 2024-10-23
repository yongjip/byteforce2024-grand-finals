import 'package:flutter/material.dart';
import 'reservation_screen.dart';
import 'my_reservations_screen.dart';


class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}


class _HomeScreenState extends State<HomeScreen> {
  String _email = '';

  final TextEditingController _emailController = TextEditingController();

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
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: 'Enter your email',
                  border: OutlineInputBorder(),
                  ),
                keyboardType: TextInputType.emailAddress,
                )
            ),
            ElevatedButton(
              child: Text('Submit Email'),
              onPressed: () {
                setState(() {
                  _email = _emailController.text;
                });
              }
            ),
            SizedBox(height: 20),
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
