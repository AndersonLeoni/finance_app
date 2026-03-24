class VariableExpense {
  final String id;
  final String description;
  final String category;
  final double value;
  final DateTime date;

  VariableExpense({
    required this.id,
    required this.description,
    required this.category,
    required this.value,
    required this.date,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'description': description,
      'category': category,
      'value': value,
      'date': date.toIso8601String(),
    };
  }

  factory VariableExpense.fromMap(Map<String, dynamic> map) {
    return VariableExpense(
      id: map['id'],
      description: map['description'] ?? '',
      category: map['category'] ?? 'Outros',
      value: (map['value'] as num).toDouble(),
      date: DateTime.parse(map['date']),
    );
  }
}
