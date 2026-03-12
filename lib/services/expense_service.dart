import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/expense.dart';

class ExpenseService {
  static const String _key = 'expenses';
  static const _uuid = Uuid();

  static List<Expense> _defaultExpenses() => [
    Expense(
      id: _uuid.v4(),
      category: 'Visa Elite',
      name: 'Adobe',
      type: ExpenseType.fixed,
      value: 139.01,
    ),
    Expense(
      id: _uuid.v4(),
      category: 'Visa Elite',
      name: 'Hope',
      type: ExpenseType.installment,
      value: 83.16,
      currentInstallment: 4,
      totalInstallments: 6,
    ),
    Expense(
      id: _uuid.v4(),
      category: 'Visa Elite',
      name: 'Ginasta',
      type: ExpenseType.installment,
      value: 74.22,
      currentInstallment: 5,
      totalInstallments: 12,
    ),
    Expense(
      id: _uuid.v4(),
      category: 'Visa Elite',
      name: 'Centauro',
      type: ExpenseType.installment,
      value: 209.99,
      currentInstallment: 5,
      totalInstallments: 5,
    ),
    Expense(
      id: _uuid.v4(),
      category: 'Smiles Gold',
      name: 'Total Pass',
      type: ExpenseType.fixed,
      value: 119.90,
    ),
    Expense(
      id: _uuid.v4(),
      category: 'Smiles Gold',
      name: 'Apple',
      type: ExpenseType.fixed,
      value: 5.90,
    ),
    Expense(
      id: _uuid.v4(),
      category: 'Smiles Gold',
      name: 'Trend',
      type: ExpenseType.installment,
      value: 124.92,
      currentInstallment: 2,
      totalInstallments: 10,
    ),
    Expense(
      id: _uuid.v4(),
      category: 'Smiles Gold',
      name: 'Amazon',
      type: ExpenseType.installment,
      value: 48.84,
      currentInstallment: 3,
      totalInstallments: 4,
    ),
    Expense(
      id: _uuid.v4(),
      category: 'Smiles Gold',
      name: 'Amazon',
      type: ExpenseType.installment,
      value: 51.26,
      currentInstallment: 5,
      totalInstallments: 6,
    ),
    Expense(
      id: _uuid.v4(),
      category: 'Smiles Gold',
      name: 'ML',
      type: ExpenseType.installment,
      value: 861.68,
      currentInstallment: 6,
      totalInstallments: 12,
    ),
    Expense(
      id: _uuid.v4(),
      category: 'Smiles Gold',
      name: 'Kabum',
      type: ExpenseType.installment,
      value: 267.54,
      currentInstallment: 10,
      totalInstallments: 10,
    ),
    Expense(
      id: _uuid.v4(),
      category: 'Smiles Gold',
      name: 'Perimetral',
      type: ExpenseType.installment,
      value: 117.00,
      currentInstallment: 3,
      totalInstallments: 6,
    ),
    Expense(
      id: _uuid.v4(),
      category: 'Nubank',
      name: 'Hope',
      type: ExpenseType.installment,
      value: 192.00,
      currentInstallment: 10,
      totalInstallments: 10,
    ),
    Expense(
      id: _uuid.v4(),
      category: 'Nubank',
      name: 'Casio',
      type: ExpenseType.installment,
      value: 72.21,
      currentInstallment: 5,
      totalInstallments: 6,
    ),
    Expense(
      id: _uuid.v4(),
      category: 'Nubank',
      name: 'Tess',
      type: ExpenseType.installment,
      value: 49.00,
      currentInstallment: 11,
      totalInstallments: 12,
    ),
    Expense(
      id: _uuid.v4(),
      category: 'Nubank',
      name: 'TS',
      type: ExpenseType.installment,
      value: 118.80,
      currentInstallment: 4,
      totalInstallments: 8,
    ),
    Expense(
      id: _uuid.v4(),
      category: 'Nubank',
      name: 'Samsung',
      type: ExpenseType.installment,
      value: 338.84,
      currentInstallment: 1,
      totalInstallments: 18,
    ),
    Expense(
      id: _uuid.v4(),
      category: 'Nubank',
      name: 'Prime',
      type: ExpenseType.fixed,
      value: 19.90,
    ),
    Expense(
      id: _uuid.v4(),
      category: 'Nubank',
      name: 'Sushi Trei',
      type: ExpenseType.installment,
      value: 25.84,
      currentInstallment: 5,
      totalInstallments: 12,
    ),
    Expense(
      id: _uuid.v4(),
      category: 'Mercado Livre',
      name: 'Garmin',
      type: ExpenseType.installment,
      value: 190.80,
      currentInstallment: 3,
      totalInstallments: 21,
    ),
    Expense(
      id: _uuid.v4(),
      category: 'Emprestimo',
      name: 'Emprestimo',
      type: ExpenseType.installment,
      value: 479.02,
      currentInstallment: 14,
      totalInstallments: 36,
    ),
    Expense(
      id: _uuid.v4(),
      category: 'Claro Residencial',
      name: 'Claro',
      type: ExpenseType.fixed,
      value: 357.64,
    ),
    Expense(
      id: _uuid.v4(),
      category: 'Natação',
      name: 'Edu',
      type: ExpenseType.fixed,
      value: 196.00,
    ),
  ];

  Future<List<Expense>> loadExpenses() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_key);

    if (data == null) {
      final defaults = _defaultExpenses();
      await saveExpenses(defaults);
      return defaults;
    }

    final List<dynamic> list = json.decode(data);
    return list.map((e) => Expense.fromMap(e)).toList();
  }

  Future<void> saveExpenses(List<Expense> expenses) async {
    final prefs = await SharedPreferences.getInstance();
    final data = json.encode(expenses.map((e) => e.toMap()).toList());
    await prefs.setString(_key, data);
  }

  Future<void> addExpense(Expense expense) async {
    final list = await loadExpenses();
    list.add(expense);
    await saveExpenses(list);
  }

  Future<void> updateExpense(Expense updated) async {
    final list = await loadExpenses();
    final index = list.indexWhere((e) => e.id == updated.id);
    if (index != -1) {
      list[index] = updated;
      await saveExpenses(list);
    }
  }

  Future<void> payInstallment(String id) async {
    final list = await loadExpenses();
    final index = list.indexWhere((e) => e.id == id);
    if (index != -1) {
      final expense = list[index];
      if (expense.type == ExpenseType.installment &&
          expense.currentInstallment! < expense.totalInstallments!) {
        list[index] = expense.copyWith(
          currentInstallment: expense.currentInstallment! + 1,
        );
        await saveExpenses(list);
      }
    }
  }

  Future<void> deleteExpense(String id) async {
    final list = await loadExpenses();
    list.removeWhere((e) => e.id == id);
    await saveExpenses(list);
  }
}
