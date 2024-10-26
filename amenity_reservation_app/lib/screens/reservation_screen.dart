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
    Map<TimeOfDay, bool> slots = await SupabaseService().getAvailableSlots(_selectedDate);

    // Filter out past times
    final now = DateTime.now();
    final currentTimeOfDay = TimeOfDay.fromDateTime(now);

    slots.removeWhere((time, available) {
      // If the selected date is today, remove past times
      return _selectedDate.day == now.day &&
          _selectedDate.month == now.month &&
          _selectedDate.year == now.year &&
          (time.hour < currentTimeOfDay.hour);
    });

    setState(() {
      _slotAvailability = slots;
    });
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(Duration(days: 7)),
    );
    if (pickedDate != null && pickedDate != _selectedDate) {
      setState(() {
        _selectedDate = pickedDate;
      });
      _fetchAvailableSlots();
    }
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

    bool success = await SupabaseService().reserveSlot(_email, startTime, 60);
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

  String _formatTimeOfDay(TimeOfDay time) {
    final now = DateTime.now();
    final dt = DateTime(now.year, now.month, now.day, time.hour, time.minute);
    return DateFormat('HH:mm').format(dt);
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
            child: Column(
              children: [
                Text(
                  'Available Slots for ${widget.email}',
                  style: TextStyle(fontSize: 20),
                ),
                SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Selected Date: $formattedDate'),
                    SizedBox(width: 10),
                    ElevatedButton(
                      onPressed: () => _selectDate(context),
                      child: Text('Select Date'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _slotAvailability.length,
              itemBuilder: (context, index) {
                TimeOfDay time = _slotAvailability.keys.elementAt(index);
                bool isAvailable = _slotAvailability[time]!;
                String startTimeFormatted = _formatTimeOfDay(time);
                String endTimeFormatted = _formatTimeOfDay(
                    time.replacing(minute: (time.minute + 59) % 60));

                return ListTile(
                  title: Text('$startTimeFormatted - $endTimeFormatted'),
                  trailing: ElevatedButton(
                    child: Text(isAvailable ? 'Reserve' : 'Occupied'),
                    onPressed: isAvailable ? () => _reserveSlot(time) : null,
                    style: ElevatedButton.styleFrom(
                      disabledForegroundColor: Colors.grey,
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
