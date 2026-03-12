import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/expense.dart';
import '../../models/income.dart';
import '../../services/expense_service.dart';
import '../../services/income_service.dart';
import '../../services/variable_expense_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final ExpenseService _expenseService = ExpenseService();
  final IncomeService _incomeService = IncomeService();
  final VariableExpenseService _variableService = VariableExpenseService();

  final _currency = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

  double _totalExpenses = 0;
  double _income = 0;
  double _balance = 0;
  int _activeInstallments = 0;

  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final expenses = await _expenseService.loadExpenses();

    final now = DateTime.now();

    final incomeData = await _incomeService.getIncomeForMonth(
      now.month,
      now.year,
    );

    double total = 0;
    int installments = 0;

    for (Expense e in expenses) {
      if (e.isActive) {
        total += e.value;
      }

      if (e.type == ExpenseType.installment && !e.isCompleted) {
        installments++;
      }
    }

    final variableTotal = await _variableService.getTotalCurrentMonth();
    total += variableTotal;

    double salary = incomeData?.total ?? 0;

    setState(() {
      _totalExpenses = total;
      _income = salary;
      _balance = salary - total;
      _activeInstallments = installments;
      _loading = false;
    });
  }

  Widget _card(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: color.withOpacity(0.15),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 13, color: Colors.grey),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Dashboard Financeiro"),
        backgroundColor: const Color(0xFF2B5876),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _card(
              "Renda do mês",
              _currency.format(_income),
              Icons.account_balance_wallet,
              Colors.green,
            ),
            const SizedBox(height: 12),
            _card(
              "Contas mensais",
              _currency.format(_totalExpenses),
              Icons.credit_card,
              Colors.red,
            ),
            const SizedBox(height: 12),
            _card(
              "Saldo livre",
              _currency.format(_balance),
              Icons.trending_up,
              Colors.blue,
            ),
            const SizedBox(height: 12),
            _card(
              "Parcelas ativas",
              _activeInstallments.toString(),
              Icons.payments,
              Colors.orange,
            ),
          ],
        ),
      ),
    );
  }
}
