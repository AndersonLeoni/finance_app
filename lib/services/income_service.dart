import '../models/income.dart';
import 'firebase_income_service.dart';

class IncomeService {
  final _firebase = FirebaseIncomeService();

  Future<void> saveIncome(Income income) async {
    try {
      await _firebase.saveIncome(income);
    } catch (e) {
      throw Exception('Erro ao salvar renda no Firebase');
    }
  }

  Future<List<Income>> getAllIncome() async {
    try {
      return await _firebase.getAllIncome();
    } catch (e) {
      return [];
    }
  }

  Future<Income?> getIncomeForMonth(int month, int year) async {
    try {
      return await _firebase.getIncomeForMonth(month, year);
    } catch (e) {
      return null;
    }
  }
}
