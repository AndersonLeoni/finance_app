import 'package:cloud_firestore/cloud_firestore.dart';

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
      'name': description, // Mapeado para 'name' conforme visto no Firebase
      'category': category,
      'value': value,
      'date': date, // Firestore aceita DateTime diretamente como Timestamp
    };
  }

  factory VariableExpense.fromMap(Map<String, dynamic> map, String documentId) {
    // Tenta pegar a data de várias formas para garantir compatibilidade
    DateTime parsedDate;
    if (map['date'] is Timestamp) {
      parsedDate = (map['date'] as Timestamp).toDate();
    } else if (map['date'] is String) {
      parsedDate = DateTime.parse(map['date']);
    } else {
      parsedDate = DateTime.now();
    }

    return VariableExpense(
      id: map['id'] ?? documentId,
      description: map['name'] ?? map['description'] ?? '',
      category: map['category'] ?? 'Outros',
      value: (map['value'] as num).toDouble(),
      date: parsedDate,
    );
  }
}
