import '../models/variable_expense.dart';
import 'firebase_variable_expense_service.dart';

class VariableExpenseService {
  final _firebase = FirebaseVariableExpenseService();

  Future<List<VariableExpense>> getAll() async {
    try {
      return await _firebase.getVariableExpenses();
    } catch (e) {
      return [];
    }
  }

  Future<void> save(List<VariableExpense> list) async {
    // Para manter compatibilidade com a interface antiga se necessário,
    // mas o ideal é usar add/delete individualmente no Firebase.
    for (var expense in list) {
      await add(expense);
    }
  }

  Future<void> add(VariableExpense expense) async {
    try {
      await _firebase.addVariableExpense(expense);
    } catch (e) {
      throw Exception('Erro ao salvar gasto variável no Firebase');
    }
  }

  Future<void> delete(String id) async {
    try {
      await _firebase.deleteVariableExpense(id);
    } catch (e) {
      throw Exception('Erro ao deletar gasto variável no Firebase');
    }
  }

  Future<double> getTotalCurrentMonth() async {
    try {
      final list = await getAll();
      final now = DateTime.now();

      double total = 0;
      for (final e in list) {
        if (e.date.month == now.month && e.date.year == now.year) {
          total += e.value;
        }
      }
      return total;
    } catch (e) {
      return 0;
    }
  }
}
