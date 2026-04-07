import 'package:uuid/uuid.dart';
import '../models/expense.dart';
import 'firebase_expense_service.dart';

class ExpenseService {
  final _uuid = const Uuid();
  final _firebase = FirebaseExpenseService();

  String generateId() => _uuid.v4();

  Future<List<Expense>> loadExpenses() async {
    try {
      return await _firebase.getExpenses();
    } catch (e) {
      return [];
    }
  }

  Future<void> addExpense(Expense expense) async {
    try {
      await _firebase.addExpense(expense);
    } catch (e) {
      throw Exception('Erro ao salvar despesa');
    }
  }

  Future<void> deleteExpense(String id) async {
    try {
      await _firebase.deleteExpense(id);
    } catch (e) {
      throw Exception('Erro ao deletar despesa');
    }
  }

  Future<void> updateExpense(Expense expense) async {
    try {
      await _firebase.updateExpense(expense);
    } catch (e) {
      throw Exception('Erro ao atualizar despesa');
    }
  }

  Future<void> payInstallment(String id) async {
    final list = await loadExpenses();

    final index = list.indexWhere((e) => e.id == id);
    if (index == -1) return;

    final expense = list[index];

    if (expense.type == ExpenseType.installment &&
        expense.currentInstallment != null) {
      final updated = expense.copyWith(
        currentInstallment: expense.currentInstallment! + 1,
      );

      await updateExpense(updated);
    }
  }
}
