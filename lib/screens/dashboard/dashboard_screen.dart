import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/expense.dart';
import '../../models/projection_month.dart';
import '../../services/expense_service.dart';
import '../../services/income_service.dart';
import '../../services/variable_expense_service.dart';
import '../../services/projection_service.dart';

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

  final NumberFormat _currency = NumberFormat.currency(
    locale: 'pt_BR',
    symbol: 'R\$',
  );

  double _income = 0;
  double _fixedExpenses = 0;
  double _variableExpenses = 0;
  double _totalExpenses = 0;
  double _balance = 0;
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

    final incomeData = await _incomeService.getIncomeForMonth(
      now.month,
      now.year,
    );

    // --- CORRIGIDO: CHAMANDO O SERVIÇO CORRETAMENTE ---
    final variableTotal = await _variableService.getTotalCurrentMonth();

    double fixedTotal = 0;
    int installments = 0;

    for (final e in expenses) {
      if (e.isActive) {
        fixedTotal += e.value;
      }
      if (e.type == ExpenseType.installment && !e.isCompleted) {
        installments++;
      }
    }

    final income = incomeData?.total ?? 0;
    final totalExpenses = fixedTotal + variableTotal;
    final balance = income - totalExpenses;

    final projections = _projectionService.simulate(
      expenses: expenses,
      income: income,
    );

    setState(() {
      _income = income;
      _fixedExpenses = fixedTotal;
      _variableExpenses = variableTotal;
      _totalExpenses = totalExpenses;
      _balance = balance;
      _activeInstallments = installments;
      _nextMonth = projections.length > 1 ? projections[1] : null;
      _in6Months = projections.length > 6 ? projections[6] : null;
      _in12Months = projections.length > 12 ? projections[12] : null;
      _loading = false;
    });
  }

  Widget _card({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.15),
          child: Icon(icon, color: color),
        ),
        title: Text(title),
        subtitle: Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
    );
  }

  Widget _projectionCard(String title, ProjectionMonth? data) {
    if (data == null) return const SizedBox();

    return Card(
      child: ListTile(
        title: Text(title),
        trailing: Text(
          _currency.format(data.balance),
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: data.balance >= 0 ? Colors.green : Colors.red,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
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
            _card(
              title: 'Renda do mês',
              value: _currency.format(_income),
              icon: Icons.account_balance_wallet,
              color: Colors.green,
            ),
            _card(
              title: 'Contas fixas + parcelas',
              value: _currency.format(_fixedExpenses),
              icon: Icons.credit_card,
              color: Colors.red,
            ),
            _card(
              title: 'Gastos variáveis',
              value: _currency.format(_variableExpenses),
              icon: Icons.receipt_long,
              color: Colors.orange,
            ),
            _card(
              title: 'Total de saídas',
              value: _currency.format(_totalExpenses),
              icon: Icons.payments,
              color: Colors.deepOrange,
            ),
            _card(
              title: 'Saldo livre',
              value: _currency.format(_balance),
              icon: Icons.trending_up,
              color: _balance >= 0 ? Colors.blue : Colors.red,
            ),
            _card(
              title: 'Parcelas ativas',
              value: _activeInstallments.toString(),
              icon: Icons.layers,
              color: Colors.purple,
            ),
            const SizedBox(height: 20),
            const Text(
              'Tendência futura',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 10),
            _projectionCard('Próximo mês', _nextMonth),
            _projectionCard('Em 6 meses', _in6Months),
            _projectionCard('Em 12 meses', _in12Months),
          ],
        ),
      ),
    );
  }
}
