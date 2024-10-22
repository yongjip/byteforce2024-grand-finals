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
  List<MealKit> _selectedMealKits = [];

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
    bool success = await SupabaseService().addMealKitsToReservation(
      widget.email,
      widget.reservationTime,
      _selectedMealKits,
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
                  bool isSelected = _selectedMealKits.contains(kit);
                  return ListTile(
                    title: Text(kit.name),
                    subtitle: Text(kit.description),
                    trailing: Checkbox(
                      value: isSelected,
                      onChanged: (value) {
                        setState(() {
                          if (value == true) {
                            _selectedMealKits.add(kit);
                          } else {
                            _selectedMealKits.remove(kit);
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
