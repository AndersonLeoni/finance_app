import 'dart:convert';

enum ExpenseType { fixed, installment }

class Expense {
  final String id;
  final String category;
  final String name;
  final ExpenseType type;
  final double value;
  final int? currentInstallment;
  final int? totalInstallments;

  Expense({
    required this.id,
    required this.category,
    required this.name,
    required this.type,
    required this.value,
    this.currentInstallment,
    this.totalInstallments,
  });

  bool get isCompleted =>
      type == ExpenseType.installment &&
      currentInstallment != null &&
      totalInstallments != null &&
      currentInstallment! >= totalInstallments!;

  bool get isActive => type == ExpenseType.fixed || !isCompleted;

  Expense copyWith({
    String? id,
    String? category,
    String? name,
    ExpenseType? type,
    double? value,
    int? currentInstallment,
    int? totalInstallments,
  }) {
    return Expense(
      id: id ?? this.id,
      category: category ?? this.category,
      name: name ?? this.name,
      type: type ?? this.type,
      value: value ?? this.value,
      currentInstallment: currentInstallment ?? this.currentInstallment,
      totalInstallments: totalInstallments ?? this.totalInstallments,
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'category': category,
    'name': name,
    'type': type.name,
    'value': value,
    'currentInstallment': currentInstallment,
    'totalInstallments': totalInstallments,
  };

  factory Expense.fromMap(Map<String, dynamic> map) => Expense(
    id: map['id'],
    category: map['category'],
    name: map['name'],
    type: ExpenseType.values.firstWhere((e) => e.name == map['type']),
    value: map['value'].toDouble(),
    currentInstallment: map['currentInstallment'],
    totalInstallments: map['totalInstallments'],
  );

  String toJson() => json.encode(toMap());

  factory Expense.fromJson(String source) =>
      Expense.fromMap(json.decode(source));
}
