import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/supabase_service.dart';
import 'meal_kits_screen.dart';

class ReservationScreen extends StatefulWidget {
  @override
  _ReservationScreenState createState() => _ReservationScreenState();
}

class _ReservationScreenState extends State<ReservationScreen> {
  DateTime _selectedDate = DateTime.now();
  List<TimeOfDay> _availableSlots = [];
  String _email = '';
  final _emailController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchAvailableSlots();
  }

  void _fetchAvailableSlots() async {
    List<TimeOfDay> slots =
    await SupabaseService().getAvailableSlots(_selectedDate);
    setState(() {
      _availableSlots = slots;
    });
  }

  void _reserveSlot(TimeOfDay time) async {
    if (_email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter your email address')),
      );
      return;
    }

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
            child: TextField(
              controller: _emailController,
              decoration: InputDecoration(labelText: 'Enter your email'),
              onChanged: (value) {
                _email = value;
              },
            ),
          ),
          Text('Available Slots on $formattedDate'),
          Expanded(
            child: ListView.builder(
              itemCount: _availableSlots.length,
              itemBuilder: (context, index) {
                TimeOfDay time = _availableSlots[index];
                return ListTile(
                  title: Text(time.format(context)),
                  trailing: ElevatedButton(
                    child: Text('Reserve'),
                    onPressed: () => _reserveSlot(time),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
