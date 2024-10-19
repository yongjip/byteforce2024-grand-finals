import 'package:flutter/material.dart';
import '../models/amenity.dart';
import 'reservation_confirmation_screen.dart';

class AmenityDetailsScreen extends StatelessWidget {
  final Amenity amenity;

  AmenityDetailsScreen({required this.amenity});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(amenity.name),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Image.network(amenity.imageUrl),
            SizedBox(height: 20),
            Text(amenity.description, style: TextStyle(fontSize: 18)),
            SizedBox(height: 20),
            Text(
              amenity.isAvailable ? 'Available' : 'Currently Unavailable',
              style: TextStyle(
                fontSize: 16,
                color: amenity.isAvailable ? Colors.green : Colors.red,
              ),
            ),
            SizedBox(height: 20),
            if (amenity.isAvailable)
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ReservationConfirmationScreen(),
                    ),
                  );
                },
                child: Text('Reserve'),
              ),
          ],
        ),
      ),
    );
  }
}
