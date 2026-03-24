import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/variable_expense.dart';

class VariableExpenseService {
  static const String _key = 'variable_expenses';

  Future<List<VariableExpense>> getAll() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_key);

    if (data == null || data.isEmpty) return [];

    final List decoded = jsonDecode(data);

    return decoded.map((e) => VariableExpense.fromMap(e)).toList();
  }

  Future<void> save(List<VariableExpense> list) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(list.map((e) => e.toMap()).toList());

    await prefs.setString(_key, encoded);
  }

  Future<void> add(VariableExpense expense) async {
    final list = await getAll();
    list.add(expense);
    await save(list);
  }

  Future<void> delete(String id) async {
    final list = await getAll();
    list.removeWhere((e) => e.id == id);
    await save(list);
  }

  Future<double> getTotalCurrentMonth() async {
    final list = await getAll();
    final now = DateTime.now();

    double total = 0;

    for (final e in list) {
      if (e.date.month == now.month && e.date.year == now.year) {
        total += e.value;
      }
    }

    return total;
  }
}
