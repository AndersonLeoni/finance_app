class VariableExpense {
  final String id;
  final String category;
  final String description;
  final double value;
  final DateTime date;

  VariableExpense({
    required this.id,
    required this.category,
    required this.description,
    required this.value,
    required this.date,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'category': category,
      'description': description,
      'value': value,
      'date': date.millisecondsSinceEpoch,
    };
  }

  factory VariableExpense.fromMap(Map<String, dynamic> map) {
    return VariableExpense(
      id: map['id'],
      category: map['category'],
      description: map['description'],
      value: map['value'],
      date: DateTime.fromMillisecondsSinceEpoch(map['date']),
    );
  }
}
