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
  Map<MealKit, int> _selectedMealKitsWithQuantities = {}; // Map to track selected meal kits and their quantities

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

  void _confirmReservation() async {
    List<MealKit> selectedKits = _selectedMealKitsWithQuantities.keys.toList();

    bool success = await SupabaseService().addMealKitsToReservation(
      widget.email,
      widget.reservationTime,
      selectedKits,
    );

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Reservation Confirmed')),
      );
      Navigator.popUntil(context, (route) => route.isFirst);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to confirm reservation')),
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
                Text('Ingredients:'),
                Text(kit.ingredients.join(', ')),
                SizedBox(height: 10),
                Text('Recipe:'),
                Text(kit.recipe),
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
                  bool isSelected = _selectedMealKitsWithQuantities.containsKey(kit);
                  int quantity = _selectedMealKitsWithQuantities[kit] ?? 1; // Default to 1 if not selected yet
                  return ListTile(
                    title: Text(kit.name),
                  subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                      Text(kit.description),
                    Text('Price: \$${kit.price.toStringAsFixed(2)}'), // Show price
                      if (isSelected)
                        Row(
                          children: [
                            Text('Quantity: '),
                            SizedBox(width: 10),
                            DropdownButton<int>(
                              value: quantity,
                              items: List.generate(10, (index) => index + 1)
                                .map((int value) {
                                  return DropdownMenuItem<int>(
                                    value: value,
                                    child: Text(value.toString()),
                                  );
                                }).toList(),
                              onChanged: (newQuantity) {
                                setState(() {
                                  if (newQuantity != null) {
                                    _selectedMealKitsWithQuantities[kit] = newQuantity;
                                  }
                                });
                              },
                            ),
                          ],
                        ),
                    ],
                  ),


                    trailing: Checkbox(
                      value: isSelected,
                      onChanged: (value) {
                        setState(() {
                          if (value == true) {
                            _selectedMealKitsWithQuantities[kit] = 1;
                          } else {
                            _selectedMealKitsWithQuantities.remove(kit);
                          }
                        });
                      },
                    ),
                    onTap: () {
                      _showMealKitDetails(kit);
                    },
                  );
                },
              ),
            ),
            ElevatedButton(
              child: Text('Confirm Reservation'),
              onPressed: _confirmReservation,
            ),
          ],
        ));
  }
}
