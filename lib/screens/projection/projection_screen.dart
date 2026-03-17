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

  final NumberFormat _currency = NumberFormat.currency(
    locale: 'pt_BR',
    symbol: 'R\$',
  );

  List<ProjectionMonth> _projections = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProjection();
  }

  Future<void> _loadProjection() async {
    final expenses = await _expenseService.loadExpenses();
    final now = DateTime.now();
    final incomeData = await _incomeService.getIncomeForMonth(
      now.month,
      now.year,
    );

    final income = incomeData?.total ?? 0;

    final projections = _projectionService.simulate(
      expenses: expenses,
      income: income,
    );

    setState(() {
      _projections = projections;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Projeção Financeira'),
        backgroundColor: const Color(0xFF2B5876),
        foregroundColor: Colors.white,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _projections.length,
        itemBuilder: (context, index) {
          final projection = _projections[index];
          final date = DateTime(projection.year, projection.month);

          return Card(
            child: ListTile(
              title: Text(DateFormat('MMMM yyyy', 'pt_BR').format(date)),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Renda: ${_currency.format(projection.income)}'),
                  Text('Contas: ${_currency.format(projection.expenses)}'),
                ],
              ),
              trailing: Text(
                _currency.format(projection.balance),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: projection.balance >= 0 ? Colors.green : Colors.red,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
