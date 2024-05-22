class Worker {
  final String name;
  final String position;
  final String currency;
  final num dayHourRate;
  final num nightHourRate;
  final num pensionPercentage;
  final List<Map<String, dynamic>> workDate;
  final String nextPaymentDate;
  final int paymentIntervalDays;
  final int countWorkDate;
  final int countProbablyWorkDate;

  Worker({
    required this.name,
    required this.position,
    required this.currency,
    required this.dayHourRate,
    required this.nightHourRate,
    required this.pensionPercentage,
    required this.workDate,
    required this.nextPaymentDate,
    required this.paymentIntervalDays,
    this.countWorkDate = 0,
    this.countProbablyWorkDate = 0,
  });

  factory Worker.fromMap(Map<String, dynamic> map) {
    return Worker(
      name: map['name'],
      position: map['position'],
      currency: map['currency'],
      nightHourRate: map['nightHourRate'],
      dayHourRate: map['dayHourRate'],
      pensionPercentage: map['pensionPercentage'],
      workDate: List<Map<String, dynamic>>.from(map['workDate'] ?? []),
      nextPaymentDate: map['nextPaymentDate'],
      paymentIntervalDays: map['paymentIntervalDays'],
      countWorkDate: map['countWorkDate'],
      countProbablyWorkDate: map['countProbablyWorkDate'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'position': position,
      'currency': currency,
      'dayHourRate': dayHourRate,
      'nightHourRate': nightHourRate,
      'pensionPercentage': pensionPercentage,
      'workDate': workDate,
      'nextPaymentDate': nextPaymentDate,
      'paymentIntervalDays': paymentIntervalDays,
      'countWorkDate': countWorkDate,
      'countProbablyWorkDate': countProbablyWorkDate,
    };
  }
}
