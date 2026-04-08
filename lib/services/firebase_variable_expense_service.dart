import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/variable_expense.dart';

class FirebaseVariableExpenseService {
  final _db = FirebaseFirestore.instance;
  final _collection = 'variable_expenses';

  Future<void> addVariableExpense(VariableExpense e) async {
    await _db.collection(_collection).doc(e.id).set(e.toMap());
  }

  Future<List<VariableExpense>> getVariableExpenses() async {
    final snapshot = await _db.collection(_collection).get();
    return snapshot.docs.map((doc) => VariableExpense.fromMap(doc.data())).toList();
  }

  Future<void> deleteVariableExpense(String id) async {
    await _db.collection(_collection).doc(id).delete();
  }

  Future<void> updateVariableExpense(VariableExpense e) async {
    await _db.collection(_collection).doc(e.id).update(e.toMap());
  }
}
