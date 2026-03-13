import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/expense.dart';
import '../../services/expense_service.dart';
import '../../services/income_service.dart';
import '../../services/variable_expense_service.dart';
import '../../services/projection_service.dart';
import '../../models/projection_month.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final ExpenseService _expenseService = ExpenseService();
  final IncomeService _incomeService = IncomeService();
  final VariableExpenseService _variableService = VariableExpenseService();
  final ProjectionService _projectionService = ProjectionService();

  final _currency = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

  double _totalExpenses = 0;
  double _income = 0;
  double _balance = 0;
  double _variableTotal = 0;
  int _activeInstallments = 0;

  ProjectionMonth? _nextMonth;
  ProjectionMonth? _in6Months;
  ProjectionMonth? _in12Months;

  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final expenses = await _expenseService.loadExpenses();
    final now = DateTime.now();
    final incomeData = await _incomeService.getIncomeForMonth(now.month, now.year);

    double total = 0;
    int installments = 0;

    for (Expense e in expenses) {
      if (e.isActive) total += e.value;
      if (e.type == ExpenseType.installment && !e.isCompleted) installments++;
    }

    final varTotal = await _variableService.getTotalCurrentMonth();
    total += varTotal;

    final income = incomeData?.total ?? 0;

    final projection = _projectionService.simulate(
      expenses: expenses,
      income: income,
    );

    setState(() {
      _totalExpenses = total;
      _income = income;
      _balance = income - total;
      _variableTotal = varTotal;
      _activeInstallments = installments;
      _nextMonth = projection.length > 1 ? projection[1] : null;
      _in6Months = projection.length > 6 ? projection[6] : null;
      _in12Months = projection.length > 12 ? projection[12] : null;
      _loading = false;
    });
  }

  Widget _card(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
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

  Widget _projectionCard(String label, ProjectionMonth? month) {
    if (month == null) return const SizedBox.shrink();

    final isPositive = month.balance >= 0;

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
            Text(
              _currency.format(month.balance),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: isPositive ? Colors.green : Colors.red,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard Financeiro'),
        backgroundColor: const Color(0xFF2B5876),
        foregroundColor: Colors.white,
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [

            const Text(
              'MÊS ATUAL',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
                letterSpacing: 1.2,
              ),
            ),

            const SizedBox(height: 8),

            _card('Renda do mês', _currency.format(_income),
                Icons.account_balance_wallet, Colors.green),
            const SizedBox(height: 8),

            _card('Contas fixas + parcelas',
                _currency.format(_totalExpenses - _variableTotal),
                Icons.credit_card, Colors.red),
            const SizedBox(height: 8),

            _card('Gastos variáveis', _currency.format(_variableTotal),
                Icons.receipt_long, Colors.orange),
            const SizedBox(height: 8),

            _card('Saldo livre', _currency.format(_balance),
                Icons.trending_up,
                _balance >= 0 ? Colors.blue : Colors.red),
            const SizedBox(height: 8),

            _card('Parcelas ativas', _activeInstallments.toString(),
                Icons.payments, Colors.purple),

            const SizedBox(height: 24),

            const Text(
              'TENDÊNCIA FUTURA',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
                letterSpacing: 1.2,
              ),
            ),

            const SizedBox(height: 8),

            _projectionCard('Próximo mês', _nextMonth),
            const SizedBox(height: 8),
            _projectionCard('Em 6 meses', _in6Months),
            const SizedBox(height: 8),
            _projectionCard('Em 12 meses', _in12Months),

            const SizedBox(height: 16),

            const Text(
              '* Puxe para baixo para atualizar',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}
