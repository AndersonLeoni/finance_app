import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';

enum ExpenseType { fixed, installment }

class Expense {
  final String id;
  final String category;
  final String name;
  final ExpenseType type;
  final double value;
  final int? currentInstallment;
  final int? totalInstallments;
  final DateTime? date; // Adicionado campo de data para compatibilidade

  Expense({
    required this.id,
    required this.category,
    required this.name,
    required this.type,
    required this.value,
    this.currentInstallment,
    this.totalInstallments,
    this.date,
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
    DateTime? date,
  }) {
    return Expense(
      id: id ?? this.id,
      category: category ?? this.category,
      name: name ?? this.name,
      type: type ?? this.type,
      value: value ?? this.value,
      currentInstallment: currentInstallment ?? this.currentInstallment,
      totalInstallments: totalInstallments ?? this.totalInstallments,
      date: date ?? this.date,
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
    'date': date ?? DateTime.now(),
  };

  factory Expense.fromMap(Map<String, dynamic> map, String documentId) {
    // Tratamento seguro para o tipo de despesa
    ExpenseType expenseType = ExpenseType.fixed;
    if (map['type'] != null) {
      try {
        expenseType = ExpenseType.values.firstWhere((e) => e.name == map['type']);
      } catch (_) {
        // Se não encontrar o nome, mantém o padrão fixed
      }
    }

    // Tratamento para data (Timestamp ou String)
    DateTime? parsedDate;
    if (map['date'] is Timestamp) {
      parsedDate = (map['date'] as Timestamp).toDate();
    } else if (map['date'] is String) {
      parsedDate = DateTime.tryParse(map['date']);
    }

    return Expense(
      id: map['id'] ?? documentId,
      category: map['category'] ?? 'Geral',
      name: map['name'] ?? 'Sem nome',
      type: expenseType,
      value: (map['value'] as num?)?.toDouble() ?? 0.0,
      currentInstallment: map['currentInstallment'] as int?,
      totalInstallments: map['totalInstallments'] as int?,
      date: parsedDate,
    );
  }

  String toJson() => json.encode(toMap());

  factory Expense.fromJson(String source) =>
      Expense.fromMap(json.decode(source), '');
}
