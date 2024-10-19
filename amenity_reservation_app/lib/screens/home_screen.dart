import 'package:flutter/material.dart';
import '../models/amenity.dart';
import 'amenity_details_screen.dart';

class HomeScreen extends StatelessWidget {
  final List<Amenity> amenities = [
    Amenity(
      id: '1',
      name: 'Social Kitchen',
      description: 'A place to cook and socialize.',
      imageUrl: 'https://example.com/kitchen.jpg',
      isAvailable: true,
    ),
    Amenity(
      id: '2',
      name: 'Co-working Space',
      description: 'Work in a shared space with great Wi-Fi.',
      imageUrl: 'https://example.com/coworking.jpg',
      isAvailable: true,
    ),
    Amenity(
      id: '3',
      name: 'Social Gym',
      description: 'Get fit and stay healthy.',
      imageUrl: 'https://example.com/gym.jpg',
      isAvailable: false,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Amenities'),
      ),
      body: ListView.builder(
        itemCount: amenities.length,
        itemBuilder: (context, index) {
          final amenity = amenities[index];
          return ListTile(
            leading: Image.network(amenity.imageUrl, width: 50),
            title: Text(amenity.name),
            subtitle: Text(amenity.isAvailable ? 'Available' : 'Unavailable'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AmenityDetailsScreen(amenity: amenity),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
