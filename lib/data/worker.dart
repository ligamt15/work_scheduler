class Worker {
  final String name;
  final String position;
  final String currency;
  final num hourRate;
  final num pensionPercentage;
  final List<Map<String, dynamic>> workDate;

  Worker({
    required this.name,
    required this.position,
    required this.currency,
    required this.hourRate,
    required this.pensionPercentage,
    required this.workDate,
  });

  factory Worker.fromMap(Map<String, dynamic> map) {
    return Worker(
      name: map['name'],
      position: map['position'],
      currency: map['currency'],
      hourRate: map['hourRate'],
      pensionPercentage: map['pensionPercentage'],
      workDate: List<Map<String, dynamic>>.from(map['workDate'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'position': position,
      'currency': currency,
      'hourRate': hourRate,
      'pensionPercentage': pensionPercentage,
      'workDate': workDate,
    };
  }
}
