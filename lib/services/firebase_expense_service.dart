import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/expense.dart';

class FirebaseExpenseService {
  final _db = FirebaseFirestore.instance;
  final _collection = 'expenses';

  Future<void> addExpense(Expense e) async {
    await _db.collection(_collection).doc(e.id).set(e.toMap());
  }

  Future<List<Expense>> getExpenses() async {
    final snapshot = await _db.collection(_collection).get();

    return snapshot.docs.map((doc) => Expense.fromMap(doc.data())).toList();
  }

  Future<void> deleteExpense(String id) async {
    await _db.collection(_collection).doc(id).delete();
  }

  Future<void> updateExpense(Expense e) async {
    await _db.collection(_collection).doc(e.id).update(e.toMap());
  }
}
