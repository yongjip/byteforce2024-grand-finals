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

  @override
  void initState() {
    super.initState();
    _fetchReservations();
  }

  void _fetchReservations() async {
    List<Reservation> res = await SupabaseService().getUserReservations(widget.email);
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

  @override
  Widget build(BuildContext context) {
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
              child: Text('Fetch Reservations'),
              onPressed: _fetchReservations,
            ),
            Expanded(
              child: ListView.builder(
                itemCount: _reservations.length,
                itemBuilder: (context, index) {
                  Reservation res = _reservations[index];
                  String formattedTime =
                  DateFormat('yyyy-MM-dd HH:mm').format(res.startTime);
                  return ListTile(
                    title: Text('Reservation at $formattedTime'),
                    trailing: ElevatedButton(
                      child: Text('Cancel'),
                      onPressed: () => _cancelReservation(res.id),
                    ),
                  );
                },
              ),
            ),
            // Adding padding to the bottom for iPhone's home indicator
            SizedBox(height: MediaQuery.of(context).padding.bottom + 20),
          ],
        ));
  }
}
