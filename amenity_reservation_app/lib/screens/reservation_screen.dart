import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/supabase_service.dart';
import 'meal_kits_screen.dart';

class ReservationScreen extends StatefulWidget {
  final String email;
  ReservationScreen({required this.email});
  @override
  _ReservationScreenState createState() => _ReservationScreenState();
}

class _ReservationScreenState extends State<ReservationScreen> {
  DateTime _selectedDate = DateTime.now();
  Map<TimeOfDay, bool> _slotAvailability = {};

  @override
  void initState() {
    super.initState();
    _fetchAvailableSlots();
  }

  void _fetchAvailableSlots() async {
    Map<TimeOfDay, bool> slots =
    await SupabaseService().getAvailableSlots(_selectedDate);
    setState(() {
      _slotAvailability = slots;
    });
  }

  void _reserveSlot(TimeOfDay time) async {
    String _email = widget.email;

    DateTime startTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      time.hour,
      time.minute,
    );

    bool success = await SupabaseService().reserveSlot(_email, startTime, 30);
    if (success) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => MealKitsScreen(
            reservationTime: startTime,
            email: _email,
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to reserve slot')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    String formattedDate = DateFormat('yyyy-MM-dd').format(_selectedDate);


    return Scaffold(
      appBar: AppBar(
        title: Text('Reserve a Slot'),
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Available Slots for ${widget.email}',
              style: TextStyle(fontSize: 20),
            ),
          ),
          Text('Available Slots on $formattedDate'),
          Expanded(
            child: ListView.builder(
              itemCount: _slotAvailability.length,
              itemBuilder: (context, index) {
                TimeOfDay time = _slotAvailability.keys.elementAt(index);
                bool isAvailable = _slotAvailability[time]!;
                return ListTile(
                  title: Text('${time.format(context)}'),
                  trailing: ElevatedButton(
                    child: Text(isAvailable ? 'Reserve' : 'Occupied'),
                    onPressed: isAvailable
                      ? () => _reserveSlot(time)
                        : null,
                    style: ElevatedButton.styleFrom(
                      disabledForegroundColor: Colors.grey,
                    )
                  )
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
