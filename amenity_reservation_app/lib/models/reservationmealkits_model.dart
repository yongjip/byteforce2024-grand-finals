class ReservationMealKits {
  final String reservationId;
  final String mealKitId;
  final String mealKitName;
  final int quantity;

  ReservationMealKits({
    required this.reservationId,
    required this.mealKitId,
    required this.mealKitName,
    required this.quantity,
  });

  factory ReservationMealKits.fromMap(Map<String, dynamic> map) {
    return ReservationMealKits(
      reservationId: map['reservation_id'],
      mealKitId: map['meal_kit_id'],
      mealKitName: map['meal_kit_name'],
      quantity: map['quantity'],
    );
  }
}
