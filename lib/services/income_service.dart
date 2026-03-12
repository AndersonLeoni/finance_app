import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/income.dart';

class IncomeService {
  static const _key = "income_data";

  Future<void> saveIncome(Income income) async {
    final prefs = await SharedPreferences.getInstance();

    final data = await getAllIncome();
    data.removeWhere((i) => i.month == income.month && i.year == income.year);

    data.add(income);

    final encoded = jsonEncode(data.map((e) => e.toMap()).toList());

    await prefs.setString(_key, encoded);
  }

  Future<List<Income>> getAllIncome() async {
    final prefs = await SharedPreferences.getInstance();

    final json = prefs.getString(_key);

    if (json == null) return [];

    final decoded = jsonDecode(json) as List;

    return decoded.map((e) => Income.fromMap(e)).toList();
  }

  Future<Income?> getIncomeForMonth(int month, int year) async {
    final list = await getAllIncome();

    try {
      return list.firstWhere((i) => i.month == month && i.year == year);
    } catch (_) {
      return null;
    }
  }
}
