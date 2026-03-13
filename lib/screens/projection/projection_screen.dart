import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/projection_month.dart';
import '../../services/expense_service.dart';
import '../../services/income_service.dart';
import '../../services/projection_service.dart';

class ProjectionScreen extends StatefulWidget {
  const ProjectionScreen({super.key});

  @override
  State<ProjectionScreen> createState() => _ProjectionScreenState();
}

class _ProjectionScreenState extends State<ProjectionScreen> {
  final ExpenseService _expenseService = ExpenseService();
  final IncomeService _incomeService = IncomeService();
  final ProjectionService _projectionService = ProjectionService();

  final _currency = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

  List<ProjectionMonth> _months = [];

  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final expenses = await _expenseService.loadExpenses();

    final now = DateTime.now();

    final incomeData = await _incomeService.getIncomeForMonth(
      now.month,
      now.year,
    );

    final income = incomeData?.total ?? 0;

    final result = _projectionService.simulate(
      expenses: expenses,
      income: income,
    );

    setState(() {
      _months = result;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Projeção Financeira"),
        backgroundColor: const Color(0xFF2B5876),
        foregroundColor: Colors.white,
      ),
      body: ListView.builder(
        itemCount: _months.length,
        itemBuilder: (context, index) {
          final m = _months[index];

          final date = DateTime(m.year, m.month);

          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: ListTile(
              title: Text(DateFormat("MMMM yyyy", "pt_BR").format(date)),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Renda: ${_currency.format(m.income)}"),
                  Text("Contas: ${_currency.format(m.expenses)}"),
                ],
              ),
              trailing: Text(
                _currency.format(m.balance),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: m.balance >= 0 ? Colors.green : Colors.red,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
