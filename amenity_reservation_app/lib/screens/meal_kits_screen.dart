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
  bool _isLoading = false; // Loading state to prevent multiple submissions

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

  void _confirmMealKitOrder() async {
    if (_isLoading) return; // Prevent multiple taps
    setState(() {
      _isLoading = true;
    });

    bool orderConfirmed = await SupabaseService().addMealKitsToReservation(
      widget.email,
      widget.reservationTime,
      _selectedMealKitsWithQuantities,
    );

    if (orderConfirmed) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Meal Kits Added to Reservation')),
      );
      Navigator.popUntil(context, (route) => route.isFirst);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to confirm meal kit order')),
      );
    }

    setState(() {
      _isLoading = false;
    });
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
                      width: 200,
                      height: 150,
                      fit: BoxFit.cover,
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
                    width: 60,
                    height: 60,
                    child: Image.network(
                      kit.imageUrl,
                      fit: BoxFit.cover,
                    ),
                  )
                      : Icon(Icons.image, size: 50),
                  title: Text(kit.name),
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
                  child: _isLoading
                      ? CircularProgressIndicator(color: Colors.white)
                      : Text('Confirm Meal Kits'),
                  onPressed: _isLoading ? null : _confirmMealKitOrder,
                ),
              ],
            ),
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom + 20),
        ],
      ),
    );
  }
}
