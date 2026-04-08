import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/income.dart';

class FirebaseIncomeService {
  final _db = FirebaseFirestore.instance;
  final _collection = 'incomes';

  Future<void> saveIncome(Income income) async {
    // Usamos um ID previsível baseado no mês e ano para facilitar a atualização
    final id = 'income_${income.month}_${income.year}';
    await _db.collection(_collection).doc(id).set(income.toMap());
  }

  Future<List<Income>> getAllIncome() async {
    final snapshot = await _db.collection(_collection).get();
    return snapshot.docs.map((doc) => Income.fromMap(doc.data())).toList();
  }

  Future<Income?> getIncomeForMonth(int month, int year) async {
    final id = 'income_${month}_${year}';
    final doc = await _db.collection(_collection).doc(id).get();
    
    if (doc.exists && doc.data() != null) {
      return Income.fromMap(doc.data()!);
    }
    return null;
  }
}
