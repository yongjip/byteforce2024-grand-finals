import 'package:flutter/material.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(AmenityReservationApp());
}

class AmenityReservationApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Amenity Reservation App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: HomeScreen(),
    );
  }
}
