import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/expense.dart';
import 'package:uuid/uuid.dart';

class ExpenseService {
  static const String _key = 'expenses';

  Future<List<Expense>> loadExpenses() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_key);

    if (data == null || data.isEmpty) return [];

    final List decoded = jsonDecode(data);

    return decoded.map((e) => Expense.fromMap(e)).toList();
  }

  Future<void> saveExpenses(List<Expense> list) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(list.map((e) => e.toMap()).toList());

    await prefs.setString(_key, encoded);
  }

  Future<void> addExpense(Expense expense) async {
    final list = await loadExpenses();
    list.add(expense);
    await saveExpenses(list);
  }

  Future<void> deleteExpense(String id) async {
    final list = await loadExpenses();
    list.removeWhere((e) => e.id == id);
    await saveExpenses(list);
  }

  Future<void> updateExpense(Expense updated) async {
    final list = await loadExpenses();

    final index = list.indexWhere((e) => e.id == updated.id);
    if (index != -1) {
      list[index] = updated;
    }

    await saveExpenses(list);
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
    final list = await loadExpenses();

    final index = list.indexWhere((e) => e.id == id);
    if (index == -1) return;

    final expense = list[index];

    if (expense.type == ExpenseType.installment &&
        expense.currentInstallment != null &&
        expense.totalInstallments != null) {
      final next = expense.currentInstallment! + 1;

      list[index] = expense.copyWith(currentInstallment: next);

      await saveExpenses(list);
    }
  }

  String generateId() => const Uuid().v4();
}
