import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/expense.dart';

class ExpenseService {
  static const String _key = 'expenses';
  static const Uuid _uuid = Uuid();

  Future<List<Expense>> loadExpenses() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_key);

    if (data == null || data.isEmpty) return [];

    final List decoded = jsonDecode(data);

    return decoded.map((item) => Expense.fromMap(item)).toList();
  }

  Future<void> saveExpenses(List<Expense> expenses) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(expenses.map((e) => e.toMap()).toList());
    await prefs.setString(_key, encoded);
  }

  Future<void> addExpense(Expense expense) async {
    final expenses = await loadExpenses();
    expenses.add(expense);
    await saveExpenses(expenses);
  }

  Future<void> deleteExpense(String id) async {
    final expenses = await loadExpenses();
    expenses.removeWhere((e) => e.id == id);
    await saveExpenses(expenses);
  }

  Future<void> updateExpense(Expense updated) async {
    final expenses = await loadExpenses();
    final index = expenses.indexWhere((e) => e.id == updated.id);
    if (index != -1) {
      expenses[index] = updated;
    }
    await saveExpenses(expenses);
  }

  Future<void> saveAll(List<Expense> newExpenses) async {
    final existing = await loadExpenses();
    existing.addAll(newExpenses);
    await saveExpenses(existing);
  }

  Future<void> replaceAll(List<Expense> newExpenses) async {
    await saveExpenses(newExpenses);
  }

  Future<void> payInstallment(String id) async {
    final expenses = await loadExpenses();
    final index = expenses.indexWhere((e) => e.id == id);

    if (index != -1) {
      final expense = expenses[index];

      if (expense.type == ExpenseType.installment &&
          expense.currentInstallment != null &&
          expense.totalInstallments != null &&
          !expense.isCompleted) {
        expenses[index] = Expense(
          id: expense.id,
          category: expense.category,
          name: expense.name,
          type: expense.type,
          value: expense.value,
          currentInstallment: expense.currentInstallment! + 1,
          totalInstallments: expense.totalInstallments,
        );
        await saveExpenses(expenses);
      }
    }
  }

  String generateId() => _uuid.v4();
}
