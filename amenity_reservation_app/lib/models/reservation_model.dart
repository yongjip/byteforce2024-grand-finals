class Reservation {
  final String id;
  final String userId;
  final DateTime startTime;
  final DateTime endTime;

  Reservation({
    required this.id,
    required this.userId,
    required this.startTime,
    required this.endTime,
  });

  factory Reservation.fromMap(Map<String, dynamic> map) {
    return Reservation(
      id: map['id'],
      userId: map['user_id'],
      startTime: DateTime.parse(map['start_time']),
      endTime: DateTime.parse(map['end_time']),
    );
  }
}
