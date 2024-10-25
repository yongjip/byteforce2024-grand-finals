import '../models/reservationmealkits_model.dart';
import '../models/meal_kit_model.dart';

class Reservation {
  final String id;
  final String userId;
  final DateTime startTime;
  final DateTime endTime;
  List<ReservationMealKits> orderedMealKits; // List of ordered meal kits

  Reservation({
    required this.id,
    required this.userId,
    required this.startTime,
    required this.endTime,
    this.orderedMealKits = const [], // Default to an empty list
  });

  factory Reservation.fromMap(Map<String, dynamic> map) {
    return Reservation(
      id: map['id'],
      userId: map['user_id'],
      startTime: DateTime.parse(map['start_time']),
      endTime: DateTime.parse(map['end_time']),
      // orderedMealKits will be assigned after fetching meal kits separately
      // We'll assign orderedMealKits after fetching meal kits separately
    );
  }
}