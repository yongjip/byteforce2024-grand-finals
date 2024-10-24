import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/user_model.dart';
import '../models/reservation_model.dart';
import '../models/meal_kit_model.dart';

class SupabaseService {
  final supabase = Supabase.instance.client;
  final uuid = Uuid();

  /// Retrieves an existing user by email or creates a new one if not found.
  Future<UserModel> getOrCreateUser(String email) async {
    try {
      // Use lowercase table name 'users'
      final response = await supabase
          .from('users')
          .select()
          .eq('email', email)
          .maybeSingle();

      if (response != null) {
        // User exists, return the user
        return UserModel.fromMap(response);
      } else {
        // Create new user
        final newUser = {
          'id': uuid.v4(),
          'email': email,
        };
        final insertResponse = await supabase
            .from('users') // Use lowercase
            .insert(newUser)
            .select()
            .single();

        return UserModel.fromMap(insertResponse);
      }
    } catch (e) {
      // Handle error
      throw Exception('Failed to get or create user: $e');
    }
  }

  Future<Map<TimeOfDay, bool>> getAvailableSlots(DateTime date) async {
    try {
      Map<TimeOfDay, bool> slotAvailability = {};
      for (int hour = 0; hour < 24; hour++) {
        for (int minute = 0; minute < 60; minute += 30) {
          slotAvailability[TimeOfDay(hour: hour, minute: minute)] = true;
        }
      }
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = startOfDay.add(Duration(days: 1));

      final response = await supabase
          .from('reservations')
          .select()
          .gte('start_time', startOfDay.toIso8601String())
          .lt('start_time', endOfDay.toIso8601String());

      List<Reservation> reservations = (response as List<dynamic>)
          .map((data) => Reservation.fromMap(data as Map<String, dynamic>))
          .toList();

      for (var res in reservations) {
        TimeOfDay time = TimeOfDay.fromDateTime(res.startTime);
        slotAvailability[time] = false;
      }

      return slotAvailability;

    } catch (e) {
      throw Exception('Failed to get available slots: $e');
    }

  }

  // /// Fetches available kitchen slots for a given date.
  // Future<List<TimeOfDay>> getAvailableSlots(DateTime date) async {
  //   try {
  //     // Assuming kitchen operates from 8 AM to 10 PM
  //     List<TimeOfDay> allSlots = [];
  //     for (int hour = 8; hour < 22; hour++) {
  //       allSlots.add(TimeOfDay(hour: hour, minute: 0));
  //       allSlots.add(TimeOfDay(hour: hour, minute: 30));
  //     }
  //
  //     final startOfDay = DateTime(date.year, date.month, date.day);
  //     final endOfDay = startOfDay.add(Duration(days: 1));
  //
  //     // Use lowercase table name 'reservations'
  //     final response = await supabase
  //         .from('reservations')
  //         .select()
  //         .gte('start_time', startOfDay.toIso8601String())
  //         .lt('start_time', endOfDay.toIso8601String());
  //
  //     List<Reservation> reservations = (response as List<dynamic>)
  //         .map((data) => Reservation.fromMap(data as Map<String, dynamic>))
  //         .toList();
  //
  //     // Remove occupied slots
  //     for (var res in reservations) {
  //       TimeOfDay time = TimeOfDay.fromDateTime(res.startTime);
  //       allSlots.removeWhere((slot) => slot == time);
  //     }
  //
  //     return allSlots;
  //   } catch (e) {
  //     // Handle error
  //     throw Exception('Failed to get available slots: $e');
  //   }
  // }

  /// Reserves a kitchen slot for a user.
  Future<bool> reserveSlot(
      String email, DateTime startTime, int durationMinutes) async {
    try {
      UserModel user = await getOrCreateUser(email);

      // Check total reserved minutes for the day
      final totalMinutes = await getUserReservedMinutes(user.id, startTime);

      if (totalMinutes + durationMinutes > 180) {
        // Exceeds daily limit
        return false;
      }

      final reservation = {
        'id': uuid.v4(),
        'user_id': user.id,
        'start_time': startTime.toIso8601String(),
        'end_time': startTime.add(Duration(minutes: durationMinutes)).toIso8601String(),
      };

      // Use lowercase table name 'reservations'
      await supabase.from('reservations').insert(reservation);

      return true;
    } catch (e) {
      // Handle error
      return false;
    }
  }

  /// Retrieves the total reserved minutes for a user on a specific date.
  Future<int> getUserReservedMinutes(String userId, DateTime date) async {
    try {
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = startOfDay.add(Duration(days: 1));

      // Use lowercase table name 'reservations'
      final response = await supabase
          .from('reservations')
          .select('start_time, end_time')
          .eq('user_id', userId)
          .gte('start_time', startOfDay.toIso8601String())
          .lt('start_time', endOfDay.toIso8601String());

      int totalMinutes = 0;
      (response as List<dynamic>).forEach((data) {
        DateTime start = DateTime.parse(data['start_time']);
        DateTime end = DateTime.parse(data['end_time']);
        totalMinutes += end.difference(start).inMinutes;
      });

      return totalMinutes;
    } catch (e) {
      // Handle error
      throw Exception('Failed to get user reserved minutes: $e');
    }
  }

  /// Fetches all available meal kits.
  Future<List<MealKit>> getMealKits() async {
    try {
      // Use lowercase table name 'mealkits'
      final response = await supabase.from('mealkits').select();

      return (response as List<dynamic>)
          .map((data) => MealKit.fromMap(data as Map<String, dynamic>))
          .toList();
    } catch (e) {
      // Handle error
      throw Exception('Failed to get meal kits: $e');
    }
  }

  /// Links selected meal kits to a reservation.
  Future<bool> addMealKitsToReservation(
      String email, DateTime reservationTime, Map<MealKit, int> mealKitsWithQuantities) async {
    try {
      // Get user
      UserModel user = await getOrCreateUser(email);

      // Get reservation
      final response = await supabase
          .from('reservations') // Use lowercase
          .select()
          .eq('user_id', user.id)
          .eq('start_time', reservationTime.toIso8601String())
          .maybeSingle();

      if (response == null) {
        // Reservation not found
        return false;
      }

      String reservationId = response['id'];

      // Link meal kits to reservation using lowercase table name
      for (MealKit kit in mealKitsWithQuantities.keys) {
        final link = {
          'reservation_id': reservationId,
          'meal_kit_id': kit.id,
          'quantity': mealKitsWithQuantities[kit],
        };
        await supabase.from('reservationmealkits').insert(link);
      }

      return true;
    } catch (e) {
      // Handle error
      return false;
    }
  }

  /// Retrieves all reservations for a user.
  Future<List<Reservation>> getUserReservations(String email) async {
    try {
      UserModel user = await getOrCreateUser(email);

      // Use lowercase table name 'reservations'
      final response = await supabase
          .from('reservations')
          .select()
          .eq('user_id', user.id)
          .order('start_time', ascending: false);

      return (response as List<dynamic>)
          .map((data) => Reservation.fromMap(data as Map<String, dynamic>))
          .toList();
    } catch (e) {
      // Handle exception
      return [];
    }
  }

  /// Cancels a reservation by its ID.
  Future<bool> cancelReservation(String reservationId) async {
    try {
      // Delete linked meal kits using lowercase table name
      await supabase
          .from('reservationmealkits')
          .delete()
          .eq('reservation_id', reservationId);

      // Delete the reservation using lowercase table name
      await supabase.from('reservations').delete().eq('id', reservationId);

      return true;
    } catch (e) {
      // Handle error
      return false;
    }
  }
}
