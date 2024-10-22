import 'package:flutter/material.dart';
import 'reservation_screen.dart';
import 'my_reservations_screen.dart';

class HomeScreen extends StatelessWidget {
  // Main menu screen
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
            ElevatedButton(
              child: Text('Reserve a Kitchen Slot'),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ReservationScreen()),
                );
              },
            ),
            SizedBox(height: 20),
            ElevatedButton(
              child: Text('My Reservations'),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => MyReservationsScreen()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
