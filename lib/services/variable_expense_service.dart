import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/variable_expense.dart';

class VariableExpenseService {
  static const String _key = 'variable_expenses';

  Future<List<VariableExpense>> getAll() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_key);

    if (data == null || data.isEmpty) {
      return [];
    }

    final List decoded = jsonDecode(data);

    return decoded
        .map((item) => VariableExpense.fromMap(item))
        .toList();
  }

  Future<void> save(List<VariableExpense> expenses) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(
      expenses.map((expense) => expense.toMap()).toList(),
    );
    await prefs.setString(_key, encoded);
  }

  Future<void> add(VariableExpense expense) async {
    final expenses = await getAll();
    expenses.add(expense);
    await save(expenses);
  }

  Future<void> delete(String id) async {
    final expenses = await getAll();
    expenses.removeWhere((expense) => expense.id == id);
    await save(expenses);
  }

  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }

  Future<double> getTotalCurrentMonth() async {
    final expenses = await getAll();
    final now = DateTime.now();

    double total = 0;

    for (final expense in expenses) {
      if (expense.date.month == now.month &&
          expense.date.year == now.year) {
        total += expense.value;
      }
    }

    return total;
  }
}
