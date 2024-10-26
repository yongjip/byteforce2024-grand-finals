import 'package:flutter/material.dart';
import '../services/supabase_service.dart';
import '../models/meal_kit_model.dart';

class MealKitsScreen extends StatefulWidget {
  final DateTime reservationTime;
  final String email;

  MealKitsScreen({required this.reservationTime, required this.email});

  @override
  _MealKitsScreenState createState() => _MealKitsScreenState();
}

class _MealKitsScreenState extends State<MealKitsScreen> {
  List<MealKit> _mealKits = [];
  Map<MealKit, int> _selectedMealKitsWithQuantities = {};

  @override
  void initState() {
    super.initState();
    _fetchMealKits();
  }

  void _fetchMealKits() async {
    List<MealKit> kits = await SupabaseService().getMealKits();
    setState(() {
      _mealKits = kits;
    });
  }

  double _calculateTotalPrice() {
    double total = 0;
    _selectedMealKitsWithQuantities.forEach((kit, quantity) {
      total += kit.price * quantity;
    });
    return total;
  }

  void _confirmReservation() async {
    // First, add the meal kits to the reservation
    bool orderConfirmed = await SupabaseService().addMealKitsToReservation(
      widget.email,
      widget.reservationTime,
      _selectedMealKitsWithQuantities,
    );

    if (orderConfirmed) {
      // Only proceed to reserve the slot if the meal kit order was successful
      bool reservationMade = await SupabaseService().reserveSlot(
        widget.email,
        widget.reservationTime,
        60, // Duration in minutes
      );

      if (reservationMade) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Reservation Confirmed')),
        );
        Navigator.popUntil(context, (route) => route.isFirst);
      } else {
        // If reservation fails after meal kit order is confirmed
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to reserve slot')),
        );
        // Optionally, you might want to rollback or inform the user
      }
    } else {
      // If meal kit order fails, show a failure message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to confirm meal kit order')),
      );
    }
  }


  void _showMealKitDetails(MealKit kit) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(kit.name),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (kit.imageUrl.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: Image.network(
                      kit.imageUrl,
                      width: 200, // Set fixed width
                      height: 150, // Set fixed height
                      fit: BoxFit.cover, // Ensures the image fills the box while keeping its aspect ratio
                    ),
                  ),
                Text('Ingredients:'),
                Text(kit.ingredients.join(', ')),
                SizedBox(height: 10),
                Text('Recipe:'),
                Text(kit.recipe.replaceAll('\\n', '\n')),
              ],
            ),
          ),
          actions: [
            TextButton(
              child: Text('Close'),
              onPressed: () => Navigator.pop(context),
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
        title: Text('Select Meal Kits'),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: _mealKits.length,
              itemBuilder: (context, index) {
                MealKit kit = _mealKits[index];
                int quantity = _selectedMealKitsWithQuantities[kit] ?? 0;
                return ListTile(
                  leading: kit.imageUrl.isNotEmpty
                      ? SizedBox(
                    width: 60, // Set fixed width
                    height: 60, // Set fixed height
                    child: Image.network(
                      kit.imageUrl,
                      fit: BoxFit.cover, // Ensures the image fills the box while keeping its aspect ratio
                    ),
                  )
                      : Icon(Icons.image, size: 50), // Placeholder if no image                  title: Text(kit.name),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(kit.description.replaceAll('\\n', '\n')),
                      Text('Price: \$${kit.price.toStringAsFixed(2)}'),
                      Row(
                        children: [
                          Text('Quantity: '),
                          SizedBox(width: 10),
                          DropdownButton<int>(
                            value: quantity,
                            items: List.generate(10, (index) => index)
                                .map((int value) {
                              return DropdownMenuItem<int>(
                                value: value,
                                child: Text(value == 0 ? 'Select' : value.toString()),
                              );
                            }).toList(),
                            onChanged: (newQuantity) {
                              setState(() {
                                if (newQuantity != null && newQuantity > 0) {
                                  _selectedMealKitsWithQuantities[kit] = newQuantity;
                                } else {
                                  _selectedMealKitsWithQuantities.remove(kit);
                                }
                              });
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                  onTap: () {
                    _showMealKitDetails(kit);
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Text(
                  'Total Price: \$${_calculateTotalPrice().toStringAsFixed(2)}',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 16),
                ElevatedButton(
                  child: Text('Confirm Reservation'),
                  onPressed: _confirmReservation,
                ),
              ],
            ),
          ),
          // Adding padding to the bottom for iPhone's home indicator
          SizedBox(height: MediaQuery.of(context).padding.bottom + 20),
        ],
      ),
    );
  }
}
