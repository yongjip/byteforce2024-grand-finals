import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/supabase_service.dart';
import '../models/reservation_model.dart';
import '../models/reservationmealkits_model.dart';

class MyReservationsScreen extends StatefulWidget {
  final String email;
  MyReservationsScreen({required this.email});

  @override
  _MyReservationsScreenState createState() => _MyReservationsScreenState();
}

class _MyReservationsScreenState extends State<MyReservationsScreen> {
  List<Reservation> _reservations = [];
  bool _showPastReservations = false; // Toggle for showing past reservations

  @override
  void initState() {
    super.initState();
    _fetchReservations();
  }

  void _fetchReservations() async {
    List<Reservation> res = await SupabaseService().getUserReservations(widget.email);
    res.sort((a, b) => a.startTime.compareTo(b.startTime));

    setState(() {
      _reservations = res;
    });
  }

  void _cancelReservation(String reservationId) async {
    bool success = await SupabaseService().cancelReservation(reservationId);
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Reservation Cancelled')),
      );
      _fetchReservations();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to cancel reservation')),
      );
    }
  }

  double _calculateTotalPrice(List<ReservationMealKits> orderedMealKits) {
    double total = 0;
    for (var kit in orderedMealKits) {
      total += kit.price * kit.quantity;
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    DateTime now = DateTime.now();

    // Separate current/future and past reservations
    List<Reservation> currentAndFutureReservations =
    _reservations.where((res) => res.startTime.isAfter(now) || res.startTime.isAtSameMomentAs(now)).toList();
    List<Reservation> pastReservations =
    _reservations.where((res) => res.startTime.isBefore(now)).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text('My Reservations'),
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Reservations for ${widget.email}',
              style: TextStyle(fontSize: 20),
            ),
          ),
          ElevatedButton(
            child: Text(_showPastReservations ? 'Show Current & Future Reservations' : 'Show Past Reservations'),
            onPressed: () {
              setState(() {
                _showPastReservations = !_showPastReservations;
              });
            },
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _showPastReservations ? pastReservations.length : currentAndFutureReservations.length,
              itemBuilder: (context, index) {
                Reservation res = _showPastReservations ? pastReservations[index] : currentAndFutureReservations[index];
                String formattedTime = DateFormat('yyyy-MM-dd HH:mm').format(res.startTime);

                double totalPrice = _calculateTotalPrice(res.orderedMealKits);

                return Card(
                  margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  child: Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('$formattedTime', style: TextStyle(fontWeight: FontWeight.bold)),
                        SizedBox(height: 8),
                        Text('Ordered Meal Kits:', style: TextStyle(fontSize: 16)),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: res.orderedMealKits.map((link) {
                            return Text(
                              '${link.mealKitName} x${link.quantity} @ \$${link.price.toStringAsFixed(2)}',
                              style: TextStyle(fontSize: 14),
                            );
                          }).toList(),
                        ),
                        Divider(),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Total Price:',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              '\$${totalPrice.toStringAsFixed(2)}',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        SizedBox(height: 10),
                        if (!_showPastReservations)
                          Align(
                            alignment: Alignment.centerRight,
                            child: ElevatedButton(
                              child: Text('Cancel'),
                              onPressed: () => _cancelReservation(res.id),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom + 20),
        ],
      ),
    );
  }
}
