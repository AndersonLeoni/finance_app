class Income {
  final String id;
  final int month;
  final int year;
  final double salary;
  final double extra;

  Income({
    required this.id,
    required this.month,
    required this.year,
    required this.salary,
    required this.extra,
  });

  double get total => salary + extra;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'month': month,
      'year': year,
      'salary': salary,
      'extra': extra,
    };
  }

  factory Income.fromMap(Map<String, dynamic> map) {
    return Income(
      id: map['id'],
      month: map['month'],
      year: map['year'],
      salary: (map['salary'] as num).toDouble(),
      extra: (map['extra'] as num).toDouble(),
    );
  }
}
